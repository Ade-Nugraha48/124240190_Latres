class UserModel {
  final int? id;
  final String username;
  final String password;

  const UserModel({
    this.id,
    required this.username,
    required this.password,
  });

  UserModel copyWith({
    int? id,
    String? username,
    String? password,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'username': username,
      'password': password,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: (map['username'] ?? '') as String,
      password: (map['password'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          password == other.password;

  @override
  int get hashCode => id.hashCode ^ username.hashCode ^ password.hashCode;

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, password: [PROTECTED])';
  }
}

