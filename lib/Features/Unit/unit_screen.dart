// Create Unit Screen
import 'package:attendanceapp/Models/unit_model.dart';
import 'package:attendanceapp/Providers/unit_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UnitScreen extends ConsumerStatefulWidget {
  final String lecturerId;
  final UnitModel? unit; // For editing existing unit

  const UnitScreen({
    Key? key,
    required this.lecturerId,
    this.unit,
  }) : super(key: key);

  @override
  ConsumerState<UnitScreen> createState() => _CreateUnitScreenState();
}

class _CreateUnitScreenState extends ConsumerState<UnitScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.unit?.name ?? '');
    _codeController = TextEditingController(text: widget.unit?.code ?? '');
    _descriptionController = TextEditingController(text: widget.unit?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveUnit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the lecturer data (assuming there's a way to get the name)
      // This could be from a provider or passed in as a parameter
      final lecturerName = "Current Lecturer"; // Replace with actual logic

      if (widget.unit == null) {
        // Create new unit
        final newUnit = UnitModel(
          id: '', // Will be assigned by Firestore
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          courseId: 'courseId', // Replace with actual courseId
          lecturerId: widget.lecturerId,
          lecturerName: lecturerName,
          description: _descriptionController.text.trim(),
          status: UnitStatus.pending,
          isAttendanceActive: false,
          createdAt: Timestamp.now(),
        );

        await ref.read(unitManagerProvider.notifier).addUnit(newUnit, newUnit.courseId );
      } else {
        // Update existing unit
        final updatedUnit = widget.unit!.copyWith(
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          description: _descriptionController.text.trim(),
        );

        await ref.read(unitManagerProvider.notifier).updateUnit(updatedUnit);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.unit == null ? 'Create New Unit' : 'Edit Unit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Unit Name',
                  hintText: 'e.g., Introduction to Computer Science',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a unit name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Unit Code',
                  hintText: 'e.g., CS101',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a unit code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Briefly describe the unit',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              if (widget.unit != null)
                Text(
                  'Status: ${widget.unit!.status.toString().split('.').last}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(widget.unit!.status),
                  ),
                ),
              if (widget.unit != null && widget.unit!.adminComments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Admin Comments: ${widget.unit!.adminComments}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveUnit,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(widget.unit == null ? 'Create Unit' : 'Update Unit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(UnitStatus status) {
    switch (status) {
      case UnitStatus.approved:
        return Colors.green;
      case UnitStatus.rejected:
        return Colors.red;
      case UnitStatus.pending:
      default:
        return Colors.orange;
    }
  }
}
