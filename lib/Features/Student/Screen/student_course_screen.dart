import 'package:attendanceapp/Features/Auth/Model/course_model.dart';
import 'package:attendanceapp/Features/Auth/Model/user_model.dart';
import 'package:attendanceapp/Features/Auth/Provider/providers.dart';
import 'package:attendanceapp/Features/Student/Screen/unit_details_screen.dart';
import 'package:attendanceapp/Features/Unit/Model/course_registration_model.dart';
import 'package:attendanceapp/Features/Unit/Model/unit_model.dart';
import 'package:flutter/material.dart';


class StudentCoursesScreen {
  const StudentCoursesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends ConsumerState<StudentCoursesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      data: (UserModel? user) {
        if (user == null) {
          return const Center(child: Text('User not found'));
        }

        final registrationsAsync = ref.watch(studentRegistrationsProvider(user.uid));

        return Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: 'Enrolled Courses'),
                Tab(text: 'Pending Approvals'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Enrolled Courses Tab
                  registrationsAsync.when(
                    data: (List<CourseRegistrationModel> registrations) {
                      final approvedRegistrations = registrations
                          .where((reg) => reg.status == 'approved')
                          .toList();
                      
                      if (approvedRegistrations.isEmpty) {
                        return const Center(
                          child: Text('No enrolled courses yet'),
                        );
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: approvedRegistrations.length,
                        itemBuilder: (context, index) {
                          final registration = approvedRegistrations[index];
                          return _buildCourseCard(registration);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(child: Text('Error: $error')),
                  ),

                  // Pending Approvals Tab
                  registrationsAsync.when(
                    data: (List<CourseRegistrationModel> registrations) {
                      final pendingRegistrations = registrations
                          .where((reg) => reg.status == 'pending')
                          .toList();
                      
                      if (pendingRegistrations.isEmpty) {
                        return const Center(
                          child: Text('No pending course registrations'),
                        );
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: pendingRegistrations.length,
                        itemBuilder: (context, index) {
                          final registration = pendingRegistrations[index];
                          return _buildPendingCourseCard(registration);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(child: Text('Error: $error')),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildCourseCard(CourseRegistrationModel registration) {
    return FutureBuilder<CourseModel?>(
      future: ref.read(firebaseRepositoryProvider).getCourseById(registration.courseId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final course = snapshot.data!;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Text(
              course.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Text(
              'Course Code: ${course.code}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            expandedAlignment: Alignment.topLeft,
            childrenPadding: const EdgeInsets.all(16),
            children: [
              FutureBuilder<List<UnitModel>>(
                future: ref.read(firebaseRepositoryProvider).getUnitsByCourseId(course.id),
                builder: (context, unitsSnapshot) {
                  if (!unitsSnapshot.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  final units = unitsSnapshot.data!;
                  
                  if (units.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No units available for this course'),
                    );
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Course Units:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...units.map((unit) => ListTile(
                        title: Text(unit.name),
                        subtitle: Text('Venue: ${unit.venue}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UnitDetailsScreen(unit: unit, course: course),
                            ),
                          );
                        },
                      )),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingCourseCard(CourseRegistrationModel registration) {
    return FutureBuilder<CourseModel?>(
      future: ref.read(firebaseRepositoryProvider).getCourseById(registration.courseId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final course = snapshot.data!;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              course.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Course Code: ${course.code}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.pending_actions,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pending Approval',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Submitted on: ${registration.createdAt.day}/${registration.createdAt.month}/${registration.createdAt.year}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}