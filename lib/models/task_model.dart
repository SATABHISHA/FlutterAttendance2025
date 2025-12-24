import 'package:equatable/equatable.dart';

enum TaskStatus { pending, inProgress, completed, cancelled }

enum TaskPriority { low, medium, high, urgent }

enum TaskReviewStatus { pending, approved, rejected }

class TaskModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String assignedTo;
  final String assignedToName;
  final String assignedBy;
  final String assignedByName;
  final String companyId;
  final String corpId;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String? report;
  final DateTime? reportedAt;
  final String? completionRemarks;       // Remarks by subordinate when completing
  final TaskReviewStatus? reviewStatus;   // Supervisor review status
  final String? reviewFeedback;           // Supervisor feedback/remarks
  final DateTime? reviewedAt;             // When supervisor reviewed
  final bool isDaily;                     // Is this a daily self-reported task

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.assignedToName,
    required this.assignedBy,
    required this.assignedByName,
    required this.companyId,
    required this.corpId,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.dueDate,
    this.completedAt,
    this.report,
    this.reportedAt,
    this.completionRemarks,
    this.reviewStatus,
    this.reviewFeedback,
    this.reviewedAt,
    this.isDaily = false,
  });

  factory TaskModel.fromRealtimeDB(String id, Map<String, dynamic> data) {
    return TaskModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      assignedToName: data['assignedToName'] ?? '',
      assignedBy: data['assignedBy'] ?? '',
      assignedByName: data['assignedByName'] ?? '',
      companyId: data['companyId'] ?? '',
      corpId: data['corpId'] ?? '',
      status: TaskStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TaskStatus.pending,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => TaskPriority.medium,
      ),
      createdAt: data['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt']) 
          : DateTime.now(),
      dueDate: data['dueDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['dueDate']) 
          : null,
      completedAt: data['completedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['completedAt']) 
          : null,
      report: data['report'],
      reportedAt: data['reportedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['reportedAt']) 
          : null,
      completionRemarks: data['completionRemarks'],
      reviewStatus: data['reviewStatus'] != null
          ? TaskReviewStatus.values.firstWhere(
              (e) => e.name == data['reviewStatus'],
              orElse: () => TaskReviewStatus.pending,
            )
          : null,
      reviewFeedback: data['reviewFeedback'],
      reviewedAt: data['reviewedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['reviewedAt'])
          : null,
      isDaily: data['isDaily'] ?? false,
    );
  }

  Map<String, dynamic> toRealtimeDB() {
    return {
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'assignedBy': assignedBy,
      'assignedByName': assignedByName,
      'companyId': companyId,
      'corpId': corpId,
      'status': status.name,
      'priority': priority.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'report': report,
      'reportedAt': reportedAt?.millisecondsSinceEpoch,
      'completionRemarks': completionRemarks,
      'reviewStatus': reviewStatus?.name,
      'reviewFeedback': reviewFeedback,
      'reviewedAt': reviewedAt?.millisecondsSinceEpoch,
      'isDaily': isDaily,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? assignedTo,
    String? assignedToName,
    String? assignedBy,
    String? assignedByName,
    String? companyId,
    String? corpId,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? completedAt,
    String? report,
    DateTime? reportedAt,
    String? completionRemarks,
    TaskReviewStatus? reviewStatus,
    String? reviewFeedback,
    DateTime? reviewedAt,
    bool? isDaily,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedByName: assignedByName ?? this.assignedByName,
      companyId: companyId ?? this.companyId,
      corpId: corpId ?? this.corpId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      report: report ?? this.report,
      reportedAt: reportedAt ?? this.reportedAt,
      completionRemarks: completionRemarks ?? this.completionRemarks,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      reviewFeedback: reviewFeedback ?? this.reviewFeedback,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      isDaily: isDaily ?? this.isDaily,
    );
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && status != TaskStatus.completed;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        assignedTo,
        assignedToName,
        assignedBy,
        assignedByName,
        companyId,
        corpId,
        status,
        priority,
        createdAt,
        dueDate,
        completedAt,
        report,
        reportedAt,
        completionRemarks,
        reviewStatus,
        reviewFeedback,
        reviewedAt,
        isDaily,
      ];
}
