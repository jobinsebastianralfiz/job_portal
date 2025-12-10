import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/firebase/storage_service.dart';
import '../../services/firebase/user_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'subscription_plans_view.dart';

class ProviderProfileView extends StatefulWidget {
  const ProviderProfileView({super.key});

  @override
  State<ProviderProfileView> createState() => _ProviderProfileViewState();
}

class _ProviderProfileViewState extends State<ProviderProfileView> {
  bool _isUploadingImage = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.grey200,
                        backgroundImage: user?.profileImage != null
                            ? NetworkImage(user!.profileImage!)
                            : null,
                        child: user?.profileImage == null
                            ? Text(
                                user?.initials ?? 'U',
                                style: AppTextStyles.h3,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingImage ? null : _changeProfileImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: _isUploadingImage
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.fullName ?? 'User',
                    style: AppTextStyles.h5,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Job Provider',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Subscription Section
            _buildSectionHeader('Subscription'),
            const SizedBox(height: 12),
            _buildSubscriptionCard(context),
            const SizedBox(height: 24),

            // Account Settings Section
            _buildSectionHeader('Account Settings'),
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: Icons.person_outline,
              title: 'Personal Information',
              subtitle: 'Update your name and contact info',
              onTap: () => _showEditPersonalInfoSheet(context),
            ),
            _buildSettingsTile(
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your password',
              onTap: () => _showChangePasswordDialog(context),
            ),
            const SizedBox(height: 24),

            // App Settings Section
            _buildSectionHeader('App Settings'),
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Manage notification preferences',
              onTap: () {
                // Navigate to notifications settings
              },
            ),
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help or contact support',
              onTap: () {
                // Navigate to help
              },
            ),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'App version and info',
              onTap: () {
                _showAboutDialog(context);
              },
            ),
            const SizedBox(height: 32),

            // Logout Button
            CustomButton(
              text: 'Logout',
              onPressed: () => _showLogoutDialog(context),
              width: double.infinity,
              backgroundColor: AppColors.error,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextStyles.h6,
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();

    final hasSubscription = subscriptionProvider.hasActiveSubscription;
    final currentPlan = subscriptionProvider.currentPlan;
    final subscription = subscriptionProvider.currentSubscription;
    final remainingJobs = subscriptionProvider.remainingJobPosts;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasSubscription ? AppColors.primary : AppColors.grey200,
        ),
      ),
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
                    color: (hasSubscription ? AppColors.primary : AppColors.grey400)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.card_membership,
                    color: hasSubscription ? AppColors.primary : AppColors.grey500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasSubscription ? currentPlan.name : 'No Active Plan',
                        style: AppTextStyles.labelLarge,
                      ),
                      if (hasSubscription && subscription != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Expires: ${_formatDate(subscription.endDate)}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey600,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(
                          'Subscribe to post jobs',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasSubscription)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
            if (hasSubscription) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSubscriptionStat(
                    'Jobs Remaining',
                    currentPlan.jobPostsPerMonth == -1 ? 'Unlimited' : '$remainingJobs',
                  ),
                  _buildSubscriptionStat(
                    'AI Features',
                    currentPlan.hasAIFeatures ? 'Enabled' : 'Disabled',
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionPlansView(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasSubscription ? AppColors.grey100 : AppColors.primary,
                  foregroundColor: hasSubscription ? AppColors.grey700 : Colors.white,
                ),
                child: Text(hasSubscription ? 'Manage Subscription' : 'View Plans'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: AppTextStyles.labelLarge),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Future<void> _changeProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && mounted) {
      setState(() => _isUploadingImage = true);

      try {
        final authProvider = context.read<AuthProvider>();
        final user = authProvider.currentUser;
        if (user == null) return;

        final storageService = StorageService();
        final imageUrl = await storageService.uploadProfileImage(
          File(pickedFile.path),
          user.userId,
        );

        if (imageUrl != null) {
          final userService = UserService();
          await userService.updateProfile(
            userId: user.userId,
            profileImage: imageUrl,
          );
          await authProvider.refreshUserData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile image updated'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploadingImage = false);
        }
      }
    }
  }

  void _showEditPersonalInfoSheet(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);
    final phoneController = TextEditingController(text: user.phoneNumber);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Personal Info', style: AppTextStyles.h5),
              const SizedBox(height: 16),
              CustomTextField(
                controller: firstNameController,
                label: 'First Name',
                hintText: 'Enter first name',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: lastNameController,
                label: 'Last Name',
                hintText: 'Enter last name',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: phoneController,
                label: 'Phone',
                hintText: 'Enter phone number',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Save Changes',
                onPressed: () async {
                  final userService = UserService();
                  await userService.updateProfile(
                    userId: user.userId,
                    firstName: firstNameController.text,
                    lastName: lastNameController.text,
                    phone: phoneController.text,
                  );
                  if (context.mounted) {
                    context.read<AuthProvider>().refreshUserData();
                    Navigator.pop(context);
                  }
                },
                width: double.infinity,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text(
          'A password reset email will be sent to your registered email address.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              final email = authProvider.currentUser?.email;
              if (email != null) {
                await authProvider.resetPassword(email);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Job Portal'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('A modern job portal app connecting employers with talented candidates.'),
          ],
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  RouteConstants.login,
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
