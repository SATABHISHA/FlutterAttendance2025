import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../../blocs/blocs.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';

class TaskPerformanceScreen extends StatefulWidget {
  final String? userId; // If null, shows current user's performance
  final String? userName;
  final bool isSupervisorView; // If supervisor viewing subordinate

  const TaskPerformanceScreen({
    super.key,
    this.userId,
    this.userName,
    this.isSupervisorView = false,
  });

  @override
  State<TaskPerformanceScreen> createState() => _TaskPerformanceScreenState();
}

class _TaskPerformanceScreenState extends State<TaskPerformanceScreen>
    with SingleTickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();
  final ExportService _exportService = ExportService();

  late TabController _tabController;
  
  // Data for different views
  Map<String, int> _myStatistics = {};
  Map<String, int> _teamStatistics = {};
  List<TaskModel> _myTasks = [];
  List<TaskModel> _teamTasks = [];
  List<UserModel> _subordinates = [];
  Map<String, Map<String, int>> _individualStats = {};
  
  bool _isLoading = true;
  String _filterPeriod = 'month'; // 'week', 'month', 'quarter', 'year'
  String? _filterProject;
  List<String> _availableProjects = [];
  String? _selectedSubordinateId;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    final isSupervisor = user?.isSupervisor ?? false;
    _tabController = TabController(length: isSupervisor ? 3 : 1, vsync: this);
    _loadPerformanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _targetUserId {
    return widget.userId ?? context.read<AuthBloc>().state.user?.id ?? '';
  }

  String get _targetUserName {
    return widget.userName ?? context.read<AuthBloc>().state.user?.name ?? '';
  }

  Future<void> _loadPerformanceData() async {
    setState(() => _isLoading = true);
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    try {
      final dateRange = _getDateRange();
      
      // Load my statistics
      final myStats = await _taskService.getTaskStatistics(
        user.id,
        startDate: dateRange['start'],
        endDate: dateRange['end'],
      );

      // Load my tasks
      final myTasks = await _taskService.getTasksAssignedToUser(user.id);
      final filteredMyTasks = myTasks.where((t) {
        return t.createdAt.isAfter(dateRange['start']!) &&
            t.createdAt.isBefore(dateRange['end']!.add(const Duration(days: 1)));
      }).toList();

      // Get available projects
      final projects = filteredMyTasks
          .where((t) => t.projectName != null && t.projectName!.isNotEmpty)
          .map((t) => t.projectName!)
          .toSet()
          .toList();

      setState(() {
        _myStatistics = myStats;
        _myTasks = filteredMyTasks;
        _availableProjects = projects;
      });

      // If supervisor, load team data
      if (user.isSupervisor) {
        print('User is supervisor, loading team data...');
        await _loadTeamData(user.id, dateRange);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error in _loadPerformanceData: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _loadTeamData(String supervisorId, Map<String, DateTime?> dateRange) async {
    try {
      print('Loading team data for supervisor: $supervisorId');
      // Get subordinates
      final subordinates = await _authService.getSubordinates(supervisorId);
      print('Loaded ${subordinates.length} subordinates for team performance');
      
      List<TaskModel> allTeamTasks = [];
      Map<String, Map<String, int>> individualStats = {};
      int teamTotal = 0;
      int teamCompleted = 0;
      int teamApproved = 0;
      int teamRejected = 0;
      int teamPending = 0;
      int teamOverdue = 0;

      for (final sub in subordinates) {
        // Get tasks for each subordinate
        final tasks = await _taskService.getTasksAssignedToUser(sub.id);
        final filteredTasks = tasks.where((t) {
          return t.createdAt.isAfter(dateRange['start']!) &&
              t.createdAt.isBefore(dateRange['end']!.add(const Duration(days: 1)));
        }).toList();

        allTeamTasks.addAll(filteredTasks);

        // Calculate individual stats
        int completed = filteredTasks.where((t) => t.status == TaskStatus.completed).length;
        int approved = filteredTasks.where((t) => t.reviewStatus == TaskReviewStatus.approved).length;
        int rejected = filteredTasks.where((t) => t.reviewStatus == TaskReviewStatus.rejected).length;
        int pending = filteredTasks.where((t) => t.reviewStatus == TaskReviewStatus.pending).length;
        int overdue = filteredTasks.where((t) => t.isOverdue).length;

        individualStats[sub.id] = {
          'total': filteredTasks.length,
          'completed': completed,
          'approved': approved,
          'rejected': rejected,
          'pending': pending,
          'overdue': overdue,
        };

        teamTotal += filteredTasks.length;
        teamCompleted += completed;
        teamApproved += approved;
        teamRejected += rejected;
        teamPending += pending;
        teamOverdue += overdue;
      }

      setState(() {
        _subordinates = subordinates;
        _teamTasks = allTeamTasks;
        _individualStats = individualStats;
        _teamStatistics = {
          'total': teamTotal,
          'completed': teamCompleted,
          'approved': teamApproved,
          'rejected': teamRejected,
          'pending': teamPending,
          'overdue': teamOverdue,
        };
      });
    } catch (e) {
      print('Error loading team data: $e');
    }
  }

  Map<String, DateTime?> _getDateRange() {
    final now = DateTime.now();
    DateTime start;
    
    switch (_filterPeriod) {
      case 'week':
        start = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        start = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'quarter':
        start = DateTime(now.year, now.month - 3, now.day);
        break;
      case 'year':
        start = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        start = DateTime(now.year, now.month - 1, now.day);
    }

    return {'start': start, 'end': now};
  }

  List<TaskModel> get _filteredTasks {
    if (_filterProject == null) return _myTasks;
    return _myTasks.where((t) => t.projectName == _filterProject).toList();
  }

  Future<void> _exportPerformanceReport() async {
    try {
      final dateRange = _getDateRange();
      final filePath = await _exportService.exportPerformanceReport(
        userName: _targetUserName,
        statistics: _myStatistics,
        recentTasks: _filteredTasks,
        startDate: dateRange['start']!,
        endDate: dateRange['end']!,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.successColor),
                SizedBox(width: 8),
                Text('Export Successful'),
              ],
            ),
            content: const Text('Performance report exported successfully.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  OpenFilex.open(filePath);
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    final isSupervisor = user?.isSupervisor ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Performance'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportPerformanceReport,
            tooltip: 'Export Report',
          ),
        ],
        bottom: isSupervisor
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'My Performance', icon: Icon(Icons.person)),
                  Tab(text: 'Team Overview', icon: Icon(Icons.groups)),
                  Tab(text: 'Individual', icon: Icon(Icons.person_search)),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isSupervisor
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMyPerformanceTab(),
                    _buildTeamOverviewTab(),
                    _buildIndividualPerformanceTab(),
                  ],
                )
              : _buildMyPerformanceTab(),
    );
  }

  Widget _buildMyPerformanceTab() {
    return RefreshIndicator(
      onRefresh: _loadPerformanceData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period filter
            _buildPeriodFilter(),
            const SizedBox(height: 16),

            // Statistics cards
            _buildStatisticsSection(_myStatistics),
            const SizedBox(height: 20),

            // Performance metrics
            _buildPerformanceMetrics(_myStatistics),
            const SizedBox(height: 20),

            // Project filter
            if (_availableProjects.isNotEmpty) ...[
              _buildProjectFilter(),
              const SizedBox(height: 16),
            ],

            // Task history
            _buildTaskHistory(_myTasks),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadPerformanceData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period filter
            _buildPeriodFilter(),
            const SizedBox(height: 16),

            // Team Statistics
            Text(
              'Team Statistics (${_subordinates.length} members)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildStatisticsSection(_teamStatistics),
            const SizedBox(height: 20),

            // Team Performance metrics
            _buildPerformanceMetrics(_teamStatistics),
            const SizedBox(height: 20),

            // Team members performance list
            Text(
              'Team Members Performance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ..._subordinates.map((sub) => _buildTeamMemberCard(sub)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMemberCard(UserModel subordinate) {
    final stats = _individualStats[subordinate.id] ?? {};
    final total = stats['total'] ?? 0;
    final completed = stats['completed'] ?? 0;
    final approved = stats['approved'] ?? 0;
    final rejected = stats['rejected'] ?? 0;
    final completionRate = total > 0 ? (completed / total * 100) : 0;
    final approvalRate = completed > 0 ? (approved / completed * 100) : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    Helpers.getInitials(subordinate.name),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subordinate.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        subordinate.email,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () {
                    setState(() => _selectedSubordinateId = subordinate.id);
                    _tabController.animateTo(2);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMiniStat('Total', total.toString(), Colors.blue),
                _buildMiniStat('Done', completed.toString(), Colors.green),
                _buildMiniStat('Approved', approved.toString(), AppTheme.successColor),
                _buildMiniStat('Rejected', rejected.toString(), Colors.red),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Completion', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: completionRate / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                      ),
                      Text('${completionRate.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Approval', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: approvalRate / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(AppTheme.successColor),
                      ),
                      Text('${approvalRate.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildIndividualPerformanceTab() {
    return RefreshIndicator(
      onRefresh: _loadPerformanceData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subordinate selector
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  value: _selectedSubordinateId,
                  decoration: const InputDecoration(
                    labelText: 'Select Team Member',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Choose a team member'),
                  items: _subordinates.map((sub) => DropdownMenuItem(
                    value: sub.id,
                    child: Text(sub.name),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSubordinateId = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_selectedSubordinateId != null) ...[
              // Period filter
              _buildPeriodFilter(),
              const SizedBox(height: 16),

              // Individual Statistics
              _buildStatisticsSection(_individualStats[_selectedSubordinateId] ?? {}),
              const SizedBox(height: 20),

              // Performance metrics
              _buildPerformanceMetrics(_individualStats[_selectedSubordinateId] ?? {}),
              const SizedBox(height: 20),

              // Task history for selected user
              Text(
                'Recent Tasks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildTaskHistory(_teamTasks.where((t) => t.assignedTo == _selectedSubordinateId).toList()),
            ] else ...[
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 60),
                    Icon(Icons.person_search, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Select a team member to view their performance',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            const Text('Period:'),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPeriodChip('week', 'Week'),
                    _buildPeriodChip('month', 'Month'),
                    _buildPeriodChip('quarter', 'Quarter'),
                    _buildPeriodChip('year', 'Year'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _filterPeriod == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _filterPeriod = value);
            _loadPerformanceData();
          }
        },
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      ),
    );
  }

  Widget _buildStatisticsSection(Map<String, int> statistics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Task Statistics',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Tasks',
                statistics['total']?.toString() ?? '0',
                Icons.assignment,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Completed',
                statistics['completed']?.toString() ?? '0',
                Icons.check_circle,
                AppTheme.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Approved',
                statistics['approved']?.toString() ?? '0',
                Icons.thumb_up,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Rejected',
                statistics['rejected']?.toString() ?? '0',
                Icons.thumb_down,
                AppTheme.errorColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending Review',
                statistics['pending']?.toString() ?? '0',
                Icons.hourglass_empty,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Overdue',
                statistics['overdue']?.toString() ?? '0',
                Icons.warning,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics(Map<String, int> statistics) {
    final total = statistics['total'] ?? 0;
    final completed = statistics['completed'] ?? 0;
    final approved = statistics['approved'] ?? 0;
    final rejected = statistics['rejected'] ?? 0;

    final completionRate = total > 0 ? (completed / total * 100) : 0.0;
    final approvalRate = completed > 0 ? (approved / completed * 100) : 0.0;
    final rejectionRate = completed > 0 ? (rejected / completed * 100) : 0.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildMetricBar('Completion Rate', completionRate, AppTheme.primaryColor),
            const SizedBox(height: 12),
            _buildMetricBar('Approval Rate', approvalRate, AppTheme.successColor),
            const SizedBox(height: 12),
            _buildMetricBar('Rejection Rate', rejectionRate, AppTheme.errorColor),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBar(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectFilter() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.work, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            const Text('Project:'),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<String?>(
                value: _filterProject,
                hint: const Text('All Projects'),
                isExpanded: true,
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Projects'),
                  ),
                  ..._availableProjects.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p),
                  )),
                ],
                onChanged: (value) {
                  setState(() => _filterProject = value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHistory(List<TaskModel> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Task History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '${tasks.length} tasks',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.assignment_outlined, 
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No tasks found',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _buildTaskCard(task);
            },
          ),
      ],
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    Color statusColor;
    IconData statusIcon;

    switch (task.reviewStatus) {
      case TaskReviewStatus.approved:
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case TaskReviewStatus.rejected:
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel;
        break;
      case TaskReviewStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.projectName != null)
              Text(
                task.projectName!,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                ),
              ),
            Text(
              dateFormat.format(task.createdAt),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                task.reviewStatus?.name.toUpperCase() ?? task.status.name.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (task.reviewFeedback != null) ...[
              const SizedBox(height: 4),
              Icon(Icons.comment, size: 14, color: Colors.grey.shade400),
            ],
          ],
        ),
        onTap: () => _showTaskDetails(task),
      ),
    );
  }

  void _showTaskDetails(TaskModel task) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                task.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (task.projectName != null) ...[
                const SizedBox(height: 8),
                Chip(
                  avatar: const Icon(Icons.work, size: 16),
                  label: Text(task.projectName!),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                task.description,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _buildDetailRow('Status', task.status.name.toUpperCase()),
              _buildDetailRow('Priority', task.priority.name.toUpperCase()),
              _buildDetailRow('Created', dateFormat.format(task.createdAt)),
              if (task.dueDate != null)
                _buildDetailRow('Due Date', dateFormat.format(task.dueDate!)),
              if (task.completedAt != null)
                _buildDetailRow('Completed', dateFormat.format(task.completedAt!)),
              if (task.completionRemarks != null) ...[
                const SizedBox(height: 12),
                const Text('Completion Remarks:', 
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(task.completionRemarks!),
              ],
              if (task.reviewStatus != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _buildDetailRow('Review Status', 
                    task.reviewStatus!.name.toUpperCase()),
                if (task.reviewedAt != null)
                  _buildDetailRow('Reviewed', dateFormat.format(task.reviewedAt!)),
                if (task.reviewFeedback != null) ...[
                  const SizedBox(height: 12),
                  const Text('Review Feedback:', 
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: task.reviewStatus == TaskReviewStatus.approved
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(task.reviewFeedback!),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
