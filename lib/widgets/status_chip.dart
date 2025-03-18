// lib/Widgets/status_chip.dart
import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final AttendanceStatus status;
  
  const StatusChip({Key? key, required this.status}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    Color chipColor;
    String statusText = status.toString().split('.').last;
    
    switch (status) {
      case AttendanceStatus.pending:
        chipColor = Colors.orange;
        break;
      case AttendanceStatus.approved:
        chipColor = Colors.green;
        break;
      case AttendanceStatus.rejected:
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor, width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class AttendanceButton extends StatelessWidget {
  final AttendanceStatus? status;
  final VoidCallback? onPressed;
  final Color color;
  
  const AttendanceButton({
    Key? key,
    required this.status,
    required this.onPressed,
    required this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    String buttonText = 'Sign Attendance';
    Color buttonColor = color;
    
    if (status != null) {
      switch (status) {
        case AttendanceStatus.pending:
          buttonText = 'Pending';
          buttonColor = Colors.orange;
          break;
        case AttendanceStatus.approved:
          buttonText = 'Approved';
          buttonColor = Colors.green;
          break;
        case AttendanceStatus.rejected:
          buttonText = 'Rejected';
          buttonColor = Colors.red;
          break;
        default:
          buttonText = 'Sign Attendance';
      }
    }
    
    return SizedBox(
      width: 140, // Fixed width to maintain consistency
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: buttonColor.withOpacity(0.7),
          disabledForegroundColor: Colors.white70,
        ),
        child: Text(buttonText),
      ),
    );
  }
}