import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/Models/course_model.dart';
import 'package:attendanceapp/Models/unit_model.dart';
import 'package:attendanceapp/Providers/attendance_providers.dart';
import 'package:attendanceapp/Providers/course_providers.dart';
import 'package:attendanceapp/Providers/unit_providers.dart';
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
      print('Error loading student data: $e');
    }
  }

  void _showRegisterCoursesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer(
          builder: (context, ref, child) {
            final coursesAsyncValue = ref.watch(coursesProvider);
            final enrolledUnitsAsyncValue = ref.watch(unitsProvider);

            return coursesAsyncValue.when(
              data: (courses) {
                final enrolledUnits = enrolledUnitsAsyncValue.maybeWhen(
                  data: (units) => units
                      .where(
                          (unit) => unit.enrolledStudents.contains(_studentId))
                      .toList(),
                  orElse: () => <UnitModel>[],
                );

                return AlertDialog(
                  title: const Text('Available Courses'),
                  content: Container(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        // Check if student is already enrolled in this course
                        bool isEnrolled = enrolledUnits
                            .any((unit) => unit.courseId == course.id);

                        return ListTile(
                          title: Text(course.name),
                          subtitle: Text(
                              '${course.courseCode} - ${course.lecturerName}'),
                          trailing: isEnrolled
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : ElevatedButton(
                                  onPressed: () {
                                    ref
                                        .read(courseNotifierProvider.notifier)
                                        .enrollStudent(course.id, _studentId);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Register'),
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

  void _showUnitsList(CourseModel course) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer(
          builder: (context, ref, child) {
            final unitsAsyncValue = ref.watch(unitsProvider);

            return unitsAsyncValue.when(
              data: (allUnits) {
                // Filter units by the selected course
                final courseUnits = allUnits
                    .where((unit) => unit.courseId == course.id)
                    .toList();

                return AlertDialog(
                  title: Text('Units for ${course.name}'),
                  content: Container(
                    width: double.maxFinite,
                    child: courseUnits.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No units available for this course'),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: courseUnits.length,
                            itemBuilder: (context, index) {
                              final unit = courseUnits[index];
                              return ListTile(
                                title: Text(unit.name),
                                subtitle: Text(unit.courseId),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () => _showAttendanceForm(unit),
                                  child: const Text('Sign Attendance'),
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

  void _showAttendanceForm(UnitModel unit) {
    final _commentController = TextEditingController();
    final _locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Submit Attendance'),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unit: ${unit.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Code: ${unit.courseId}'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
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
                      studentId: _studentId,
                      studentName: _studentName, // Added studentName
                      courseName: unit.courseId, // Added courseName
                      lecturerId:
                          unit.lecturerId, // Use the lecturerId from the unit
                      venue: _locationController.text, // Changed from location
                      attendanceDate: Timestamp.fromDate(
                          DateTime.now()), // Changed from timestamp
                      status: AttendanceStatus
                          .pending, // Changed from approved: false
                      lecturerComments:
                          _commentController.text, // Changed from comment
                    );

                    // Submit attendance
                    ref
                        .read(attendanceNotifierProvider.notifier)
                        .submitAttendance(attendance);

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Attendance submitted successfully!')),
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
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => LoginScreen(toggleView: () {})),
              );
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final coursesAsyncValue = ref.watch(coursesProvider);
          final unitsAsyncValue = ref.watch(unitsProvider);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _actionButton(
                              context,
                              icon: Icons.book,
                              label: 'Register Courses',
                              onTap: _showRegisterCoursesDialog,
                            ),
                            _actionButton(
                              context,
                              icon: Icons.list,
                              label: 'My Courses',
                              onTap: () {
                                setState(() {
                                  // Just to refresh the view
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'My Registered Courses',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                coursesAsyncValue.when(
                  data: (courses) {
                    final enrolledUnits = unitsAsyncValue.maybeWhen(
                      data: (units) => units
                          .where((unit) =>
                              unit.enrolledStudents.contains(_studentId))
                          .toList(),
                      orElse: () => <UnitModel>[],
                    );

                    // Get unique course IDs from enrolled units
                    final enrolledCourseIds =
                        enrolledUnits.map((unit) => unit.courseId).toSet();

                    // Filter courses based on enrolled units
                    final enrolledCourses = courses
                        .where(
                            (course) => enrolledCourseIds.contains(course.id))
                        .toList();

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
                                child: const Text('Register Courses'),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            title: Text(
                              course.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle:
                                Text('${course.id} - ${course.lecturerName}'),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: () => _showUnitsList(course),
                              child: const Text('View Units'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text('Error loading courses: $err'),
                  ),
                ),

                // Recently Attended Sessions
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
                    final attendancesAsyncValue =
                        ref.watch(attendancesProvider);
                    final unitsAsyncValue = ref.watch(unitsProvider);

                    return attendancesAsyncValue.when(
                      data: (attendances) {
                        // Filter attendances for current student and sort by most recent
                        final studentAttendances = attendances
                            .where((a) => a.studentId == _studentId)
                            .toList()
                          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                        // Get just the most recent 5 attendances
                        final recentAttendances =
                            studentAttendances.take(5).toList();

                        if (recentAttendances.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No recent attendance records',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentAttendances.length,
                          itemBuilder: (context, index) {
                            final attendance = recentAttendances[index];

                            // Find unit name for this attendance
                            String unitName = 'Unknown Unit';
                            String unitCode = '';
                            unitsAsyncValue.whenData((units) {
                              final unit = units.firstWhere(
                                (u) => u.id == attendance.unitId,
                                orElse: () => UnitModel(
                                  id: '',
                                  courseId: '',
                                  name: 'Unknown Unit',
                                  enrolledStudents: [],
                                  lecturerId: '',
                                ),
                              );
                              unitName = unit.name;
                            });

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: attendance.approved
                                      ? Colors.green.shade50
                                      : Colors.orange.shade50,
                                  child: Icon(
                                    attendance.approved
                                        ? Icons.check
                                        : Icons.pending_outlined,
                                    color: attendance.approved
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                                title: Text(unitName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(unitCode),
                                    Text(
                                      '${attendance.timestamp.day}/${attendance.timestamp.month}/${attendance.timestamp.year} at ${attendance.timestamp.hour}:${attendance.timestamp.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: Chip(
                                  label: Text(
                                    attendance.approved
                                        ? 'Approved'
                                        : 'Pending',
                                    style: TextStyle(
                                      color: attendance.approved
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: attendance.approved
                                      ? Colors.green.shade50
                                      : Colors.orange.shade50,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(
                        child: Text('Error loading attendance: $err'),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
