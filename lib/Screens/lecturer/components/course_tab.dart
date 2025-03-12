import 'package:attendanceapp/Models/course_model.dart';

import 'package:attendanceapp/Providers/course_providers.dart';

import 'package:attendanceapp/Screens/course_detail_screen.dart';
import 'package:attendanceapp/Screens/lecturer/screens/add_course_dialog.dart';
import 'package:attendanceapp/Screens/lecturer/screens/student_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CoursesTab extends ConsumerWidget {
  const CoursesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesStream = ref.watch(lecturerCoursesProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Units',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: coursesStream.when(
              data: (courses) {
                if (courses.isEmpty) {
                  return const Center(
                    child: Text('No Units yet. Add your first Unit!'),
                  );
                }

                return ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return CourseListItem(course: course);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add New Unit'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddCourseDialog(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CourseListItem extends ConsumerWidget {
  final CourseModel course;

  const CourseListItem({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(course.name),
        subtitle: Text(course.courseCode),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentListScreen(course: course),
                  ),
                );
              },
              tooltip: 'View Students',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteCourse(context, ref),
              tooltip: 'Delete Unit',
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(course: course),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteCourse(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Unit'),
        content: Text('Are you sure you want to delete ${course.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(courseServiceProvider).deleteCourse(course.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unit deleted')),
      );
    }
  }
}