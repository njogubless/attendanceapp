import 'package:attendanceapp/Models/course_model.dart';
import 'package:attendanceapp/Providers/course_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentListScreen extends ConsumerWidget {
  final CourseModel course;

  const StudentListScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsStream = ref.watch(courseStudentsProvider(course.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Students - ${course.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Show dialog to add students to the course
              _showAddStudentsDialog(context, ref);
            },
            tooltip: 'Add Students',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Course Code: ${course.courseCode}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            studentsStream.when(
              data: (students) {
                if (students.isEmpty) {
                  return const Expanded(
                    child: Center(
                      child: Text('No students enrolled in this unit yet'),
                    ),
                  );
                }

                return Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(student.name[0].toUpperCase()),
                          ),
                          title: Text(student.name),
                          subtitle: Text(student.email),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () {
                              // TODO: Implement removing student from course
                              _showRemoveStudentDialog(context, ref, student);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Expanded(
                child: Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStudentsDialog(BuildContext context, WidgetRef ref) {
    // TODO: Implement adding students to course functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Students to ${course.name}'),
        content: const Text('This feature will allow you to add students to this unit.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRemoveStudentDialog(BuildContext context, WidgetRef ref, dynamic student) {
    // TODO: Implement removing student from course
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text('Are you sure you want to remove ${student.name} from this unit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement removing student
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Student removed from unit')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}