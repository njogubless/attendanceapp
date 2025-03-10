import 'package:cloud_firestore/cloud_firestore.dart';

class UnitModel {
  final String id;
  final String name;
  final String courseId;
  final String lecturerId;
  final List<String> enrolledStudents;
  final Timestamp? createdAt;
  final String description;

  UnitModel({
    required this.id,
    required this.name,
    required this.courseId,
    required this.lecturerId,
    this.enrolledStudents = const [],
    this.createdAt,
    this.description = '',
  });

  factory UnitModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UnitModel(
      id: doc.id,
      name: data['name'] ?? '',
      courseId: data['courseId'] ?? '',
      lecturerId: data['lecturerId'] ?? '',
      enrolledStudents: List<String>.from(data['enrolledStudents'] ?? []),
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'courseId': courseId,
      'lecturerId': lecturerId,
      'enrolledStudents': enrolledStudents,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  UnitModel copyWith({
    String? id,
    String? name,
    String? courseId,
    String? lecturerId,
    List<String>? enrolledStudents,
    Timestamp? createdAt,
    String? description,
  }) {
    return UnitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      courseId: courseId ?? this.courseId,
      lecturerId: lecturerId ?? this.lecturerId,
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'courseId': courseId,
      'lecturerId': lecturerId,
      'enrolledStudents': enrolledStudents,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'description': description,
    };
  }
}
