// Attendance Report Screen
import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/Models/unit_model.dart';
import 'package:attendanceapp/Providers/attendance_providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class AttendanceReportScreen extends ConsumerStatefulWidget {
  final String unitId;

  const AttendanceReportScreen({Key? key, required this.unitId}) : super(key: key);

  @override
  ConsumerState<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends ConsumerState<AttendanceReportScreen> {
  String _selectedFilter = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  
  @override
  Widget build(BuildContext context) {
    final unitData = ref.watch(unitProvider(widget.unitId));
    final attendanceData = ref.watch(attendanceForUnitProvider(widget.unitId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              attendanceData.maybeWhen(
                data: (attendances) {
                  _exportAttendanceData(attendances);
                },
                orElse: () {},
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildReportHeader(unitData),
          _buildFilterSection(),
          Expanded(
            child: attendanceData.when(
              data: (attendances) {
                // Apply filters
                final filteredAttendances = _filterAttendances(attendances);
                
                if (filteredAttendances.isEmpty) {
                  return const Center(
                    child: Text('No attendance records found matching the filters.'),
                  );
                }
                
                return _buildAttendanceTable(filteredAttendances);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading attendance data: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportHeader(AsyncValue<UnitModel> unitData) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey.shade100,
      child: unitData.when(
        data: (unit) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                unit.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text('Unit Code: ${unit.code}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Attendance Status: ${unit.isAttendanceActive ? "Active" : "Inactive"}',
                    style: TextStyle(
                      color: unit.isAttendanceActive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Text('Error loading unit data'),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Records',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedFilter = newValue;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDateRange(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date Range',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _getDateRangeText(),
                      style: TextStyle(
                        color: _startDate == null ? Colors.grey.shade600 : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear Filters'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable(List<AttendanceModel> attendances) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Student')),
            DataColumn(label: Text('Reg Number')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: attendances.map((attendance) {
            return DataRow(
              cells: [
                DataCell(Text(attendance.studentName)),
                DataCell(Text(attendance.registrationNumber)),
                DataCell(Text(DateFormat.yMMMd().format(attendance.attendanceDate.toDate()))),
                DataCell(Text(DateFormat.Hm().format(attendance.attendanceDate.toDate()))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(attendance.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      attendance.status.toString().split('.').last,
                      style: TextStyle(color: _getStatusColor(attendance.status)),
                    ),
                  ),
                ),
                DataCell(
                  attendance.status == AttendanceStatus.pending
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _updateAttendanceStatus(
                                attendance.id,
                                AttendanceStatus.approved,
                              ),
                              tooltip: 'Approve',
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _updateAttendanceStatus(
                                attendance.id,
                                AttendanceStatus.rejected,
                              ),
                              tooltip: 'Reject',
                            ),
                          ],
                        )
                      : const Text('No actions available'),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.approved:
        return Colors.green;
      case AttendanceStatus.rejected:
        return Colors.red;
      case AttendanceStatus.pending:
      default:
        return Colors.orange;
    }
  }

  String _getDateRangeText() {
    if (_startDate == null && _endDate == null) {
      return 'All Dates';
    } else if (_startDate != null && _endDate == null) {
      return 'From ${DateFormat.yMMMd().format(_startDate!)}';
    } else if (_startDate == null && _endDate != null) {
      return 'Until ${DateFormat.yMMMd().format(_endDate!)}';
    } else {
      return '${DateFormat.yMMMd().format(_startDate!)} - ${DateFormat.yMMMd().format(_endDate!)}';
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: _endDate ?? DateTime.now(),
    );

    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: initialDateRange,
    );

    if (newDateRange != null) {
      setState(() {
        _startDate = newDateRange.start;
        _endDate = newDateRange.end;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedFilter = 'All';
      _startDate = null;
      _endDate = null;
    });
  }

  List<AttendanceModel> _filterAttendances(List<AttendanceModel> attendances) {
    return attendances.where((attendance) {
      // Filter by status
      if (_selectedFilter != 'All') {
        final statusString = attendance.status.toString().split('.').last;
        if (statusString != _selectedFilter) {
          return false;
        }
      }

      // Filter by date range
      if (_startDate != null || _endDate != null) {
        final attendanceDate = attendance.attendanceDate.toDate();
        
        if (_startDate != null && attendanceDate.isBefore(_startDate!)) {
          return false;
        }
        
        if (_endDate != null) {
          final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
          if (attendanceDate.isAfter(endOfDay)) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  void _updateAttendanceStatus(String attendanceId, AttendanceStatus newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newStatus == AttendanceStatus.approved ? 'Approve Attendance' : 'Reject Attendance'),
        content: Text(
          newStatus == AttendanceStatus.approved
              ? 'Are you sure you want to approve this attendance record?'
              : 'Are you sure you want to reject this attendance record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(attendanceManagerProvider.notifier).updateAttendanceStatus(
                attendanceId,
                newStatus,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == AttendanceStatus.approved ? Colors.green : Colors.red,
            ),
            child: Text(newStatus == AttendanceStatus.approved ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAttendanceData(List<AttendanceModel> attendances) async {
    try {
      // Apply filters first
      final filteredAttendances = _filterAttendances(attendances);
      
      // Prepare CSV data
      List<List<dynamic>> csvData = [
        ['Student Name', 'Registration Number', 'Date', 'Time', 'Status']
      ];
      
      for (var attendance in filteredAttendances) {
        csvData.add([
          attendance.studentName,
          attendance.registrationNumber,
          DateFormat.yMMMd().format(attendance.attendanceDate.toDate()),
          DateFormat.Hm().format(attendance.attendanceDate.toDate()),
          attendance.status.toString().split('.').last,
        ]);
      }
      
      // Generate CSV string
      String csv = const ListToCsvConverter().convert(csvData);
      
      // Get app directory for temporary storage
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/attendance_report.csv';
      final file = File(path);
      
      // Write to file
      await file.writeAsString(csv);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Attendance Report - ${DateFormat.yMMMd().format(DateTime.now())}',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance report exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting data: $e')),
      );
    }
  }
}