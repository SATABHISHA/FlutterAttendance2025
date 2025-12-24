import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../blocs/blocs.dart';
import '../../models/models.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';

class TeamReportsScreen extends StatefulWidget {
  const TeamReportsScreen({super.key});

  @override
  State<TeamReportsScreen> createState() => _TeamReportsScreenState();
}

class _TeamReportsScreenState extends State<TeamReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _subordinates = [];
  bool _isLoading = true;
  Map<String, List<TaskModel>> _tasksBySubordinate = {};

  @override
  void initState() {
    super.initState();
    _loadSubordinatesAndReports();
  }

  Future<void> _loadSubordinatesAndReports() async {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final database = FirebaseDatabase.instance;
      
      // Get all subordinates
      final usersSnapshot = await database.ref('users').get();
      
      if (usersSnapshot.exists) {
        final usersMap = usersSnapshot.value as Map<dynamic, dynamic>;
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

        _subordinates = filteredUsers;

        // Load tasks for each subordinate for the selected date
        await _loadTasksForDate();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading subordinates: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTasksForDate() async {
    final database = FirebaseDatabase.instance;
    final Map<String, List<TaskModel>> tasksBySubordinate = {};

    for (final sub in _subordinates) {
      final subordinateId = sub['id'] as String;
      
      try {
        // Get all tasks for this subordinate (both assigned and self-reported)
        final snapshot = await database
            .ref('tasks')
            .orderByChild('assignedTo')
            .equalTo(subordinateId)
            .get();

        final List<TaskModel> tasks = [];
        
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          data.forEach((key, value) {
            final task = TaskModel.fromRealtimeDB(
              key.toString(),
              Map<String, dynamic>.from(value as Map),
            );
            
            // Filter by date - check if task was created/updated/completed on selected date
            final taskDate = task.completedAt ?? task.createdAt;
            if (_isSameDay(taskDate, _selectedDate)) {
              tasks.add(task);
            }
          });
        }

        tasksBySubordinate[subordinateId] = tasks;
      } catch (e) {
        print('Error loading tasks for $subordinateId: $e');
        tasksBySubordinate[subordinateId] = [];
      }
    }

    setState(() {
      _tasksBySubordinate = tasksBySubordinate;
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
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
      await _loadTasksForDate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Reports'),
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
          // Date selector header
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
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chevron_left, color: AppTheme.primaryColor, size: 20),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                    });
                    _loadTasksForDate();
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            Helpers.isToday(_selectedDate)
                                ? 'Today - ${Helpers.formatDate(_selectedDate)}'
                                : Helpers.formatDate(_selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Helpers.isToday(_selectedDate)
                          ? Colors.grey.shade200
                          : AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: Helpers.isToday(_selectedDate)
                          ? Colors.grey
                          : AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  onPressed: Helpers.isToday(_selectedDate)
                      ? null
                      : () {
                          setState(() {
                            _selectedDate = _selectedDate.add(const Duration(days: 1));
                          });
                          _loadTasksForDate();
                        },
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _subordinates.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.group_off,
                        title: 'No Team Members',
                        subtitle: 'You don\'t have any subordinates assigned',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSubordinatesAndReports,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _subordinates.length,
                          itemBuilder: (context, index) {
                            final sub = _subordinates[index];
                            final subId = sub['id'] as String;
                            final subName = sub['name'] as String;
                            final tasks = _tasksBySubordinate[subId] ?? [];
                            
                            return _buildSubordinateReportCard(subName, tasks);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubordinateReportCard(String name, List<TaskModel> tasks) {
    final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).toList();
    final pendingReviewTasks = completedTasks.where((t) => t.reviewStatus == TaskReviewStatus.pending).toList();
    final dailyTasks = tasks.where((t) => t.isDaily).toList();
    final assignedTasks = tasks.where((t) => !t.isDaily).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: tasks.isEmpty
              ? Colors.grey.shade300
              : AppTheme.primaryColor.withOpacity(0.1),
          radius: 24,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              color: tasks.isEmpty ? Colors.grey : AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildMiniStat(
                  icon: Icons.task_alt,
                  count: tasks.length,
                  label: 'Total',
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                _buildMiniStat(
                  icon: Icons.today,
                  count: dailyTasks.length,
                  label: 'Self',
                  color: Colors.purple,
                ),
                const SizedBox(width: 12),
                if (pendingReviewTasks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pending_actions, size: 12, color: AppTheme.warningColor),
                        const SizedBox(width: 4),
                        Text(
                          '${pendingReviewTasks.length} Review',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.warningColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: tasks.isEmpty
                ? Colors.grey.shade100
                : AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            tasks.isEmpty ? 'No Reports' : '${tasks.length} Tasks',
            style: TextStyle(
              color: tasks.isEmpty ? Colors.grey : AppTheme.successColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        children: [
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No tasks reported for this day',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else ...[
            // Daily (Self-Reported) Tasks
            if (dailyTasks.isNotEmpty) ...[
              _buildTaskCategoryHeader(
                title: 'Self-Reported Tasks',
                count: dailyTasks.length,
                color: Colors.purple,
                icon: Icons.today,
              ),
              ...dailyTasks.map((task) => _buildTaskItem(task)),
            ],
            // Assigned Tasks
            if (assignedTasks.isNotEmpty) ...[
              _buildTaskCategoryHeader(
                title: 'Assigned Tasks',
                count: assignedTasks.length,
                color: AppTheme.primaryColor,
                icon: Icons.assignment_ind,
              ),
              ...assignedTasks.map((task) => _buildTaskItem(task)),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCategoryHeader({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskModel task) {
    Color statusColor;
    IconData statusIcon;

    switch (task.status) {
      case TaskStatus.completed:
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case TaskStatus.inProgress:
        statusColor = AppTheme.infoColor;
        statusIcon = Icons.autorenew;
        break;
      case TaskStatus.pending:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.pending_actions;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
    }

    return InkWell(
      onTap: () => _showTaskDetails(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(statusIcon, color: statusColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Review status badge
            if (task.status == TaskStatus.completed)
              _buildReviewBadge(task.reviewStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewBadge(TaskReviewStatus? status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case TaskReviewStatus.approved:
        color = AppTheme.successColor;
        text = 'Approved';
        icon = Icons.thumb_up;
        break;
      case TaskReviewStatus.rejected:
        color = AppTheme.errorColor;
        text = 'Rejected';
        icon = Icons.thumb_down;
        break;
      default:
        color = AppTheme.warningColor;
        text = 'Review';
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
            child: Icon(icon, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
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
      // Reload after review
      _loadTasksForDate();
    });
  }
}
