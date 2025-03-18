// lib/Widgets/empty_courses_view.dart
import 'package:flutter/material.dart';

class EmptyCoursesView extends StatelessWidget {
  final VoidCallback onRefresh;
  
  const EmptyCoursesView({Key? key, required this.onRefresh}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            const Text(
              'No courses found. Please register for courses first.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRefresh,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}