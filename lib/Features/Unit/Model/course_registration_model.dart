class CourseRegistrationModel {
  final String id;
  final String studentId;
  final String courseId;
  final String status; // 'pending', 'approved', 'rejected'
  final String? lecturerComment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CourseRegistrationModel({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.status,
    this.lecturerComment,
    required this.createdAt,
    this.updatedAt,
  });

  factory CourseRegistrationModel.fromJson(Map<String, dynamic> json) {
    return CourseRegistrationModel(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      courseId: json['courseId'] as String,
      status: json['status'] as String,
      lecturerComment: json['lecturerComment'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'courseId': courseId,
      'status': status,
      'lecturerComment': lecturerComment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}