import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/Models/course_model.dart';
import 'package:attendanceapp/Models/unit_model.dart';
import 'package:attendanceapp/Providers/attendance_providers.dart';
import 'package:attendanceapp/Providers/auth_providers.dart';
import 'package:attendanceapp/Providers/course_providers.dart';
import 'package:attendanceapp/Providers/unit_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final CourseModel course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> with TickerProviderStateMixin {
  // Tab controller for managing units and attendance tabs
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
  Widget build(
    BuildContext context,
  ) {
    final course = widget.course;
    final attendanceStream = ref.watch(attendanceForCourseProvider(course.id));
    final unitsStream = ref.watch(courseUnitsProvider(course.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(course.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Units', icon: Icon(Icons.book)),
            Tab(text: 'Attendance', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // UNITS TAB
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Units for ${course.name}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Course Code: ${course.courseCode}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: unitsStream.when(
                    data: (units) {
                      if (units.isEmpty) {
                        return const Center(
                          child: Text('No units added to this course yet'),
                        );
                      }

                      return ListView.builder(
                        itemCount: units.length,
                        itemBuilder: (context, index) {
                          final unit = units[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(unit.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (unit.description.isNotEmpty)
                                    Text(unit.description),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showEditUnitDialog(unit),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteUnit(unit),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Unit'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () => _showAddUnitDialog(),
                ),
              ],
            ),
          ),

          // ATTENDANCE TAB
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(DateFormat('MMM dd, yyyy')
                                      .format(attendance.date)),
                                  Text('Unit: ${attendance.unitName ?? "N/A"}')
                                ],
                              ),
                              trailing: _getStatusIcon(attendance.status),
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUnitDialog() {
    final formKey = GlobalKey<FormState>();
    String unitName = '';
    String unitDescription = '';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Add New Unit'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Unit Name'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter unit name'
                      : null,
                  onChanged: (value) => unitName = value,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Description (Optional)'),
                  maxLines: 3,
                  onChanged: (value) => unitDescription = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            isLoading
                ? const CircularProgressIndicator()
                : TextButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          isLoading = true;
                        });

                        try {
                          final userData = ref.read(userDataProvider).value;
                          if (userData != null) {
                            // Create a document reference to get an ID
                            final docRef = FirebaseFirestore.instance
                                .collection('units')
                                .doc();
                                final courseId = widget.course.id;

                            final unit = UnitModel(
                              id: docRef.id,
                              name: unitName,
                              courseId: courseId,
                              lecturerId: userData.id,
                              description: unitDescription,
                              code: 'unitCode', // Add appropriate unit code here
                              lecturerName: userData.name, // Add lecturer name here
                            );

                            await ref
                                .read(unitManagerProvider.notifier)
                                .addUnit(unit, courseId);

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Unit added successfully')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Error adding unit: ${e.toString()}')),
                          );
                        } finally {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    },
                    child: const Text('Add'),
                  ),
          ],
        );
      }),
    );
  }

  void _showEditUnitDialog(UnitModel unit) {
    final formKey = GlobalKey<FormState>();
    String unitName = unit.name;
    String unitDescription = unit.description;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Edit Unit'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: unitName,
                  decoration: const InputDecoration(labelText: 'Unit Name'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter unit name'
                      : null,
                  onChanged: (value) => unitName = value,
                ),
                TextFormField(
                  initialValue: unitDescription,
                  decoration: const InputDecoration(
                      labelText: 'Description (Optional)'),
                  maxLines: 3,
                  onChanged: (value) => unitDescription = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            isLoading
                ? const CircularProgressIndicator()
                : TextButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          isLoading = true;
                        });

                        try {
                          final updatedUnit = unit.copyWith(
                            name: unitName,
                            description: unitDescription,
                          );

                          await ref
                              .read(unitManagerProvider.notifier)
                              .updateUnit(updatedUnit);

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Unit updated successfully')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Error updating unit: ${e.toString()}')),
                          );
                        } finally {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    },
                    child: const Text('Update'),
                  ),
          ],
        );
      }),
    );
  }

  Future<void> _deleteUnit(UnitModel unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Unit'),
        content: Text('Are you sure you want to delete ${unit.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(unitManagerProvider.notifier)
            .deleteUnit(unit.id, unit.courseId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unit deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting unit: ${e.toString()}')),
        );
      }
    }
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
