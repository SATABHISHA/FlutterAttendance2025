import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/blocs.dart';
import '../../models/models.dart';
import '../../utils/utils.dart';

class TeamAttendanceScreen extends StatefulWidget {
  const TeamAttendanceScreen({super.key});

  @override
  State<TeamAttendanceScreen> createState() => _TeamAttendanceScreenState();
}

class _TeamAttendanceScreenState extends State<TeamAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTeamAttendance();
  }

  void _loadTeamAttendance() {
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      context.read<AttendanceBloc>().add(AttendanceLoadSubordinates(
            supervisorId: user.id,
            date: _selectedDate,
          ));
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadTeamAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Attendance'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(
                        const Duration(days: 1),
                      );
                    });
                    _loadTeamAttendance();
                  },
                ),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      Helpers.isToday(_selectedDate)
                          ? 'Today'
                          : Helpers.formatDate(_selectedDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: Helpers.isToday(_selectedDate)
                      ? null
                      : () {
                          setState(() {
                            _selectedDate = _selectedDate.add(
                              const Duration(days: 1),
                            );
                          });
                          _loadTeamAttendance();
                        },
                ),
              ],
            ),
          ),

          // Attendance List
          Expanded(
            child: BlocBuilder<AttendanceBloc, AttendanceState>(
              builder: (context, state) {
                if (state.status == AttendanceStateStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.subordinatesAttendance.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No team members found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final presentCount = state.subordinatesAttendance
                    .where((a) => a.hasCheckedIn)
                    .length;
                final totalCount = state.subordinatesAttendance.length;

                return Column(
                  children: [
                    // Summary
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppTheme.secondaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem(
                            'Present',
                            presentCount.toString(),
                            Icons.check_circle,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white30,
                          ),
                          _buildSummaryItem(
                            'Absent',
                            (totalCount - presentCount).toString(),
                            Icons.cancel,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white30,
                          ),
                          _buildSummaryItem(
                            'Total',
                            totalCount.toString(),
                            Icons.people,
                          ),
                        ],
                      ),
                    ),

                    // List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.subordinatesAttendance.length,
                        itemBuilder: (context, index) {
                          final attendance = state.subordinatesAttendance[index];
                          return _buildAttendanceItem(attendance);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceItem(AttendanceModel attendance) {
    final isPresent = attendance.hasCheckedIn;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPresent
              ? AppTheme.successColor.withOpacity(0.1)
              : AppTheme.errorColor.withOpacity(0.1),
          child: Icon(
            isPresent ? Icons.check : Icons.close,
            color: isPresent ? AppTheme.successColor : AppTheme.errorColor,
          ),
        ),
        title: Text(
          attendance.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: isPresent
            ? Row(
                children: [
                  Text(
                    'In: ${Helpers.formatTime(attendance.checkInTime!)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  if (attendance.checkOutTime != null) ...[
                    const SizedBox(width: 16),
                    Text(
                      'Out: ${Helpers.formatTime(attendance.checkOutTime!)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              )
            : Text(
                'Not checked in',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: isPresent
                ? AppTheme.successColor.withOpacity(0.1)
                : AppTheme.errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isPresent ? 'Present' : 'Absent',
            style: TextStyle(
              color: isPresent ? AppTheme.successColor : AppTheme.errorColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
