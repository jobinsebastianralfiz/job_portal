import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import 'admin_dashboard_view.dart';
import 'user_management_view.dart';
import 'job_moderation_view.dart';
import 'admin_settings_view.dart';
import 'provider_approvals_view.dart';

class AdminMainView extends StatefulWidget {
  const AdminMainView({super.key});

  @override
  State<AdminMainView> createState() => _AdminMainViewState();
}

class _AdminMainViewState extends State<AdminMainView> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Schedule the data loading after the first frame to avoid calling
    // notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    if (!mounted) return;

    final adminProvider = context.read<AdminProvider>();
    adminProvider.loadDashboardStats();
    adminProvider.loadUsers();
    adminProvider.loadJobs();
    adminProvider.loadPendingJobs();
    adminProvider.loadReportedJobs();
    adminProvider.loadPendingVerifications();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const AdminDashboardView(),
      const ProviderApprovalsView(),
      const UserManagementView(),
      const JobModerationView(),
      const AdminSettingsView(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey500,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _hasPendingProviders,
              child: const Icon(Icons.verified_user_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: _hasPendingProviders,
              child: const Icon(Icons.verified_user),
            ),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _hasPendingUsers,
              child: const Icon(Icons.people_outline),
            ),
            activeIcon: Badge(
              isLabelVisible: _hasPendingUsers,
              child: const Icon(Icons.people),
            ),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _hasPendingJobs,
              child: const Icon(Icons.work_outline),
            ),
            activeIcon: Badge(
              isLabelVisible: _hasPendingJobs,
              child: const Icon(Icons.work),
            ),
            label: 'Jobs',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  bool get _hasPendingProviders {
    final adminProvider = context.watch<AdminProvider>();
    return adminProvider.pendingVerifications.isNotEmpty;
  }

  bool get _hasPendingUsers {
    final adminProvider = context.watch<AdminProvider>();
    return adminProvider.users.any((u) => !u.isActive);
  }

  bool get _hasPendingJobs {
    final adminProvider = context.watch<AdminProvider>();
    return adminProvider.pendingJobs.isNotEmpty ||
           adminProvider.reportedJobs.isNotEmpty;
  }
}
