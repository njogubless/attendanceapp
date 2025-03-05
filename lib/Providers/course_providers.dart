import 'package:attendanceapp/Models/course_model.dart';
import 'package:attendanceapp/services/course_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final courseServiceProvider = Provider<CourseService>((ref) {
  return CourseService();
});

final coursesProvider = StreamProvider<List<CourseModel>>((ref) {
  return ref.read(courseServiceProvider).getCourses();
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