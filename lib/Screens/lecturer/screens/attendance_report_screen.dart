import 'dart:io';
import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/Providers/attendance_providers.dart';
import 'package:attendanceapp/Providers/course_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AttendanceReportScreen extends ConsumerStatefulWidget {
  final String courseId;

  const AttendanceReportScreen({Key? key, required this.courseId}) : super(key: key);

  @override
  _AttendanceReportScreenState createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends ConsumerState<AttendanceReportScreen> {
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Initialize with the last 30 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load the course data
      await ref.read(attendanceManagerProvider.notifier).fetchAttendanceForCourse(widget.courseId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseAttendanceAsync = ref.watch(attendanceManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Filter by date',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _generatePDF(context),
            tooltip: 'Generate PDF Report',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadPDF(context),
            tooltip: 'Download PDF Report',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangeHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: courseAttendanceAsync.when(
                data: (attendanceList) {
                  // Filter by date range if applicable
                  final filteredAttendance = attendanceList.where((attendance) {
                    if (_startDate == null || _endDate == null) return true;
                    final attendanceDate = attendance.date;
                    return attendanceDate.isAfter(_startDate!) && 
                           attendanceDate.isBefore(_endDate!.add(const Duration(days: 1)));
                  }).toList();

                  if (filteredAttendance.isEmpty) {
                    return const Center(
                      child: Text('No attendance records found'),
                    );
                  }

                  return _buildAttendanceTable(filteredAttendance);
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

  Widget _buildDateRangeHeader() {
    final startFormatted = _startDate != null 
        ? DateFormat('MMM dd, yyyy').format(_startDate!) 
        : 'All time';
    final endFormatted = _endDate != null 
        ? DateFormat('MMM dd, yyyy').format(_endDate!) 
        : 'Present';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date Range',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text('$startFormatted to $endFormatted'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTable(List<AttendanceModel> attendanceList) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Reg. Number')),
            DataColumn(label: Text('Student Name')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Comments')),
            DataColumn(label: Text('Actions')),
          ],
          rows: attendanceList.map((attendance) {
            return DataRow(
              cells: [
                DataCell(Text(attendance.registrationNumber)),
                DataCell(Text(attendance.studentName)),
                DataCell(Text(DateFormat('MMM dd, yyyy').format(attendance.date))),
                DataCell(Text(DateFormat('HH:mm').format(attendance.date))),
                DataCell(_buildStatusCell(attendance.status)),
                DataCell(Text(attendance.lecturerComments)),
                DataCell((_buildActionButtons(attendance))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

Widget _buildActionButtons(AttendanceModel attendance) {
  // Only show action buttons for pending attendance
  if (attendance.status != AttendanceStatus.pending) {
    return const Text('-');
  }
  
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
        tooltip: 'Approve',
        onPressed: () => _approveAttendance(attendance.id),
      ),
      IconButton(
        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
        tooltip: 'Reject',
        onPressed: () => _showRejectDialog(attendance.id),
      ),
    ],
  );
}


Future<void> _approveAttendance(String attendanceId) async {
  try {
    await ref.read(attendanceManagerProvider.notifier).approveAttendance(attendanceId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance approved successfully')),
    );
    // Refresh data
    _loadAttendanceData();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error approving attendance: $e')),
    );
  }
}

Future<void> _showRejectDialog(String attendanceId) async {
  final commentController = TextEditingController();
  
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reject Attendance'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Please provide a reason for rejection:'),
          const SizedBox(height: 16),
          TextField(
            controller: commentController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter comments',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _rejectAttendance(attendanceId, commentController.text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Reject'),
        ),
      ],
    ),
  );
}

