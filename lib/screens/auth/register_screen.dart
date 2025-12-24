import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../blocs/blocs.dart';
import '../../utils/utils.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String? _selectedCompanyId;
  String? _selectedCompanyName;
  String? _selectedCorpId;
  String? _selectedSupervisorId;
  bool _isAdmin = false;
  bool _isSupervisor = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  List<Map<String, dynamic>> _supervisors = [];
  bool _isLoadingSupervisors = false;

  @override
  void initState() {
    super.initState();
    context.read<CompanyBloc>().add(CompanyLoadAll());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSupervisors(String companyId) async {
    setState(() {
      _isLoadingSupervisors = true;
      _supervisors = [];
      _selectedSupervisorId = null;
    });

    try {
      final database = FirebaseDatabase.instance;
      final snapshot = await database.ref('users').get();
      
      if (snapshot.exists) {
        final usersMap = snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> supervisorList = [];
        
        usersMap.forEach((key, value) {
          final userData = value as Map<dynamic, dynamic>;
          // Only include users who are supervisors for this company
          if (userData['isSupervisor'] == true && 
              userData['companyId'] == companyId) {
            supervisorList.add({
              'id': key,
              'name': userData['name']?.toString() ?? 'Unknown',
            });
          }
        });
        
        setState(() {
          _supervisors = supervisorList;
          _isLoadingSupervisors = false;
        });
        print('Loaded ${_supervisors.length} supervisors for company $companyId');
      } else {
        setState(() {
          _isLoadingSupervisors = false;
        });
      }
    } catch (e) {
      print('Error loading supervisors: $e');
      setState(() {
        _isLoadingSupervisors = false;
      });
    }
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCompanyId == null || _selectedCorpId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a company and Corp ID'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
      
      // Regular employees (not admin, not supervisor) must select a supervisor
      if (!_isAdmin && !_isSupervisor && _selectedSupervisorId == null && _supervisors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your supervisor'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      context.read<AuthBloc>().add(AuthRegisterRequested(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            companyId: _selectedCompanyId!,
            companyName: _selectedCompanyName!,
            corpId: _selectedCorpId!,
            isAdmin: _isAdmin,
            isSupervisor: _isSupervisor,
            supervisorId: _selectedSupervisorId,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Registration failed'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        builder: (context, authState) {
          return Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header
                      const Icon(
                        Icons.person_add_outlined,
                        size: 60,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create Account',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fill in the details to register',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 32),

                      // Form Container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Name Field
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: AppStrings.fullName,
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: Helpers.validateName,
                              ),
                              const SizedBox(height: 16),

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: AppStrings.email,
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: Helpers.validateEmail,
                              ),
                              const SizedBox(height: 16),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: AppStrings.password,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: Helpers.validatePassword,
                              ),
                              const SizedBox(height: 16),

                              // Confirm Password Field
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: AppStrings.confirmPassword,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) => Helpers.validateConfirmPassword(
                                  value,
                                  _passwordController.text,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Company Dropdown
                              BlocBuilder<CompanyBloc, CompanyState>(
                                builder: (context, companyState) {
                                  if (companyState.status == CompanyStateStatus.loading ||
                                      companyState.status == CompanyStateStatus.initial) {
                                    return const InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Select Company',
                                        prefixIcon: Icon(Icons.business_outlined),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Loading companies...'),
                                        ],
                                      ),
                                    );
                                  }
                                  
                                  if (companyState.status == CompanyStateStatus.error) {
                                    return InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Select Company',
                                        prefixIcon: Icon(Icons.business_outlined),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  'Error loading companies',
                                                  style: TextStyle(color: Colors.red),
                                                ),
                                                const SizedBox(height: 4),
                                                GestureDetector(
                                                  onTap: () => context.read<CompanyBloc>().add(CompanyLoadAll()),
                                                  child: Text(
                                                    'Tap to retry',
                                                    style: TextStyle(
                                                      color: Colors.blue.shade700,
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  
                                  if (companyState.companies.isEmpty) {
                                    return InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Select Company',
                                        prefixIcon: Icon(Icons.business_outlined),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Text(
                                              'No companies available. Please contact admin.',
                                              style: TextStyle(color: Colors.grey),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  
                                  return DropdownButtonFormField<String>(
                                    value: _selectedCompanyId,
                                    decoration: const InputDecoration(
                                      labelText: AppStrings.selectCompany,
                                      prefixIcon: Icon(Icons.business_outlined),
                                    ),
                                    items: companyState.companies.map((company) {
                                      return DropdownMenuItem(
                                        value: company.id,
                                        child: Text(company.companyName),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCompanyId = value;
                                        final company = companyState.companies
                                            .firstWhere((c) => c.id == value);
                                        _selectedCompanyName = company.companyName;
                                        _selectedCorpId = company.corpId;
                                      });
                                      // Load supervisors for the selected company
                                      if (value != null) {
                                        _loadSupervisors(value);
                                      }
                                    },
                                    validator: (value) =>
                                        value == null ? 'Please select a company' : null,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Corp ID Dropdown
                              BlocBuilder<CompanyBloc, CompanyState>(
                                builder: (context, companyState) {
                                  if (companyState.status == CompanyStateStatus.loading || 
                                      companyState.corpIds.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  return DropdownButtonFormField<String>(
                                    value: _selectedCorpId,
                                    decoration: const InputDecoration(
                                      labelText: AppStrings.selectCorpId,
                                      prefixIcon: Icon(Icons.tag),
                                    ),
                                    items: companyState.corpIds.map((corpId) {
                                      return DropdownMenuItem(
                                        value: corpId,
                                        child: Text(corpId),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCorpId = value;
                                      });
                                    },
                                    validator: (value) =>
                                        value == null ? 'Please select a Corp ID' : null,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Admin Switch
                              SwitchListTile(
                                title: const Text(AppStrings.isAdmin),
                                subtitle: const Text('Enable admin privileges'),
                                value: _isAdmin,
                                onChanged: (value) {
                                  setState(() {
                                    _isAdmin = value;
                                    if (value) {
                                      _isSupervisor = false;
                                      _selectedSupervisorId = null;
                                    }
                                  });
                                },
                                activeColor: AppTheme.primaryColor,
                              ),

                              // Supervisor Switch
                              SwitchListTile(
                                title: const Text(AppStrings.isSupervisor),
                                subtitle: const Text('Enable supervisor privileges'),
                                value: _isSupervisor,
                                onChanged: _isAdmin
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _isSupervisor = value;
                                          if (value) {
                                            _selectedSupervisorId = null;
                                          }
                                        });
                                      },
                                activeColor: AppTheme.primaryColor,
                              ),
                              
                              // Supervisor Selection (for regular employees only)
                              if (!_isAdmin && !_isSupervisor && _selectedCompanyId != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    Text(
                                      'Select Your Supervisor',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    _isLoadingSupervisors
                                        ? const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child: CircularProgressIndicator(),
                                            ),
                                          )
                                        : _supervisors.isEmpty
                                            ? Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.orange.shade200),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        'No supervisors available for this company. You can register without selecting a supervisor.',
                                                        style: TextStyle(color: Colors.orange.shade800),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : DropdownButtonFormField<String>(
                                                value: _selectedSupervisorId,
                                                decoration: const InputDecoration(
                                                  labelText: 'Supervisor',
                                                  prefixIcon: Icon(Icons.supervisor_account),
                                                ),
                                                items: _supervisors.map((supervisor) {
                                                  return DropdownMenuItem(
                                                    value: supervisor['id'] as String,
                                                    child: Text(supervisor['name'] as String),
                                                  );
                                                }).toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedSupervisorId = value;
                                                  });
                                                },
                                                validator: (value) => 
                                                    _supervisors.isNotEmpty && value == null 
                                                        ? 'Please select your supervisor' 
                                                        : null,
                                              ),
                                  ],
                                ),
                              
                              const SizedBox(height: 24),

                              // Register Button
                              SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: authState.status == AuthStatus.loading
                                      ? null
                                      : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: authState.status == AuthStatus.loading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          AppStrings.register,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              AppStrings.login,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
