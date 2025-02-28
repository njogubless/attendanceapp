class UnitModel {
  final String id;
  final String name;
  final String code;
  final String courseId;
  final String lecturerId;
  final String venue;
  final List<String> schedules; // e.g., ["Monday 10:00-12:00", "Wednesday 14:00-16:00"]
  final DateTime createdAt;

  UnitModel({
    required this.id,
    required this.name,
    required this.code,
    required this.courseId,
    required this.lecturerId,
    required this.venue,
    required this.schedules,
    required this.createdAt,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      courseId: json['courseId'] as String,
      lecturerId: json['lecturerId'] as String,
      venue: json['venue'] as String,
      schedules: List<String>.from(json['schedules'] as List),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'courseId': courseId,
      'lecturerId': lecturerId,
      'venue': venue,
      'schedules': schedules,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}