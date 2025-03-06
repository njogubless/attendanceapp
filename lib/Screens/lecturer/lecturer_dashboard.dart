// lib/screens/lecturer/lecturer_dashboard.dart
import 'package:attendanceapp/Screens/Auth/login_Screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class LecturerDashboard extends StatelessWidget {
  const LecturerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturer Dashboard'),
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
            const Text('Welcome, Lecturer!'),
            ElevatedButton(
              onPressed: () {
      
              },
              child: const Text('Manage Courses'),
            ),
            ElevatedButton(
              onPressed: () {
            
              },
              child: const Text('Approve Attendance'),
            ),
          ],
        ),
      ),
    );
  }
}