Future<void> _rejectAttendance(String attendanceId, String comments) async {
  if (comments.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please provide comments for rejection')),
    );
    return;
  }
  
  try {
    await ref.read(attendanceManagerProvider.notifier).rejectAttendance(attendanceId, comments);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance rejected')),
    );
    // Refresh data
    _loadAttendanceData();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error rejecting attendance: $e')),
    );
  }
}

  Widget _buildStatusCell(AttendanceStatus status) {
    Color color;
    String text = status.toString().split('.').last;
    
    switch (status) {
      case AttendanceStatus.approved:
        color = Colors.green;
        break;
      case AttendanceStatus.rejected:
        color = Colors.red;
        break;
      case AttendanceStatus.pending:
      default:
        color = Colors.orange;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAttendanceData();
    }
  }

  Future<void> _generatePDF(BuildContext context) async {
    final courseAttendanceAsync = ref.read(attendanceManagerProvider);
    
    if (courseAttendanceAsync is! AsyncData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data is still loading. Please wait.')),
      );
      return;
    }
    
    final attendanceList = courseAttendanceAsync.value;
    
  final filteredAttendance = attendanceList != null ? attendanceList.where((attendance) {
  if (_startDate == null || _endDate == null) return true;
  final attendanceDate = attendance.date;
  return attendanceDate.isAfter(_startDate!) && 
         attendanceDate.isBefore(_endDate!.add(const Duration(days: 1)));
}).toList() : [];
    final pdf = pw.Document();
    
    final courseName = ref.read(courseProvider(widget.courseId)).when(
      data: (course) => course.name,
      loading: () => 'Loading...',
      error: (_, __) => 'Unknown Course',
    );
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Attendance Report - $courseName'),
            ),
            pw.Paragraph(
              text: 'Date Range: ${DateFormat('MMM dd, yyyy').format(_startDate ?? DateTime(2020))} to ${DateFormat('MMM dd, yyyy').format(_endDate ?? DateTime.now())}',
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              headers: ['Reg. Number', 'Student Name', 'Date', 'Time', 'Status'],
              data: filteredAttendance.map((attendance) {
                return [
                  attendance.studentId,
                  attendance.studentName,
                  DateFormat('MMM dd, yyyy').format(attendance.date),
                  DateFormat('HH:mm').format(attendance.date),
                  attendance.status.toString().split('.').last,
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Footer(
              title: pw.Text(
                'Generated on ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _downloadPDF(BuildContext context) async {
    final courseAttendanceAsync = ref.read(attendanceManagerProvider);
    if (courseAttendanceAsync is! AsyncData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data is still loading. Please wait.')),
      );
      return;
    }
    
    final attendanceList = courseAttendanceAsync.value;
    
final filteredAttendance = attendanceList != null ? attendanceList.where((attendance) {
  if (_startDate == null || _endDate == null) return true;
  final attendanceDate = attendance.date;
  return attendanceDate.isAfter(_startDate!) && 
         attendanceDate.isBefore(_endDate!.add(const Duration(days: 1)));
}).toList() : [];
    
    final pdf = pw.Document();
    
    final courseName = ref.read(courseProvider(widget.courseId)).when(
      data: (course) => course.name,
      loading: () => 'Loading...',
      error: (_, __) => 'Unknown Course',
    );
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Attendance Report - $courseName'),
            ),
            pw.Paragraph(
              text: 'Date Range: ${DateFormat('MMM dd, yyyy').format(_startDate ?? DateTime(2020))} to ${DateFormat('MMM dd, yyyy').format(_endDate ?? DateTime.now())}',
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              headers: ['Reg. Number', 'Student Name', 'Date', 'Time', 'Status'],
              data: filteredAttendance.map((attendance) {
                return [
                  attendance.registrationNumber,
                  attendance.studentName,
                  DateFormat('MMM dd, yyyy').format(attendance.date),
                  DateFormat('HH:mm').format(attendance.date),
                  attendance.status.toString().split('.').last,
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Footer(
              title: pw.Text(
                'Generated on ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ];
        },
      ),
    );

    // Save to temporary file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/attendance_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    // Show success message with file path
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF saved to: ${file.path}'),
        action: SnackBarAction(
          label: 'Share',
          onPressed: () {
            // Implement share functionality if needed
          },
        ),
      ),
    );
  }
}