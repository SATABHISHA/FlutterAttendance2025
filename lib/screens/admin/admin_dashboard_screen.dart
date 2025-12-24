import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/blocs.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final StorageService _storageService = StorageService();
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    context.read<CompanyBloc>().add(CompanyLoadAll());
  }

  Future<void> _loadProfileImage() async {
    final path = await _storageService.getProfileImagePath();
    if (mounted) {
      setState(() {
        _profileImagePath = path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompanyBloc, CompanyState>(
      listener: (context, companyState) {
        if (companyState.status == CompanyStateStatus.error && companyState.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(companyState.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
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
            body: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 180,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.accentColor,
                          AppTheme.accentDark,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.admin_panel_settings,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Admin Portal',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Welcome, ${user.name}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.companyName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
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
                      // Quick Stats
                      _buildQuickStats(),
                      const SizedBox(height: 24),

                      // Companies Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Companies',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _showAddCompanyDialog(user);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add New'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildCompaniesList(user),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              _showAddCompanyDialog(user);
            },
            backgroundColor: AppTheme.accentColor,
            icon: const Icon(Icons.add),
            label: const Text('Add Company'),
          ),
        );
        },
      ),
    );
  }

  Widget _buildDrawer(UserModel user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.accentColor, AppTheme.accentDark],
              ),
            ),
            accountName: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Admin',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: _profileImagePath != null
                  ? FileImage(File(_profileImagePath!))
                  : null,
              child: _profileImagePath == null
                  ? Text(
                      Helpers.getInitials(user.name),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentColor,
                      ),
                    )
                  : null,
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
            leading: const Icon(Icons.business),
            title: const Text('Companies'),
            onTap: () {
              Navigator.pop(context);
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
  }

  Widget _buildQuickStats() {
    return BlocBuilder<CompanyBloc, CompanyState>(
      builder: (context, state) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Companies',
                state.companies.length.toString(),
                Icons.business,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Corp IDs',
                state.corpIds.length.toString(),
                Icons.tag,
                AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Branches',
                state.companies
                    .map((c) => c.branch)
                    .toSet()
                    .length
                    .toString(),
                Icons.store,
                AppTheme.accentColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
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
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompaniesList(UserModel user) {
    return BlocBuilder<CompanyBloc, CompanyState>(
      builder: (context, state) {
        if (state.status == CompanyStateStatus.loading ||
            state.status == CompanyStateStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == CompanyStateStatus.error) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading companies',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage ?? 'Unknown error',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.read<CompanyBloc>().add(CompanyLoadAll()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state.companies.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.business_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No companies added yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddCompanyDialog(user),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Company'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.companies.length,
          itemBuilder: (context, index) {
            final company = state.companies[index];
            return _buildCompanyCard(company);
          },
        );
      },
    );
  }

  Widget _buildCompanyCard(CompanyModel company) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.business,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          company.companyName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Corp ID: ${company.corpId}',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.store, 'Branch', company.branch),
                _buildInfoRow(Icons.location_city, 'City', company.city),
                _buildInfoRow(Icons.map, 'State', company.state),
                _buildInfoRow(Icons.location_on, 'Address', company.address),
                _buildInfoRow(Icons.person, 'Created By', company.createdByName),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Created At',
                  Helpers.formatDate(company.createdAt),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showEditCompanyDialog(company),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _confirmDeleteCompany(company),
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: AppTheme.errorColor,
                      ),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCompanyDialog(UserModel user) {
    final companyNameController = TextEditingController();
    final corpIdController = TextEditingController();
    final branchController = TextEditingController();
    final stateController = TextEditingController();
    final cityController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Company'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: companyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) =>
                      Helpers.validateRequired(value, 'Company name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: corpIdController,
                  decoration: const InputDecoration(
                    labelText: 'Corp ID',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  validator: (value) =>
                      Helpers.validateRequired(value, 'Corp ID'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: branchController,
                  decoration: const InputDecoration(
                    labelText: 'Branch',
                    prefixIcon: Icon(Icons.store),
                  ),
                  validator: (value) => Helpers.validateRequired(value, 'Branch'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: stateController,
                        decoration: const InputDecoration(
                          labelText: 'State',
                        ),
                        validator: (value) =>
                            Helpers.validateRequired(value, 'State'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                        ),
                        validator: (value) =>
                            Helpers.validateRequired(value, 'City'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) =>
                      Helpers.validateRequired(value, 'Address'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<CompanyBloc>().add(CompanyCreate(
                      companyName: companyNameController.text.trim(),
                      corpId: corpIdController.text.trim(),
                      branch: branchController.text.trim(),
                      state: stateController.text.trim(),
                      city: cityController.text.trim(),
                      address: addressController.text.trim(),
                      createdBy: user.id,
                      createdByName: user.name,
                    ));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCompanyDialog(CompanyModel company) {
    final companyNameController = TextEditingController(text: company.companyName);
    final corpIdController = TextEditingController(text: company.corpId);
    final branchController = TextEditingController(text: company.branch);
    final stateController = TextEditingController(text: company.state);
    final cityController = TextEditingController(text: company.city);
    final addressController = TextEditingController(text: company.address);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Company'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: companyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) =>
                      Helpers.validateRequired(value, 'Company name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: corpIdController,
                  decoration: const InputDecoration(
                    labelText: 'Corp ID',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  validator: (value) =>
                      Helpers.validateRequired(value, 'Corp ID'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: branchController,
                  decoration: const InputDecoration(
                    labelText: 'Branch',
                    prefixIcon: Icon(Icons.store),
                  ),
                  validator: (value) => Helpers.validateRequired(value, 'Branch'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: stateController,
                        decoration: const InputDecoration(
                          labelText: 'State',
                        ),
                        validator: (value) =>
                            Helpers.validateRequired(value, 'State'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                        ),
                        validator: (value) =>
                            Helpers.validateRequired(value, 'City'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) =>
                      Helpers.validateRequired(value, 'Address'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<CompanyBloc>().add(CompanyUpdate(
                      id: company.id,
                      companyName: companyNameController.text.trim(),
                      corpId: corpIdController.text.trim(),
                      branch: branchController.text.trim(),
                      state: stateController.text.trim(),
                      city: cityController.text.trim(),
                      address: addressController.text.trim(),
                    ));
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCompany(CompanyModel company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Company'),
        content: Text(
          'Are you sure you want to delete "${company.companyName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CompanyBloc>().add(CompanyDelete(id: company.id));
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
}
