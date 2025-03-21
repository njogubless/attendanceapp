import 'package:attendanceapp/Models/course_model.dart';
import 'package:attendanceapp/Providers/auth_providers.dart';

import 'package:attendanceapp/Screens/Auth/Login_Screen.dart';
import 'package:attendanceapp/Screens/course_detail_screen.dart';
import 'package:attendanceapp/Screens/lecturer/components/attendance_tab.dart';
import 'package:attendanceapp/Screens/lecturer/components/course_tab.dart';
import 'package:attendanceapp/Screens/lecturer/components/profile_tab.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LecturerDashboard extends ConsumerStatefulWidget {
  const LecturerDashboard({super.key});

  @override
  ConsumerState<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends ConsumerState<LecturerDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userDataProvider);
    
    // Create the screens with navigation capabilities
    final List<Widget> screens = [
      CoursesTab(
        onCourseSelected: (CourseModel course) {
          _navigateToCourseDetail(context, course);
        },
      ),
      const AttendanceTab(),
      const ProfileTab(),
    ];

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
          body: screens[_selectedIndex],
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
                label: 'Units',
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
  
  void _navigateToCourseDetail(BuildContext context, CourseModel course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailScreen(course: course),
      ),
    );
  }
}