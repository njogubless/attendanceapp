// lib/screens/student/student_dashboard.dart

import 'package:attendanceapp/Screens/Auth/Login_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome, Student!'),
            ElevatedButton(
              onPressed: () {
      
              },
              child: const Text('Register Courses'),
            ),
            ElevatedButton(
              onPressed: () {
   
              },
              child: const Text('Submit Attendance'),
            ),
          ],
        ),
      ),
    );
  }
}