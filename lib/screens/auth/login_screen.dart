import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/blocs.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _corpIdController = TextEditingController();
  bool _obscurePassword = true;
  String _authMethodsDescription = '';
  bool _isIOS = false;

  @override
  void initState() {
    super.initState();
    _isIOS = Platform.isIOS;
    _loadAuthMethods();
  }

  Future<void> _loadAuthMethods() async {
    final biometricService = BiometricService();
    final description = await biometricService.getAuthMethodsDescription();
    
    if (mounted) {
      setState(() {
        _authMethodsDescription = description;
      });
    }
  }

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

  void _faceIdLogin() {
    context.read<AuthBloc>().add(AuthFaceIdLoginRequested());
  }

  void _fingerprintLogin() {
    context.read<AuthBloc>().add(AuthFingerprintLoginRequested());
  }

  void _pinPatternLogin() {
    context.read<AuthBloc>().add(AuthPinPatternLoginRequested());
  }

  void _quickLogin() {
    context.read<AuthBloc>().add(AuthQuickLoginRequested());
  }

  String _getFaceIdButtonText() {
    // On Android, face unlock triggers the system BiometricPrompt
    // which may show face, fingerprint, or PIN/pattern options
    return _isIOS ? 'Face ID' : 'Face/Biometric';
  }

  String _getFingerprintButtonText() {
    return _isIOS ? 'Touch ID' : 'Fingerprint';
  }

  Widget _buildQuickLoginSection(AuthState state) {
    // Check if any quick login is enabled and device is locked (user has logged in before)
    final hasAnyQuickLogin = state.faceIdEnabled || 
                              state.fingerprintEnabled || 
                              state.pinPatternEnabled;
    
    if (!hasAnyQuickLogin || !state.hasCompletedFirstLogin) {
      return const SizedBox.shrink();
    }

    final List<Widget> buttons = [];
    
    // Face ID / Face Unlock button
    if (state.faceIdAvailable && state.faceIdEnabled) {
      buttons.add(
        _buildQuickLoginButton(
          icon: Icons.face,
          label: _getFaceIdButtonText(),
          onPressed: state.status == AuthStatus.loading ? null : _faceIdLogin,
          color: AppTheme.primaryColor,
        ),
      );
    }
    
    // Fingerprint / Touch ID button
    if (state.fingerprintAvailable && state.fingerprintEnabled) {
      buttons.add(
        _buildQuickLoginButton(
          icon: Icons.fingerprint,
          label: _getFingerprintButtonText(),
          onPressed: state.status == AuthStatus.loading ? null : _fingerprintLogin,
          color: AppTheme.secondaryColor,
        ),
      );
    }
    
    // PIN / Pattern button
    if (state.pinPatternAvailable && state.pinPatternEnabled) {
      buttons.add(
        _buildQuickLoginButton(
          icon: Icons.lock_outline,
          label: 'PIN/Pattern',
          onPressed: state.status == AuthStatus.loading ? null : _pinPatternLogin,
          color: AppTheme.accentColor,
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Quick Login',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        // Show welcome back message if device is locked to user
        if (state.lockedUserName != null && state.lockedUserName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Welcome back, ${state.lockedUserName}!',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: buttons,
        ),
      ],
    );
  }

  Widget _buildQuickLoginButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: 100,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          side: BorderSide(color: color.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
              Navigator.pushReplacementNamed(context, '/dashboard');
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
                      // Logo and Title
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fingerprint,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome back!',
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
                                AppStrings.login,
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
                                    backgroundColor: AppTheme.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: state.status == AuthStatus.loading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          AppStrings.login,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),

                              // Quick Login Section (Face ID / Touch ID / Fingerprint / PIN)
                              _buildQuickLoginSection(state),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: const Text(
                              AppStrings.register,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Admin Login Link
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/admin-login');
                        },
                        child: const Text(
                          'Admin Login',
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
