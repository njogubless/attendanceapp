import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/services/attendance_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Provider for the AttendanceService
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

// Provider to get all attendance records for a student
final studentAttendanceProvider = 
    StreamProvider.family<List<AttendanceModel>, String>((ref, studentId) {
  return ref.watch(attendanceServiceProvider).getAttendanceByStudent(studentId);
});

// Enum for filtering attendance
enum AttendanceFilter {
  all,
  pending,
  approved,
  rejected,
}

// Provider to track the current filter
final attendanceFilterProvider = StateProvider<AttendanceFilter>((ref) {
  return AttendanceFilter.all;
});

class StudentAttendanceStatus extends ConsumerWidget {
  final String studentId;

  const StudentAttendanceStatus({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAttendance = ref.watch(studentAttendanceProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance Status'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterButtons(context, ref),
            const SizedBox(height: 16),
            Expanded(
              child: studentAttendance.when(
                data: (attendanceList) {
                  if (attendanceList.isEmpty) {
                    return const Center(
                      child: Text('No attendance records found'),
                    );
                  }

                  final filteredList = _getFilteredList(ref, attendanceList);

                  if (filteredList.isEmpty) {
                    return Center(
                      child: Text('No ${_getCurrentFilterName(ref).toLowerCase()} attendance records'),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final attendance = filteredList[index];
                      return _buildAttendanceCard(attendance);
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

  Widget _buildFilterButtons(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(attendanceFilterProvider);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterButton(
            context,
            ref,
            'All',
            AttendanceFilter.all,
            currentFilter,
            Colors.blue,
          ),
          const SizedBox(width: 8),
          _filterButton(
            context,
            ref,
            'Pending',
            AttendanceFilter.pending,
            currentFilter,
            Colors.orange,
          ),
          const SizedBox(width: 8),
          _filterButton(
            context,
            ref,
            'Approved',
            AttendanceFilter.approved,
            currentFilter,
            Colors.green,
          ),
          const SizedBox(width: 8),
          _filterButton(
            context,
            ref,
            'Rejected',
            AttendanceFilter.rejected,
            currentFilter,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _filterButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    AttendanceFilter filter,
    AttendanceFilter currentFilter,
    Color color,
  ) {
    final isSelected = filter == currentFilter;
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: isSelected ? 4 : 0,
      ),
      onPressed: () {
        ref.read(attendanceFilterProvider.notifier).state = filter;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(label),
      ),
    );
  }

  List<AttendanceModel> _getFilteredList(WidgetRef ref, List<AttendanceModel> attendanceList) {
    final filter = ref.watch(attendanceFilterProvider);
    
    if (filter == AttendanceFilter.all) {
      return attendanceList;
    }
    
    // Convert the enum filter to string status as stored in your model
    String statusFilter;
    
    switch (filter) {
      case AttendanceFilter.pending:
        statusFilter = AttendanceStatus.pending.toString().split('.').last;
        break;
      case AttendanceFilter.approved:
        statusFilter = AttendanceStatus.approved.toString().split('.').last;
        break;
      case AttendanceFilter.rejected:
        statusFilter = AttendanceStatus.rejected.toString().split('.').last;
        break;
      default:
        return attendanceList;
    }
    
    return attendanceList.where((attendance) => 
      attendance.status.toString().split('.').last == statusFilter
    ).toList();
  }

  String _getCurrentFilterName(WidgetRef ref) {
    final filter = ref.watch(attendanceFilterProvider);
    switch (filter) {
      case AttendanceFilter.pending:
        return 'Pending';
      case AttendanceFilter.approved:
        return 'Approved';
      case AttendanceFilter.rejected:
        return 'Rejected';
      default:
        return 'All';
    }
  }

  Widget _buildAttendanceCard(AttendanceModel attendance) {
    // Determine status chip color and background
    Color statusColor;
    Color cardBackgroundColor = Colors.white;
    IconData statusIcon;
    
    final status = attendance.status.toString().split('.').last.toLowerCase();
    
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        cardBackgroundColor = Colors.orange.shade50;
        statusIcon = Icons.pending_outlined;
        break;
      case 'approved':
        statusColor = Colors.green;
        cardBackgroundColor = Colors.green.shade50;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'rejected':
        statusColor = Colors.red;
        cardBackgroundColor = Colors.red.shade50;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    attendance.courseName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Chip(
                  avatar: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 16,
                  ),
                  label: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: statusColor.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today_outlined, 
              'Date: ${DateFormat('MMM dd, yyyy').format(attendance.attendanceDate.toDate())}'),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.location_on_outlined, 'Venue: ${attendance.venue}'),
            if (attendance.studentComments != null && attendance.studentComments.isNotEmpty)
              ...[
                const SizedBox(height: 4),
                _buildInfoRow(Icons.comment_outlined, 'Comment: ${attendance.studentComments}'),
              ],
            if (status == 'rejected' && attendance.lecturerComments != null && attendance.lecturerComments!.isNotEmpty)
              ...[
                const SizedBox(height: 4),
                _buildInfoRow(Icons.feedback_outlined, 'Lecturer feedback: ${attendance.lecturerComments}'),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }
}