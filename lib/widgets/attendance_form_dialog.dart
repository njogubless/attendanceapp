import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/Models/course_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceFormDialog extends StatefulWidget {
  final CourseModel course;
  final String studentId;
  final String studentName;
  final Function(AttendanceModel) onSubmit;

  const AttendanceFormDialog({
    Key? key,
    required this.course,
    required this.studentId,
    required this.studentName,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _AttendanceFormDialogState createState() => _AttendanceFormDialogState();
}
class _AttendanceFormDialogState extends State<AttendanceFormDialog> {
  final emailController = TextEditingController();
  final locationController = TextEditingController();
  final reasonController = TextEditingController();
  bool isPresent = true;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    emailController.dispose();
    locationController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _submitAttendance() {
    final timestamp = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final attendance = AttendanceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      courseId: widget.course.id,
      courseName: widget.course.name,
      studentId: widget.studentId,
      studentName: widget.studentName,
      isPresent: isPresent,
      email: emailController.text,
      location: locationController.text,
      reason: reasonController.text,
      timestamp: Timestamp.fromDate(timestamp),
    );

    widget.onSubmit(attendance);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.course.name} - Attendance'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${widget.studentName}'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Status:'),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Present'),
                  selected: isPresent,
                  onSelected: (selected) {
                    setState(() {
                      isPresent = true;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Absent'),
                  selected: !isPresent,
                  onSelected: (selected) {
                    setState(() {
                      isPresent = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text('Date: ${selectedDate.toLocal().toString().split(' ')[0]}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            ListTile(
              title: Text('Time: ${selectedTime.format(context)}'),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime(context),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            if (!isPresent) ...[
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Absence',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitAttendance,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}