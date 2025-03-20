// Complete the UnitsTab widget that was cut off
import 'package:attendanceapp/Features/Unit/unit_deatil_screen.dart';
import 'package:attendanceapp/Features/Unit/unit_screen.dart';
import 'package:attendanceapp/Models/unit_model.dart';
import 'package:attendanceapp/Providers/auth_providers.dart';
import 'package:attendanceapp/Providers/unit_providers.dart';
import 'package:attendanceapp/Providers/units_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class UnitsTab extends ConsumerWidget {
  const UnitsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider);
    
    return userData.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('User not found'));
        }

        final lecturerUnits = ref.watch(lecturerUnitsProvider(user.id));

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Units',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Filter tabs for different unit statuses
                _buildFilterTabs(context),
                
                const SizedBox(height: 16),
                Expanded(
                  child: lecturerUnits.when(
                    data: (units) {
                      if (units.isEmpty) {
                        return const Center(
                          child: Text('No units found. Create a new unit to get started.'),
                        );
                      }
                      
                      // Get the currently selected filter
                      final selectedFilter = _getSelectedFilter(context);
                      
                      // Filter units based on selected filter
                      final filteredUnits = _filterUnits(units, selectedFilter);
                      
                      return ListView.builder(
                        itemCount: filteredUnits.length,
                        itemBuilder: (context, index) {
                          final unit = filteredUnits[index];
                          return _buildUnitCard(context, ref, unit);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text('Error loading units: $error'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UnitScreen(lecturerId: user.id),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading user data: $error'),
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: TabBar(
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Pending'),
          Tab(text: 'Approved'),
          Tab(text: 'Rejected'),
        ],
        onTap: (index) {
          // Save the selected filter
          _saveSelectedFilter(context, index);
        },
      ),
    );
  }

  // Helper to get the currently selected filter index
  int _getSelectedFilter(BuildContext context) {
    // You would typically store this in a state provider
    // For simplicity, we'll default to 'All' (0)
    return 0;
  }

  // Helper to save the selected filter
  void _saveSelectedFilter(BuildContext context, int index) {
    // Implement state saving logic
  }

  // Helper to filter units based on the selected filter
  List<UnitModel> _filterUnits(List<UnitModel> units, int filterIndex) {
    switch (filterIndex) {
      case 1: // Pending
        return units.where((unit) => unit.status == UnitStatus.pending).toList();
      case 2: // Approved
        return units.where((unit) => unit.status == UnitStatus.approved).toList();
      case 3: // Rejected
        return units.where((unit) => unit.status == UnitStatus.rejected).toList();
      case 0: // All
      default:
        return units;
    }
  }

  Widget _buildUnitCard(BuildContext context, WidgetRef ref, UnitModel unit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UnitDetailScreen(unitId: unit.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    unit.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(unit.status),
                ],
              ),
              const SizedBox(height: 8),
              Text('Code: ${unit.code}'),
              const SizedBox(height: 8),
              Text('Created: ${DateFormat.yMMMd().format(unit.createdAt.toDate())}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildAttendanceToggle(context, ref, unit),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UnitDetailScreen(unitId: unit.id),
                        ),
                      );
                    },
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(UnitStatus status) {
    Color chipColor;
    String statusText;

    switch (status) {
      case UnitStatus.approved:
        chipColor = Colors.green;
        statusText = 'Approved';
        break;
      case UnitStatus.rejected:
        chipColor = Colors.red;
        statusText = 'Rejected';
        break;
      case UnitStatus.pending:
      default:
        chipColor = Colors.orange;
        statusText = 'Pending';
    }

    return Chip(
      label: Text(statusText),
      backgroundColor: chipColor.withOpacity(0.2),
      labelStyle: TextStyle(color: chipColor),
    );
  }

  Widget _buildAttendanceToggle(BuildContext context, WidgetRef ref, UnitModel unit) {
    // Only show toggle for approved units
    if (unit.status != UnitStatus.approved) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        const Text('Attendance:'),
        Switch(
          value: unit.isAttendanceActive,
          onChanged: (value) {
            _toggleAttendance(context, ref, unit.id, value);
          },
        ),
        Text(unit.isAttendanceActive ? 'Active' : 'Inactive'),
      ],
    );
  }

  void _toggleAttendance(BuildContext context, WidgetRef ref, String unitId, bool isActive) {
    ref.read(unitManagerProvider.notifier).toggleAttendanceStatus(unitId, isActive);
  }
}