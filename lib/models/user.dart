import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String? id; // Firestore document ID
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
        'icNumber': icNumber,
        'realName': realName,
        'randomUsername': randomUsername,
        'password': password,
        'role': role,
      };

  factory User.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return User(
      id: doc.id,
      icNumber: d['icNumber'] as String,
      realName: d['realName'] as String,
      randomUsername: d['randomUsername'] as String,
      password: d['password'] as String,
      role: d['role'] as String,
    );
  }

  User copyWith({
    String? id,
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
