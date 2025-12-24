import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/blocs.dart';
import '../../utils/utils.dart';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _corpIdController = TextEditingController();
  final _branchController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _corpIdController.dispose();
    _branchController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      // First create the company
      context.read<CompanyBloc>().add(CompanyCreate(
            companyName: _companyNameController.text.trim(),
            corpId: _corpIdController.text.trim(),
            branch: _branchController.text.trim(),
            state: _stateController.text.trim(),
            city: _cityController.text.trim(),
            address: _addressController.text.trim(),
            createdBy: '', // Will be updated after user creation
            createdByName: _nameController.text.trim(),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<CompanyBloc, CompanyState>(
        listener: (context, companyState) {
          if (companyState.companies.isNotEmpty && !companyState.isCreating) {
            final company = companyState.companies.first;
            // Now register the admin user
            context.read<AuthBloc>().add(AuthRegisterRequested(
                  name: _nameController.text.trim(),
                  email: _emailController.text.trim(),
                  password: _passwordController.text,
                  companyId: company.id,
                  companyName: company.companyName,
                  corpId: company.corpId,
                  isAdmin: true,
                  isSupervisor: false,
                ));
          }
        },
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated) {
              Navigator.pushReplacementNamed(context, '/admin-dashboard');
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
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Header
                        const Icon(
                          Icons.admin_panel_settings,
                          size: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Admin Registration',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your organization and admin account',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white70,
                              ),
                          textAlign: TextAlign.center,
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
                                // Section: Personal Information
                                Text(
                                  'Personal Information',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: AppTheme.primaryColor,
                                      ),
                                ),
                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.fullName,
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: Helpers.validateName,
                                ),
                                const SizedBox(height: 16),

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
                                const SizedBox(height: 24),

                                // Section: Company Information
                                Text(
                                  'Company Information',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: AppTheme.primaryColor,
                                      ),
                                ),
                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _companyNameController,
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.companyName,
                                    prefixIcon: Icon(Icons.business_outlined),
                                  ),
                                  validator: (value) =>
                                      Helpers.validateRequired(value, 'Company name'),
                                ),
                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _corpIdController,
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.corpId,
                                    prefixIcon: Icon(Icons.tag),
                                  ),
                                  validator: (value) =>
                                      Helpers.validateRequired(value, 'Corp ID'),
                                ),
                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _branchController,
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.branch,
                                    prefixIcon: Icon(Icons.store_outlined),
                                  ),
                                  validator: (value) =>
                                      Helpers.validateRequired(value, 'Branch'),
                                ),
                                const SizedBox(height: 16),

                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _stateController,
                                        decoration: const InputDecoration(
                                          labelText: AppStrings.state,
                                          prefixIcon: Icon(Icons.map_outlined),
                                        ),
                                        validator: (value) =>
                                            Helpers.validateRequired(value, 'State'),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _cityController,
                                        decoration: const InputDecoration(
                                          labelText: AppStrings.city,
                                          prefixIcon: Icon(Icons.location_city),
                                        ),
                                        validator: (value) =>
                                            Helpers.validateRequired(value, 'City'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _addressController,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.address,
                                    prefixIcon: Icon(Icons.location_on_outlined),
                                  ),
                                  validator: (value) =>
                                      Helpers.validateRequired(value, 'Address'),
                                ),
                                const SizedBox(height: 24),

                                // Register Button
                                BlocBuilder<CompanyBloc, CompanyState>(
                                  builder: (context, companyState) {
                                    final isLoading = authState.status ==
                                            AuthStatus.loading ||
                                        companyState.isCreating;

                                    return SizedBox(
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: isLoading ? null : _register,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.accentColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: isLoading
                                            ? const CircularProgressIndicator(
                                                color: Colors.white,
                                              )
                                            : const Text(
                                                'Create Admin Account',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Back to Admin Login
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          label: const Text(
                            'Back to Admin Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
