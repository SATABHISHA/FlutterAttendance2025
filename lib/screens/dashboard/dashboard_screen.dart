import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/blocs.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final StorageService _storageService = StorageService();
  final ProjectService _projectService = ProjectService();
  String? _profileImagePath;
  bool _isIOS = false;
  List<ProjectAssignment> _userAssignments = [];
  bool _loadingAssignments = false;

  @override
  void initState() {
    super.initState();
    _isIOS = Platform.isIOS;
    _loadProfileImage();
    _loadData();
    _loadUserAssignments();
  }

  Future<void> _loadUserAssignments() async {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;
    
    setState(() => _loadingAssignments = true);
    try {
      final assignments = await _projectService.getActiveUserAssignments(user.id);
      if (mounted) {
        setState(() {
          _userAssignments = assignments;
          _loadingAssignments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAssignments = false);
      }
    }
  }

  Future<void> _loadProfileImage() async {
    final path = await _storageService.getProfileImagePath();
    if (mounted) {
      setState(() {
        _profileImagePath = path;
      });
    }
  }

  void _loadData() {
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      context.read<AttendanceBloc>().add(AttendanceLoadToday(oderId: user.id));
      context.read<TaskBloc>().add(TaskLoadAssignedTo(oderId: user.id));
      if (user.isSupervisor) {
        context.read<TaskBloc>().add(TaskLoadAssignedBy(oderId: user.id));
        context.read<AttendanceBloc>().add(
              AttendanceLoadSubordinates(supervisorId: user.id),
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
          key: _scaffoldKey,
          drawer: _buildDrawer(user),
          body: RefreshIndicator(
            onRefresh: () async {
              _loadData();
              _loadUserAssignments();
            },
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Helpers.getGreeting(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      user.companyName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (user.isSupervisor) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentColor.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Supervisor',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Today's Attendance Card
                        _buildAttendanceCard(user),
                        const SizedBox(height: 20),

                        // Project Assignments Section (for location-based check-in)
                        if (_userAssignments.isNotEmpty || _loadingAssignments) ...[
                          Text(
                            'My Project Assignments',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          _buildProjectAssignmentsSection(),
                          const SizedBox(height: 20),
                        ],

                        // Quick Actions
                        Text(
                          'Quick Actions',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        _buildQuickActions(user),
                        const SizedBox(height: 20),

                        // My Tasks
                        Text(
                          'My Tasks',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        _buildTasksSection(user),

                        // Supervisor Section
                        if (user.isSupervisor) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Team Overview',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          _buildSupervisorSection(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(UserModel user) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                accountName: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(user.email),
                currentAccountPicture: GestureDetector(
                  onTap: _changeProfileImage,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: _profileImagePath != null
                        ? FileImage(File(_profileImagePath!))
                        : null,
                    child: _profileImagePath == null
                        ? Text(
                            Helpers.getInitials(user.name),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Attendance History'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/attendance-history');
                },
              ),
              ListTile(
                leading: const Icon(Icons.task_alt),
                title: const Text('My Tasks'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/tasks');
                },
              ),
              ListTile(
                leading: const Icon(Icons.today),
                title: const Text('Daily Reports'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/daily-report');
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('My Statistics'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/task-statistics');
                },
              ),
              if (user.isSupervisor) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Team Attendance'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/team-attendance');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assignment),
                  title: const Text('Assign Task'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/assign-task');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.fact_check),
                  title: const Text('Review Team Tasks'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/subordinate-tasks');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.summarize),
                  title: const Text('Team Daily Reports'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/team-reports');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.business),
                  title: const Text('Project Allocation'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/project-allocation');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('Team Performance'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/task-performance');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export Attendance'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/attendance-export');
                  },
                ),
              ],
              const Divider(),
              // Security Settings Section
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
                child: Text(
                  'Quick Login Settings',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              // Show note if first login not completed
              if (!authState.hasCompletedFirstLogin)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Complete your first login to enable quick login options.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.orange,
                    ),
                  ),
                ),
              // Face ID / Face Unlock Toggle
              if (authState.faceIdAvailable)
                SwitchListTile(
                  secondary: const Icon(Icons.face),
                  title: Text(_isIOS ? 'Face ID' : 'Face Unlock'),
                  subtitle: Text(
                    authState.faceIdEnabled 
                        ? 'Enabled for quick login' 
                        : 'Enable ${_isIOS ? "Face ID" : "Face Unlock"} for quick login',
                  ),
                  value: authState.faceIdEnabled,
                  onChanged: authState.hasCompletedFirstLogin
                      ? (value) {
                          context.read<AuthBloc>().add(AuthEnableFaceId(enable: value));
                        }
                      : null,
                ),
              // Fingerprint / Touch ID Toggle
              if (authState.fingerprintAvailable)
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: Text(_isIOS ? 'Touch ID' : 'Fingerprint'),
                  subtitle: Text(
                    authState.fingerprintEnabled 
                        ? 'Enabled for quick login' 
                        : 'Enable ${_isIOS ? "Touch ID" : "Fingerprint"} for quick login',
                  ),
                  value: authState.fingerprintEnabled,
                  onChanged: authState.hasCompletedFirstLogin
                      ? (value) {
                          context.read<AuthBloc>().add(AuthEnableFingerprint(enable: value));
                        }
                      : null,
                ),
              // PIN/Pattern Toggle - always show if available
              if (authState.pinPatternAvailable)
                SwitchListTile(
                  secondary: const Icon(Icons.lock_outline),
                  title: const Text('PIN/Pattern'),
                  subtitle: Text(
                    authState.pinPatternEnabled 
                        ? 'Enabled for quick login' 
                        : 'Enable device PIN/Pattern for quick login',
                  ),
                  value: authState.pinPatternEnabled,
                  onChanged: authState.hasCompletedFirstLogin
                      ? (value) {
                          context.read<AuthBloc>().add(AuthEnablePinPattern(enable: value));
                        }
                      : null,
                ),
              // Show message if no biometrics available
              if (!authState.faceIdAvailable && !authState.fingerprintAvailable && !authState.pinPatternAvailable)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No quick login options available on this device. Please enable device security (PIN, Pattern, or Biometrics) in your device settings.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              // Device Lock Info
              if (authState.isDeviceLocked && authState.lockedUserName != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Device locked to: ${authState.lockedUserName}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Advanced Security Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _showBiometricSettings();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Change Profile Picture'),
                onTap: () {
                  Navigator.pop(context);
                  _changeProfileImage();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppTheme.errorColor),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
                onTap: () {
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceCard(UserModel user) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        return GradientCard(
          gradient: state.hasCheckedIn && !state.hasCheckedOut
              ? AppTheme.secondaryGradient
              : state.hasCheckedOut
                  ? LinearGradient(
                      colors: [Colors.grey.shade600, Colors.grey.shade800],
                    )
                  : AppTheme.primaryGradient,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Status",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.hasCheckedOut
                            ? 'Completed'
                            : state.hasCheckedIn
                                ? 'Checked In'
                                : 'Not Checked In',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      state.hasCheckedOut
                          ? Icons.check_circle
                          : state.hasCheckedIn
                              ? Icons.access_time
                              : Icons.login,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.todayAttendance != null) ...[
                Row(
                  children: [
                    if (state.todayAttendance!.checkInTime != null) ...[
                      _buildTimeChip(
                        'Check In',
                        Helpers.formatTime(state.todayAttendance!.checkInTime!),
                        Icons.login,
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (state.todayAttendance!.checkOutTime != null) ...[
                      _buildTimeChip(
                        'Check Out',
                        Helpers.formatTime(state.todayAttendance!.checkOutTime!),
                        Icons.logout,
                      ),
                    ],
                  ],
                ),
                if (state.todayAttendance!.workDuration != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Work Duration: ${Helpers.formatDuration(state.todayAttendance!.workDuration!)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: state.hasCheckedIn || state.isCheckingIn
                          ? null
                          : () => _checkIn(user),
                      icon: state.isCheckingIn
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login),
                      label: const Text('Check In'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: state.canCheckOut && !state.isCheckingOut
                          ? () => _checkOut(state.todayAttendance!.id, user.id)
                          : null,
                      icon: state.isCheckingOut
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.logout),
                      label: const Text('Check Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeChip(String label, String time, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectAssignmentsSection() {
    if (_loadingAssignments) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final user = context.read<AuthBloc>().state.user;
    final isSupervisor = user?.isSupervisor ?? false;
    
    if (_userAssignments.isEmpty && !isSupervisor) {
      // Non-supervisor with no project - show warning and request button
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.warning_amber, color: Colors.orange, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No Project Assigned',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You cannot check in without an assigned project. Contact your supervisor or request attendance permission.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _requestAttendancePermission(user!),
                  icon: const Icon(Icons.send),
                  label: const Text('Request Attendance Permission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_userAssignments.isEmpty && isSupervisor) {
      // Supervisor with no assignments - that's ok, they can still check in
      return const SizedBox.shrink();
    }

    return Column(
      children: _userAssignments.map((assignment) {
        return _buildProjectAssignmentCard(assignment);
      }).toList(),
    );
  }

  Widget _buildProjectAssignmentCard(ProjectAssignment assignment) {
    final now = DateTime.now();
    final totalDays = assignment.endDate.difference(assignment.startDate).inDays;
    final elapsedDays = now.difference(assignment.startDate).inDays;
    final remainingDays = assignment.endDate.difference(now).inDays;
    final progress = totalDays > 0 ? (elapsedDays / totalDays).clamp(0.0, 1.0) : 0.0;
    
    final isOverdue = remainingDays < 0;
    final isNearEnd = remainingDays >= 0 && remainingDays <= 7;
    
    Color statusColor;
    String statusText;
    if (isOverdue) {
      statusColor = AppTheme.errorColor;
      statusText = 'Overdue by ${remainingDays.abs()} days';
    } else if (isNearEnd) {
      statusColor = Colors.orange;
      statusText = remainingDays == 0 ? 'Ends today' : '$remainingDays days remaining';
    } else {
      statusColor = AppTheme.successColor;
      statusText = '$remainingDays days remaining';
    }

    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOverdue ? AppTheme.errorColor.withOpacity(0.5) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.business, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.projectName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              assignment.address,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOverdue ? Icons.warning : Icons.schedule,
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress Bar Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Project Duration',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}% elapsed',
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Animated Progress Bar
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Stack(
                      children: [
                        // Background
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        // Progress
                        FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isOverdue
                                    ? [AppTheme.errorColor.withOpacity(0.7), AppTheme.errorColor]
                                    : isNearEnd
                                        ? [Colors.orange.withOpacity(0.7), Colors.orange]
                                        : [AppTheme.primaryColor.withOpacity(0.7), AppTheme.primaryColor],
                              ),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Date Range
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateFormat.format(assignment.startDate),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    Text(
                      dateFormat.format(assignment.endDate),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Check-in Location Info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Check-in allowed within ${assignment.locationBoundary.radiusInMeters.toInt()}m of project location',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(UserModel user) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.history,
            label: 'History',
            color: AppTheme.primaryColor,
            onTap: () => Navigator.pushNamed(context, '/attendance-history'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.task_alt,
            label: 'Tasks',
            color: AppTheme.secondaryColor,
            onTap: () => Navigator.pushNamed(context, '/tasks'),
          ),
        ),
        if (user.isSupervisor) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              icon: Icons.assignment_add,
              label: 'Assign',
              color: AppTheme.accentColor,
              onTap: () => Navigator.pushNamed(context, '/assign-task'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksSection(UserModel user) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state.status == TaskStateStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.assignedToMe.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.task_alt, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'No tasks assigned',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Task Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildTaskSummaryCard(
                    'Pending',
                    state.pendingTasksCount,
                    AppTheme.warningColor,
                    Icons.pending_actions,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTaskSummaryCard(
                    'In Progress',
                    state.inProgressTasksCount,
                    AppTheme.infoColor,
                    Icons.autorenew,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTaskSummaryCard(
                    'Completed',
                    state.completedTasksCount,
                    AppTheme.successColor,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recent Tasks List
            ...state.assignedToMe.take(3).map((task) => TaskListItem(
                  task: task,
                  onTap: () {
                    _showTaskDetails(task);
                  },
                )),
          ],
        );
      },
    );
  }

  Widget _buildTaskSummaryCard(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorSection() {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        final presentCount = state.subordinatesAttendance
            .where((a) => a.hasCheckedIn)
            .length;
        final totalCount = state.subordinatesAttendance.length;
        final absentCount = totalCount - presentCount;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.accentColor.withOpacity(0.1),
                AppTheme.accentDark.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.people,
                          color: AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Team Attendance',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (state.status == AttendanceStateStatus.loading)
                            const Text(
                              'Loading team...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            )
                          else
                            Text(
                              '$presentCount of $totalCount present today',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/team-attendance');
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              if (state.status == AttendanceStateStatus.loading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: LinearProgressIndicator(),
                )
              else if (state.subordinatesAttendance.isNotEmpty) ...[
                const SizedBox(height: 16),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: totalCount > 0 ? presentCount / totalCount : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      presentCount == totalCount 
                          ? AppTheme.successColor 
                          : AppTheme.accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Quick stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickStat(
                      icon: Icons.check_circle,
                      label: 'Present',
                      value: presentCount.toString(),
                      color: AppTheme.successColor,
                    ),
                    _buildQuickStat(
                      icon: Icons.cancel,
                      label: 'Absent',
                      value: absentCount.toString(),
                      color: AppTheme.errorColor,
                    ),
                    _buildQuickStat(
                      icon: Icons.people,
                      label: 'Total',
                      value: totalCount.toString(),
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'No team members found',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _checkIn(UserModel user) async {
    // Check if user is a supervisor - they can check in without project
    if (user.isSupervisor) {
      context.read<AttendanceBloc>().add(AttendanceCheckIn(
            oderId: user.id,
            userName: user.name,
            companyId: user.companyId,
            corpId: user.corpId,
          ));
      return;
    }

    // For non-supervisors, check project assignments
    if (_userAssignments.isEmpty) {
      // No project assigned - check if there's an approved request for today
      final hasApproval = await _projectService.hasApprovedAttendanceRequest(user.id);
      if (hasApproval) {
        // User has approved request, allow check-in
        context.read<AttendanceBloc>().add(AttendanceCheckIn(
              oderId: user.id,
              userName: user.name,
              companyId: user.companyId,
              corpId: user.corpId,
            ));
        return;
      }
      
      // No project and no approval
      _showNoProjectError();
      return;
    }

    // User has project assignments - validate location
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Validating location...'),
                ],
              ),
            ),
          ),
        ),
      );
      
      // Get current location
      final locationService = LocationService();
      final currentPosition = await locationService.getCurrentPosition();
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      // Check if user is within any of their assigned project locations
      bool isWithinProjectLocation = false;
      ProjectAssignment? matchedAssignment;
      
      for (final assignment in _userAssignments) {
        if (_projectService.isWithinBoundary(
          currentPosition.latitude,
          currentPosition.longitude,
          assignment.locationBoundary,
        )) {
          isWithinProjectLocation = true;
          matchedAssignment = assignment;
          break;
        }
      }
      
      if (!isWithinProjectLocation) {
        // User is not within any project location
        _showLocationError(
          'You are not within your assigned project location.\n\n'
          'Please move to one of your assigned project areas to check in:\n'
          '${_userAssignments.map((a) => '• ${a.projectName} - ${a.address}').join('\n')}'
        );
        return;
      }
      
      // Show success message with matched project
      if (mounted && matchedAssignment != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checking in at ${matchedAssignment.projectName}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Check if dialog is showing before trying to pop
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Close loading if open
        }
        _showLocationError('Error validating location: $e');
      }
      return;
    }
    
    // Proceed with check-in
    context.read<AttendanceBloc>().add(AttendanceCheckIn(
          oderId: user.id,
          userName: user.name,
          companyId: user.companyId,
          corpId: user.corpId,
        ));
  }

  void _showNoProjectError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('No Project Assigned'),
          ],
        ),
        content: const Text(
          'You cannot check in without an assigned project.\n\n'
          'Please request attendance permission from your supervisor using the button in the "My Project Assignments" section.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _requestAttendancePermission(UserModel user) async {
    // Show dialog to request attendance permission from supervisor
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.send, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Request Attendance'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You have no project assigned. Send a request to your supervisor for attendance permission today.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'Why do you need attendance permission?',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Send Request'),
            ),
          ],
        );
      },
    );

    if (reason != null && mounted) {
      // Store attendance request in Firebase
      try {
        await _projectService.createAttendanceRequest(
          userId: user.id,
          userName: user.name,
          supervisorId: user.supervisorId ?? '',
          reason: reason,
          requestDate: DateTime.now(),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance request sent to your supervisor'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send request: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  void _showLocationError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: AppTheme.errorColor),
            SizedBox(width: 8),
            Text('Location Check Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _checkOut(String attendanceId, String userId) {
    context.read<AttendanceBloc>().add(AttendanceCheckOut(
          attendanceId: attendanceId,
          userId: userId,
        ));
  }

  void _changeProfileImage() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
          ],
        ),
      ),
    );

    if (choice != null) {
      String? path;
      if (choice == 'gallery') {
        path = await _storageService.pickAndSaveProfileImage();
      } else {
        path = await _storageService.takeAndSaveProfilePhoto();
      }

      if (path != null && mounted) {
        setState(() {
          _profileImagePath = path;
        });
        context.read<AuthBloc>().add(AuthUpdateProfileImage(imagePath: path));
      }
    }
  }

  void _showBiometricSettings() {
    final authBloc = context.read<AuthBloc>();
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: authBloc,
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              // Dialog will auto-update through BlocBuilder
              print('Security settings state updated: biometricEnabled=${state.biometricEnabled}');
            },
            builder: (blocContext, state) {
              return AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.security, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('Security Settings'),
                  ],
                ),
                content: FutureBuilder<List<dynamic>>(
                  future: Future.wait([
                    BiometricService().getAuthMethodsDescription(),
                    BiometricService().hasFaceId(),
                    BiometricService().hasTouchId(),
                    BiometricService().hasPinPattern(),
                    BiometricService().getAvailableBiometrics(),
                  ]),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading security options...'),
                        ],
                      );
                    }
                    
                    final authMethods = snapshot.data![0] as String;
                    final hasFace = snapshot.data![1] as bool;
                    final hasFingerprint = snapshot.data![2] as bool;
                    final hasPinPattern = snapshot.data![3] as bool;
                    final biometrics = snapshot.data![4] as List;
                    
                    print('Auth methods: $authMethods');
                    print('Has Face: $hasFace, Has Fingerprint: $hasFingerprint, Has PIN/Pattern: $hasPinPattern');
                    print('Raw biometrics: $biometrics');
                    
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // First login requirement notice
                          if (!state.hasCompletedFirstLogin)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Complete your first login to enable quick login options.',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Available methods info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Available: $authMethods',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Face ID / Face Unlock
                          if (hasFace) ...[
                            _buildSettingsTile(
                              icon: Icons.face,
                              title: _isIOS ? 'Face ID' : 'Face Unlock',
                              subtitle: _isIOS 
                                  ? 'Use Face ID for quick login'
                                  : 'Use your face for quick login',
                              enabled: state.faceIdEnabled,
                              isDisabled: !state.hasCompletedFirstLogin,
                              onChanged: state.hasCompletedFirstLogin
                                  ? (value) {
                                      blocContext.read<AuthBloc>().add(
                                        AuthEnableFaceId(enable: value),
                                      );
                                    }
                                  : null,
                            ),
                            const Divider(),
                          ],
                          
                          // Fingerprint / Touch ID
                          if (hasFingerprint) ...[
                            _buildSettingsTile(
                              icon: Icons.fingerprint,
                              title: _isIOS ? 'Touch ID' : 'Fingerprint',
                              subtitle: _isIOS 
                                  ? 'Use Touch ID for quick login'
                                  : 'Use your fingerprint for quick login',
                              enabled: state.fingerprintEnabled,
                              isDisabled: !state.hasCompletedFirstLogin,
                              onChanged: state.hasCompletedFirstLogin
                                  ? (value) {
                                      blocContext.read<AuthBloc>().add(
                                        AuthEnableFingerprint(enable: value),
                                      );
                                    }
                                  : null,
                            ),
                            const Divider(),
                          ],
                          
                          // Device Credential (PIN/Pattern)
                          if (hasPinPattern) ...[
                            _buildSettingsTile(
                              icon: Icons.lock_outline,
                              title: 'Device PIN/Pattern',
                              subtitle: 'Use your device PIN or pattern for quick login',
                              enabled: state.pinPatternEnabled,
                              isDisabled: !state.hasCompletedFirstLogin,
                              onChanged: state.hasCompletedFirstLogin
                                  ? (value) {
                                      blocContext.read<AuthBloc>().add(
                                        AuthEnablePinPattern(enable: value),
                                      );
                                    }
                                  : null,
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          
                          // Device Lock Info
                          if (state.isDeviceLocked && state.lockedUserName != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock, color: AppTheme.primaryColor, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Device locked to: ${state.lockedUserName}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Clear app data or reinstall to use with another account.',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Status indicator
                          if (state.faceIdEnabled || state.fingerprintEnabled || state.pinPatternEnabled)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Quick login is enabled',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info, color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Enable at least one option for quick login',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    bool isDisabled = false,
    ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: isDisabled ? Colors.grey.shade400 : (enabled ? AppTheme.primaryColor : Colors.grey)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDisabled ? Colors.grey.shade400 : (enabled ? Colors.black : Colors.grey.shade700),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
      value: enabled,
      onChanged: isDisabled ? null : onChanged,
      contentPadding: EdgeInsets.zero,
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
