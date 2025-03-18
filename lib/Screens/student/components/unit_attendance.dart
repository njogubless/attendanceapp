// lib/Widgets/course_attendance.dart
import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/Models/course_model.dart';
import 'package:attendanceapp/Providers/attendance_providers.dart';
import 'package:attendanceapp/Providers/course_providers.dart'
    as course_providers;
import 'package:attendanceapp/Screens/student/components/empty_course_view.dart';
import 'package:attendanceapp/widgets/attendance_form.dart';
import 'package:attendanceapp/widgets/status_chip.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
    final enrolledCoursesAsyncValue =
        ref.watch(course_providers.studentEnrolledCoursesProvider);
    final studentAttendanceAsyncValue =
        ref.watch(studentAttendancesProvider(studentId));

    return enrolledCoursesAsyncValue.when(
      data: (courses) {
        if (courses.isEmpty) {
          return EmptyCoursesView(
              onRefresh: () =>
                  ref.refresh(course_providers.studentEnrolledCoursesProvider));
        }

        return studentAttendanceAsyncValue.when(
          data: (attendances) {
            // Create a map of course IDs to their latest attendance
            final Map<String, AttendanceModel> latestAttendanceMap =
                _createLatestAttendanceMap(attendances);
            return _buildCoursesList(
                context, ref, courses, latestAttendanceMap);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Error loading attendance data: $err'),
          ),
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

  Map<String, AttendanceModel> _createLatestAttendanceMap(
      List<AttendanceModel> attendances) {
    final Map<String, AttendanceModel> latestAttendanceMap = {};

    for (var attendance in attendances) {
      final unitId = attendance.unitId;
      if (!latestAttendanceMap.containsKey(unitId) ||
          attendance.attendanceDate
                  .compareTo(latestAttendanceMap[unitId]!.attendanceDate) >
              0) {
        latestAttendanceMap[unitId] = attendance;
      }
    }

    return latestAttendanceMap;
  }

  Widget _buildCoursesList(
      BuildContext context,
      WidgetRef ref,
      List<CourseModel> courses,
      Map<String, AttendanceModel> latestAttendanceMap) {
    final uniqueCourses = courses.toSet().toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: uniqueCourses.length,
      itemBuilder: (context, index) {
        final course = uniqueCourses[index];
        final hasRecentAttendance = latestAttendanceMap.containsKey(course.id);
        final recentAttendance =
            hasRecentAttendance ? latestAttendanceMap[course.id] : null;

        // Check if attendance was submitted today
        bool isSubmittedToday = false;
        if (hasRecentAttendance) {
          final attendanceDate = recentAttendance!.attendanceDate.toDate();
          final today = DateTime.now();
          isSubmittedToday = attendanceDate.year == today.year &&
              attendanceDate.month == today.month &&
              attendanceDate.day == today.day;
        }

        return _buildCourseCard(context, ref, course, recentAttendance,
            hasRecentAttendance, isSubmittedToday);
      },
    );
  }

  Widget _buildCourseCard(
      BuildContext context,
      WidgetRef ref,
      CourseModel course,
      AttendanceModel? recentAttendance,
      bool hasRecentAttendance,
      bool isSubmittedToday) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Text(
                course.name.isNotEmpty ? course.name[0].toLowerCase() : 'c',
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
          ),

          // Separate section for attendance info to prevent overflow
          if (hasRecentAttendance)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 8,
                children: [
                  Text(
                    'Last Attendance: ${DateFormat('MMM dd, yyyy').format(recentAttendance!.attendanceDate.toDate())}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  StatusChip(status: recentAttendance.status),
                ],
              ),
            ),

          // Action button in its own row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildAttendanceActionButton(context, ref, course,
                    recentAttendance, hasRecentAttendance, isSubmittedToday),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceActionButton(
      BuildContext context,
      WidgetRef ref,
      CourseModel course,
      AttendanceModel? recentAttendance,
      bool hasRecentAttendance,
      bool isSubmittedToday) {
    if (hasRecentAttendance &&
        isSubmittedToday &&
        recentAttendance!.status != AttendanceStatus.rejected) {
      // Show disabled button if attendance already submitted today
      return AttendanceButton(
          status: recentAttendance.status,
          onPressed: null,
          color: recentAttendance.status == AttendanceStatus.pending
              ? Colors.orange
              : Colors.green);
    } else {
      // Show active button to submit attendance
      return AttendanceButton(
          status: null,
          onPressed: () => showAttendanceForm(context, ref, course),
          color: Colors.green);
    }
  }

  void showAttendanceForm(
      BuildContext context, WidgetRef ref, CourseModel course) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AttendanceFormDialog(
          course: course,
          studentId: studentId,
          studentName: studentName,
          onSubmit: (attendance) {
            // Submit attendance using the provider
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
        );
      },
    );
  }
}
