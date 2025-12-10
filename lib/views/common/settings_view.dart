import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Account'),
          _buildSettingItem(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () {},
          ),
          _buildSettingItem(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () {},
          ),
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Preferences'),
          _buildSettingItem(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            trailing: Switch(
              value: false,
              onChanged: (value) {},
            ),
          ),
          _buildSettingItem(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'English',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Support'),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {},
          ),
          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _buildSettingItem(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {},
          ),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _buildSettingItem(
            icon: Icons.logout,
            title: 'Sign Out',
            textColor: AppColors.error,
            onTap: () {
              // Handle sign out
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? AppColors.textPrimaryLight,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          color: textColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTextStyles.bodySmall,
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(
                  Icons.chevron_right,
                  color: AppColors.grey400,
                )
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
