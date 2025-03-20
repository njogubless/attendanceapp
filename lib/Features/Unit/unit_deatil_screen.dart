// Unit Detail Screen
import 'package:attendanceapp/Features/Unit/unit_screen.dart';
import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/Models/unit_model.dart';
import 'package:attendanceapp/Providers/attendance_providers.dart';
import 'package:attendanceapp/Screens/lecturer/screens/attendance_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class UnitDetailScreen extends ConsumerWidget {
  final String unitId;

  const UnitDetailScreen({Key? key, required this.unitId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitData = ref.watch(unitProvider(unitId));
    final attendanceData = ref.watch(attendanceForCourseProvider(unitId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              unitData.maybeWhen(
                data: (unit) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UnitScreen(
                        lecturerId: unit.lecturerId,
                        unit: unit,
                      ),
                    ),
                  );
                },
                orElse: () {},
              );
            },
          ),
        ],
      ),
      body: unitData.when(
        data: (unit) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUnitInfo(context, unit),
                const SizedBox(height: 24),
                _buildAttendanceControls(context, ref, unit),
                const SizedBox(height: 24),
                _buildAttendanceSection(context, ref, unit, attendanceData),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading unit: $error'),
        ),
      ),
    );
  }

  Widget _buildUnitInfo(BuildContext context, UnitModel unit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  unit.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(unit.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Code: ${unit.code}'),
            const SizedBox(height: 8),
            Text('Created: ${DateFormat.yMMMd().format(unit.createdAt.toDate())}'),
            if (unit.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(unit.description),
            ],
            if (unit.adminComments.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Admin Comments:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                unit.adminComments,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(UnitStatus status) {
    Color chipColor;
    String statusText;

    switch (status) {
      case UnitStatus.approved:
        chipColor = Colors.green;
        statusText = 'Approved';
        break;
      case UnitStatus.rejected:
        chipColor = Colors.red;
        statusText = 'Rejected';
        break;
      case UnitStatus.pending:
      default:
        chipColor = Colors.orange;
        statusText = 'Pending';
    }

    return Chip(
      label: Text(statusText),
      backgroundColor: chipColor.withOpacity(0.2),
      labelStyle: TextStyle(color: chipColor),
    );
  }

  Widget _buildAttendanceControls(BuildContext context, WidgetRef ref, UnitModel unit) {
    // Only show controls for approved units
    if (unit.status != UnitStatus.approved) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Management',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Attendance management is only available for approved units.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Attendance Status:'),
                Row(
                  children: [
                    Text(
                      unit.isAttendanceActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: unit.isAttendanceActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: unit.isAttendanceActive,
                      onChanged: (value) {
                        _toggleAttendance(context, ref, unit.id, value);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (unit.isAttendanceActive)
              const Text(
                'Students can now submit attendance for this unit.',
                style: TextStyle(color: Colors.green),
              )
            else
              const Text(
                'Attendance is currently disabled for this unit.',
                style: TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttendanceReportScreen(courseId: unit.id),
                    ),
                  );
                },
                child: const Text('View Attendance Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSection(
    BuildContext context, 
    WidgetRef ref, 
    UnitModel unit, 
    AsyncValue<List<AttendanceModel>> attendanceData
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Attendance Records',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            attendanceData.when(
              data: (attendances) {
                if (attendances.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No attendance records found for this unit.'),
                    ),
                  );
                }

                // Sort by date, most recent first
                attendances.sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));

                // Take only the most recent 5 for this screen
                final recentAttendances = attendances.take(5).toList();

                return Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentAttendances.length,
                      itemBuilder: (context, index) {
                        final attendance = recentAttendances[index];
                        return _buildAttendanceItem(context, attendance);
                      },
                    ),
                    if (attendances.length > 5) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AttendanceReportScreen(courseId: unit.id),
                            ),
                          );
                        },
                        child: const Text('View All Records'),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading attendance: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceItem(BuildContext context, AttendanceModel attendance) {
    Color statusColor;
    
    switch (attendance.status) {
      case AttendanceStatus.approved:
        statusColor = Colors.green;
        break;
      case AttendanceStatus.rejected:
        statusColor = Colors.red;
        break;
      case AttendanceStatus.pending:
      default:
        statusColor = Colors.orange;
    }

    return ListTile(
      title: Text(attendance.studentName),
      subtitle: Text(
        'Date: ${DateFormat.yMMMd().format(attendance.attendanceDate.toDate())}'
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          attendance.status.toString().split('.').last,
          style: TextStyle(color: statusColor),
        ),
      ),
      onTap: () {
        // Handle tapping on an attendance record
        // Could show a dialog with more details or navigate to a detail screen
      },
    );
  }

  void _toggleAttendance(BuildContext context, WidgetRef ref, String unitId, bool isActive) {
    final notifier = ref.read(attendanceManagerProvider.notifier);

    if (isActive) {
      notifier.activateAttendanceForUnit(unitId);
    } else {
      notifier.deactivateAttendanceForUnit(unitId);
    }
  }
}
