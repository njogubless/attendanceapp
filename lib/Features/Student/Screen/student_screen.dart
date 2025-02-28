import 'package:attendanceapp/Features/Auth/Model/course_model.dart';
import 'package:attendanceapp/Features/Auth/Model/user_model.dart';
import 'package:attendanceapp/Features/Auth/Provider/providers.dart';
import 'package:attendanceapp/Features/Student/Screen/course_registration_Screen.dart';
import 'package:attendanceapp/Features/Student/Screen/student_course_screen.dart';
import 'package:attendanceapp/Features/Unit/Model/course_registration_model.dart';
import 'package:flutter/material.dart';


class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      data: (UserModel? user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('User not found')),
          );
        }

        final screens = [
          _buildDashboard(user),
          const StudentCoursesScreen(),
          const StudentAttendanceScreen(),
          StudentProfileScreen(user: user),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Student Portal'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await ref.read(firebaseRepositoryProvider).signOut();
                },
              ),
            ],
          ),
          body: screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book),
                label: 'My Courses',
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
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildDashboard(UserModel user) {
    final studentRegistrationsAsync = ref.watch(
      studentRegistrationsProvider(user.uid),
    );

    return studentRegistrationsAsync.when(
      data: (List<CourseRegistrationModel> registrations) {
        final approvedRegistrations = registrations
            .where((reg) => reg.status == 'approved')
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
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
                            child: Text(
                              user.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Stats section
              const Text(
                'Your Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatCard(
                    'Enrolled Courses',
                    approvedRegistrations.length.toString(),
                    Icons.school,
                    Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'Pending Approvals',
                    registrations
                        .where((reg) => reg.status == 'pending')
                        .length
                        .toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatCard(
                    'Today\'s Classes',
                    '0', // This would be calculated based on schedule
                    Icons.today,
                    Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'Attendance Rate',
                    '0%', // This would be calculated from attendance data
                    Icons.check_circle,
                    Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Course registration button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseRegistrationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_circle),
                label: const Text('Register for a New Course'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Recent activity
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (registrations.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No recent activities. Register for courses to get started!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: registrations.length > 3 ? 3 : registrations.length,
                  itemBuilder: (context, index) {
                    final registration = registrations[index];
                    return FutureBuilder<CourseModel?>(
                      future: ref
                          .read(firebaseRepositoryProvider)
                          .getCourseById(registration.courseId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        final course = snapshot.data!;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(course.name),
                            subtitle: Text(
                              'Status: ${registration.status.toUpperCase()}',
                              style: TextStyle(
                                color: registration.status == 'approved'
                                    ? Colors.green
                                    : registration.status == 'rejected'
                                        ? Colors.red
                                        : Colors.orange,
                              ),
                            ),
                            trailing: Icon(
                              registration.status == 'approved'
                                  ? Icons.check_circle
                                  : registration.status == 'rejected'
                                      ? Icons.cancel
                                      : Icons.pending_actions,
                              color: registration.status == 'approved'
                                  ? Colors.green
                                  : registration.status == 'rejected'
                                      ? Colors.red
                                      : Colors.orange,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}