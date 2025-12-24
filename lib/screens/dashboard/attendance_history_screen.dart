import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../blocs/blocs.dart';
import '../../models/models.dart';
import '../../utils/utils.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  DateTime _selectedMonth = DateTime.now();
  
  // For supervisor - subordinates
  List<Map<String, dynamic>> _subordinates = [];
  String? _selectedSubordinateId;
  bool _isLoadingSubordinates = true;
  List<AttendanceModel> _subordinateHistory = [];
  bool _isLoadingSubordinateHistory = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    
    // Setup tabs for supervisors
    if (user?.isSupervisor == true) {
      _tabController = TabController(length: 2, vsync: this);
      _loadSubordinates();
    }
    
    _loadMyAttendance();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _loadMyAttendance() {
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      context.read<AttendanceBloc>().add(AttendanceLoadHistory(oderId: user.id));
    }
  }

  Future<void> _loadSubordinates() async {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    try {
      final database = FirebaseDatabase.instance;
      final snapshot = await database.ref('users').get();

      if (snapshot.exists) {
        final usersMap = snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> filteredUsers = [];

        usersMap.forEach((key, value) {
          final userData = value as Map<dynamic, dynamic>;
          final supervisorId = userData['supervisorId'];

          if (supervisorId != null && supervisorId.toString() == user.id) {
            filteredUsers.add({
              'id': key.toString(),
              'name': userData['name']?.toString() ?? 'Unknown',
            });
          }
        });

        setState(() {
          _subordinates = filteredUsers;
          _isLoadingSubordinates = false;
          if (_subordinates.isNotEmpty) {
            _selectedSubordinateId = _subordinates.first['id'];
            _loadSubordinateAttendance();
          }
        });
      } else {
        setState(() {
          _isLoadingSubordinates = false;
        });
      }
    } catch (e) {
      print('Error loading subordinates: $e');
      setState(() {
        _isLoadingSubordinates = false;
      });
    }
  }

  Future<void> _loadSubordinateAttendance() async {
    if (_selectedSubordinateId == null) return;

    setState(() {
      _isLoadingSubordinateHistory = true;
    });

    try {
      final database = FirebaseDatabase.instance;
      final snapshot = await database
          .ref('attendance/$_selectedSubordinateId')
          .get();

      if (snapshot.exists) {
        final List<AttendanceModel> history = [];
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data.forEach((key, value) {
          history.add(AttendanceModel.fromRealtimeDB(
            key,
            Map<String, dynamic>.from(value),
          ));
        });
        history.sort((a, b) => b.date.compareTo(a.date));
        
        setState(() {
          _subordinateHistory = history;
          _isLoadingSubordinateHistory = false;
        });
      } else {
        setState(() {
          _subordinateHistory = [];
          _isLoadingSubordinateHistory = false;
        });
      }
    } catch (e) {
      print('Error loading subordinate attendance: $e');
      setState(() {
        _isLoadingSubordinateHistory = false;
      });
    }
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
      });
    }
  }

  Map<String, List<AttendanceModel>> _groupByDate(List<AttendanceModel> history) {
    final Map<String, List<AttendanceModel>> grouped = {};
    
    for (final attendance in history) {
      final dateKey = Helpers.formatDate(attendance.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(attendance);
    }
    
    return grouped;
  }

  List<AttendanceModel> _filterByMonth(List<AttendanceModel> history) {
    return history.where((a) {
      return a.date.year == _selectedMonth.year && 
             a.date.month == _selectedMonth.month;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    final isSupervisor = user?.isSupervisor == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        bottom: isSupervisor && _tabController != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person, size: 18),
                            SizedBox(width: 6),
                            Text('My Attendance'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group, size: 18),
                            SizedBox(width: 6),
                            Text('Team Attendance'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: isSupervisor && _tabController != null
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildMyAttendanceTab(),
                _buildTeamAttendanceTab(),
              ],
            )
          : _buildMyAttendanceTab(),
    );
  }

  Widget _buildMyAttendanceTab() {
    return Column(
      children: [
        // Month Selector
        _buildMonthSelector(),
        // Attendance List
        Expanded(
          child: BlocBuilder<AttendanceBloc, AttendanceState>(
            builder: (context, state) {
              if (state.status == AttendanceStateStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.status == AttendanceStateStatus.error) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading attendance',
                        style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _loadMyAttendance,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final filteredHistory = _filterByMonth(state.attendanceHistory);

              if (filteredHistory.isEmpty) {
                return _buildEmptyState('No attendance records for this month');
              }

              return _buildAttendanceList(filteredHistory);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeamAttendanceTab() {
    return Column(
      children: [
        // Subordinate Selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people_alt, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Select Team Member',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _isLoadingSubordinates
                  ? const Center(child: CircularProgressIndicator())
                  : _subordinates.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange.shade700),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('No team members found'),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedSubordinateId,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person_search),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: _subordinates.map((sub) {
                              return DropdownMenuItem(
                                value: sub['id'] as String,
                                child: Text(
                                  sub['name'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSubordinateId = value;
                              });
                              _loadSubordinateAttendance();
                            },
                          ),
                        ),
            ],
          ),
        ),
        // Month Selector
        _buildMonthSelector(),
        // Attendance List
        Expanded(
          child: _isLoadingSubordinateHistory
              ? const Center(child: CircularProgressIndicator())
              : _subordinates.isEmpty
                  ? _buildEmptyState('No team members to show')
                  : _buildAttendanceList(_filterByMonth(_subordinateHistory)),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.05),
            AppTheme.secondaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chevron_left, color: AppTheme.primaryColor),
            ),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
            },
          ),
          GestureDetector(
            onTap: _selectMonth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chevron_right, color: AppTheme.primaryColor),
            ),
            onPressed: () {
              final now = DateTime.now();
              if (_selectedMonth.year < now.year ||
                  (_selectedMonth.year == now.year && _selectedMonth.month < now.month)) {
                setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(List<AttendanceModel> history) {
    if (history.isEmpty) {
      return _buildEmptyState('No attendance records for this month');
    }

    // Group by date
    final grouped = _groupByDate(history);
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // Calculate statistics
    final totalDays = history.length;
    final completedDays = history.where((a) => a.hasCheckedOut).length;
    final totalHours = history
        .where((a) => a.workDuration != null)
        .fold<Duration>(Duration.zero, (sum, a) => sum + a.workDuration!);

    return Column(
      children: [
        // Stats Summary
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.9),
                AppTheme.secondaryColor.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.calendar_today,
                value: totalDays.toString(),
                label: 'Days Present',
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                icon: Icons.check_circle,
                value: completedDays.toString(),
                label: 'Full Days',
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                icon: Icons.timer,
                value: '${totalHours.inHours}h',
                label: 'Total Hours',
              ),
            ],
          ),
        ),
        // Attendance List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _loadMyAttendance(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final dateKey = sortedDates[index];
                final records = grouped[dateKey]!;
                return _buildDateGroup(dateKey, records);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDateGroup(String dateKey, List<AttendanceModel> records) {
    final attendance = records.first;
    final isCompleted = attendance.hasCheckedOut;
    final isToday = Helpers.isToday(attendance.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? AppTheme.primaryColor.withOpacity(0.5)
              : isCompleted
                  ? AppTheme.successColor.withOpacity(0.3)
                  : AppTheme.warningColor.withOpacity(0.3),
          width: isToday ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Date Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isToday
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : isCompleted
                      ? AppTheme.successColor.withOpacity(0.05)
                      : AppTheme.warningColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppTheme.primaryColor
                        : isCompleted
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        attendance.date.day.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getWeekday(attendance.date.weekday),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isToday ? 'Today' : Helpers.getRelativeDate(attendance.date),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isToday ? AppTheme.primaryColor : Colors.black87,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'TODAY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateKey,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.schedule,
                        size: 14,
                        color: isCompleted ? AppTheme.successColor : AppTheme.warningColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCompleted ? 'Completed' : 'In Progress',
                        style: TextStyle(
                          color: isCompleted ? AppTheme.successColor : AppTheme.warningColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Time Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTimeCard(
                    icon: Icons.login,
                    label: 'Check In',
                    time: attendance.checkInTime != null
                        ? Helpers.formatTime(attendance.checkInTime!)
                        : '-',
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeCard(
                    icon: Icons.logout,
                    label: 'Check Out',
                    time: attendance.checkOutTime != null
                        ? Helpers.formatTime(attendance.checkOutTime!)
                        : '-',
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeCard(
                    icon: Icons.timer,
                    label: 'Duration',
                    time: attendance.workDuration != null
                        ? Helpers.formatDuration(attendance.workDuration!)
                        : '-',
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ),
          // Location
          if (attendance.checkInAddress != null)
            Container(
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      attendance.checkInAddress!,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeCard({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekday(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }
}
