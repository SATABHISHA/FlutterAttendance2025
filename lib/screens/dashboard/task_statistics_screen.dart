import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/blocs.dart';
import '../../services/task_service.dart';
import '../../utils/utils.dart';

class TaskStatisticsScreen extends StatefulWidget {
  const TaskStatisticsScreen({super.key});

  @override
  State<TaskStatisticsScreen> createState() => _TaskStatisticsScreenState();
}

class _TaskStatisticsScreenState extends State<TaskStatisticsScreen> {
  Map<String, int> _statistics = {};
  bool _isLoading = true;
  String _selectedPeriod = 'This Month';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _setDateRange('This Month');
    _loadStatistics();
  }

  void _setDateRange(String period) {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case 'Today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = _startDate.add(const Duration(days: 1));
          break;
        case 'This Week':
          _startDate = now.subtract(Duration(days: now.weekday - 1));
          _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
          _endDate = _startDate.add(const Duration(days: 7));
          break;
        case 'This Month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case 'Last Month':
          _startDate = DateTime(now.year, now.month - 1, 1);
          _endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
          break;
        case 'All Time':
          _startDate = DateTime(2020, 1, 1);
          _endDate = now.add(const Duration(days: 1));
          break;
      }
    });
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    try {
      final taskService = TaskService();
      final stats = await taskService.getTaskStatistics(
        user.id,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Statistics'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Period',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'Today',
                              'This Week',
                              'This Month',
                              'Last Month',
                              'All Time',
                            ].map((period) {
                              final isSelected = _selectedPeriod == period;
                              return ChoiceChip(
                                label: Text(period),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    _setDateRange(period);
                                    _loadStatistics();
                                  }
                                },
                                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${Helpers.formatDate(_startDate)} - ${Helpers.formatDate(_endDate.subtract(const Duration(days: 1)))}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Tasks',
                          _statistics['total'] ?? 0,
                          Icons.assignment,
                          AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Completed',
                          _statistics['completed'] ?? 0,
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
                          _statistics['approved'] ?? 0,
                          Icons.thumb_up,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Rejected',
                          _statistics['rejected'] ?? 0,
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
                          _statistics['pending'] ?? 0,
                          Icons.hourglass_empty,
                          AppTheme.warningColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Daily Reports',
                          _statistics['dailyReported'] ?? 0,
                          Icons.today,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Performance overview
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Performance Overview',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _buildProgressRow(
                            'Completion Rate',
                            _statistics['total'] != null && _statistics['total']! > 0
                                ? (_statistics['completed'] ?? 0) / _statistics['total']!
                                : 0,
                            AppTheme.successColor,
                          ),
                          const SizedBox(height: 12),
                          _buildProgressRow(
                            'Approval Rate',
                            _statistics['completed'] != null && _statistics['completed']! > 0
                                ? (_statistics['approved'] ?? 0) / _statistics['completed']!
                                : 0,
                            Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _buildProgressRow(
                            'Self-Reported Tasks',
                            _statistics['total'] != null && _statistics['total']! > 0
                                ? (_statistics['dailyReported'] ?? 0) / _statistics['total']!
                                : 0,
                            Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tips card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tip',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Report your daily tasks regularly to keep your supervisor informed and improve your visibility!',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
