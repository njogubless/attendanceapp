import 'package:attendanceapp/Models/course_model.dart';
import 'package:attendanceapp/Models/user_models.dart';
import 'package:attendanceapp/Providers/auth_providers.dart';
import 'package:attendanceapp/services/course_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final courseServiceProvider = Provider<CourseService>((ref) {
  return CourseService();
});

final coursesProvider = StreamProvider<List<CourseModel>>((ref) {
  return ref.read(courseServiceProvider).getCourses();
});

// Add the missing provider for lecturer courses
final lecturerCoursesStreamProvider = StreamProvider<List<CourseModel>>((ref) {
  final user = ref.watch(userDataProvider).value;
  if (user == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('courses')
      .where('lecturerId', isEqualTo: user.id)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => CourseModel.fromFirestore(doc))
          .toList());
});

// Add the missing provider for students in a course
final courseStudentsProvider = StreamProvider.family<List<UserModel>, String>((ref, courseId) {
  return FirebaseFirestore.instance
      .collection('enrollments')
      .where('courseId', isEqualTo: courseId)
      .snapshots()
      .asyncMap((snapshot) async {
        List<UserModel> students = [];
        for (var doc in snapshot.docs) {
          final studentId = doc.data()['studentId'];
          final studentDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(studentId)
              .get();
          
          if (studentDoc.exists) {
            students.add(UserModel.fromFirestore(studentDoc));
          }
        }
        return students;
      });
});

final courseNotifierProvider = StateNotifierProvider<CourseNotifier, AsyncValue<List<CourseModel>>>((ref) {
  return CourseNotifier(ref.read(courseServiceProvider));
});

class CourseNotifier extends StateNotifier<AsyncValue<List<CourseModel>>> {
  final CourseService _courseService;

  CourseNotifier(this._courseService) : super(AsyncValue.loading());

  Future<void> addCourse(CourseModel course) async {
    state = AsyncValue.loading();
    try {
      await _courseService.addCourse(course);
      final courses = await _courseService.getCourses().first;
      state = AsyncValue.data(courses);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> enrollStudent(String courseId, String studentId) async {
    state = AsyncValue.loading();
    try {
      await _courseService.enrollStudent(courseId, studentId);
      final courses = await _courseService.getCourses().first;
      state = AsyncValue.data(courses);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}