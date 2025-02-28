class CourseModel {
  final String id;
  final String name;
  final String code;
  final String lecturerId;
  final List<String> unitIds;
  final DateTime createdAt;
  
  CourseModel({
    required this.id,
    required this.name,
    required this.code,
    required this.lecturerId,
    required this.unitIds,
    required this.createdAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      lecturerId: json['lecturerId'] as String,
      unitIds: List<String>.from(json['unitIds'] as List),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'lecturerId': lecturerId,
      'unitIds': unitIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}