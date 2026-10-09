class ObjectiveItem {
  final String id;
  String text;
  bool completed;
  int updatedAt;
  String parentId;

  ObjectiveItem({
    required this.id,
    required this.text,
    this.completed = false,
    this.updatedAt = 0,
    this.parentId = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'completed': completed,
      'updatedAt': updatedAt,
      'parentId': parentId,
    };
  }

  factory ObjectiveItem.fromJson(Map<String, dynamic> json) {
    return ObjectiveItem(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text']?.toString() ?? '',
      completed: json['completed'] == true,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as num).toInt()
          : (json['updated_at'] != null
              ? (DateTime.tryParse(json['updated_at'].toString())?.millisecondsSinceEpoch ?? 0)
              : 0),
      parentId: json['parentId']?.toString() ?? '',
    );
  }
}

class DashboardObjectives {
  List<ObjectiveItem> yearly;
  List<ObjectiveItem> monthly;
  List<ObjectiveItem> weekly;

  DashboardObjectives({
    List<ObjectiveItem> ? yearly,
    List<ObjectiveItem>? monthly,
    List<ObjectiveItem>? weekly,
  })  : yearly = yearly ?? [],
        monthly = monthly ?? [],
        weekly = weekly ?? [];

  Map<String, dynamic> toJson() {
    return {
      'yearly': yearly.map((e) => e.toJson()).toList(),
      'monthly': monthly.map((e) => e.toJson()).toList(),
      'weekly': weekly.map((e) => e.toJson()).toList(),
    };
  }

  factory DashboardObjectives.fromJson(Map<String, dynamic> json) {
    return DashboardObjectives(
      yearly: (json['yearly'] as List<dynamic>?)
              ?.map((e) => ObjectiveItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      monthly: (json['monthly'] as List<dynamic>?)
              ?.map((e) => ObjectiveItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      weekly: (json['weekly'] as List<dynamic>?)
              ?.map((e) => ObjectiveItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );
  }
}
