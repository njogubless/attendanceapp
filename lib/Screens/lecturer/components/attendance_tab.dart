import 'package:attendanceapp/Features/Unit/unit_deatil_screen.dart';
import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/Models/unit_model.dart';
import 'package:attendanceapp/Providers/auth_providers.dart';
import 'package:attendanceapp/Providers/unit_providers.dart';
import 'package:attendanceapp/Providers/attendance_providers.dart';
import 'package:attendanceapp/Providers/units_provider.dart';

import 'package:attendanceapp/Screens/lecturer/screens/attendance_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';


final pendingAttendanceProvider = FutureProvider.family<List<AttendanceModel>, String>((ref, lecturerId) async {
  final attendanceService = ref.read(attendanceServiceProvider); // Assuming you have this provider
  try {
    return await attendanceService.getPendingAttendanceForLecturer(lecturerId);
  } catch (e) {
    throw e;
  }
});
class AttendanceTab extends ConsumerWidget {
  const AttendanceTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider).value;
    
    if (userData == null) {
      return const Center(child: Text("No user data found"));
    }
    
    final unitsStream = ref.watch(lecturerUnitsProvider(userData.id));
    final pendingAttendance = ref.watch(pendingAttendanceProvider(userData.id));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Pending Attendance Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending Attendance Requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
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
                            return ListTile(
                              title: Text(attendance.studentName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(attendance.unitName ?? 'Unknown Unit'),
                                  Text(DateFormat('MMM dd, yyyy - HH:mm')
                                      .format(attendance.attendanceDate.toDate())),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    onPressed: () => _approveAttendance(context, ref, attendance),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () => _rejectAttendance(context, ref, attendance),
                                  ),
                                ],
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
          ),
          const SizedBox(height: 16),
          // Units Section
          const Text(
            'My Units',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: unitsStream.when(
              data: (units) {
                if (units.isEmpty) {
                  return const Center(
                    child: Text('No units created yet'),
                  );
                }

                return ListView.builder(
                  itemCount: units.length,
                  itemBuilder: (context, index) {
                    final unit = units[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(unit.name),
                        subtitle: Text('Code: ${unit.code}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: unit.isAttendanceActive,
                              onChanged: (value) => _toggleAttendance(ref, unit.id, value),
                            ),
                            IconButton(
                              icon: const Icon(Icons.assessment),
                              onPressed: () => _navigateToAttendanceReport(context, unit.id),
                              tooltip: 'Attendance Report',
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () => _navigateToUnitDetail(context, unit.id),
                            ),
                          ],
                        ),
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
    );
  }

  void _approveAttendance(BuildContext context, WidgetRef ref, AttendanceModel attendance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Attendance'),
        content: Text('Approve attendance for ${attendance.studentName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(attendanceManagerProvider.notifier)
                .updateAttendanceStatus(
                  attendance.id, 
                  AttendanceStatus.approved.toString()
                );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectAttendance(BuildContext context, WidgetRef ref, AttendanceModel attendance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Attendance'),
        content: Text('Reject attendance for ${attendance.studentName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(attendanceManagerProvider.notifier)
                .updateAttendanceStatus(
                  attendance.id, 
                  AttendanceStatus.rejected.toString()
                );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _toggleAttendance(WidgetRef ref, String courseId, bool isActive) {
    final notifier = ref.read(attendanceManagerProvider.notifier);
    
    if (isActive) {
      notifier.activateAttendanceForUnit(courseId);
    } else {
      notifier.deactivateAttendanceForUnit(courseId);
    }
  }

  void _navigateToUnitDetail(BuildContext context, String unitId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnitDetailScreen(unitId: unitId),
      ),
    );
  }

  void _navigateToAttendanceReport(BuildContext context, String unitId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceReportScreen(courseId: unitId,),
      ),
    );
  }
}