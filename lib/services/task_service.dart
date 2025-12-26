import 'package:firebase_database/firebase_database.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<TaskModel> createTask({
    required String title,
    required String description,
    required String assignedTo,
    required String assignedToName,
    required String assignedBy,
    required String assignedByName,
    required String companyId,
    required String corpId,
    required TaskPriority priority,
    DateTime? dueDate,
    String? projectId,
    String? projectName,
    bool isSupervisorTask = false,
  }) async {
    try {
      final newTaskRef = _database.ref('tasks').push();
      final taskId = newTaskRef.key!;

      final task = TaskModel(
        id: taskId,
        title: title,
        description: description,
        assignedTo: assignedTo,
        assignedToName: assignedToName,
        assignedBy: assignedBy,
        assignedByName: assignedByName,
        companyId: companyId,
        corpId: corpId,
        status: TaskStatus.pending,
        priority: priority,
        createdAt: DateTime.now(),
        dueDate: dueDate,
        projectId: projectId,
        projectName: projectName,
        isSupervisorTask: isSupervisorTask,
      );

      await newTaskRef.set(task.toRealtimeDB());

      // Also store reference in user's tasks for efficient querying
      await _database.ref('user_tasks/$assignedTo/$taskId').set(true);
      await _database.ref('assigned_tasks/$assignedBy/$taskId').set(true);
      
      // Index by project if project is specified
      if (projectId != null && projectId.isNotEmpty) {
        await _database.ref('project_tasks/$projectId/$taskId').set(true);
      }
      
      // Index supervisor tasks for admin review
      if (isSupervisorTask) {
        await _database.ref('supervisor_tasks/$companyId/$taskId').set(true);
      }

      return task;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
      };

      if (status == TaskStatus.completed) {
        updates['completedAt'] = DateTime.now().millisecondsSinceEpoch;
      }

      await _database.ref('tasks/$taskId').update(updates);
    } catch (e) {
      throw Exception('Failed to update task status: $e');
    }
  }

  Future<void> submitReport(String taskId, String report) async {
    try {
      await _database.ref('tasks/$taskId').update({
        'report': report,
        'reportedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  Future<List<TaskModel>> getTasksAssignedToUser(String userId) async {
    try {
      // Get task IDs from user_tasks index
      final taskIdsSnapshot = await _database.ref('user_tasks/$userId').get();
      
      if (!taskIdsSnapshot.exists) {
        return [];
      }

      final taskIds = (taskIdsSnapshot.value as Map).keys.toList();
      final tasks = <TaskModel>[];

      for (final taskId in taskIds) {
        final taskSnapshot = await _database.ref('tasks/$taskId').get();
        if (taskSnapshot.exists) {
          tasks.add(TaskModel.fromRealtimeDB(
            taskId.toString(),
            Map<String, dynamic>.from(taskSnapshot.value as Map),
          ));
        }
      }

      // Sort by createdAt descending
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return tasks;
    } catch (e) {
      throw Exception('Failed to get tasks: $e');
    }
  }

  Future<List<TaskModel>> getTasksAssignedByUser(String userId) async {
    try {
      // Get task IDs from assigned_tasks index
      final taskIdsSnapshot = await _database.ref('assigned_tasks/$userId').get();
      
      if (!taskIdsSnapshot.exists) {
        return [];
      }

      final taskIds = (taskIdsSnapshot.value as Map).keys.toList();
      final tasks = <TaskModel>[];

      for (final taskId in taskIds) {
        final taskSnapshot = await _database.ref('tasks/$taskId').get();
        if (taskSnapshot.exists) {
          tasks.add(TaskModel.fromRealtimeDB(
            taskId.toString(),
            Map<String, dynamic>.from(taskSnapshot.value as Map),
          ));
        }
      }

      // Sort by createdAt descending
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return tasks;
    } catch (e) {
      throw Exception('Failed to get assigned tasks: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      // First get the task to know assignedTo and assignedBy
      final taskSnapshot = await _database.ref('tasks/$taskId').get();
      
      if (taskSnapshot.exists) {
        final taskData = taskSnapshot.value as Map<dynamic, dynamic>;
        final assignedTo = taskData['assignedTo'] as String?;
        final assignedBy = taskData['assignedBy'] as String?;

        // Delete from all locations
        await _database.ref('tasks/$taskId').remove();
        
        if (assignedTo != null) {
          await _database.ref('user_tasks/$assignedTo/$taskId').remove();
        }
        if (assignedBy != null) {
          await _database.ref('assigned_tasks/$assignedBy/$taskId').remove();
        }
      }
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // Complete task with remarks from subordinate
  Future<void> completeTaskWithRemarks(String taskId, String remarks) async {
    try {
      await _database.ref('tasks/$taskId').update({
        'status': TaskStatus.completed.name,
        'completedAt': DateTime.now().millisecondsSinceEpoch,
        'completionRemarks': remarks,
        'reviewStatus': TaskReviewStatus.pending.name,
      });
    } catch (e) {
      throw Exception('Failed to complete task: $e');
    }
  }

  // Supervisor reviews task
  Future<void> reviewTask(String taskId, TaskReviewStatus reviewStatus, String? feedback) async {
    try {
      await _database.ref('tasks/$taskId').update({
        'reviewStatus': reviewStatus.name,
        'reviewFeedback': feedback,
        'reviewedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to review task: $e');
    }
  }

  // Create daily self-reported task
  Future<TaskModel> createDailyTask({
    required String title,
    required String description,
    required String userId,
    required String userName,
    required String supervisorId,
    required String supervisorName,
    required String companyId,
    required String corpId,
  }) async {
    try {
      final newTaskRef = _database.ref('tasks').push();
      final taskId = newTaskRef.key!;

      final task = TaskModel(
        id: taskId,
        title: title,
        description: description,
        assignedTo: userId,
        assignedToName: userName,
        assignedBy: userId,  // Self-assigned
        assignedByName: userName,
        companyId: companyId,
        corpId: corpId,
        status: TaskStatus.completed,  // Already completed since it's a report
        priority: TaskPriority.medium,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        isDaily: true,
        reviewStatus: TaskReviewStatus.pending,
      );

      await newTaskRef.set(task.toRealtimeDB());

      // Store in user_tasks and supervisor view
      await _database.ref('user_tasks/$userId/$taskId').set(true);
      await _database.ref('daily_tasks/$supervisorId/$userId/${_getDateKey(DateTime.now())}/$taskId').set(true);

      return task;
    } catch (e) {
      throw Exception('Failed to create daily task: $e');
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get tasks by date for a user
  Future<List<TaskModel>> getTasksByDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final taskIdsSnapshot = await _database.ref('user_tasks/$userId').get();
      
      if (!taskIdsSnapshot.exists) {
        return [];
      }

      final taskIds = (taskIdsSnapshot.value as Map).keys.toList();
      final tasks = <TaskModel>[];

      for (final taskId in taskIds) {
        final taskSnapshot = await _database.ref('tasks/$taskId').get();
        if (taskSnapshot.exists) {
          final task = TaskModel.fromRealtimeDB(
            taskId.toString(),
            Map<String, dynamic>.from(taskSnapshot.value as Map),
          );
          
          // Filter by date - check createdAt or completedAt
          if ((task.createdAt.isAfter(startOfDay) && task.createdAt.isBefore(endOfDay)) ||
              (task.completedAt != null && task.completedAt!.isAfter(startOfDay) && task.completedAt!.isBefore(endOfDay))) {
            tasks.add(task);
          }
        }
      }

      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    } catch (e) {
      throw Exception('Failed to get tasks by date: $e');
    }
  }

  // Get subordinate tasks for supervisor (filtered by subordinate)
  Future<List<TaskModel>> getSubordinateTasks(String supervisorId, String subordinateId, {DateTime? date}) async {
    try {
      final taskIdsSnapshot = await _database.ref('user_tasks/$subordinateId').get();
      
      if (!taskIdsSnapshot.exists) {
        return [];
      }

      final taskIds = (taskIdsSnapshot.value as Map).keys.toList();
      final tasks = <TaskModel>[];

      for (final taskId in taskIds) {
        final taskSnapshot = await _database.ref('tasks/$taskId').get();
        if (taskSnapshot.exists) {
          final task = TaskModel.fromRealtimeDB(
            taskId.toString(),
            Map<String, dynamic>.from(taskSnapshot.value as Map),
          );
          
          if (date != null) {
            final startOfDay = DateTime(date.year, date.month, date.day);
            final endOfDay = startOfDay.add(const Duration(days: 1));
            
            if ((task.createdAt.isAfter(startOfDay) && task.createdAt.isBefore(endOfDay)) ||
                (task.completedAt != null && task.completedAt!.isAfter(startOfDay) && task.completedAt!.isBefore(endOfDay))) {
              tasks.add(task);
            }
          } else {
            tasks.add(task);
          }
        }
      }

      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    } catch (e) {
      throw Exception('Failed to get subordinate tasks: $e');
    }
  }

  // Get task statistics for user
  Future<Map<String, int>> getTaskStatistics(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final taskIdsSnapshot = await _database.ref('user_tasks/$userId').get();
      
      if (!taskIdsSnapshot.exists) {
        return {
          'total': 0,
          'completed': 0,
          'approved': 0,
          'rejected': 0,
          'pending': 0,
          'dailyReported': 0,
        };
      }

      final taskIds = (taskIdsSnapshot.value as Map).keys.toList();
      int total = 0;
      int completed = 0;
      int approved = 0;
      int rejected = 0;
      int pending = 0;
      int dailyReported = 0;

      for (final taskId in taskIds) {
        final taskSnapshot = await _database.ref('tasks/$taskId').get();
        if (taskSnapshot.exists) {
          final task = TaskModel.fromRealtimeDB(
            taskId.toString(),
            Map<String, dynamic>.from(taskSnapshot.value as Map),
          );
          
          // Filter by date range if provided
          if (startDate != null && endDate != null) {
            if (task.createdAt.isBefore(startDate) || task.createdAt.isAfter(endDate)) {
              continue;
            }
          }
          
          total++;
          
          if (task.status == TaskStatus.completed) completed++;
          if (task.reviewStatus == TaskReviewStatus.approved) approved++;
          if (task.reviewStatus == TaskReviewStatus.rejected) rejected++;
          if (task.reviewStatus == TaskReviewStatus.pending) pending++;
          if (task.isDaily) dailyReported++;
        }
      }

      return {
        'total': total,
        'completed': completed,
        'approved': approved,
        'rejected': rejected,
        'pending': pending,
        'dailyReported': dailyReported,
      };
    } catch (e) {
      throw Exception('Failed to get task statistics: $e');
    }
  }

  Stream<List<TaskModel>> streamTasksAssignedToUser(String userId) {
    return _database.ref('user_tasks/$userId').onValue.asyncMap((event) async {
      if (!event.snapshot.exists) {
        return <TaskModel>[];
      }

      final taskIds = (event.snapshot.value as Map).keys.toList();
      final tasks = <TaskModel>[];

      for (final taskId in taskIds) {
        final taskSnapshot = await _database.ref('tasks/$taskId').get();
        if (taskSnapshot.exists) {
          tasks.add(TaskModel.fromRealtimeDB(
            taskId.toString(),
            Map<String, dynamic>.from(taskSnapshot.value as Map),
          ));
        }
      }

      // Sort by createdAt descending
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return tasks;
    });
  }

  Stream<List<TaskModel>> streamTasksAssignedByUser(String userId) {
    return _database.ref('assigned_tasks/$userId').onValue.asyncMap((event) async {
      if (!event.snapshot.exists) {
        return <TaskModel>[];
      }

      final taskIds = (event.snapshot.value as Map).keys.toList();
      final tasks = <TaskModel>[];

      for (final taskId in taskIds) {
        final taskSnapshot = await _database.ref('tasks/$taskId').get();
        if (taskSnapshot.exists) {
          tasks.add(TaskModel.fromRealtimeDB(
            taskId.toString(),
            Map<String, dynamic>.from(taskSnapshot.value as Map),
          ));
        }
      }

      // Sort by createdAt descending
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return tasks;
    });
  }

  // Get tasks by project
  Future<List<TaskModel>> getTasksByProject(String projectId) async {
    try {
      final taskIdsSnapshot = await _database.ref('project_tasks/$projectId').get();
      
      if (!taskIdsSnapshot.exists) {
        return [];
      }

      final taskIds = (taskIdsSnapshot.value as Map).keys.toList();
      final tasks = <TaskModel>[];

      for (final taskId in taskIds) {
        final taskSnapshot = await _database.ref('tasks/$taskId').get();
        if (taskSnapshot.exists) {
          tasks.add(TaskModel.fromRealtimeDB(
            taskId.toString(),
            Map<String, dynamic>.from(taskSnapshot.value as Map),
          ));
        }
      }

      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    } catch (e) {
      throw Exception('Failed to get tasks by project: $e');
    }
  }

  // Get supervisor tasks for admin review
  Future<List<TaskModel>> getSupervisorTasksForAdmin(String companyId) async {
    try {
      final taskIdsSnapshot = await _database.ref('supervisor_tasks/$companyId').get();
      
      if (!taskIdsSnapshot.exists) {
        return [];
      }

      final taskIds = (taskIdsSnapshot.value as Map).keys.toList();
      final tasks = <TaskModel>[];

      for (final taskId in taskIds) {
        final taskSnapshot = await _database.ref('tasks/$taskId').get();
        if (taskSnapshot.exists) {
          tasks.add(TaskModel.fromRealtimeDB(
            taskId.toString(),
            Map<String, dynamic>.from(taskSnapshot.value as Map),
          ));
        }
      }

      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    } catch (e) {
      throw Exception('Failed to get supervisor tasks: $e');
    }
  }

  // Admin reviews supervisor task
  Future<void> adminReviewTask(String taskId, String status, String? feedback) async {
    try {
      await _database.ref('tasks/$taskId').update({
        'adminReviewStatus': status,
        'adminFeedback': feedback,
        'adminReviewedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to review supervisor task: $e');
    }
  }

  // Get tasks filtered by project and/or user
  Future<List<TaskModel>> getFilteredTasks({
    String? projectId,
    String? userId,
    String? assignedBy,
    TaskStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<TaskModel> tasks = [];
      
      // Start with either project tasks or user tasks
      if (projectId != null) {
        tasks = await getTasksByProject(projectId);
      } else if (userId != null) {
        tasks = await getTasksAssignedToUser(userId);
      } else if (assignedBy != null) {
        tasks = await getTasksAssignedByUser(assignedBy);
      }

      // Apply filters
      if (userId != null && projectId != null) {
        tasks = tasks.where((t) => t.assignedTo == userId).toList();
      }
      
      if (assignedBy != null && projectId != null) {
        tasks = tasks.where((t) => t.assignedBy == assignedBy).toList();
      }

      if (status != null) {
        tasks = tasks.where((t) => t.status == status).toList();
      }

      if (startDate != null) {
        tasks = tasks.where((t) => t.createdAt.isAfter(startDate)).toList();
      }

      if (endDate != null) {
        tasks = tasks.where((t) => t.createdAt.isBefore(endDate.add(const Duration(days: 1)))).toList();
      }

      return tasks;
    } catch (e) {
      throw Exception('Failed to get filtered tasks: $e');
    }
  }

  // Create daily task with project association
  Future<TaskModel> createDailyTaskWithProject({
    required String title,
    required String description,
    required String userId,
    required String userName,
    required String supervisorId,
    required String supervisorName,
    required String companyId,
    required String corpId,
    String? projectId,
    String? projectName,
  }) async {
    try {
      final newTaskRef = _database.ref('tasks').push();
      final taskId = newTaskRef.key!;

      final task = TaskModel(
        id: taskId,
        title: title,
        description: description,
        assignedTo: userId,
        assignedToName: userName,
        assignedBy: userId,  // Self-assigned
        assignedByName: userName,
        companyId: companyId,
        corpId: corpId,
        status: TaskStatus.completed,  // Already completed since it's a report
        priority: TaskPriority.medium,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        isDaily: true,
        reviewStatus: TaskReviewStatus.pending,
        projectId: projectId,
        projectName: projectName,
      );

      await newTaskRef.set(task.toRealtimeDB());

      // Store in user_tasks and supervisor view
      await _database.ref('user_tasks/$userId/$taskId').set(true);
      await _database.ref('daily_tasks/$supervisorId/$userId/${_getDateKey(DateTime.now())}/$taskId').set(true);
      
      // Index by project if specified
      if (projectId != null && projectId.isNotEmpty) {
        await _database.ref('project_tasks/$projectId/$taskId').set(true);
      }

      return task;
    } catch (e) {
      throw Exception('Failed to create daily task: $e');
    }
  }

  // Get pending tasks for review (by reviewer)
  Future<List<TaskModel>> getPendingReviewTasks(String reviewerId) async {
    try {
      final tasks = await getTasksAssignedByUser(reviewerId);
      return tasks.where((t) => 
        t.status == TaskStatus.completed && 
        t.reviewStatus == TaskReviewStatus.pending
      ).toList();
    } catch (e) {
      throw Exception('Failed to get pending review tasks: $e');
    }
  }

  // Get all unique projects from tasks
  Future<List<Map<String, String>>> getProjectsFromTasks(String userId) async {
    try {
      final tasks = await getTasksAssignedToUser(userId);
      final projects = <String, String>{};
      
      for (final task in tasks) {
        if (task.projectId != null && task.projectName != null) {
          projects[task.projectId!] = task.projectName!;
        }
      }
      
      return projects.entries
          .map((e) => {'id': e.key, 'name': e.value})
          .toList();
    } catch (e) {
      throw Exception('Failed to get projects from tasks: $e');
    }
  }
}

