import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/Models/course_model.dart';
import 'package:attendanceapp/Providers/attendance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CourseDetailScreen extends ConsumerWidget {
  final CourseModel course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceStream = ref.watch(attendanceForCourseProvider(course.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(course.name),
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
            if (course.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(course.description),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attendance History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Sign Attendance'),
                  onPressed: () {
                    // Show dialog to take attendance for this unit
                    _showSignAttendanceDialog(context, ref);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: attendanceStream.when(
                data: (attendanceList) {
                  if (attendanceList.isEmpty) {
                    return const Center(
                      child: Text('No attendance records yet'),
                    );
                  }

                  return ListView.builder(
                    itemCount: attendanceList.length,
                    itemBuilder: (context, index) {
                      final attendance = attendanceList[index];
                      return Card(
                        child: ListTile(
                          title: Text(attendance.studentName),
                          subtitle: Text(DateFormat('MMM dd, yyyy').format(attendance.date)),
                          trailing: _getStatusIcon(attendance.status),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignAttendanceDialog(BuildContext context, WidgetRef ref) {
    // TODO: Implement the sign attendance functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Attendance for ${course.name}'),
        content: const Text('This feature will allow you to sign attendance for the whole class or individual students.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.approved:
        return const Icon(Icons.check_circle, color: Colors.green);
      case AttendanceStatus.rejected:
        return const Icon(Icons.cancel, color: Colors.red);
      case AttendanceStatus.pending:
      default:
        return const Icon(Icons.access_time, color: Colors.orange);
    }
  }
}