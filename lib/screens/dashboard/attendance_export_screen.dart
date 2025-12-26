import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../../blocs/blocs.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';

class AttendanceExportScreen extends StatefulWidget {
  final bool isAdmin;
  
  const AttendanceExportScreen({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<AttendanceExportScreen> createState() => _AttendanceExportScreenState();
}

class _AttendanceExportScreenState extends State<AttendanceExportScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final AuthService _authService = AuthService();
  final ExportService _exportService = ExportService();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _exportType = 'team'; // 'team' or 'individual'
  UserModel? _selectedEmployee;
  List<UserModel> _subordinates = [];
  bool _isLoading = false;
  bool _isExporting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadSubordinates();
  }

  Future<void> _loadSubordinates() async {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      List<UserModel> users = [];
      print('Loading employees for export. isAdmin: ${widget.isAdmin}, user.isAdmin: ${user.isAdmin}, user.isSupervisor: ${user.isSupervisor}');
      
      if (widget.isAdmin || user.isAdmin) {
        // Admin can see all supervisors and their subordinates
        print('Admin mode - loading all supervisors and subordinates');
        final supervisors = await _authService.getSupervisorsByCompany(user.companyId);
        print('Found ${supervisors.length} supervisors');
        users.addAll(supervisors);
        // Also get subordinates of each supervisor
        for (final supervisor in supervisors) {
          final subs = await _authService.getSubordinates(supervisor.id);
          print('Supervisor ${supervisor.name} has ${subs.length} subordinates');
          users.addAll(subs);
        }
      } else if (user.isSupervisor) {
        // Supervisor sees their subordinates
        print('Supervisor mode - loading subordinates for ${user.id}');
        users = await _authService.getSubordinates(user.id);
        print('Found ${users.length} subordinates');
      }
      
      // Remove duplicates based on id
      final uniqueUsers = <String, UserModel>{};
      for (final u in users) {
        uniqueUsers[u.id] = u;
      }
      
      print('Total unique users: ${uniqueUsers.length}');
      
      setState(() {
        _subordinates = uniqueUsers.values.toList();
        _isLoading = false;
      });
      
      if (_subordinates.isEmpty) {
        setState(() {
          _loadError = 'No team members found. Make sure you have subordinates assigned to you.';
        });
      }
    } catch (e) {
      print('Error loading employees: $e');
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to load employees: ${e.toString()}';
      });
    }
  }

  Future<void> _exportAttendance() async {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    if (_subordinates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No employees available for export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      List<AttendanceModel> attendanceList = [];

      if (_exportType == 'team') {
        // Get team attendance
        final subordinateInfos = _subordinates.map((s) => {
          'id': s.id,
          'name': s.name,
          'companyId': s.companyId,
          'corpId': s.corpId,
        }).toList();

        // Fetch attendance for date range
        for (DateTime date = _startDate;
            date.isBefore(_endDate.add(const Duration(days: 1)));
            date = date.add(const Duration(days: 1))) {
          final dayAttendance = await _attendanceService
              .getSubordinatesAttendanceWithAbsent(subordinateInfos, date: date);
          attendanceList.addAll(dayAttendance);
        }

        // Export
        final filePath = await _exportService.exportTeamAttendanceReport(
          attendanceList: attendanceList,
          startDate: _startDate,
          endDate: _endDate,
          teamName: user.isSupervisor ? 'Team' : 'Company',
        );

        _showExportSuccess(filePath);
      } else if (_exportType == 'individual' && _selectedEmployee != null) {
        // Get individual attendance
        attendanceList = await _attendanceService.getUserAttendanceHistory(
          _selectedEmployee!.id,
          limit: 365,
        );

        // Filter by date range
        attendanceList = attendanceList.where((a) =>
            a.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
            a.date.isBefore(_endDate.add(const Duration(days: 1)))).toList();

        // Export
        final filePath = await _exportService.exportEmployeeAttendanceReport(
          attendanceList: attendanceList,
          employeeName: _selectedEmployee!.name,
          startDate: _startDate,
          endDate: _endDate,
        );

        _showExportSuccess(filePath);
      } else if (_exportType == 'individual' && _selectedEmployee == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an employee for individual export'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }

    setState(() => _isExporting = false);
  }

  void _showExportSuccess(String filePath) {
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your attendance report has been exported successfully.'),
            const SizedBox(height: 12),
            Text(
              'File: ${filePath.split('/').last}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ],
        ),
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
            label: const Text('Open File'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Attendance'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubordinates,
            tooltip: 'Refresh employees',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message if any
                  if (_loadError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _loadError!,
                              style: TextStyle(color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Employee count info
                  if (_subordinates.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700),
                          const SizedBox(width: 12),
                          Text(
                            '${_subordinates.length} employees loaded',
                            style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Export type selection
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export Type',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildExportTypeCard(
                                  'team',
                                  'Team Report',
                                  Icons.group,
                                  'Export attendance for all team members',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildExportTypeCard(
                                  'individual',
                                  'Individual',
                                  Icons.person,
                                  'Export for a specific employee',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Employee selection (for individual export)
                  if (_exportType == 'individual') ...[
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Employee',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            _subordinates.isEmpty
                                ? const Text('No employees available', 
                                    style: TextStyle(color: Colors.grey))
                                : DropdownButtonFormField<UserModel>(
                                    value: _selectedEmployee,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.person),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    hint: const Text('Select employee'),
                                    items: _subordinates.map((user) {
                                      return DropdownMenuItem(
                                        value: user,
                                        child: Text(user.name),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() => _selectedEmployee = value);
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Date range selection
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date Range',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateSelector(
                                  'Start Date',
                                  _startDate,
                                  (date) => setState(() => _startDate = date),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDateSelector(
                                  'End Date',
                                  _endDate,
                                  (date) => setState(() => _endDate = date),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Quick date range buttons
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildQuickDateButton('Last 7 days', 7),
                              _buildQuickDateButton('Last 30 days', 30),
                              _buildQuickDateButton('Last 90 days', 90),
                              _buildQuickDateButton('This month', -1),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Preview info
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, 
                                  color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Export Summary',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow('Type', _exportType == 'team' 
                              ? 'Team Report' 
                              : 'Individual Report'),
                          if (_exportType == 'individual' && _selectedEmployee != null)
                            _buildSummaryRow('Employee', _selectedEmployee!.name),
                          if (_exportType == 'team')
                            _buildSummaryRow('Team Members', 
                                '${_subordinates.length} employees'),
                          _buildSummaryRow('Date Range', 
                              '${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}'),
                          _buildSummaryRow('Duration', 
                              '${_endDate.difference(_startDate).inDays + 1} days'),
                          _buildSummaryRow('Format', 'CSV (Excel compatible)'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Export button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _canExport() ? _exportAttendance : null,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download),
                      label: Text(_isExporting 
                          ? 'Exporting...' 
                          : 'Export to CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildExportTypeCard(
    String type,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = _exportType == type;
    return GestureDetector(
      onTap: () => setState(() => _exportType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.1) 
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(
    String label,
    DateTime date,
    Function(DateTime) onDateSelected,
  ) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
        );
        if (selectedDate != null) {
          onDateSelected(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateButton(String label, int days) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          if (days == -1) {
            // This month
            final now = DateTime.now();
            _startDate = DateTime(now.year, now.month, 1);
            _endDate = now;
          } else {
            _endDate = DateTime.now();
            _startDate = _endDate.subtract(Duration(days: days - 1));
          }
        });
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  bool _canExport() {
    if (_isExporting) return false;
    if (_exportType == 'individual' && _selectedEmployee == null) return false;
    if (_exportType == 'team' && _subordinates.isEmpty) return false;
    return true;
  }
}
