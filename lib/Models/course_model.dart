import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String name;
  final String courseCode;    // Add this field
  final String description;   // Add this field
  final String lecturerId;
  final String lecturerName;  // Add this field
  final List<String> units;
  final List<String> enrolledStudents;
  final Timestamp? createdAt;

  CourseModel({
    required this.id,
    required this.name,
    required this.courseCode,
    required this.description,
    required this.lecturerId,
    required this.lecturerName,
    this.units = const [],
    this.enrolledStudents = const [],
    this.createdAt,
  });

  // Update the fromFirestore and toFirestore methods to include the new fields
  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      name: data['name'] ?? '',
      courseCode: data['courseCode'] ?? '',
      description: data['description'] ?? '',
      lecturerId: data['lecturerId'] ?? '',
      lecturerName: data['lecturerName'] ?? '',
      units: List<String>.from(data['units'] ?? []),
      enrolledStudents: List<String>.from(data['enrolledStudents'] ?? []),
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'courseCode': courseCode,
      'description': description,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'units': units,
      'enrolledStudents': enrolledStudents,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}