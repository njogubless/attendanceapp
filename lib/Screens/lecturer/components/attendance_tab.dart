import 'package:attendanceapp/Providers/attendance_providers.dart';
import 'package:attendanceapp/Providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AttendanceTab extends ConsumerWidget {
  const AttendanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userDataProvider).value;
    final lecturerId = user?.id ?? '';
    final pendingAttendance = ref.watch(pendingAttendanceForLecturerProvider(lecturerId));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pending Attendance Requests',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: pendingAttendance.when(
              data: (attendanceList) {
                if (attendanceList.isEmpty) {
                  return const Center(
                    child: Text('No pending attendance requests'),
                  );
                }

                return ListView.builder(
                  itemCount: attendanceList.length,
                  itemBuilder: (context, index) {
                    final attendance = attendanceList[index];
                    return AttendanceRequestItem(attendance: attendance);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceRequestItem extends ConsumerWidget {
  final dynamic attendance; // Replace with your AttendanceModel type

  const AttendanceRequestItem({
    super.key,
    required this.attendance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(attendance.studentName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Course: ${attendance.courseName}'),
            Text('Date: ${DateFormat('MMM dd, yyyy').format(attendance.date)}'),
            Text('Status: ${attendance.status.toString().split('.').last}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () async {
                await ref
                    .read(attendanceServiceProvider)
                    .updateAttendanceStatus(attendance.id, 'approved');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attendance approved')),
                );
              },
              tooltip: 'Approve',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () async {
                await ref
                    .read(attendanceServiceProvider)
                    .updateAttendanceStatus(attendance.id, 'rejected');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attendance rejected')),
                );
              },
              tooltip: 'Reject',
            ),
          ],
        ),
      ),
    );
  }
}