class UserModel {
  final String id;
  final String name;
  final String email;
  final String? password;
  final String? avatar;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.password,
    this.avatar,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'avatar': avatar,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String?,
      avatar: map['avatar'] as String?,
    );
  }

  UserModel copyWith({
    String? name,
    String? password,
    String? avatar,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      password: password ?? this.password,
      avatar: avatar ?? this.avatar,
    );
  }
} 