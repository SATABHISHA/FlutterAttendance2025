import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/blocs.dart';
import '../models/task_model.dart';
import '../utils/utils.dart';

class TaskDetailsSheet extends StatefulWidget {
  final TaskModel task;

  const TaskDetailsSheet({super.key, required this.task});

  @override
  State<TaskDetailsSheet> createState() => _TaskDetailsSheetState();
}

class _TaskDetailsSheetState extends State<TaskDetailsSheet> {
  final _reportController = TextEditingController();
  final _remarksController = TextEditingController();
  final _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reportController.text = widget.task.report ?? '';
    _remarksController.text = widget.task.completionRemarks ?? '';
    _feedbackController.text = widget.task.reviewFeedback ?? '';
  }

  @override
  void dispose() {
    _reportController.dispose();
    _remarksController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Color get _priorityColor {
    switch (widget.task.priority) {
      case TaskPriority.low:
        return Colors.grey;
      case TaskPriority.medium:
        return AppTheme.infoColor;
      case TaskPriority.high:
        return AppTheme.warningColor;
      case TaskPriority.urgent:
        return AppTheme.errorColor;
    }
  }

  Color get _statusColor {
    switch (widget.task.status) {
      case TaskStatus.pending:
        return AppTheme.warningColor;
      case TaskStatus.inProgress:
        return AppTheme.infoColor;
      case TaskStatus.completed:
        return AppTheme.successColor;
      case TaskStatus.cancelled:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    final isAssignedToMe = user?.id == widget.task.assignedTo;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title and Priority
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.task.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      Helpers.capitalize(widget.task.priority.name),
                      style: TextStyle(
                        color: _priorityColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(), size: 16, color: _statusColor),
                    const SizedBox(width: 4),
                    Text(
                      Helpers.capitalizeWords(widget.task.status.name),
                      style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.task.description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Details
              _buildDetailRow(
                Icons.person_outline,
                'Assigned by',
                widget.task.assignedByName,
              ),
              _buildDetailRow(
                Icons.person,
                'Assigned to',
                widget.task.assignedToName,
              ),
              _buildDetailRow(
                Icons.calendar_today,
                'Created',
                Helpers.formatDateTime(widget.task.createdAt),
              ),
              if (widget.task.dueDate != null)
                _buildDetailRow(
                  Icons.schedule,
                  'Due Date',
                  Helpers.formatDate(widget.task.dueDate!),
                  isOverdue: widget.task.isOverdue,
                ),
              if (widget.task.completedAt != null)
                _buildDetailRow(
                  Icons.check_circle,
                  'Completed',
                  Helpers.formatDateTime(widget.task.completedAt!),
                ),

              // Report Section
              if (isAssignedToMe || widget.task.report != null) ...[
                const SizedBox(height: 20),
                Text(
                  'Report',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                if (isAssignedToMe && widget.task.status != TaskStatus.completed)
                  TextFormField(
                    controller: _reportController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write your report here...',
                      border: OutlineInputBorder(),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.task.report ?? 'No report submitted',
                      style: TextStyle(
                        color: widget.task.report != null
                            ? Colors.grey.shade700
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                if (widget.task.reportedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reported on ${Helpers.formatDateTime(widget.task.reportedAt!)}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],

              // Completion Remarks Section (for subordinate)
              if (isAssignedToMe && widget.task.status == TaskStatus.inProgress) ...[
                const SizedBox(height: 20),
                Text(
                  'Completion Remarks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _remarksController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Add remarks when completing the task...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

              // Show completion remarks if already completed
              if (widget.task.completionRemarks != null && widget.task.completionRemarks!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Completion Remarks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    widget.task.completionRemarks!,
                    style: TextStyle(color: Colors.green.shade800),
                  ),
                ),
              ],

              // Review Status Section
              if (widget.task.reviewStatus != null) ...[
                const SizedBox(height: 20),
                Text(
                  'Review Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getReviewStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getReviewStatusIcon(),
                        size: 16,
                        color: _getReviewStatusColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Helpers.capitalizeWords(widget.task.reviewStatus!.name),
                        style: TextStyle(
                          color: _getReviewStatusColor(),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.task.reviewFeedback != null && widget.task.reviewFeedback!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getReviewStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getReviewStatusColor().withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Supervisor Feedback:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.task.reviewFeedback!,
                          style: TextStyle(color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.task.reviewedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reviewed on ${Helpers.formatDateTime(widget.task.reviewedAt!)}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],

              // Supervisor Review Section (only for supervisor viewing completed tasks)
              if (!isAssignedToMe && 
                  widget.task.status == TaskStatus.completed && 
                  widget.task.reviewStatus == TaskReviewStatus.pending) ...[
                const SizedBox(height: 20),
                Text(
                  'Review Task',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _feedbackController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Add feedback (optional)...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<TaskBloc>().add(TaskReview(
                                taskId: widget.task.id,
                                reviewStatus: TaskReviewStatus.rejected,
                                feedback: _feedbackController.text.trim().isNotEmpty
                                    ? _feedbackController.text.trim()
                                    : null,
                              ));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task marked as incorrect'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<TaskBloc>().add(TaskReview(
                                taskId: widget.task.id,
                                reviewStatus: TaskReviewStatus.approved,
                                feedback: _feedbackController.text.trim().isNotEmpty
                                    ? _feedbackController.text.trim()
                                    : null,
                              ));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task approved!'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Action Buttons for subordinate
              if (isAssignedToMe && widget.task.status != TaskStatus.completed) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (widget.task.status == TaskStatus.pending)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<TaskBloc>().add(TaskUpdateStatus(
                                  taskId: widget.task.id,
                                  status: TaskStatus.inProgress,
                                ));
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.infoColor,
                          ),
                          child: const Text('Start Task'),
                        ),
                      ),
                    if (widget.task.status == TaskStatus.inProgress) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (_reportController.text.isNotEmpty) {
                              context.read<TaskBloc>().add(TaskSubmitReport(
                                    taskId: widget.task.id,
                                    report: _reportController.text.trim(),
                                  ));
                            }
                            Navigator.pop(context);
                          },
                          child: const Text('Save Report'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Save report if exists
                            if (_reportController.text.isNotEmpty) {
                              context.read<TaskBloc>().add(TaskSubmitReport(
                                    taskId: widget.task.id,
                                    report: _reportController.text.trim(),
                                  ));
                            }
                            // Complete with remarks
                            context.read<TaskBloc>().add(TaskCompleteWithRemarks(
                                  taskId: widget.task.id,
                                  remarks: _remarksController.text.trim(),
                                ));
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Task completed! Awaiting supervisor review.'),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                          ),
                          child: const Text('Complete'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // Daily task badge
              if (widget.task.isDaily) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.today, size: 16, color: Colors.purple.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Daily Report',
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getReviewStatusColor() {
    switch (widget.task.reviewStatus) {
      case TaskReviewStatus.approved:
        return AppTheme.successColor;
      case TaskReviewStatus.rejected:
        return AppTheme.errorColor;
      case TaskReviewStatus.pending:
      default:
        return AppTheme.warningColor;
    }
  }

  IconData _getReviewStatusIcon() {
    switch (widget.task.reviewStatus) {
      case TaskReviewStatus.approved:
        return Icons.check_circle;
      case TaskReviewStatus.rejected:
        return Icons.cancel;
      case TaskReviewStatus.pending:
      default:
        return Icons.hourglass_empty;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.task.status) {
      case TaskStatus.pending:
        return Icons.pending_actions;
      case TaskStatus.inProgress:
        return Icons.autorenew;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isOverdue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isOverdue ? AppTheme.errorColor : Colors.grey.shade500,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: isOverdue ? AppTheme.errorColor : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
