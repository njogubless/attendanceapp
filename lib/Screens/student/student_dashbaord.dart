// student_dashboard.dart - Main dashboard file

import 'package:attendanceapp/Providers/auth_providers.dart';
import 'package:attendanceapp/Providers/course_providers.dart' as course_providers;
import 'package:attendanceapp/Screens/Auth/Login_Screen.dart';
import 'package:attendanceapp/Screens/student/components/resgistered_courses.dart';
import 'package:attendanceapp/Screens/student/components/student_header.dart';
import 'package:attendanceapp/Screens/student/components/unit_attendance.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _studentName = 'Student';
  String _studentId = '';

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        setState(() {
          _studentName = user.displayName ?? 'Student';
          _studentId = user.uid;
        });
      }
    } catch (e) {
      debugPrint('Error loading student data: $e');
    }
  }

  void _showRegisterCoursesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer(
          builder: (context, ref, child) {
            final coursesAsyncValue = ref.watch(course_providers.coursesProvider);
            final enrolledCoursesAsyncValue = ref.watch(course_providers.studentEnrolledCoursesProvider);

            return coursesAsyncValue.when(
              data: (courses) {
                final enrolledCourseIds = enrolledCoursesAsyncValue.maybeWhen(
                  data: (enrolledCourses) => enrolledCourses.map((c) => c.id).toSet(),
                  orElse: () => <String>{},
                );

                return AlertDialog(
                  title: const Text('Available Courses'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 400,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        // Check if student is already enrolled in this course
                        bool isEnrolled = enrolledCourseIds.contains(course.id);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(course.name),
                            subtitle: Text('${course.courseCode} - ${course.lecturerName}'),
                            trailing: isEnrolled
                                ? const Chip(
                                    label: Text('Enrolled'),
                                    backgroundColor: Colors.green,
                                    labelStyle: TextStyle(color: Colors.white),
                                  )
                                : ElevatedButton(
                                    onPressed: () {
                                      ref
                                          .read(course_providers.courseNotifierProvider.notifier)
                                          .enrollStudent(course.id, _studentId);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Enrolled in ${course.name}'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                    child: const Text('Register'),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
              loading: () => const AlertDialog(
                content: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => AlertDialog(
                title: const Text('Error'),
                content: Text('Failed to load courses: $err'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => LoginScreen(toggleView: () {})),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate providers to refresh data
          ref.refresh(course_providers.studentEnrolledCoursesProvider);
          ref.refresh(course_providers.allStudentUnitsProvider);
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with student info and action buttons
              StudentHeader(
                studentName: _studentName,
                onRegisterUnits: _showRegisterCoursesDialog,
                onViewCourses: () => setState(() {}),
              ),

              // Registered Courses Section
              const SizedBox(height: 24),
              const Text(
                'My Registered Courses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              RegisteredCourses(
                onRegisterCourses: _showRegisterCoursesDialog,
              ),

              // Units Attendance Section - replacing the Recent Attendance
              const SizedBox(height: 24),
              const Text(
                'Sign Attendance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              UnitAttendance(
                studentId: _studentId,
                studentName: _studentName,
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}