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
   final bool isActive; // Track if the course attendance is active
  final Timestamp? activationTime; // When attendance was activated
  final Timestamp? deactivationTime; 

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
     this.isActive = false,
    this.activationTime,
    this.deactivationTime,
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
      isActive: data['isActive'] ?? false,
      activationTime: data['activationTime'],
      deactivationTime: data['deactivationTime'],
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
       'isActive': isActive,
      'activationTime': activationTime,
      'deactivationTime': deactivationTime,
    };
  }

  CourseModel copyWith({
    String? id,
    String? name,
    String? courseCode,
    String? lecturerId,
    String? lecturerName,
    String? description,
    bool? isActive,
    Timestamp? activationTime,
    Timestamp? deactivationTime,
  }) {
    return CourseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      courseCode: courseCode ?? this.courseCode,
      lecturerId: lecturerId ?? this.lecturerId,
      lecturerName: lecturerName ?? this.lecturerName,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      activationTime: activationTime ?? this.activationTime,
      deactivationTime: deactivationTime ?? this.deactivationTime,
    );
  }
}