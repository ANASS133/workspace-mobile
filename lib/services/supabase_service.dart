import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class SupabaseRecord {
  final String key;
  final dynamic value;
  final String? updatedAt;

  SupabaseRecord({
    required this.key,
    required this.value,
    this.updatedAt,
  });

  factory SupabaseRecord.fromJson(Map<String, dynamic> json) {
    return SupabaseRecord(
      key: json['key']?.toString() ?? '',
      value: json['value'],
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class SupabaseService {
  final String url;
  final String anonKey;
  final String tableName;
  WebSocketChannel? _realtimeChannel;
  StreamSubscription<dynamic>? _realtimeSubscription;
  Timer? _heartbeat;
  Timer? _reconnect;
  int _messageRef = 1;
  bool _realtimeStopped = false;

  SupabaseService({
    this.url = 'https://cpagjchpwbsqjwnjnigk.supabase.co',
    this.anonKey = 'sb_publishable_5iMG-eox9sPl_Z1hB3FEpQ_rB4fBjoY',
    this.tableName = 'workspace_state',
  });

  Map<String, String> get _headers => {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
      };

  /// Subscribe to the table-level Postgres changes stream used by desktop.
  /// REST remains the source of the full state; Realtime only wakes the
  /// synchronizer, which avoids applying partial records or echo races.
  void startRealtime(void Function() onChange) {
    _realtimeStopped = false;
    _connectRealtime(onChange);
  }

  void _connectRealtime(void Function() onChange) {
    if (_realtimeStopped || _realtimeChannel != null) return;
    try {
      final realtimeUrl = url.replaceFirst(RegExp(r'^http'), 'ws');
      final uri = Uri.parse('$realtimeUrl/realtime/v1/websocket?apikey=${Uri.encodeQueryComponent(anonKey)}&vsn=1.0.0');
      final channel = WebSocketChannel.connect(uri);
      _realtimeChannel = channel;
      _realtimeSubscription = channel.stream.listen(
        (raw) {
          try {
            final message = jsonDecode(raw as String) as Map<String, dynamic>;
            if (message['event'] != 'postgres_changes') return;
            final data = message['payload']?['data'];
            final record = data is Map ? data['record'] : null;
            if (record is Map && record['key'] != null) onChange();
          } catch (_) {
            // A malformed/heartbeat response must not take down sync.
          }
        },
        onDone: () => _scheduleReconnect(onChange),
        onError: (_) => _scheduleReconnect(onChange),
      );
      channel.sink.add(jsonEncode({
        'topic': 'realtime:public:$tableName',
        'event': 'phx_join',
        'payload': {
          'config': {
            'postgres_changes': [
              {'event': '*', 'schema': 'public', 'table': tableName}
            ]
          }
        },
        'ref': '${_messageRef++}',
      }));
      _heartbeat = Timer.periodic(const Duration(seconds: 25), (_) {
        try {
          channel.sink.add(jsonEncode({
            'topic': 'phoenix', 'event': 'heartbeat', 'payload': {}, 'ref': '${_messageRef++}',
          }));
        } catch (_) {}
      });
    } catch (_) {
      _scheduleReconnect(onChange);
    }
  }

  void _scheduleReconnect(void Function() onChange) {
    _heartbeat?.cancel();
    _heartbeat = null;
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    _realtimeChannel = null;
    if (!_realtimeStopped && _reconnect == null) {
      _reconnect = Timer(const Duration(seconds: 5), () {
        _reconnect = null;
        _connectRealtime(onChange);
      });
    }
  }

  void dispose() {
    _realtimeStopped = true;
    _reconnect?.cancel();
    _heartbeat?.cancel();
    _realtimeSubscription?.cancel();
    _realtimeChannel?.sink.close();
  }

  /// Fetch all workspace state keys from Supabase
  Future<List<SupabaseRecord>?> fetchAll() async {
    try {
      final uri = Uri.parse('$url/rest/v1/$tableName?select=*');
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded
              .map((item) => SupabaseRecord.fromJson(Map<String, dynamic>.from(item as Map)))
              .where((r) => !r.key.startsWith('snapshot:'))
              .toList();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Upsert batch of key-value pairs
  Future<bool> upsertKeys(List<Map<String, dynamic>> entries) async {
    try {
      final uri = Uri.parse('$url/rest/v1/$tableName');
      final headers = {
        ..._headers,
        'Prefer': 'resolution=merge-duplicates',
      };

      final nowIso = DateTime.now().toUtc().toIso8601String();
      final bodyPayload = entries.map((entry) {
        final item = Map<String, dynamic>.from(entry);
        item['updated_at'] = nowIso;
        return item;
      }).toList();

      final body = jsonEncode(bodyPayload);
      final res = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 8));

      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Single key upsert
  Future<bool> upsertSingle(String key, dynamic value) async {
    return upsertKeys([{'key': key, 'value': value}]);
  }
}
