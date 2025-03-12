import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/Models/course_model.dart';
import 'package:attendanceapp/Providers/attendance_providers.dart';
import 'package:attendanceapp/Providers/course_providers.dart' as course_providers;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CourseAttendance extends ConsumerWidget {
  final String studentId;
  final String studentName;
  
  const CourseAttendance({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrolledCoursesAsyncValue = ref.watch(course_providers.studentEnrolledCoursesProvider);
    
    return enrolledCoursesAsyncValue.when(
      data: (courses) {
        if (courses.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text(
                    'No courses found. Please register for courses first.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Refresh the provider
                      ref.refresh(course_providers.studentEnrolledCoursesProvider);
                    },
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    course.name.isNotEmpty ? course.name[0] : 'C',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  course.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Course Code: ${course.courseCode}'),
                    Text('Lecturer: ${course.lecturerName}'),
                  ],
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () => _showAttendanceForm(context, ref, course, studentId, studentName),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                'Error loading courses: $err',
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

  void _showAttendanceForm(BuildContext context, WidgetRef ref, CourseModel course, String studentId, String studentName) {
    final emailController = TextEditingController();
    final locationController = TextEditingController();
    final commentController = TextEditingController();

    // Pre-fill some information
    emailController.text = '$studentName@example.com'; // Replace with actual student email if available

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
                  Text('Course: ${course.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Course Code: ${course.courseCode}'),
                  Text('Lecturer: ${course.lecturerName}'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
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
                  unitId: course.id, // Use courseId as unitId for now
                  unitName: course.name, // Use course name as unit name
                  studentId: studentId,
                  studentName: studentName,
                  courseName: course.name,
                  lecturerId: course.lecturerId,
                  venue: locationController.text,
                  attendanceDate: Timestamp.now(),
                  status: AttendanceStatus.pending,
                  studentComments: commentController.text,
                  studentEmail: emailController.text,
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