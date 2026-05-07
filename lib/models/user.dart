class User {
  final int? id;
  final String icNumber;
  final String realName;
  final String randomUsername;
  final String password;
  final String role; // 'admin' or 'user'

  const User({
    this.id,
    required this.icNumber,
    required this.realName,
    required this.randomUsername,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'ic_number': icNumber,
        'real_name': realName,
        'random_username': randomUsername,
        'password': password,
        'role': role,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'] as int?,
        icNumber: map['ic_number'] as String,
        realName: map['real_name'] as String,
        randomUsername: map['random_username'] as String,
        password: map['password'] as String,
        role: map['role'] as String,
      );

  User copyWith({
    int? id,
    String? icNumber,
    String? realName,
    String? randomUsername,
    String? password,
    String? role,
  }) =>
      User(
        id: id ?? this.id,
        icNumber: icNumber ?? this.icNumber,
        realName: realName ?? this.realName,
        randomUsername: randomUsername ?? this.randomUsername,
        password: password ?? this.password,
        role: role ?? this.role,
      );
}
