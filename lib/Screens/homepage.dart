import 'package:attendanceapp/Models/user_models.dart';
import 'package:attendanceapp/Providers/auth_providers.dart';
import 'package:attendanceapp/Screens/Auth/Login_Screen.dart';
import 'package:attendanceapp/Screens/lecturer/lecturer_dashboard.dart';
import 'package:attendanceapp/Screens/student/student_dashbaord.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(userDataProvider);

    return userDataAsync.when(
      data: (userData) {
        if (userData == null) {
          return const LoginScreen();
        }
        return _buildHomePage(context, userData, ref);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () => ref.refresh(userDataProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomePage(BuildContext context, UserModel userData, WidgetRef  ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${userData.role.toUpperCase()} Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Add logout logic
              ref.read(authNotifierProvider.notifier).signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _buildDashboardContent(userData),
      bottomNavigationBar: _buildBottomNavigationBar(context, userData),
      drawer: _buildDrawer(context, userData, ref),
    );
  }

  Widget _buildDashboardContent(UserModel userData) {
    switch (userData.role) {
      case 'lecturer':
        return  LecturerDashboard();
      case 'student':
        return StudentDashboard();
      default:
        return Center(
          child: Text('Welcome, ${userData.name}'),
        );
    }
  }

  Widget _buildBottomNavigationBar(BuildContext context, UserModel userData) {
    return BottomNavigationBar(
      items: _getBottomNavItems(userData.role),
      onTap: (index) => _onBottomNavTap(context, userData.role, index),
    );
  }

  List<BottomNavigationBarItem> _getBottomNavItems(String role) {
    switch (role) {
      case 'lecturer':
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.class_),
            label: 'Courses',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.check),
            label: 'Attendance',
          ),
        ];
      case 'student':
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Courses',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Attendance',
          ),
        ];
      default:
        return [];
    }
  }

  void _onBottomNavTap(BuildContext context, String role, int index) {
    switch (role) {
      case 'lecturer':
        _navigateLecturerPages(context, index);
        break;
      case 'student':
        _navigateStudentPages(context, index);
        break;
    }
  }

  void _navigateLecturerPages(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Already on Dashboard
        break;
      case 1:
        // Navigate to Manage Courses
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ManageCoursesScreen()),
        );
        break;
      case 2:
        // Navigate to Attendance Approval
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AttendanceApprovalScreen()),
        );
        break;
    }
  }

  void _navigateStudentPages(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Already on Dashboard
        break;
      case 1:
        // Navigate to Available Courses
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AvailableCoursesScreen()),
        );
        break;
      case 2:
        // Navigate to Attendance Submission
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AttendanceSubmissionScreen()),
        );
        break;
    }
  }

  Widget _buildDrawer(BuildContext context, UserModel userData, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userData.name),
            accountEmail: Text(userData.email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userData.name[0].toUpperCase(),
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          ..._getDrawerMenuItems(context, userData.role),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Add settings navigation
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              ref.read(authNotifierProvider.notifier).signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) =>  const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _getDrawerMenuItems(BuildContext context, String role) {
    switch (role) {
      case 'lecturer':
        return [
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              // Potentially refresh or navigate to dashboard
            },
          ),
          ListTile(
            leading: const Icon(Icons.class_),
            title: const Text('Manage Courses'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageCoursesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.check),
            title: const Text('Attendance Approval'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AttendanceApprovalScreen()),
              );
            },
          ),
        ];
      case 'student':
        return [
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              // Potentially refresh or navigate to dashboard
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Available Courses'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AvailableCoursesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('Attendance Submission'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AttendanceSubmissionScreen()),
              );
            },
          ),
        ];
      default:
        return [];
    }
  }
}

// Placeholder screens (you'll need to implement these)
class ManageCoursesScreen extends StatelessWidget {
  const ManageCoursesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Courses')),
      body: const Center(child: Text('Manage Courses Screen')),
    );
  }
}

class AttendanceApprovalScreen extends StatelessWidget {
  const AttendanceApprovalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Approval')),
      body: const Center(child: Text('Attendance Approval Screen')),
    );
  }
}

class AvailableCoursesScreen extends StatelessWidget {
  const AvailableCoursesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Courses')),
      body: const Center(child: Text('Available Courses Screen')),
    );
  }
}

class AttendanceSubmissionScreen extends StatelessWidget {
  const AttendanceSubmissionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Submission')),
      body: const Center(child: Text('Attendance Submission Screen')),
    );
  }
}