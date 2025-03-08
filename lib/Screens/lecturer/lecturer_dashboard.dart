import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/Providers/attendance_providers.dart';
import 'package:attendanceapp/Providers/auth_providers.dart';
import 'package:attendanceapp/Providers/course_providers.dart';
import 'package:attendanceapp/Screens/Auth/Login_Screen.dart';

import 'package:attendanceapp/Models/course_model.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class LecturerDashboard extends ConsumerStatefulWidget {
  const LecturerDashboard({super.key});

  @override
  ConsumerState<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends ConsumerState<LecturerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const CoursesTab(),
    const AttendanceTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userDataProvider);

    return user.when(
      data: (userData) {
        if (userData == null) {
          return const Scaffold(
            body: Center(child: Text("No user data found")),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Lecturer Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).signOut();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => LoginScreen(toggleView: () {})),
                  );
                },
              ),
            ],
          ),
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.book),
                label: 'Courses',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.check_circle),
                label: 'Attendance',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text("Error loading user data")),
      ),
    );
  }
}

class CoursesTab extends ConsumerStatefulWidget {
  const CoursesTab({super.key});

  @override
  ConsumerState<CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends ConsumerState<CoursesTab> {
  final _formKey = GlobalKey<FormState>();
  String _courseName = '';
  String _courseCode = '';
  String _description = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final coursesStream = ref.watch(lecturerCoursesStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Courses',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: coursesStream.when(
              data: (courses) {
                if (courses.isEmpty) {
                  return const Center(
                    child: Text('No courses yet. Add your first course!'),
                  );
                }

                return ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(course.name),
                        subtitle: Text(course.courseCode),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.people),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        StudentListScreen(course: course),
                                  ),
                                );
                              },
                              tooltip: 'View Students',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Course'),
                                    content: Text(
                                        'Are you sure you want to delete ${course.name}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  await ref
                                      .read(courseServiceProvider)
                                      .deleteCourse(course.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Course deleted')),
                                  );
                                }
                              },
                              tooltip: 'Delete Course',
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CourseDetailScreen(course: course),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add New Course'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Add New Course'),
                  content: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'Course Name'),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter course name'
                              : null,
                          onChanged: (value) => _courseName = value,
                        ),
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'Course Code'),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter course code'
                              : null,
                          onChanged: (value) => _courseCode = value,
                        ),
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                          maxLines: 3,
                          onChanged: (value) => _description = value,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : TextButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _isLoading = true;
                                });

                                try {
                                  final userData =
                                      ref.read(userDataProvider).value;
                                  if (userData != null) {
                                    // Create a document reference to get an ID
                                    final docRef = FirebaseFirestore.instance
                                        .collection('courses')
                                        .doc();

                                    final course = CourseModel(
                                      id: docRef
                                          .id, // Use the generated document ID
                                      name: _courseName,
                                      lecturerId: userData.id,
                                      courseCode: _courseCode,
                                      description: _description,
                                      lecturerName: userData.name,
                                      // Optional parameters don't need to be explicitly set if using defaults
                                    );

                                    await ref
                                        .read(courseNotifierProvider.notifier)
                                        .addCourse(course);

                                    // Use a variable to store context before the async gap
                                    final currentContext = context;
                                    Navigator.pop(currentContext);
                                    ScaffoldMessenger.of(currentContext)
                                        .showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Course added successfully')),
                                    );
                                  }
                                } catch (e) {
                                  // Use a variable to store context before the async gap
                                  final currentContext = context;
                                  ScaffoldMessenger.of(currentContext)
                                      .showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Error adding course: ${e.toString()}')),
                                  );
                                } finally {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              }
                            },
                            child: const Text('Add'),
                          ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AttendanceTab extends ConsumerWidget {
  const AttendanceTab({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userDataProvider).value;
    final lecturerId = user?.id ?? '';
    final pendingAttendance =
        ref.watch(pendingAttendanceForLecturerProvider(lecturerId));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pending Attendance Requests',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: pendingAttendance.when(
              data: (attendanceList) {
                if (attendanceList.isEmpty) {
                  return const Center(
                    child: Text('No pending attendance requests'),
                  );
                }

                return ListView.builder(
                  itemCount: attendanceList.length,
                  itemBuilder: (context, index) {
                    final attendance = attendanceList[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(attendance.studentName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Course: ${attendance.courseName}'),
                            Text(
                                'Date: ${DateFormat('MMM dd, yyyy').format(attendance.date)}'),
                            Text(
                                'Status: ${attendance.status.toString().split('.').last}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                await ref
                                    .read(attendanceServiceProvider)
                                    .updateAttendanceStatus(
                                        attendance.id, 'approved');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Attendance approved')),
                                );
                              },
                              tooltip: 'Approve',
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () async {
                                await ref
                                    .read(attendanceServiceProvider)
                                    .updateAttendanceStatus(
                                        attendance.id, 'rejected');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Attendance rejected')),
                                );
                              },
                              tooltip: 'Reject',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userDataProvider);

    return user.when(
      data: (userData) {
        if (userData == null) {
          return const Center(child: Text('No user data found'));
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue,
                  child: Text(
                    userData.name.isNotEmpty
                        ? userData.name[0].toUpperCase()
                        : 'L',
                    style: const TextStyle(fontSize: 40, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Name'),
                        subtitle: Text(userData.name),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Email'),
                        subtitle: Text(userData.email),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.work),
                        title: const Text('Role'),
                        subtitle: Text(userData.role.toUpperCase()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     //builder: (context) => EditProfileScreen(user: userData),
                  //   ),
                  // );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Edit Profile'),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading profile')),
    );
  }
}

class StudentListScreen extends ConsumerWidget {
  final CourseModel course;

  const StudentListScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsStream = ref.watch(courseStudentsProvider(course.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Students - ${course.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Course Code: ${course.name}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            studentsStream.when(
              data: (students) {
                if (students.isEmpty) {
                  return const Expanded(
                    child: Center(
                      child: Text('No students enrolled in this course yet'),
                    ),
                  );
                }

                return Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(student.name[0].toUpperCase()),
                          ),
                          title: Text(student.name),
                          subtitle: Text(student.email),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Expanded(
                child: Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseDetailScreen extends ConsumerWidget {
  final CourseModel course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceStream = ref.watch(attendanceForCourseProvider(course.id));

    return Scaffold(
        appBar: AppBar(
          title: Text(course.name),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Course Code: ${course.courseCode}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              if (course.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Description:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(course.description),
              ],
              const SizedBox(height: 24),
              const Text(
                'Attendance History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: attendanceStream.when(
                  data: (attendanceList) {
                    if (attendanceList.isEmpty) {
                      return const Center(
                        child: Text('No attendance records yet'),
                      );
                    }

                    return ListView.builder(
                      itemCount: attendanceList.length,
                      itemBuilder: (context, index) {
                        final attendance = attendanceList[index];
                        return Card(
                          child: ListTile(
                            title: Text(attendance.studentName),
                            subtitle: Text(DateFormat('MMM dd, yyyy')
                                .format(attendance.date)),
                            trailing: _getStatusIcon(attendance.status),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.approved:
        return const Icon(Icons.check_circle, color: Colors.green);
      case AttendanceStatus.rejected:
        return const Icon(Icons.cancel, color: Colors.red);
      case AttendanceStatus.pending:
      default:
        return const Icon(Icons.access_time, color: Colors.orange);
    }
  }
}
