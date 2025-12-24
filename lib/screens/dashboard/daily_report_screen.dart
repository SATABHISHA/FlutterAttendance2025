import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../blocs/blocs.dart';
import '../../models/models.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _supervisorId;
  String? _supervisorName;
  bool _isLoadingSupervisor = true;

  @override
  void initState() {
    super.initState();
    _loadSupervisorInfo();
    _loadTasksForDate();
  }

  Future<void> _loadSupervisorInfo() async {
    final user = context.read<AuthBloc>().state.user;
    if (user != null && user.supervisorId != null) {
      try {
        final database = FirebaseDatabase.instance;
        final snapshot = await database.ref('users/${user.supervisorId}').get();
        
        if (snapshot.exists) {
          final supervisorData = snapshot.value as Map<dynamic, dynamic>;
          setState(() {
            _supervisorId = user.supervisorId;
            _supervisorName = supervisorData['name']?.toString() ?? 'Unknown';
            _isLoadingSupervisor = false;
          });
        } else {
          setState(() {
            _isLoadingSupervisor = false;
          });
        }
      } catch (e) {
        print('Error loading supervisor: $e');
        setState(() {
          _isLoadingSupervisor = false;
        });
      }
    } else {
      setState(() {
        _isLoadingSupervisor = false;
      });
    }
  }

  void _loadTasksForDate() {
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      context.read<TaskBloc>().add(TaskLoadByDate(
            userId: user.id,
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
      _loadTasksForDate();
    }
  }

  void _showAddDailyTaskDialog() {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    if (_supervisorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No supervisor assigned. Please contact admin.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Daily Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Report a task you completed today (${Helpers.formatDate(DateTime.now())})',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  hintText: 'What did you work on?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what you did...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              return ElevatedButton(
                onPressed: state.isCreating
                    ? null
                    : () {
                        if (titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a task title'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                          return;
                        }

                        context.read<TaskBloc>().add(TaskReportDaily(
                              title: titleController.text.trim(),
                              description: descriptionController.text.trim(),
                              userId: user.id,
                              userName: user.name,
                              supervisorId: _supervisorId!,
                              supervisorName: _supervisorName!,
                              companyId: user.companyId,
                              corpId: user.corpId,
                            ));

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Daily task reported successfully!'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                        _loadTasksForDate();
                      },
                child: state.isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reports'),
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
          // Date selector card
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
            child: Row(
              children: [
                Icon(Icons.event, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Helpers.formatDate(_selectedDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _isToday(_selectedDate) ? 'Today' : _getDayName(_selectedDate),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.arrow_drop_down),
                  label: const Text('Change'),
                ),
              ],
            ),
          ),

          // Supervisor info
          if (!_isLoadingSupervisor && _supervisorName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.supervisor_account, color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Reporting to: $_supervisorName',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 13,
                    ),
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

                if (state.tasksByDate.isEmpty) {
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
                          'No tasks for this date',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isToday(_selectedDate))
                          Text(
                            'Tap + to report what you worked on today',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadTasksForDate(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.tasksByDate.length,
                    itemBuilder: (context, index) {
                      final task = state.tasksByDate[index];
                      return TaskListItem(
                        task: task,
                        onTap: () => _showTaskDetails(task),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isToday(_selectedDate)
          ? FloatingActionButton.extended(
              onPressed: _showAddDailyTaskDialog,
              icon: const Icon(Icons.add),
              label: const Text('Report Task'),
            )
          : null,
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _getDayName(DateTime date) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  void _showTaskDetails(TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TaskDetailsSheet(task: task),
    );
  }
}
