import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/blocs.dart';
import '../../models/models.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    _tabController = TabController(
      length: user?.isSupervisor == true ? 2 : 1,
      vsync: this,
    );
    _loadTasks();
  }

  void _loadTasks() {
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      context.read<TaskBloc>().add(TaskLoadAssignedTo(oderId: user.id));
      if (user.isSupervisor) {
        context.read<TaskBloc>().add(TaskLoadAssignedBy(oderId: user.id));
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        bottom: user?.isSupervisor == true
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.task_alt, size: 18),
                            SizedBox(width: 8),
                            Text('My Tasks'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.assignment_ind, size: 18),
                            SizedBox(width: 8),
                            Text('Assigned by Me'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: user?.isSupervisor == true
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildMyTasks(),
                _buildAssignedTasks(),
              ],
            )
          : _buildMyTasks(),
      floatingActionButton: user?.isSupervisor == true
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/assign-task');
              },
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.add),
              label: const Text('Assign Task'),
            )
          : null,
    );
  }

  Widget _buildMyTasks() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state.status == TaskStateStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.assignedToMe.isEmpty) {
          return _buildEmptyState(
            icon: Icons.task_alt,
            title: 'No Tasks Assigned',
            subtitle: 'You don\'t have any tasks assigned to you yet',
          );
        }

        // Group tasks by status
        final pendingTasks = state.assignedToMe.where((t) => t.status == TaskStatus.pending).toList();
        final inProgressTasks = state.assignedToMe.where((t) => t.status == TaskStatus.inProgress).toList();
        final completedTasks = state.assignedToMe.where((t) => t.status == TaskStatus.completed).toList();

        return RefreshIndicator(
          onRefresh: () async => _loadTasks(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Row
                _buildTaskStats(state.assignedToMe),
                const SizedBox(height: 20),
                
                // Pending Tasks
                if (pendingTasks.isNotEmpty) ...[
                  _buildSectionHeader(
                    title: 'Pending Tasks',
                    count: pendingTasks.length,
                    color: AppTheme.warningColor,
                    icon: Icons.pending_actions,
                  ),
                  ...pendingTasks.map((task) => TaskListItem(
                    task: task,
                    onTap: () => _showTaskDetails(task),
                  )),
                  const SizedBox(height: 16),
                ],
                
                // In Progress Tasks
                if (inProgressTasks.isNotEmpty) ...[
                  _buildSectionHeader(
                    title: 'In Progress',
                    count: inProgressTasks.length,
                    color: AppTheme.infoColor,
                    icon: Icons.autorenew,
                  ),
                  ...inProgressTasks.map((task) => TaskListItem(
                    task: task,
                    onTap: () => _showTaskDetails(task),
                  )),
                  const SizedBox(height: 16),
                ],
                
                // Completed Tasks
                if (completedTasks.isNotEmpty) ...[
                  _buildSectionHeader(
                    title: 'Completed',
                    count: completedTasks.length,
                    color: AppTheme.successColor,
                    icon: Icons.check_circle,
                  ),
                  ...completedTasks.map((task) => TaskListItem(
                    task: task,
                    onTap: () => _showTaskDetails(task),
                  )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignedTasks() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state.status == TaskStateStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.assignedByMe.isEmpty) {
          return _buildEmptyState(
            icon: Icons.assignment_ind,
            title: 'No Tasks Assigned Yet',
            subtitle: 'You haven\'t assigned any tasks to your team',
            showButton: true,
            buttonLabel: 'Assign a Task',
            onButtonPressed: () => Navigator.pushNamed(context, '/assign-task'),
          );
        }

        // Group by assignee for better visibility
        final Map<String, List<TaskModel>> groupedByAssignee = {};
        for (final task in state.assignedByMe) {
          if (!groupedByAssignee.containsKey(task.assignedToName)) {
            groupedByAssignee[task.assignedToName] = [];
          }
          groupedByAssignee[task.assignedToName]!.add(task);
        }

        return RefreshIndicator(
          onRefresh: () async => _loadTasks(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Row
                _buildTaskStats(state.assignedByMe, showAssignedStats: true),
                const SizedBox(height: 20),
                
                // Tasks grouped by assignee
                ...groupedByAssignee.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAssigneeHeader(
                      name: entry.key,
                      taskCount: entry.value.length,
                      pendingCount: entry.value.where((t) => t.status != TaskStatus.completed).length,
                    ),
                    ...entry.value.map((task) => TaskListItem(
                      task: task,
                      showAssignee: true,
                      onTap: () => _showTaskDetails(task),
                    )),
                    const SizedBox(height: 16),
                  ],
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskStats(List<TaskModel> tasks, {bool showAssignedStats = false}) {
    final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
    final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
    final overdue = tasks.where((t) => t.isOverdue).length;

    return Container(
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
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                showAssignedStats ? Icons.assignment_ind : Icons.task_alt,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                showAssignedStats ? 'Tasks Assigned Overview' : 'My Tasks Overview',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                value: pending.toString(),
                label: 'Pending',
                color: Colors.orange.shade200,
              ),
              _buildStatItem(
                value: inProgress.toString(),
                label: 'In Progress',
                color: Colors.blue.shade200,
              ),
              _buildStatItem(
                value: completed.toString(),
                label: 'Completed',
                color: Colors.green.shade200,
              ),
              if (overdue > 0)
                _buildStatItem(
                  value: overdue.toString(),
                  label: 'Overdue',
                  color: Colors.red.shade200,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.9),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssigneeHeader({
    required String name,
    required int taskCount,
    required int pendingCount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            radius: 20,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$taskCount tasks • $pendingCount pending',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showButton = false,
    String? buttonLabel,
    VoidCallback? onButtonPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                icon,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
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
              textAlign: TextAlign.center,
            ),
            if (showButton && buttonLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.add),
                label: Text(buttonLabel),
              ),
            ],
          ],
        ),
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
    );
  }
}
