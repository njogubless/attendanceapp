import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/Models/course_model.dart';
import 'package:attendanceapp/Models/unit_model.dart';
import 'package:attendanceapp/Models/user_models.dart';
import 'package:attendanceapp/Providers/auth_providers.dart';
import 'package:attendanceapp/services/course_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final courseServiceProvider = Provider<CourseService>((ref) {
  return CourseService();
});

// Provider to get a single course by ID
final courseProvider = StreamProvider.family<CourseModel, String>((ref, courseId) {
  return FirebaseFirestore.instance
      .collection('courses')
      .doc(courseId)
      .snapshots()
      .map((snapshot) => CourseModel.fromFirestore(snapshot));
});

// General courses provider - lists all available courses
final coursesProvider = StreamProvider<List<CourseModel>>((ref) {
  return ref.read(courseServiceProvider).getCourses();
});

// Provider for lecturer-specific courses
final lecturerCoursesProvider = StreamProvider<List<CourseModel>>((ref) {
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

// Provider to track student's enrolled courses
final studentEnrolledCoursesProvider = StreamProvider<List<CourseModel>>((ref) {
  final user = ref.watch(userDataProvider).value;
  if (user == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('enrollments')
      .where('studentId', isEqualTo: user.id)
      .snapshots()
      .asyncMap((snapshot) async {
        List<CourseModel> enrolledCourses = [];
        Set<String> addedCourseIds = {}; // Track added course IDs
        
        for (var doc in snapshot.docs) {
          final courseId = doc.data()['courseId'];
          
          // Skip if we've already added this course
          if (addedCourseIds.contains(courseId)) continue;
          
          final courseDoc = await FirebaseFirestore.instance
              .collection('courses')
              .doc(courseId)
              .get();
          
          if (courseDoc.exists) {
            addedCourseIds.add(courseId); // Mark as added
            enrolledCourses.add(CourseModel.fromFirestore(courseDoc));
          }
        }
        return enrolledCourses;
      });
});

// Provider to get students enrolled in a specific course
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

// Provider to get units for a specific course
final courseUnitsProvider = StreamProvider.family<List<UnitModel>, String>((ref, courseId) {
  return FirebaseFirestore.instance
      .collection('units')
      .where('courseId', isEqualTo: courseId)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => UnitModel.fromFirestore(doc))
          .toList());
});

// Model to combine unit with course info
class UnitWithCourse {
  final UnitModel unit;
  final String courseName;
  final String courseId;
  
  UnitWithCourse({
    required this.unit,
    required this.courseName,
    required this.courseId,
  });
}

// Provider to get all units for a student across all courses
final allStudentUnitsProvider = FutureProvider.autoDispose<List<UnitWithCourse>>((ref) async {
  final enrolledCoursesAsync = ref.watch(studentEnrolledCoursesProvider);
  
  return enrolledCoursesAsync.when(
    data: (courses) async {
      if (courses.isEmpty) {
        return [];
      }
      
      // Create a list to hold all unit futures
      final List<Future<List<UnitWithCourse>>> unitFutures = [];
      
      // For each course, get its units
      for (final course in courses) {
        final unitsFuture = ref.watch(courseUnitsProvider(course.id).future)
          .then((units) => units.map((unit) => UnitWithCourse(
                unit: unit, 
                courseName: course.name,
                courseId: course.id
              )).toList());
        
        unitFutures.add(unitsFuture);
      }
      
      // Wait for all futures to complete and flatten the results
      final unitLists = await Future.wait(unitFutures);
      return unitLists.expand((units) => units).toList();
    },
    loading: () => throw _LoadingException(),
    error: (err, stack) => throw err,
  );
});

// An exception class to handle loading state
class _LoadingException implements Exception {}

// Provider to get all units enrolled by a student directly
final studentEnrolledUnitsProvider = StreamProvider<List<UnitModel>>((ref) {
  final user = ref.watch(userDataProvider).value;
  if (user == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('units')
      .where('enrolledStudents', arrayContains: user.id)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => UnitModel.fromFirestore(doc))
          .toList());
});

// Provider to track a student's attendance records
final studentAttendanceProvider = StreamProvider<List<AttendanceModel>>((ref) {
  final user = ref.watch(userDataProvider).value;
  if (user == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('attendance')
      .where('studentId', isEqualTo: user.id)
      .orderBy('attendanceDate', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .toList());
});

// Course state notifier provider
final courseNotifierProvider = StateNotifierProvider<CourseNotifier, AsyncValue<void>>((ref) {
  return CourseNotifier(ref.read(courseServiceProvider));
});

// Attendance state notifier provider
final attendanceNotifierProvider = StateNotifierProvider<AttendanceNotifier, AsyncValue<void>>((ref) {
  return AttendanceNotifier(FirebaseFirestore.instance);
});

class CourseNotifier extends StateNotifier<AsyncValue<void>> {
  final CourseService _courseService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CourseNotifier(this._courseService) : super(const AsyncValue.data(null));

  Future<void> addCourse(CourseModel course) async {
    state = const AsyncValue.loading();
    try {
      await _courseService.addCourse(course);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> enrollStudent(String courseId, String studentId) async {
    state = const AsyncValue.loading();
    try {
      // Create enrollment record
      await _firestore.collection('enrollments').add({
        'courseId': courseId,
        'studentId': studentId,
        'enrollmentDate': Timestamp.now(),
      });

      // Also update units in this course to include the student
      final unitDocs = await _firestore
          .collection('units')
          .where('courseId', isEqualTo: courseId)
          .get();
      
      // Batch write to update all units
      final batch = _firestore.batch();
      for (var doc in unitDocs.docs) {
        batch.update(doc.reference, {
          'enrolledStudents': FieldValue.arrayUnion([studentId])
        });
      }
      await batch.commit();
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> unenrollStudent(String courseId, String studentId) async {
    state = const AsyncValue.loading();
    try {
      // Find and delete enrollment record
      final enrollmentQuery = await _firestore
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .where('studentId', isEqualTo: studentId)
          .get();
      
      // Delete all matching enrollment documents
      final batch = _firestore.batch();
      for (var doc in enrollmentQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Also update units to remove student
      final unitDocs = await _firestore
          .collection('units')
          .where('courseId', isEqualTo: courseId)
          .get();
      
      for (var doc in unitDocs.docs) {
        batch.update(doc.reference, {
          'enrolledStudents': FieldValue.arrayRemove([studentId])
        });
      }
      
      await batch.commit();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

class AttendanceNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseFirestore _firestore;

  AttendanceNotifier(this._firestore) : super(const AsyncValue.data(null));

  Future<void> submitAttendance(AttendanceModel attendance) async {
    state = const AsyncValue.loading();
    try {
      // Create a document reference with auto-generated ID
      final docRef = _firestore.collection('attendance').doc();
      
      // Update the attendance model with the generated ID
      final updatedAttendance = attendance.copyWith(
        id: docRef.id,
        attendanceDate: Timestamp.now(),
        status: AttendanceStatus.pending
      );
      
      // Set the document data
      await docRef.set(updatedAttendance.toMap());
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> updateAttendanceStatus(String attendanceId, AttendanceStatus status, String? lecturerComments) async {
    state = const AsyncValue.loading();
    try {
      Map<String, dynamic> updateData = {
        'status': status.toString(),
      };
      
      if (lecturerComments != null) {
        updateData['lecturerComments'] = lecturerComments;
      }
      
      await _firestore
          .collection('attendance')
          .doc(attendanceId)
          .update(updateData);
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}