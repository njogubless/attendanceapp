// lib/services/course_service.dart
import 'package:attendanceapp/Models/course_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<CourseModel>> getCourses() {
    return _firestore.collection('courses').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => CourseModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addCourse(CourseModel course) async {
    try {
      await _firestore.collection('courses').add(course.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCourse(CourseModel course) async {
    try {
      await _firestore.collection('courses').doc(course.id).update(course.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      await _firestore.collection('courses').doc(courseId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> enrollStudent(String courseId, String studentId) async {
    try {
      await _firestore.collection('courses').doc(courseId).update({
        'enrolledStudents': FieldValue.arrayUnion([studentId])
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CourseModel>> getCoursesByLecturer(String lecturerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('courses')
          .where('lecturerId', isEqualTo: lecturerId)
          .get();

      return snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }
}

