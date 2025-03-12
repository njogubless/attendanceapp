// registered_courses.dart
import 'package:attendanceapp/Models/course_model.dart';
import 'package:attendanceapp/Providers/course_providers.dart' as course_providers;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisteredCourses extends ConsumerWidget {
  final VoidCallback onRegisterCourses;

  const RegisteredCourses({
    Key? key,
    required this.onRegisterCourses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrolledCoursesAsyncValue = ref.watch(course_providers.studentEnrolledCoursesProvider);

    return enrolledCoursesAsyncValue.when(
      data: (enrolledCourses) {
        if (enrolledCourses.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text(
                    'You haven\'t registered for any courses yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onRegisterCourses,
                    child: const Text('Register Units'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: enrolledCourses.length,
          itemBuilder: (context, index) {
            final course = enrolledCourses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    course.name.isNotEmpty ? course.name[0] : 'C',
                    style: TextStyle(
                      color: Colors.blue.shade800,
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
}