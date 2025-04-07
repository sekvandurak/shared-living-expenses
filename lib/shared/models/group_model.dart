class GroupModel {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final String? creatorName;
  final DateTime createdAt;
  final List<String> members;

  const GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    this.creatorName,
    required this.createdAt,
    this.members = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      createdBy: map['createdBy'] as String,
      creatorName: map['creatorName'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      members: List<String>.from(map['members'] as List? ?? []),
    );
  }

  GroupModel copyWith({
    String? name,
    String? description,
    List<String>? members,
  }) {
    return GroupModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy,
      creatorName: creatorName,
      createdAt: createdAt,
      members: members ?? this.members,
    );
  }

  String get creator => creatorName ?? createdBy;
} 