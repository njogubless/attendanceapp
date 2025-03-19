import 'package:attendanceapp/Models/course_model.dart';
import 'package:attendanceapp/Providers/course_providers.dart';
import 'package:attendanceapp/Screens/lecturer/screens/attendance_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CourseActivationCard extends ConsumerWidget {
  final CourseModel course;

  const CourseActivationCard({Key? key, required this.course}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  course.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(course.isActive),
              ],
            ),
            const SizedBox(height: 8),
            Text('Course Code: ${course.courseCode}'),
            if (course.activationTime != null && course.isActive)
              Text(
                'Activated at: ${DateFormat('MMM dd, yyyy HH:mm').format(course.activationTime!.toDate())}',
                style: const TextStyle(color: Colors.green),
              ),
            if (course.deactivationTime != null && !course.isActive)
              Text(
                'Last deactivated: ${DateFormat('MMM dd, yyyy HH:mm').format(course.deactivationTime!.toDate())}',
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Attendance Report'),
                  onPressed: () {
                    // Navigate to attendance report or generate PDF
                    _generateAttendanceReport(context, ref, course.id);
                  },
                ),
                course.isActive
                    ? ElevatedButton.icon(
                        icon: const Icon(Icons.stop_circle),
                        label: const Text('Deactivate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () {
                          _deactivateAttendance(context, ref, course.id);
                        },
                      )
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.play_circle),
                        label: const Text('Activate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () {
                          _activateAttendance(context, ref, course.id);
                        },
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Future<void> _activateAttendance(BuildContext context, WidgetRef ref, String courseId) async {
    try {
      await ref.read(courseServiceProvider).activateAttendance(courseId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance activated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deactivateAttendance(BuildContext context, WidgetRef ref, String courseId) async {
    try {
      await ref.read(courseServiceProvider).deactivateAttendance(courseId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance deactivated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _generateAttendanceReport(BuildContext context, WidgetRef ref, String courseId) async {
    // Navigate to attendance report screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceReportScreen(courseId: courseId),
      ),
    );
  }
}