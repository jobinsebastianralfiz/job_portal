import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../core/constants/app_constants.dart';
import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isCreatingAdmin = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    Helpers.dismissKeyboard(context);

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final user = authProvider.currentUser;
      if (user != null) {
        _navigateBasedOnRole(user.role);
      }
    } else {
      Helpers.showSnackBar(
        context,
        authProvider.error ?? 'Login failed',
        isError: true,
      );
    }
  }

  void _navigateBasedOnRole(String role) {
    String route;
    switch (role) {
      case AppConstants.roleJobSeeker:
        route = RouteConstants.seekerHome;
        break;
      case AppConstants.roleJobProvider:
        route = RouteConstants.providerHome;
        break;
      case AppConstants.roleAdmin:
        route = RouteConstants.adminDashboard;
        break;
      default:
        route = RouteConstants.seekerHome;
    }
    Navigator.pushReplacementNamed(context, route);
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();

    final result = await authProvider.signInWithGoogle();

    if (!mounted) return;

    if (result == 'new_user') {
      Navigator.pushNamed(context, RouteConstants.roleSelection);
    } else if (result == 'existing_user') {
      final user = authProvider.currentUser;
      if (user != null) {
        _navigateBasedOnRole(user.role);
      }
    } else {
      Helpers.showSnackBar(
        context,
        authProvider.error ?? 'Google sign in failed',
        isError: true,
      );
    }
  }

  // TEMPORARY: Create admin user for testing
  Future<void> _createAdminUser() async {
    setState(() => _isCreatingAdmin = true);

    try {
      const adminEmail = 'admin@jobportal.com';
      const adminPassword = 'Admin@123';

      // Create Firebase Auth user
      final credential = await firebase_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      if (credential.user != null) {
        // Create admin user in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'userId': credential.user!.uid,
          'email': adminEmail,
          'firstName': 'Admin',
          'lastName': 'User',
          'role': 'admin',
          'isVerified': true,
          'isActive': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        if (mounted) {
          Helpers.showSnackBar(
            context,
            'Admin created! Email: $adminEmail, Password: $adminPassword',
            isError: false,
          );
        }
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          e.code == 'email-already-in-use'
              ? 'Admin already exists! Use admin@jobportal.com / Admin@123'
              : 'Error: ${e.message}',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingAdmin = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      size: 40,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Welcome Text
                Text(
                  'Welcome Back!',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Email Field
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.grey500,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) => Validators.validateRequired(value, 'Password'),
                ),
                const SizedBox(height: 12),
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, RouteConstants.forgotPassword);
                    },
                    child: Text(
                      'Forgot Password?',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Login Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return CustomButton(
                      text: 'Sign In',
                      onPressed: _handleLogin,
                      isLoading: authProvider.isLoading,
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                // Google Sign In
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return CustomButton(
                      text: 'Continue with Google',
                      onPressed: _handleGoogleSignIn,
                      isOutlined: true,
                      icon: Icons.g_mobiledata,
                      isLoading: authProvider.isGoogleLoading,
                    );
                  },
                ),
                const SizedBox(height: 32),
                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, RouteConstants.register);
                      },
                      child: Text(
                        'Sign Up',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // TEMPORARY: Create Admin Button - Remove in production
                TextButton(
                  onPressed: _isCreatingAdmin ? null : _createAdminUser,
                  child: _isCreatingAdmin
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Create Admin User (Dev Only)',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey500,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
