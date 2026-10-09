class HabitItem {
  final String id;
  String name;
  List<int> days; // 0 = Sun, 1 = Mon, ..., 6 = Sat
  String kind; // 'check' | 'quantity'
  int target;
  String unit;
  String? objective;
  String start; // 'YYYY-MM-DD'
  bool archived;
  Map<String, int> history; // dateKey -> count completed
  int updatedAt;

  HabitItem({
    required this.id,
    required this.name,
    List<int>? days,
    this.kind = 'check',
    this.target = 1,
    this.unit = '',
    this.objective,
    String? start,
    this.archived = false,
    Map<String, int>? history,
    int? updatedAt,
  })  : days = days ?? [0, 1, 2, 3, 4, 5, 6],
        start = start ?? _defaultToday(),
        history = history ?? {},
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  static String _defaultToday() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  bool isScheduledOn(String dateKey) {
    if (dateKey.compareTo(start) < 0) return false;
    final parsed = DateTime.tryParse(dateKey);
    if (parsed == null) return false;
    final dayOfWeek = parsed.weekday % 7; // DateTime: 1=Mon..7=Sun -> 0=Sun..6=Sat
    return days.contains(dayOfWeek);
  }

  bool isCompletedOn(String dateKey) {
    final val = history[dateKey] ?? 0;
    return val >= (target > 0 ? target : 1);
  }

  int countOn(String dateKey) {
    return history[dateKey] ?? 0;
  }

  int getStreak(String todayKey) {
    final todayDt = DateTime.tryParse(todayKey) ?? DateTime.now();
    int count = 0;
    DateTime checkDt = todayDt;

    // If scheduled today and not done yet, don't count today as broken yet: check backwards from yesterday
    if (isScheduledOn(todayKey) && !isCompletedOn(todayKey)) {
      checkDt = todayDt.subtract(const Duration(days: 1));
    }

    for (int i = 0; i < 365; i++) {
      final key = _formatDate(checkDt);
      if (key.compareTo(start) < 0) break;
      if (!isScheduledOn(key)) {
        checkDt = checkDt.subtract(const Duration(days: 1));
        continue;
      }
      if (isCompletedOn(key)) {
        count++;
        checkDt = checkDt.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return count;
  }

  String get frequencyDescription {
    if (days.length == 7) return 'Every day';
    if (days.length == 5 && !days.contains(0) && !days.contains(6)) return 'Weekdays';
    if (days.length == 2 && days.contains(0) && days.contains(6)) return 'Weekends';
    return '${days.length} days/week';
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'days': days,
      'kind': kind,
      'target': target,
      'unit': unit,
      'objective': objective ?? '',
      'start': start,
      'archived': archived,
      'history': history,
      'updatedAt': updatedAt,
    };
  }

  factory HabitItem.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    final parsedDays = <int>[];
    if (rawDays is List) {
      for (final d in rawDays) {
        if (d is num) parsedDays.add(d.toInt());
      }
    }

    final rawHistory = json['history'];
    final parsedHistory = <String, int>{};
    if (rawHistory is Map) {
      rawHistory.forEach((k, v) {
        if (v is num) parsedHistory[k.toString()] = v.toInt();
      });
    }

    final rawUpdatedAt = json['updatedAt'];
    final parsedUpdatedAt = rawUpdatedAt is num ? rawUpdatedAt.toInt() : (rawUpdatedAt is String ? int.tryParse(rawUpdatedAt) ?? 0 : 0);

    return HabitItem(
      id: json['id']?.toString() ?? 'habit_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? '',
      days: parsedDays.isNotEmpty ? parsedDays : [0, 1, 2, 3, 4, 5, 6],
      kind: json['kind']?.toString() ?? 'check',
      target: json['target'] is num ? (json['target'] as num).toInt() : 1,
      unit: json['unit']?.toString() ?? '',
      objective: json['objective']?.toString().isNotEmpty == true ? json['objective'].toString() : null,
      start: json['start']?.toString() ?? _defaultToday(),
      archived: json['archived'] == true,
      history: parsedHistory,
      updatedAt: parsedUpdatedAt > 0 ? parsedUpdatedAt : null,
    );
  }

  HabitItem copyWith({
    String? id,
    String? name,
    List<int>? days,
    String? kind,
    int? target,
    String? unit,
    String? objective,
    String? start,
    bool? archived,
    Map<String, int>? history,
    int? updatedAt,
  }) {
    return HabitItem(
      id: id ?? this.id,
      name: name ?? this.name,
      days: days ?? List.from(this.days),
      kind: kind ?? this.kind,
      target: target ?? this.target,
      unit: unit ?? this.unit,
      objective: objective ?? this.objective,
      start: start ?? this.start,
      archived: archived ?? this.archived,
      history: history ?? Map.from(this.history),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
