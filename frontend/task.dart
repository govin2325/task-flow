enum TaskStatus { todo, inProgress, done }

extension TaskStatusX on TaskStatus {
  String get apiValue => switch (this) {
        TaskStatus.todo => 'todo',
        TaskStatus.inProgress => 'in_progress',
        TaskStatus.done => 'done',
      };

  static TaskStatus fromApi(String value) => switch (value) {
        'todo' => TaskStatus.todo,
        'in_progress' => TaskStatus.inProgress,
        'done' => TaskStatus.done,
        _ => TaskStatus.todo,
      };

  String get label => switch (this) {
        TaskStatus.todo => 'Backlog',
        TaskStatus.inProgress => 'In Progress',
        TaskStatus.done => 'Done',
      };

  String get emoji => switch (this) {
        TaskStatus.todo => '📋',
        TaskStatus.inProgress => '⚡',
        TaskStatus.done => '✅',
      };
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.blockedBy,
  });

  final int id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final TaskStatus status;
  final int? blockedBy;

  bool get isBlocked => blockedBy != null;

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String).toLocal()
          : null,
      status: TaskStatusX.fromApi(json['status'] as String? ?? 'todo'),
      blockedBy: json['blocked_by'] as int?,
    );
  }

  Map<String, dynamic> toUpsertJson() => {
        'title': title,
        'description': description,
        'due_date': dueDate?.toUtc().toIso8601String(),
        'status': status.apiValue,
        'blocked_by': blockedBy,
      };

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool clearDueDate = false,
    TaskStatus? status,
    int? blockedBy,
    bool clearBlockedBy = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      status: status ?? this.status,
      blockedBy: clearBlockedBy ? null : (blockedBy ?? this.blockedBy),
    );
  }
}
