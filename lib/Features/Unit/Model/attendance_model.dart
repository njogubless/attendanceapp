class AttendanceModel {
  final String id;
  final String unitId;
  final String userId; // Can be student ID or lecturer ID
  final String userType; // 'lecturer' or 'student'
  final String userName;
  final String userEmail;
  final String courseId;
  final String courseName;
  final String courseCode;
  final String venue;
  final DateTime date;
  final DateTime timestamp;

  AttendanceModel({
    required this.id,
    required this.unitId,
    required this.userId,
    required this.userType,
    required this.userName,
    required this.userEmail,
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.venue,
    required this.date,
    required this.timestamp,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      unitId: json['unitId'] as String,
      userId: json['userId'] as String,
      userType: json['userType'] as String,
      userName: json['userName'] as String,
      userEmail: json['userEmail'] as String,
      courseId: json['courseId'] as String,
      courseName: json['courseName'] as String,
      courseCode: json['courseCode'] as String,
      venue: json['venue'] as String,
      date: (json['date'] as Timestamp).toDate(),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unitId': unitId,
      'userId': userId,
      'userType': userType,
      'userName': userName,
      'userEmail': userEmail,
      'courseId': courseId,
      'courseName': courseName,
      'courseCode': courseCode,
      'venue': venue,
      'date': Timestamp.fromDate(date),
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}