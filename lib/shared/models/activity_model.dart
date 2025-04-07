class ActivityModel {
  final String id;
  final String groupId;
  final String type; // 'expense_added', 'expense_deleted', 'member_added', 'settlement'
  final String actorId; // User who performed the action
  final String? targetId; // Optional: User who is the target of the action
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? data; // Optional additional data

  ActivityModel({
    required this.id,
    required this.groupId,
    required this.type,
    required this.actorId,
    this.targetId,
    required this.description,
    required this.timestamp,
    this.data,
  });

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'] as String,
      groupId: map['groupId'] as String,
      type: map['type'] as String,
      actorId: map['actorId'] as String,
      targetId: map['targetId'] as String?,
      description: map['description'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      data: map['data'] != null ? Map<String, dynamic>.from(map['data'] as Map) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'type': type,
      'actorId': actorId,
      'targetId': targetId,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
} 