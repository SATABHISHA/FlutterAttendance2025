import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../blocs/blocs.dart';
import '../../models/models.dart';
import '../../utils/utils.dart';

class AssignTaskScreen extends StatefulWidget {
  const AssignTaskScreen({super.key});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedUserId;
  String? _selectedUserName;
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  List<Map<String, dynamic>> _subordinates = [];
  bool _isLoadingSubordinates = true;

  @override
  void initState() {
    super.initState();
    _loadSubordinates();
  }

  Future<void> _loadSubordinates() async {
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      print('Loading subordinates for supervisor: ${user.id} (${user.name})');
      try {
        final database = FirebaseDatabase.instance;
        
        // Fallback: Load all users and filter client-side (more reliable)
        final allUsersSnapshot = await database.ref('users').get();
        print('All users snapshot exists: ${allUsersSnapshot.exists}');
        
        if (allUsersSnapshot.exists) {
          final usersMap = allUsersSnapshot.value as Map<dynamic, dynamic>;
          print('Total users in database: ${usersMap.length}');
          final List<Map<String, dynamic>> filteredUsers = [];
          
          usersMap.forEach((key, value) {
            final userData = value as Map<dynamic, dynamic>;
            final supervisorId = userData['supervisorId'];
            print('User $key - supervisorId: $supervisorId, comparing with: ${user.id}');
            
            if (supervisorId != null && supervisorId.toString() == user.id) {
              filteredUsers.add({
                'id': key,
                'name': userData['name']?.toString() ?? 'Unknown',
              });
              print('Found subordinate: ${userData['name']}');
            }
          });
          
          setState(() {
            _subordinates = filteredUsers;
            _isLoadingSubordinates = false;
          });
          print('Loaded ${_subordinates.length} subordinates');
        } else {
          print('No users found in database');
          setState(() {
            _isLoadingSubordinates = false;
          });
        }
      } catch (e) {
        print('Error loading subordinates: $e');
        setState(() {
          _isLoadingSubordinates = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading team members: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } else {
      print('User is null, cannot load subordinates');
      setState(() {
        _isLoadingSubordinates = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _assignTask() {
    if (_formKey.currentState!.validate()) {
      if (_selectedUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a team member'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      final user = context.read<AuthBloc>().state.user!;

      context.read<TaskBloc>().add(TaskCreate(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            assignedTo: _selectedUserId!,
            assignedToName: _selectedUserName!,
            assignedBy: user.id,
            assignedByName: user.name,
            companyId: user.companyId,
            corpId: user.corpId,
            priority: _priority,
            dueDate: _dueDate,
          ));

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task assigned successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Task'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Task Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) =>
                    Helpers.validateRequired(value, 'Task title'),
              ),
              const SizedBox(height: 16),

              // Task Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                validator: (value) =>
                    Helpers.validateRequired(value, 'Description'),
              ),
              const SizedBox(height: 16),

              // Assign To Dropdown
              _isLoadingSubordinates
                  ? const InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Assign To',
                        prefixIcon: Icon(Icons.person),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Loading team members...'),
                        ],
                      ),
                    )
                  : _subordinates.isEmpty
                      ? const InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Assign To',
                            prefixIcon: Icon(Icons.person),
                          ),
                          child: Text(
                            'No team members found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          value: _selectedUserId,
                          decoration: const InputDecoration(
                            labelText: 'Assign To',
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: _subordinates.map((user) {
                            return DropdownMenuItem(
                              value: user['id'] as String,
                              child: Text(user['name'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedUserId = value;
                              _selectedUserName = _subordinates
                                  .firstWhere((u) => u['id'] == value)['name'] as String;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Please select a team member' : null,
                        ),
              const SizedBox(height: 16),

              // Priority Selection
              Text(
                'Priority',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TaskPriority.values.map((priority) {
                  final isSelected = _priority == priority;
                  Color color;
                  switch (priority) {
                    case TaskPriority.low:
                      color = Colors.grey;
                      break;
                    case TaskPriority.medium:
                      color = AppTheme.infoColor;
                      break;
                    case TaskPriority.high:
                      color = AppTheme.warningColor;
                      break;
                    case TaskPriority.urgent:
                      color = AppTheme.errorColor;
                      break;
                  }

                  return ChoiceChip(
                    label: Text(Helpers.capitalize(priority.name)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _priority = priority;
                        });
                      }
                    },
                    selectedColor: color.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? color : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Due Date
              InkWell(
                onTap: _selectDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date (Optional)',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dueDate != null
                            ? Helpers.formatDate(_dueDate!)
                            : 'Select date',
                        style: TextStyle(
                          color: _dueDate != null ? null : Colors.grey,
                        ),
                      ),
                      if (_dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _dueDate = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Assign Button
              BlocBuilder<TaskBloc, TaskState>(
                builder: (context, state) {
                  return SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: state.isCreating ? null : _assignTask,
                      child: state.isCreating
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Assign Task'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
