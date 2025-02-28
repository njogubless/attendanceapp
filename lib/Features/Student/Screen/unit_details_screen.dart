import 'package:attendanceapp/Features/Auth/Model/course_model.dart';
import 'package:attendanceapp/Features/Unit/Model/unit_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class UnitDetailsScreen extends ConsumerStatefulWidget {
  final UnitModel unit;
  final CourseModel course;

  const UnitDetailsScreen({
    Key? key,
    required this.unit,
    required this.course,
  }) : super(key: key);

  @override
  ConsumerState<UnitDetailsScreen> createState() => _UnitDetailsScreenState();
}

class _UnitDetailsScreenState extends ConsumerState<UnitDetailsScreen> {
  bool _isSubmittingAttendance = false;

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.unit.name),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: currentUserAsync.when(
        data: (UserModel? user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unit Info Card
                Card(
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
                            const Icon(Icons.book, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              widget.unit.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow('Course', widget.course.name),
                        _buildInfoRow('Course Code', widget.course.code),
                        _buildInfoRow('Unit Code', widget.unit.code),
                        _buildInfoRow('Venue', widget.unit.venue),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Schedule Section
                const Text(
                  'Schedule',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: widget.unit.schedule.map((session) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                '${session.day}, ${DateFormat('hh:mm a').format(session.startTime)} - ${DateFormat('hh:mm a').format(session.endTime)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Attendance Section
                const Text(
                  'Attendance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Check if user is a student
                if (user.role == UserRole.student)
                  _buildStudentAttendanceSection(user)
                else if (user.role == UserRole.lecturer)
                  _buildLecturerAttendanceSection()
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Attendance tracking not available for your role.'),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentAttendanceSection(UserModel user) {
    final attendanceAsync = ref.watch(studentAttendanceProvider(
      unitId: widget.unit.id,
      studentId: user.id,
    ));

    return attendanceAsync.when(
      data: (attendanceRecords) {
        if (attendanceRecords.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No attendance records found for this unit.'),
            ),
          );
        }

        // Calculate attendance percentage
        final totalSessions = attendanceRecords.length;
        final attendedSessions = attendanceRecords.where((record) => record.present).length;
        final attendancePercentage = (attendedSessions / totalSessions) * 100;

        return Column(
          children: [
            // Attendance summary card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Attendance Rate:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${attendancePercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: attendancePercentage >= 70 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: attendancePercentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        attendancePercentage >= 70 ? Colors.green : Colors.red,
                      ),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildAttendanceStat(
                          'Present',
                          attendedSessions,
                          Colors.green,
                        ),
                        _buildAttendanceStat(
                          'Absent',
                          totalSessions - attendedSessions,
                          Colors.red,
                        ),
                        _buildAttendanceStat(
                          'Total',
                          totalSessions,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Check-in button for current session
            _buildCheckInButton(user.id),
            
            const SizedBox(height: 16),
            
            // Attendance history
            const Text(
              'Attendance History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: attendanceRecords.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final record = attendanceRecords[index];
                  return ListTile(
                    leading: Icon(
                      record.present ? Icons.check_circle : Icons.cancel,
                      color: record.present ? Colors.green : Colors.red,
                    ),
                    title: Text(DateFormat('EEEE, dd MMMM yyyy').format(record.date)),
                    subtitle: Text(DateFormat('hh:mm a').format(record.timeRecorded)),
                    trailing: Text(
                      record.present ? 'Present' : 'Absent',
                      style: TextStyle(
                        color: record.present ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error loading attendance: $error')),
    );
  }

  Widget _buildAttendanceStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckInButton(String studentId) {
    final currentSessionAsync = ref.watch(currentSessionProvider(widget.unit.id));
    
    return currentSessionAsync.when(
      data: (currentSession) {
        if (currentSession == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No active session available for check-in at the moment.'),
            ),
          );
        }
        
        // Check if already marked attendance for current session
        final alreadyMarkedAsync = ref.watch(hasMarkedAttendanceProvider(
          sessionId: currentSession.id,
          studentId: studentId,
        ));
        
        return alreadyMarkedAsync.when(
          data: (alreadyMarked) {
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Current Session: ${DateFormat('EEEE, dd MMMM').format(currentSession.date)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${DateFormat('hh:mm a').format(currentSession.startTime)} - ${DateFormat('hh:mm a').format(currentSession.endTime)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (alreadyMarked)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Attendance Marked',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _isSubmittingAttendance
                          ? null
                          : () => _markAttendance(studentId, currentSession.id),
                        icon: _isSubmittingAttendance
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.qr_code_scanner),
                        label: Text(_isSubmittingAttendance
                          ? 'Marking Attendance...'
                          : 'Mark Attendance'),
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
                  ],
                ),
              ),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error checking attendance status: $error'),
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error checking current session: $error'),
        ),
      ),
    );
  }

  Widget _buildLecturerAttendanceSection() {
    final sessionsAsync = ref.watch(unitSessionsProvider(widget.unit.id));
    
    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('No sessions available for this unit.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _createNewSession(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Column(
          children: [
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _createNewSession(),
                    icon: const Icon(Icons.add),
                    label: const Text('New Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewAttendanceReport(),
                    icon: const Icon(Icons.assessment),
                    label: const Text('View Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sessions list
            const Text(
              'Sessions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sessions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final isActive = session.active;
                  
                  return ListTile(
                    title: Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(session.date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${DateFormat('hh:mm a').format(session.startTime)} - ${DateFormat('hh:mm a').format(session.endTime)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActive)
                          const Chip(
                            label: Text('Active'),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.play_arrow, color: Colors.green),
                            onPressed: () => _startSession(session.id),
                            tooltip: 'Start Session',
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.people, color: Colors.blue),
                          onPressed: () => _viewSessionAttendance(session.id),
                          tooltip: 'View Attendance',
                        ),
                      ],
                    ),
                    onTap: () => _viewSessionDetails(session),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error loading sessions: $error')),
    );
  }

  void _markAttendance(String studentId, String sessionId) async {
    setState(() {
      _isSubmittingAttendance = true;
    });
    
    try {
      await ref.read(attendanceProvider.notifier).markAttendance(
        sessionId: sessionId,
        studentId: studentId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance marked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingAttendance = false;
        });
      }
    }
  }

  void _createNewSession() {
    // Navigate to create session screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateSessionScreen(unit: widget.unit),
      ),
    );
  }

  void _viewAttendanceReport() {
    // Navigate to attendance report screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceReportScreen(unit: widget.unit),
      ),
    );
  }

  void _startSession(String sessionId) async {
    try {
      await ref.read(sessionProvider.notifier).startSession(sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session started successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewSessionAttendance(String sessionId) {
    // Navigate to session attendance screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionAttendanceScreen(
          sessionId: sessionId,
          unitName: widget.unit.name,
        ),
      ),
    );
  }

  void _viewSessionDetails(SessionModel session) {
    // Show session details dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Date', DateFormat('EEEE, dd MMMM yyyy').format(session.date)),
            _buildInfoRow('Time', '${DateFormat('hh:mm a').format(session.startTime)} - ${DateFormat('hh:mm a').format(session.endTime)}'),
            _buildInfoRow('Venue', widget.unit.venue),
            _buildInfoRow('Status', session.active ? 'Active' : 'Inactive'),
            _buildInfoRow('Created By', session.createdBy),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!session.active)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startSession(session.id);
              },
              child: const Text('Start Session'),
            ),
        ],
      ),
    );
  }
}

// These are the classes that I added to complete the code
// But you would need to create these screens in your app

class CreateSessionScreen extends StatelessWidget {
  final UnitModel unit;
  
  const CreateSessionScreen({Key? key, required this.unit}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Implementation for creating a new session
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Session')),
      body: const Center(child: Text('Create Session Implementation')),
    );
  }
}

class AttendanceReportScreen extends StatelessWidget {
  final UnitModel unit;
  
  const AttendanceReportScreen({Key? key, required this.unit}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Implementation for viewing attendance reports
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Report')),
      body: const Center(child: Text('Attendance Report Implementation')),
    );
  }
}

class SessionAttendanceScreen extends StatelessWidget {
  final String sessionId;
  final String unitName;
  
  const SessionAttendanceScreen({
    Key? key, 
    required this.sessionId,
    required this.unitName,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Implementation for viewing session attendance
    return Scaffold(
      appBar: AppBar(title: Text('$unitName Attendance')),
      body: Center(child: Text('Session $sessionId Attendance')),
    );
  }
}

// This model class would be needed for the lecturer view
class SessionModel {
  final String id;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final bool active;
  final String createdBy;
  
  SessionModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.active,
    required this.createdBy,
  });
}