// unit_attendance.dart
import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/Models/course_model.dart';
import 'package:attendanceapp/Models/unit_model.dart';
import 'package:attendanceapp/Providers/attendance_providers.dart';
import 'package:attendanceapp/Providers/course_providers.dart' as course_providers;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final allStudentUnitsProvider = Provider<AsyncValue<List<UnitWithCourse>>>((ref) {
  final enrolledCoursesAsync = ref.watch(course_providers.studentEnrolledCoursesProvider);
  
  return enrolledCoursesAsync.when(
    data: (courses) {
      if (courses.isEmpty) {
        return const AsyncValue.data([]);
      }
      
      // Use a StreamProvider or FutureProvider instead for async operations
      final unitsAsyncValue = ref.watch(allStudentUnitsFutureProvider(courses));
      
      // Now return the AsyncValue directly
      return unitsAsyncValue;
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// Create a separate FutureProvider to handle the async work
final allStudentUnitsFutureProvider = FutureProvider.family<List<UnitWithCourse>, List<CourseModel>>((ref, courses) async {
  // Create a list to hold all unit futures
  final List<Future<List<UnitWithCourse>>> unitFutures = [];
  
  // For each course, get its units
  for (final course in courses) {
    final unitsFuture = ref.watch(course_providers.courseUnitsProvider(course.id).future)
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
});
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

class UnitAttendance extends ConsumerWidget {
  final String studentId;
  final String studentName;
  
  const UnitAttendance({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsyncValue = ref.watch(allStudentUnitsProvider);
    
    return unitsAsyncValue.when(
      data: (units) {
        if (units.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.school, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No units found. Please register for courses first.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: units.length,
          itemBuilder: (context, index) {
            final unitWithCourse = units[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    unitWithCourse.unit.name.isNotEmpty ? unitWithCourse.unit.name[0] : 'U',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(unitWithCourse.unit.name),
                subtitle: Text('Course: ${unitWithCourse.courseName}'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () => _showAttendanceForm(context, ref, unitWithCourse, studentId, studentName),
                  child: const Text(
                    'Sign Attendance',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                'Error loading units: $err',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.refresh(course_providers.studentEnrolledCoursesProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttendanceForm(BuildContext context, WidgetRef ref, UnitWithCourse unitWithCourse, String studentId, String studentName) {
    final commentController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Submit Attendance'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unit: ${unitWithCourse.unit.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Course: ${unitWithCourse.courseName}'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Comment (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Create attendance model
                final attendance = AttendanceModel(
                  id: '', // This will be generated by Firestore
                  unitId: unitWithCourse.unit.id,
                  unitName: unitWithCourse.unit.name,
                  studentId: studentId,
                  studentName: studentName,
                  courseName: unitWithCourse.courseName,
                  lecturerId: unitWithCourse.unit.lecturerId,
                  venue: locationController.text,
                  attendanceDate: Timestamp.now(),
                  status: AttendanceStatus.pending,
                  studentComments: commentController.text,
                );

                // Submit attendance
                ref
                    .read(attendanceManagerProvider.notifier)
                    .submitAttendance(attendance);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Attendance submitted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Submit Attendance'),
            ),
          ],
        );
      },
    );
  }
}