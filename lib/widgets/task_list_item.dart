import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../utils/utils.dart';

class TaskListItem extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final bool showAssignee;

  const TaskListItem({
    super.key,
    required this.task,
    this.onTap,
    this.showAssignee = false,
  });

  Color get _priorityColor {
    switch (task.priority) {
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
    switch (task.status) {
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

  Color get _reviewStatusColor {
    switch (task.reviewStatus) {
      case TaskReviewStatus.approved:
        return Colors.green;
      case TaskReviewStatus.rejected:
        return AppTheme.errorColor;
      case TaskReviewStatus.pending:
      default:
        return AppTheme.warningColor;
    }
  }

  IconData get _statusIcon {
    switch (task.status) {
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _statusIcon,
                      color: _statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          showAssignee
                              ? 'Assigned to: ${task.assignedToName}'
                              : 'From: ${task.assignedByName}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      Helpers.capitalize(task.priority.name),
                      style: TextStyle(
                        color: _priorityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (task.dueDate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: task.isOverdue
                              ? AppTheme.errorColor
                              : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${Helpers.formatDate(task.dueDate!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: task.isOverdue
                                ? AppTheme.errorColor
                                : Colors.grey.shade500,
                            fontWeight: task.isOverdue
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    )
                  else
                    const SizedBox(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      Helpers.capitalizeWords(task.status.name.replaceAll(
                        RegExp(r'([A-Z])'),
                        ' \$1',
                      )),
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              // Show review status if task is completed and has review status
              if (task.status == TaskStatus.completed && task.reviewStatus != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _reviewStatusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            task.reviewStatus == TaskReviewStatus.approved
                                ? Icons.thumb_up
                                : task.reviewStatus == TaskReviewStatus.rejected
                                    ? Icons.thumb_down
                                    : Icons.hourglass_empty,
                            size: 10,
                            color: _reviewStatusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.reviewStatus == TaskReviewStatus.approved
                                ? 'Approved'
                                : task.reviewStatus == TaskReviewStatus.rejected
                                    ? 'Rejected'
                                    : 'Pending Review',
                            style: TextStyle(
                              color: _reviewStatusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (task.isDaily) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.today,
                              size: 10,
                              color: Colors.purple.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Daily',
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
