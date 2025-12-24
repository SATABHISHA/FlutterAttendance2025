import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/blocs.dart';
import '../../utils/utils.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _corpIdController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _corpIdController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthLoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            corpId: _corpIdController.text.trim(),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            if (state.user!.isAdmin) {
              Navigator.pushReplacementNamed(context, '/admin-dashboard');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This account does not have admin privileges'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
              context.read<AuthBloc>().add(AuthLogoutRequested());
            }
          } else if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Login failed'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
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
                      // Admin Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Admin Portal',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to manage your organization',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 48),

                      // Login Form
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
                              Text(
                                'Admin Login',
                                style: Theme.of(context).textTheme.headlineMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              // Corp ID Field
                              TextFormField(
                                controller: _corpIdController,
                                decoration: const InputDecoration(
                                  labelText: AppStrings.corpId,
                                  prefixIcon: Icon(Icons.business),
                                ),
                                validator: (value) =>
                                    Helpers.validateRequired(value, 'Corp ID'),
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
                              const SizedBox(height: 24),

                              // Login Button
                              SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed:
                                      state.status == AuthStatus.loading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: state.status == AuthStatus.loading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          'Admin Login',
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

                      // Back to User Login
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        label: const Text(
                          'Back to User Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Admin Registration Link
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/admin-register');
                        },
                        child: const Text(
                          'Register as Admin',
                          style: TextStyle(
                            color: Colors.white70,
                            decoration: TextDecoration.underline,
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
    );
  }
}
