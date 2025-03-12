import 'package:attendanceapp/Models/course_model.dart';
import 'package:attendanceapp/Providers/auth_providers.dart';
import 'package:attendanceapp/Providers/course_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddCourseDialog extends ConsumerStatefulWidget {
  const AddCourseDialog({super.key});

  @override
  ConsumerState<AddCourseDialog> createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends ConsumerState<AddCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  String _courseName = '';
  String _courseCode = '';
  String _description = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Unit'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Unit Name'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter unit name' : null,
              onChanged: (value) => _courseName = value,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Unit Code'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter Unit code' : null,
              onChanged: (value) => _courseCode = value,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Description'),
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
                onPressed: () => _addCourse(context),
                child: const Text('Add'),
              ),
      ],
    );
  }

  Future<void> _addCourse(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userData = ref.read(userDataProvider).value;
        if (userData != null) {
          // Create a document reference to get an ID
          final docRef = FirebaseFirestore.instance.collection('courses').doc();

          final course = CourseModel(
            id: docRef.id, // Use the generated document ID
            name: _courseName,
            lecturerId: userData.id,
            courseCode: _courseCode,
            description: _description,
            lecturerName: userData.name,
          );

          await ref.read(courseNotifierProvider.notifier).addCourse(course);

          // Use a variable to store context before the async gap
          final currentContext = context;
          Navigator.pop(currentContext);
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(content: Text('Unit added successfully')),
          );
        }
      } catch (e) {
        // Use a variable to store context before the async gap
        final currentContext = context;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Error adding Unit: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}