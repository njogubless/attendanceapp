import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final List<String>? courses;
  String status;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.courses,
    this.status = 'pending',
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      status: data['status'] ?? 'pending',
      courses: List<String>.from(data['courses'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'courses': courses,
      'status': status,
    };
  }
}
