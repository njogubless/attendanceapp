import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/Models/course_model.dart';
import 'package:attendanceapp/Models/unit_model.dart';
import 'package:attendanceapp/Providers/attendance_providers.dart';
import 'package:attendanceapp/Providers/auth_providers.dart';
import 'package:attendanceapp/Providers/course_providers.dart' as course_providers;
import 'package:attendanceapp/Providers/course_providers.dart';
import 'package:attendanceapp/Screens/Auth/Login_Screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  void _showCourseUnits(CourseModel course) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer(
          builder: (context, ref, child) {
            final unitsAsyncValue = ref.watch(course_providers.courseUnitsProvider(course.id));

            return unitsAsyncValue.when(
              data: (units) {
                return AlertDialog(
                  title: Text('Units in ${course.name}'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 400,
                    child: units.isEmpty
                        ? const Center(
                            child: Text('No units available for this course'),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: units.length,
                            itemBuilder: (context, index) {
                              final unit = units[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(unit.name),
                                  subtitle: Text('Course: ${course.name}'),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    onPressed: () => _showAttendanceForm(unit, course.name),
                                    child: const Text('Sign Attendance'),
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
                content: Text('Failed to load units: $err'),
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

void _showAttendanceForm(UnitModel unit, String courseName) {
  final commentController = TextEditingController();
  final locationController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Submit Attendance'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Unit: ${unit.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Course: $courseName'),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'Comment (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          Consumer(
            builder: (context, ref, child) {
              return ElevatedButton(
                onPressed: () {
                  // Create attendance model
                  final attendance = AttendanceModel(
                    id: '', // This will be generated by Firestore
                    unitId: unit.id,
                    unitName: unit.name, // Adding the unit name
                    studentId: _studentId,
                    studentName: _studentName,
                    courseName: courseName,
                    lecturerId: unit.lecturerId,
                    venue: locationController.text,
                    attendanceDate: Timestamp.now(),
                    status: AttendanceStatus.pending,
                    studentComments: commentController.text,
                  );

                  // Submit attendance
                  ref
                      .read(attendanceManagerProvider.notifier)
                      .submitAttendance(attendance);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Attendance submitted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Submit Attendance'),
              );
            },
          ),
        ],
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
          ref.refresh(studentAttendanceProvider);
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(Icons.person,
                                size: 40, color: Colors.blue),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome,',
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                _studentName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _actionButton(
                            context,
                            icon: Icons.book,
                            label: 'Register Units',
                            onTap: _showRegisterCoursesDialog,
                          ),
                          _actionButton(
                            context,
                            icon: Icons.list,
                            label: 'My Courses',
                            onTap: () {
                              // Just refresh the view
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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

              Consumer(
                builder: (context, ref, child) {
                  final enrolledCoursesAsyncValue = ref.watch(course_providers.studentEnrolledCoursesProvider);

                  return enrolledCoursesAsyncValue.when(
                    data: (enrolledCourses) {
                      if (enrolledCourses.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                const Text(
                                  'You haven\'t registered for any courses yet',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _showRegisterCoursesDialog,
                                  child: const Text('Register Units'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: enrolledCourses.length,
                        itemBuilder: (context, index) {
                          final course = enrolledCourses[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: Text(
                                  course.name.isNotEmpty ? course.name[0] : 'C',
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                course.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Course Code: ${course.courseCode}'),
                                  Text('Lecturer: ${course.lecturerName}'),
                                ],
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                onPressed: () => _showCourseUnits(course),
                                child: const Text(
                                  'View Units',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              onTap: () => _showCourseUnits(course),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 8),
                            Text(
                              'Error loading courses: $err',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ref.refresh(course_providers.studentEnrolledCoursesProvider);
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Recent Attendance Section
              const SizedBox(height: 24),
              const Text(
                'Recent Attendance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Consumer(
                builder: (context, ref, child) {
                  final attendanceAsyncValue = ref.watch(studentAttendanceProvider);

                  return attendanceAsyncValue.when(
                    data: (attendanceList) {
                      if (attendanceList.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(Icons.history, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'No attendance records found',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Sort by date, most recent first
                      final sortedAttendance = [...attendanceList]
                        ..sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));

                      // Take only the 5 most recent records
                      final recentAttendance = sortedAttendance.take(5).toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentAttendance.length,
                        itemBuilder: (context, index) {
                          final attendance = recentAttendance[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: _getAttendanceStatusIcon(attendance.status),
                              title: Text(attendance.courseName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Date: ${_formatTimestamp(attendance.attendanceDate)}'),
                                  Text('Location: ${attendance.venue}'),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(_getStatusText(attendance.status)),
                                backgroundColor: _getStatusColor(attendance.status),
                                labelStyle: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Text('Error loading attendance: $err'),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getAttendanceStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.approved:
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Colors.white),
        );
      case AttendanceStatus.rejected:
        return const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.close, color: Colors.white),
        );
      case AttendanceStatus.pending:
      default:
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.access_time, color: Colors.white),
        );
    }
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.approved:
        return 'Approved';
      case AttendanceStatus.rejected:
        return 'Rejected';
      case AttendanceStatus.pending:
      default:
        return 'Pending';
    }
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

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}