import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/blocs.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';
import 'location_picker_screen.dart';

class ProjectAllocationScreen extends StatefulWidget {
  final String? supervisorId;
  final String? supervisorName;

  const ProjectAllocationScreen({
    super.key,
    this.supervisorId,
    this.supervisorName,
  });

  @override
  State<ProjectAllocationScreen> createState() => _ProjectAllocationScreenState();
}

class _ProjectAllocationScreenState extends State<ProjectAllocationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  List<UserModel> _subordinates = [];
  bool _isLoadingSubordinates = false;

  // For admin mode - when allocating to a supervisor
  bool get _isAdminMode => widget.supervisorId != null;
  String get _targetUserId => widget.supervisorId ?? context.read<AuthBloc>().state.user?.id ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      context.read<ProjectBloc>().add(ProjectLoadAll(companyId: user.companyId));
      if (_isAdminMode) {
        // Admin is allocating to a supervisor - load that supervisor's subordinates
        _loadSubordinates(widget.supervisorId!);
      } else {
        // Supervisor is allocating to their own subordinates
        _loadSubordinates(user.id);
      }
    }
  }

  Future<void> _loadSubordinates(String supervisorId) async {
    setState(() => _isLoadingSubordinates = true);
    try {
      print('Loading subordinates for supervisor: $supervisorId');
      final subordinates = await _authService.getSubordinates(supervisorId);
      print('Loaded ${subordinates.length} subordinates');
      if (mounted) {
        setState(() {
          _subordinates = subordinates;
          _isLoadingSubordinates = false;
        });
      }
    } catch (e) {
      print('Error loading subordinates: $e');
      if (mounted) {
        setState(() => _isLoadingSubordinates = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subordinates: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Project Allocation'),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Projects', icon: Icon(Icons.work)),
                Tab(text: 'Assignments', icon: Icon(Icons.assignment_ind)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildProjectsTab(user),
              _buildAssignmentsTab(user),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCreateProjectDialog(user),
            backgroundColor: AppTheme.primaryColor,
            icon: const Icon(Icons.add),
            label: const Text('New Project'),
          ),
        );
      },
    );
  }

  Widget _buildProjectsTab(UserModel user) {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        if (state.status == ProjectStateStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No projects created yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showCreateProjectDialog(user),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Project'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadData();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.projects.length,
            itemBuilder: (context, index) {
              final project = state.projects[index];
              return _buildProjectCard(project, user);
            },
          ),
        );
      },
    );
  }

  Widget _buildProjectCard(ProjectModel project, UserModel user) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isActive = project.isActive;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive 
                ? AppTheme.successColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.work,
            color: isActive ? AppTheme.successColor : Colors.grey,
          ),
        ),
        title: Text(
          project.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.address, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.successColor : Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  project.durationText,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (project.description.isNotEmpty) ...[
                  Text(
                    project.description,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildInfoRow(Icons.calendar_today, 'Start Date', 
                    dateFormat.format(project.startDate)),
                _buildInfoRow(Icons.event, 'End Date', 
                    dateFormat.format(project.endDate)),
                _buildInfoRow(Icons.location_on, 'Location', 
                    project.locationBoundary.isCircular 
                        ? 'Circle (${project.locationBoundary.radiusInMeters.round()}m radius)'
                        : 'Polygon area'),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showExtendProjectDialog(project),
                      icon: const Icon(Icons.access_time, color: Colors.orange, size: 18),
                      label: const Text('Extend', 
                          style: TextStyle(color: Colors.orange, fontSize: 12)),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAssignProjectDialog(project, user),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Assign', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton.icon(
                      onPressed: () => _showEditProjectDialog(project, user),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmDeleteProject(project),
                      icon: const Icon(Icons.delete, color: AppTheme.errorColor, size: 18),
                      label: const Text('Delete', 
                          style: TextStyle(color: AppTheme.errorColor, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab(UserModel user) {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        if (_isLoadingSubordinates) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_subordinates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No subordinates found',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Quick assign button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showQuickAssignDialog(user, state.activeProjects),
                  icon: const Icon(Icons.assignment_add),
                  label: const Text('Quick Assign Project'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _subordinates.length,
                itemBuilder: (context, index) {
                  final subordinate = _subordinates[index];
                  return _buildSubordinateCard(subordinate, user);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showQuickAssignDialog(UserModel supervisor, List<ProjectModel> projects) {
    if (projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active projects available. Create a project first.')),
      );
      return;
    }

    if (_subordinates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No subordinates available to assign')),
      );
      return;
    }

    ProjectModel? selectedProject;
    UserModel? selectedSubordinate;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign Project to Subordinate'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Dropdown (constrained)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: DropdownButtonFormField<ProjectModel>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select Project *',
                      prefixIcon: Icon(Icons.work),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    value: selectedProject,
                    items: projects.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: p.name),
                            const TextSpan(text: '\n'),
                            TextSpan(text: p.address, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedProject = value;
                        if (value != null) {
                          endDate = value.endDate;
                        }
                      });
                    },
                  ),
                ),
                if (selectedProject != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.blue.shade700),
                            const SizedBox(width: 4),
                            const Text('Project Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedProject!.address,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedProject!.locationBoundary.isCircular
                            ? 'Check-in radius: ${selectedProject!.locationBoundary.radiusInMeters.round()}m'
                            : 'Check-in area: Polygon boundary',
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Subordinate Dropdown (constrained)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: DropdownButtonFormField<UserModel>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select Subordinate *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    value: selectedSubordinate,
                    items: _subordinates.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: s.name),
                            const TextSpan(text: '\n'),
                            TextSpan(text: s.email, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedSubordinate = value);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Date selection
                const Text('Assignment Period', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: selectedProject?.endDate ?? DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => startDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(DateFormat('MMM dd, yyyy').format(startDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: selectedProject?.endDate.add(const Duration(days: 90)) ?? 
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => endDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(DateFormat('MMM dd, yyyy').format(endDate)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedProject == null || selectedSubordinate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select both project and subordinate.')),
                  );
                  return;
                }
                context.read<ProjectBloc>().add(ProjectAssign(
                  projectId: selectedProject!.id,
                  projectName: selectedProject!.name,
                  userId: selectedSubordinate!.id,
                  userName: selectedSubordinate!.name,
                  assignedBy: supervisor.id,
                  assignedByName: supervisor.name,
                  locationBoundary: selectedProject!.locationBoundary,
                  address: selectedProject!.address,
                  startDate: startDate,
                  endDate: endDate,
                ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${selectedProject!.name} assigned to ${selectedSubordinate!.name}'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubordinateCard(UserModel subordinate, UserModel supervisor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            Helpers.getInitials(subordinate.name),
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(subordinate.name),
        subtitle: Text(subordinate.email),
        trailing: IconButton(
          icon: const Icon(Icons.assignment_add, color: AppTheme.primaryColor),
          onPressed: () => _showAssignToSubordinateDialog(subordinate, supervisor),
        ),
        onTap: () => _showSubordinateAssignments(subordinate),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey.shade600)),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _showCreateProjectDialog(UserModel user) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    LocationBoundary? selectedBoundary;
    String selectedAddress = '';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Location selection
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(selectedAddress.isNotEmpty 
                      ? selectedAddress 
                      : 'Select Location'),
                  subtitle: selectedBoundary != null
                      ? Text(selectedBoundary!.isCircular
                          ? 'Circle: ${selectedBoundary!.radiusInMeters.round()}m'
                          : 'Polygon area')
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LocationPickerScreen(),
                      ),
                    );
                    if (result != null) {
                      setDialogState(() {
                        selectedBoundary = result['boundary'] as LocationBoundary;
                        selectedAddress = result['address'] as String;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Date selection
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Start Date'),
                        subtitle: Text(DateFormat('MMM dd, yyyy').format(startDate)),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          );
                          if (date != null) {
                            setDialogState(() => startDate = date);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('End Date'),
                        subtitle: Text(DateFormat('MMM dd, yyyy').format(endDate)),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                          );
                          if (date != null) {
                            setDialogState(() => endDate = date);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter project name')),
                  );
                  return;
                }
                if (selectedBoundary == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select location')),
                  );
                  return;
                }

                context.read<ProjectBloc>().add(ProjectCreate(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  companyId: user.companyId,
                  corpId: user.corpId,
                  locationBoundary: selectedBoundary!,
                  address: selectedAddress,
                  startDate: startDate,
                  endDate: endDate,
                  createdBy: user.id,
                  createdByName: user.name,
                ));
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExtendProjectDialog(ProjectModel project) {
    DateTime newEndDate = project.endDate.add(const Duration(days: 30));
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    // Quick extend options
    final extendOptions = [
      {'label': '7 days', 'days': 7},
      {'label': '14 days', 'days': 14},
      {'label': '30 days', 'days': 30},
      {'label': '60 days', 'days': 60},
      {'label': '90 days', 'days': 90},
      {'label': 'Custom', 'days': -1},
    ];
    int? selectedDays = 30;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.access_time, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Text('Extend Project'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.event, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Current End Date: ${dateFormat.format(project.endDate)}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      if (project.isExpired) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'EXPIRED',
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Quick extend options
                const Text(
                  'Extend by:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: extendOptions.map((option) {
                    final days = option['days'] as int;
                    final isSelected = selectedDays == days;
                    return ChoiceChip(
                      label: Text(option['label'] as String),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() {
                            selectedDays = days;
                            if (days > 0) {
                              newEndDate = project.endDate.add(Duration(days: days));
                            }
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 16),
                
                // Custom date picker (only shown when custom is selected)
                if (selectedDays == -1) ...[
                  ListTile(
                    title: const Text('Select new end date'),
                    subtitle: Text(dateFormat.format(newEndDate)),
                    trailing: const Icon(Icons.calendar_today),
                    tileColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: newEndDate,
                        firstDate: project.endDate,
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) {
                        setDialogState(() => newEndDate = picked);
                      }
                    },
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // New end date preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available, color: AppTheme.successColor),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'New End Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            dateFormat.format(newEndDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ],
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
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                
                // Update the project with new end date
                final updatedProject = project.copyWith(
                  endDate: newEndDate,
                  updatedAt: DateTime.now(),
                );
                
                context.read<ProjectBloc>().add(ProjectUpdate(project: updatedProject));
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Project extended to ${dateFormat.format(newEndDate)}'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Extend'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProjectDialog(ProjectModel project, UserModel user) {
    final nameController = TextEditingController(text: project.name);
    final descriptionController = TextEditingController(text: project.description);
    LocationBoundary selectedBoundary = project.locationBoundary;
    String selectedAddress = project.address;
    DateTime startDate = project.startDate;
    DateTime endDate = project.endDate;
    ProjectStatus status = project.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Status dropdown
                DropdownButtonFormField<ProjectStatus>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.flag),
                  ),
                  items: ProjectStatus.values.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.name.toUpperCase()),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => status = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Location selection
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(selectedAddress),
                  subtitle: Text(selectedBoundary.isCircular
                      ? 'Circle: ${selectedBoundary.radiusInMeters.round()}m'
                      : 'Polygon area'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPickerScreen(
                          initialLocation: selectedBoundary.center,
                          initialRadius: selectedBoundary.radiusInMeters,
                          initialPolygon: selectedBoundary.polygonPoints,
                          isCircular: selectedBoundary.isCircular,
                        ),
                      ),
                    );
                    if (result != null) {
                      setDialogState(() {
                        selectedBoundary = result['boundary'] as LocationBoundary;
                        selectedAddress = result['address'] as String;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Date selection
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Start'),
                        subtitle: Text(DateFormat('MMM dd').format(startDate)),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          );
                          if (date != null) {
                            setDialogState(() => startDate = date);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('End'),
                        subtitle: Text(DateFormat('MMM dd').format(endDate)),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                          );
                          if (date != null) {
                            setDialogState(() => endDate = date);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedProject = project.copyWith(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  locationBoundary: selectedBoundary,
                  address: selectedAddress,
                  startDate: startDate,
                  endDate: endDate,
                  status: status,
                  updatedAt: DateTime.now(),
                );
                context.read<ProjectBloc>().add(ProjectUpdate(project: updatedProject));
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignProjectDialog(ProjectModel project, UserModel supervisor) {
    if (_subordinates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No subordinates available to assign')),
      );
      return;
    }

    UserModel? selectedSubordinate;
    DateTime startDate = DateTime.now();
    DateTime endDate = project.endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign ${project.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<UserModel>(
                  decoration: const InputDecoration(
                    labelText: 'Select Subordinate',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: _subordinates.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.name),
                  )).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedSubordinate = value);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Start'),
                        subtitle: Text(DateFormat('MMM dd').format(startDate)),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: project.endDate,
                          );
                          if (date != null) {
                            setDialogState(() => startDate = date);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('End'),
                        subtitle: Text(DateFormat('MMM dd').format(endDate)),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: project.endDate.add(const Duration(days: 30)),
                          );
                          if (date != null) {
                            setDialogState(() => endDate = date);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedSubordinate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a subordinate')),
                  );
                  return;
                }

                context.read<ProjectBloc>().add(ProjectAssign(
                  projectId: project.id,
                  projectName: project.name,
                  userId: selectedSubordinate!.id,
                  userName: selectedSubordinate!.name,
                  assignedBy: supervisor.id,
                  assignedByName: supervisor.name,
                  locationBoundary: project.locationBoundary,
                  address: project.address,
                  startDate: startDate,
                  endDate: endDate,
                ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Project assigned to ${selectedSubordinate!.name}'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignToSubordinateDialog(UserModel subordinate, UserModel supervisor) {
    final projects = context.read<ProjectBloc>().state.activeProjects;
    
    if (projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active projects available')),
      );
      return;
    }

    ProjectModel? selectedProject;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign to ${subordinate.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ProjectModel>(
                  decoration: const InputDecoration(
                    labelText: 'Select Project',
                    prefixIcon: Icon(Icons.work),
                  ),
                  items: projects.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.name),
                  )).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedProject = value;
                      if (value != null) {
                        endDate = value.endDate;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Start'),
                        subtitle: Text(DateFormat('MMM dd').format(startDate)),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: selectedProject?.endDate ?? DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => startDate = date);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('End'),
                        subtitle: Text(DateFormat('MMM dd').format(endDate)),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: selectedProject?.endDate.add(const Duration(days: 30)) ?? 
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => endDate = date);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedProject == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a project')),
                  );
                  return;
                }

                context.read<ProjectBloc>().add(ProjectAssign(
                  projectId: selectedProject!.id,
                  projectName: selectedProject!.name,
                  userId: subordinate.id,
                  userName: subordinate.name,
                  assignedBy: supervisor.id,
                  assignedByName: supervisor.name,
                  locationBoundary: selectedProject!.locationBoundary,
                  address: selectedProject!.address,
                  startDate: startDate,
                  endDate: endDate,
                ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${selectedProject!.name} assigned to ${subordinate.name}'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubordinateAssignments(UserModel subordinate) {
    context.read<ProjectBloc>().add(
      ProjectLoadUserAssignments(userId: subordinate.id),
    );

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
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      Helpers.getInitials(subordinate.name),
                      style: const TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subordinate.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Text('Project Assignments'),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<ProjectBloc, ProjectState>(
                builder: (context, state) {
                  final assignments = state.userAssignments;
                  
                  if (assignments.isEmpty) {
                    return const Center(
                      child: Text('No assignments found'),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: assignments.length,
                    itemBuilder: (context, index) {
                      final assignment = assignments[index];
                      return _buildAssignmentCard(assignment);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(ProjectAssignment assignment) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isActive = assignment.isCurrentlyActive;
    final remainingDays = assignment.endDate.difference(DateTime.now()).inDays;
    final isNearExpiry = remainingDays >= 0 && remainingDays <= 7;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: assignment.isExpired 
              ? AppTheme.errorColor.withOpacity(0.3)
              : isNearExpiry
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.work,
          color: isActive ? AppTheme.successColor : Colors.grey,
        ),
        title: Text(assignment.projectName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${dateFormat.format(assignment.startDate)} - ${dateFormat.format(assignment.endDate)}',
              style: const TextStyle(fontSize: 12),
            ),
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.successColor : Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isActive ? 'Active' : (assignment.isExpired ? 'Expired' : 'Inactive'),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                if (isNearExpiry && !assignment.isExpired) ...[
                  const SizedBox(width: 6),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Text(
                      '$remainingDays days left',
                      style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'extend',
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text('Extend'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'deactivate',
              enabled: assignment.isActive,
              child: const Text('Deactivate'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
            ),
          ],
          onSelected: (value) {
            if (value == 'extend') {
              _showExtendAssignmentDialog(assignment);
            } else if (value == 'deactivate') {
              context.read<ProjectBloc>().add(
                ProjectDeactivateAssignment(assignmentId: assignment.id),
              );
            } else if (value == 'delete') {
              context.read<ProjectBloc>().add(ProjectDeleteAssignment(
                assignmentId: assignment.id,
                userId: assignment.userId,
                projectId: assignment.projectId,
              ));
            }
          },
        ),
      ),
    );
  }

  void _showExtendAssignmentDialog(ProjectAssignment assignment) {
    DateTime newEndDate = assignment.endDate.add(const Duration(days: 30));
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    final extendOptions = [
      {'label': '7 days', 'days': 7},
      {'label': '14 days', 'days': 14},
      {'label': '30 days', 'days': 30},
      {'label': '60 days', 'days': 60},
      {'label': 'Custom', 'days': -1},
    ];
    int? selectedDays = 30;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.access_time, color: Colors.orange),
              SizedBox(width: 8),
              Text('Extend Assignment'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Assignment info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assignment.projectName,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Current End: ${dateFormat.format(assignment.endDate)}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text('Extend by:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: extendOptions.map((option) {
                    final days = option['days'] as int;
                    final isSelected = selectedDays == days;
                    return ChoiceChip(
                      label: Text(option['label'] as String),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() {
                            selectedDays = days;
                            if (days > 0) {
                              newEndDate = assignment.endDate.add(Duration(days: days));
                            }
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                
                if (selectedDays == -1) ...[
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Select new end date'),
                    subtitle: Text(dateFormat.format(newEndDate)),
                    trailing: const Icon(Icons.calendar_today),
                    tileColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: newEndDate,
                        firstDate: assignment.endDate,
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) {
                        setDialogState(() => newEndDate = picked);
                      }
                    },
                  ),
                ],
                
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available, color: AppTheme.successColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'New End: ${dateFormat.format(newEndDate)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor),
                      ),
                    ],
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
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // Update the assignment with new end date
                final updatedAssignment = assignment.copyWith(endDate: newEndDate);
                context.read<ProjectBloc>().add(
                  ProjectUpdateAssignment(assignment: updatedAssignment),
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Assignment extended to ${dateFormat.format(newEndDate)}'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Extend'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteProject(ProjectModel project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Are you sure you want to delete "${project.name}"? '
          'This will also remove all assignments for this project.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ProjectBloc>().add(ProjectDelete(
                projectId: project.id,
                companyId: project.companyId,
              ));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
