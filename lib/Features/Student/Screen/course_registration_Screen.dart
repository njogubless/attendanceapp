

import 'package:attendanceapp/Features/Auth/Model/course_model.dart';
import 'package:attendanceapp/Features/Auth/Model/user_model.dart';
import 'package:attendanceapp/Features/Auth/Provider/providers.dart';
import 'package:flutter/material.dart';


class CourseRegistrationScreen extends ConsumerStatefulWidget {
  const CourseRegistrationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CourseRegistrationScreen> createState() => _CourseRegistrationScreenState();
}

class _CourseRegistrationScreenState extends ConsumerState<CourseRegistrationScreen> {
  List<CourseModel> _availableCourses = [];
  List<CourseModel> _filteredCourses = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(firebaseRepositoryProvider);
      final currentUser = await repository.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not found');
      }

      // Load all registered courses first
      final registrations = await repository.getRegistrationsByStudentId(currentUser.uid);
      final registeredCourseIds = registrations.map((reg) => reg.courseId).toSet();

      // Query Firestore for all courses
      final allCourses = await _getAllCourses();
      
      // Filter out already registered courses
      _availableCourses = allCourses
          .where((course) => !registeredCourseIds.contains(course.id))
          .toList();
      
      _filteredCourses = List.from(_availableCourses);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading courses: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<CourseModel>> _getAllCourses() async {
    final repository = ref.read(firebaseRepositoryProvider);
    
    // Get all lecturers
    final snapshot = await repository._firestore.collection('users')
        .where('userType', isEqualTo: 'lecturer')
        .get();
    
    final lecturerIds = snapshot.docs.map((doc) => doc.id).toList();
    
    // Get courses for each lecturer
    List<CourseModel> allCourses = [];
    for (final lecturerId in lecturerIds) {
      final courses = await repository.getCoursesByLecturerId(lecturerId);
      allCourses.addAll(courses);
    }
    
    return allCourses;
  }

  void _filterCourses(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCourses = List.from(_availableCourses);
      } else {
        _filteredCourses = _availableCourses
            .where((course) => 
                course.name.toLowerCase().contains(query.toLowerCase()) ||
                course.code.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _registerForCourse(CourseModel course) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(firebaseRepositoryProvider);
      final currentUser = await repository.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not found');
      }

      await repository.registerForCourse(currentUser.uid, course.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration request sent for ${course.name}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh course list
        await _loadCourses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register for Courses'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: _filterCourses,
                    decoration: InputDecoration(
                      hintText: 'Search courses...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                
                // Courses list
                Expanded(
                  child: _filteredCourses.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No available courses to register'
                                : 'No courses matching "$_searchQuery"',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredCourses.length,
                          itemBuilder: (context, index) {
                            final course = _filteredCourses[index];
                            return FutureBuilder<UserModel?>(
                              future: ref
                                  .read(firebaseRepositoryProvider)
                                  .getUserById(course.lecturerId),
                              builder: (context, snapshot) {
                                final lecturerName = snapshot.data?.name ?? 'Unknown Lecturer';
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 2,
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
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    course.name,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Course Code: ${course.code}',
                                                    style: TextStyle(
                                                      color: Colors.grey.shade700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Lecturer: $lecturerName',
                                                    style: TextStyle(
                                                      color: Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => _registerForCourse(course),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text('Register'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}