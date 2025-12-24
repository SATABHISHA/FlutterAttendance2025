import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../blocs/blocs.dart';
import '../../models/models.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';

class SubordinateTasksScreen extends StatefulWidget {
  const SubordinateTasksScreen({super.key});

  @override
  State<SubordinateTasksScreen> createState() => _SubordinateTasksScreenState();
}

class _SubordinateTasksScreenState extends State<SubordinateTasksScreen> {
  List<Map<String, dynamic>> _subordinates = [];
  String? _selectedSubordinateId;
  String? _selectedSubordinateName;
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingSubordinates = true;
  bool _filterByDate = true;

  @override
  void initState() {
    super.initState();
    _loadSubordinates();
  }

  Future<void> _loadSubordinates() async {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    try {
      final database = FirebaseDatabase.instance;
      final allUsersSnapshot = await database.ref('users').get();

      if (allUsersSnapshot.exists) {
        final usersMap = allUsersSnapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> filteredUsers = [];

        usersMap.forEach((key, value) {
          final userData = value as Map<dynamic, dynamic>;
          final supervisorId = userData['supervisorId'];

          if (supervisorId != null && supervisorId.toString() == user.id) {
            filteredUsers.add({
              'id': key,
              'name': userData['name']?.toString() ?? 'Unknown',
            });
          }
        });

        setState(() {
          _subordinates = filteredUsers;
          _isLoadingSubordinates = false;
          if (_subordinates.isNotEmpty) {
            _selectedSubordinateId = _subordinates.first['id'];
            _selectedSubordinateName = _subordinates.first['name'];
            _loadSubordinateTasks();
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

  void _loadSubordinateTasks() {
    final user = context.read<AuthBloc>().state.user;
    if (user == null || _selectedSubordinateId == null) return;

    context.read<TaskBloc>().add(TaskLoadSubordinateTasks(
          supervisorId: user.id,
          subordinateId: _selectedSubordinateId!,
          date: _filterByDate ? _selectedDate : null,
        ));
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
      _loadSubordinateTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subordinate Tasks'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        actions: [
          if (_filterByDate)
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _selectDate,
            ),
        ],
      ),
      body: Column(
        children: [
          // Subordinate selector
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
                Text(
                  'Select Team Member',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                _isLoadingSubordinates
                    ? const Center(child: CircularProgressIndicator())
                    : _subordinates.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text('No subordinates found'),
                                ),
                              ],
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            value: _selectedSubordinateId,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _subordinates.map((sub) {
                              return DropdownMenuItem(
                                value: sub['id'] as String,
                                child: Text(sub['name'] as String),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSubordinateId = value;
                                _selectedSubordinateName = _subordinates
                                    .firstWhere((s) => s['id'] == value)['name'];
                              });
                              _loadSubordinateTasks();
                            },
                          ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Filter by Date'),
                        value: _filterByDate,
                        onChanged: (value) {
                          setState(() {
                            _filterByDate = value;
                          });
                          _loadSubordinateTasks();
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    if (_filterByDate)
                      TextButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.event, size: 18),
                        label: Text(Helpers.formatDate(_selectedDate)),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Tasks list
          Expanded(
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state.status == TaskStateStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_selectedSubordinateId == null) {
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
                          'Select a team member to view their tasks',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state.subordinateTasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks found for $_selectedSubordinateName',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        if (_filterByDate)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'on ${Helpers.formatDate(_selectedDate)}',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                // Group tasks by status
                final pendingReviewTasks = state.subordinateTasks
                    .where((t) =>
                        t.status == TaskStatus.completed &&
                        t.reviewStatus == TaskReviewStatus.pending)
                    .toList();
                final otherTasks = state.subordinateTasks
                    .where((t) =>
                        t.status != TaskStatus.completed ||
                        t.reviewStatus != TaskReviewStatus.pending)
                    .toList();

                return RefreshIndicator(
                  onRefresh: () async => _loadSubordinateTasks(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Pending review section
                      if (pendingReviewTasks.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.pending_actions, 
                                  color: AppTheme.warningColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Pending Review (${pendingReviewTasks.length})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.warningColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...pendingReviewTasks.map((task) => TaskListItem(
                              task: task,
                              onTap: () => _showTaskDetails(task),
                            )),
                        const SizedBox(height: 16),
                      ],

                      // Other tasks section
                      if (otherTasks.isNotEmpty) ...[
                        if (pendingReviewTasks.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Other Tasks',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ...otherTasks.map((task) => TaskListItem(
                              task: task,
                              onTap: () => _showTaskDetails(task),
                            )),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TaskDetailsSheet(task: task),
    ).then((_) {
      // Reload tasks after closing the sheet (in case review was submitted)
      _loadSubordinateTasks();
    });
  }
}
