import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum TaskPriority { high, medium, low }
enum TaskRecurrence { once, habit, weekly, monthly }

class TaskCategoryMeta {
  final String id;
  final String title;
  final String shortTitle;
  final IconData icon;
  final Color color;

  const TaskCategoryMeta({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.icon,
    required this.color,
  });

  static const List<TaskCategoryMeta> all = [
    TaskCategoryMeta(
      id: 'din',
      title: 'Din & Spirituality',
      shortTitle: 'Din',
      icon: Icons.nightlight_round,
      color: AppTheme.dinColor,
    ),
    TaskCategoryMeta(
      id: 'lang',
      title: 'Languages (DE & FR)',
      shortTitle: 'Languages',
      icon: Icons.translate,
      color: AppTheme.langColor,
    ),
    TaskCategoryMeta(
      id: 'cyber',
      title: 'Cybersécurité',
      shortTitle: 'Cyber',
      icon: Icons.security,
      color: AppTheme.cyberColor,
    ),
    TaskCategoryMeta(
      id: 'train',
      title: 'Calisthenics & Training',
      shortTitle: 'Training',
      icon: Icons.fitness_center,
      color: AppTheme.trainColor,
    ),
    TaskCategoryMeta(
      id: 'work',
      title: 'Lkhedma & Career',
      shortTitle: 'Lkhedma',
      icon: Icons.work_outline,
      color: AppTheme.workColor,
    ),
    TaskCategoryMeta(
      id: 'proj',
      title: 'My Personal Projects',
      shortTitle: 'Projects',
      icon: Icons.rocket_launch,
      color: AppTheme.projColor,
    ),
  ];

  static TaskCategoryMeta getById(String id) {
    return all.firstWhere(
      (c) => c.id == id,
      orElse: () => all[0],
    );
  }
}

class TaskItem {
  final String id;
  String text;
  String category;
  bool completed;
  String priority; // 'high', 'medium', 'low'
  String recurrence; // 'once', 'habit', 'weekly', 'monthly'
  String? dueDate;
  String? scheduleStart;
  String? weeklyTargetId;
  List<String> completedDates;
  List<Map<String, dynamic>> subtasks;

  int updatedAt;

  TaskItem({
    required this.id,
    required this.text,
    required this.category,
    this.completed = false,
    this.priority = 'medium',
    this.recurrence = 'once',
    this.dueDate,
    this.scheduleStart,
    this.weeklyTargetId,
    this.updatedAt = 0,
    List<String>? completedDates,
    List<Map<String, dynamic>>? subtasks,
  })  : completedDates = completedDates ?? [],
        subtasks = subtasks ?? [];

  TaskPriority get priorityEnum {
    switch (priority.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  TaskRecurrence get recurrenceEnum {
    switch (recurrence.toLowerCase()) {
      case 'habit':
      case 'daily':
        return TaskRecurrence.habit;
      case 'weekly':
        return TaskRecurrence.weekly;
      case 'monthly':
        return TaskRecurrence.monthly;
      default:
        return TaskRecurrence.once;
    }
  }

  TaskCategoryMeta get categoryMeta => TaskCategoryMeta.getById(category);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'completed': completed,
      'priority': priority,
      'recurrence': recurrence,
      if (dueDate != null) 'dueDate': dueDate,
      if (scheduleStart != null) 'scheduleStart': scheduleStart,
      if (weeklyTargetId != null) 'weeklyTargetId': weeklyTargetId,
      'completedDates': completedDates,
      'subtasks': subtasks,
      'updatedAt': updatedAt,
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json, {String defaultCategory = 'din'}) {
    return TaskItem(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text']?.toString() ?? '',
      category: json['category']?.toString() ?? defaultCategory,
      completed: json['completed'] == true,
      priority: json['priority']?.toString() ?? 'medium',
      recurrence: json['recurrence']?.toString() ?? 'once',
      dueDate: json['dueDate']?.toString(),
      scheduleStart: json['scheduleStart']?.toString(),
      weeklyTargetId: json['weeklyTargetId']?.toString(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as num).toInt()
          : (json['updated_at'] != null
              ? (DateTime.tryParse(json['updated_at'].toString())?.millisecondsSinceEpoch ?? 0)
              : 0),
      completedDates: (json['completedDates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }

  TaskItem copyWith({
    String? id,
    String? text,
    String? category,
    bool? completed,
    String? priority,
    String? recurrence,
    String? dueDate,
    String? scheduleStart,
    String? weeklyTargetId,
    int? updatedAt,
    List<String>? completedDates,
    List<Map<String, dynamic>>? subtasks,
  }) {
    return TaskItem(
      id: id ?? this.id,
      text: text ?? this.text,
      category: category ?? this.category,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      recurrence: recurrence ?? this.recurrence,
      dueDate: dueDate ?? this.dueDate,
      scheduleStart: scheduleStart ?? this.scheduleStart,
      weeklyTargetId: weeklyTargetId ?? this.weeklyTargetId,
      updatedAt: updatedAt ?? this.updatedAt,
      completedDates: completedDates ?? List.from(this.completedDates),
      subtasks: subtasks ?? List.from(this.subtasks),
    );
  }
}
