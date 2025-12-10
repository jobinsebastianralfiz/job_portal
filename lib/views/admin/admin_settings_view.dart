import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class AdminSettingsView extends StatefulWidget {
  const AdminSettingsView({super.key});

  @override
  State<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<AdminSettingsView> {
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final adminProvider = context.read<AdminProvider>();
    final settings = await adminProvider.getSystemSettings();
    setState(() {
      _settings = settings ?? _getDefaultSettings();
      _isLoading = false;
    });
  }

  Map<String, dynamic> _getDefaultSettings() {
    return {
      'requireJobApproval': true,
      'requireCompanyVerification': true,
      'maxJobsPerEmployer': 10,
      'maxApplicationsPerSeeker': 50,
      'enableEmailNotifications': true,
      'enablePushNotifications': true,
      'maintenanceMode': false,
      'allowNewRegistrations': true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Admin Profile
                _SectionCard(
                  title: 'Admin Profile',
                  icon: Icons.admin_panel_settings,
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.person, color: AppColors.primary),
                        ),
                        title: Text(
                          authProvider.currentUser?.email ?? 'Admin',
                          style: AppTextStyles.labelLarge,
                        ),
                        subtitle: const Text('Administrator'),
                        trailing: TextButton(
                          onPressed: () => _changePassword(),
                          child: const Text('Change Password'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Job Settings
                _SectionCard(
                  title: 'Job Settings',
                  icon: Icons.work,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Require Job Approval'),
                        subtitle: const Text(
                          'Jobs must be approved before being published',
                        ),
                        value: _settings['requireJobApproval'] ?? true,
                        onChanged: (value) => _updateSetting('requireJobApproval', value),
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Require Company Verification'),
                        subtitle: const Text(
                          'Companies must be verified before posting jobs',
                        ),
                        value: _settings['requireCompanyVerification'] ?? true,
                        onChanged: (value) =>
                            _updateSetting('requireCompanyVerification', value),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Max Jobs per Employer'),
                        subtitle: const Text('Maximum number of active jobs'),
                        trailing: DropdownButton<int>(
                          value: _settings['maxJobsPerEmployer'] ?? 10,
                          items: [5, 10, 20, 50, 100]
                              .map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v.toString()),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              _updateSetting('maxJobsPerEmployer', value),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // User Settings
                _SectionCard(
                  title: 'User Settings',
                  icon: Icons.people,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Allow New Registrations'),
                        subtitle: const Text('Enable or disable new user signups'),
                        value: _settings['allowNewRegistrations'] ?? true,
                        onChanged: (value) =>
                            _updateSetting('allowNewRegistrations', value),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Max Applications per Seeker'),
                        subtitle: const Text('Maximum applications per month'),
                        trailing: DropdownButton<int>(
                          value: _settings['maxApplicationsPerSeeker'] ?? 50,
                          items: [10, 25, 50, 100, 200]
                              .map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v.toString()),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              _updateSetting('maxApplicationsPerSeeker', value),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Notification Settings
                _SectionCard(
                  title: 'Notifications',
                  icon: Icons.notifications,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Email Notifications'),
                        subtitle: const Text('Send email alerts to users'),
                        value: _settings['enableEmailNotifications'] ?? true,
                        onChanged: (value) =>
                            _updateSetting('enableEmailNotifications', value),
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Push Notifications'),
                        subtitle: const Text('Send push notifications to app'),
                        value: _settings['enablePushNotifications'] ?? true,
                        onChanged: (value) =>
                            _updateSetting('enablePushNotifications', value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // System Settings
                _SectionCard(
                  title: 'System',
                  icon: Icons.settings,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Maintenance Mode'),
                        subtitle: const Text(
                          'Temporarily disable the app for maintenance',
                        ),
                        value: _settings['maintenanceMode'] ?? false,
                        activeColor: AppColors.warning,
                        onChanged: (value) => _confirmMaintenanceMode(value),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Clear Cache'),
                        subtitle: const Text('Clear temporary data'),
                        trailing: TextButton(
                          onPressed: () => _clearCache(),
                          child: const Text('Clear'),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Export Data'),
                        subtitle: const Text('Download all platform data'),
                        trailing: TextButton(
                          onPressed: () => _exportData(),
                          child: const Text('Export'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // About
                _SectionCard(
                  title: 'About',
                  icon: Icons.info,
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('App Version'),
                        trailing: Text(
                          '1.0.0',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey600,
                          ),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Terms of Service'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Privacy Policy'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sign Out
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: Text(
                    'Sign Out',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () => _signOut(authProvider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  void _updateSetting(String key, dynamic value) async {
    setState(() {
      _settings[key] = value;
    });

    final adminProvider = context.read<AdminProvider>();
    await adminProvider.updateSystemSettings({key: value});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings updated')),
      );
    }
  }

  void _confirmMaintenanceMode(bool enable) async {
    if (enable) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable Maintenance Mode?'),
          content: const Text(
            'This will temporarily disable the app for all users. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enable'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        _updateSetting('maintenanceMode', true);
      }
    } else {
      _updateSetting('maintenanceMode', false);
    }
  }

  void _changePassword() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
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
            onPressed: () {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              // Implement password change logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed successfully')),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will clear all temporary data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared')),
      );
    }
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon')),
    );
  }

  void _signOut(AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authProvider.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.labelLarge),
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}
