import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final adminProvider = context.read<AdminProvider>();
      switch (_tabController.index) {
        case 0:
          adminProvider.setUserFilter('all');
          break;
        case 1:
          adminProvider.setUserFilter('job_seeker');
          break;
        case 2:
          adminProvider.setUserFilter('job_provider');
          break;
        case 3:
          adminProvider.setUserStatusFilter('suspended');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'All (${adminProvider.users.length})'),
            Tab(
              text:
                  'Seekers (${adminProvider.users.where((u) => u.role == 'job_seeker').length})',
            ),
            Tab(
              text:
                  'Employers (${adminProvider.users.where((u) => u.role == 'job_provider').length})',
            ),
            Tab(
              text:
                  'Inactive (${adminProvider.users.where((u) => !u.isActive).length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.grey200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.grey300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (value) {
                      adminProvider.setUserSearchQuery(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (value) {
                    adminProvider.setUserStatusFilter(value);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'all', child: Text('All Status')),
                    const PopupMenuItem(value: 'active', child: Text('Active')),
                    const PopupMenuItem(value: 'pending', child: Text('Pending')),
                    const PopupMenuItem(value: 'suspended', child: Text('Suspended')),
                  ],
                ),
              ],
            ),
          ),

          // User List
          Expanded(
            child: adminProvider.isLoadingUsers
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async => adminProvider.loadUsers(),
                    child: _buildUserList(adminProvider),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(AdminProvider adminProvider) {
    List<UserModel> users = adminProvider.users;

    // Filter based on tab
    switch (_tabController.index) {
      case 1:
        users = users.where((u) => u.role == 'job_seeker').toList();
        break;
      case 2:
        users = users.where((u) => u.role == 'job_provider').toList();
        break;
      case 3:
        users = users.where((u) => !u.isActive).toList();
        break;
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: AppTextStyles.h5.copyWith(color: AppColors.grey600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        return _UserCard(
          user: users[index],
          onTap: () => _showUserDetails(users[index]),
          onSuspend: () => _suspendUser(users[index]),
          onActivate: () => _activateUser(users[index]),
          onDelete: () => _deleteUser(users[index]),
        );
      },
    );
  }

  void _showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _UserDetailsSheet(user: user),
    );
  }

  void _suspendUser(UserModel user) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to suspend ${user.email}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for suspension',
                hintText: 'Enter reason...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a reason')),
                );
                return;
              }

              final adminProvider = context.read<AdminProvider>();
              final success = await adminProvider.suspendUser(
                user.userId,
                reasonController.text,
              );

              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User suspended'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _activateUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activate User'),
        content: Text('Are you sure you want to activate ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Activate'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final adminProvider = context.read<AdminProvider>();
      final success = await adminProvider.activateUser(user.userId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User activated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.email}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final adminProvider = context.read<AdminProvider>();
      final success = await adminProvider.deleteUser(user.userId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted')),
        );
      }
    }
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final VoidCallback onSuspend;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.onSuspend,
    required this.onActivate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _getRoleColor().withOpacity(0.1),
                    backgroundImage:
                        user.profileImage != null ? NetworkImage(user.profileImage!) : null,
                    child: user.profileImage == null
                        ? Text(
                            user.firstName?.isNotEmpty == true
                                ? user.firstName![0].toUpperCase()
                                : user.email[0].toUpperCase(),
                            style: AppTextStyles.h6.copyWith(
                              color: _getRoleColor(),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.firstName != null
                                    ? '${user.firstName} ${user.lastName ?? ''}'
                                    : user.email,
                                style: AppTextStyles.labelLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _StatusBadge(status: user.isActive ? 'active' : 'inactive'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.badge,
                    label: user.role == 'job_seeker' ? 'Job Seeker' : 'Employer',
                    color: _getRoleColor(),
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: _formatDate(user.createdAt),
                    color: AppColors.grey600,
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.grey500),
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          onTap();
                          break;
                        case 'suspend':
                          onSuspend();
                          break;
                        case 'activate':
                          onActivate();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 20),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      if (user.isActive)
                        const PopupMenuItem(
                          value: 'suspend',
                          child: Row(
                            children: [
                              Icon(Icons.block, size: 20, color: AppColors.warning),
                              SizedBox(width: 8),
                              Text('Suspend', style: TextStyle(color: AppColors.warning)),
                            ],
                          ),
                        )
                      else
                        const PopupMenuItem(
                          value: 'activate',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 20, color: AppColors.success),
                              SizedBox(width: 8),
                              Text('Activate', style: TextStyle(color: AppColors.success)),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor() {
    return user.role == 'job_seeker' ? AppColors.jobSeekerColor : AppColors.jobProviderColor;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'active':
        color = AppColors.success;
        break;
      case 'pending':
        color = AppColors.warning;
        break;
      case 'suspended':
        color = AppColors.error;
        break;
      default:
        color = AppColors.grey500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.overline.copyWith(color: color),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _UserDetailsSheet extends StatelessWidget {
  final UserModel user;

  const _UserDetailsSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.grey200)),
            ),
            child: Row(
              children: [
                Text('User Details', style: AppTextStyles.h5),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.grey100,
                        backgroundImage: user.profileImage != null
                            ? NetworkImage(user.profileImage!)
                            : null,
                        child: user.profileImage == null
                            ? Text(
                                user.firstName?.isNotEmpty == true
                                    ? user.firstName![0].toUpperCase()
                                    : user.email[0].toUpperCase(),
                                style: AppTextStyles.h3,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.firstName != null
                            ? '${user.firstName} ${user.lastName ?? ''}'
                            : 'No Name',
                        style: AppTextStyles.h5,
                      ),
                      const SizedBox(height: 4),
                      Text(user.email, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 8),
                      _StatusBadge(status: user.status ?? 'active'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // User Info
                _DetailSection(
                  title: 'Account Information',
                  children: [
                    _DetailRow(label: 'User ID', value: user.userId),
                    _DetailRow(
                      label: 'Role',
                      value: user.role == 'job_seeker' ? 'Job Seeker' : 'Employer',
                    ),
                    _DetailRow(
                      label: 'Email Verified',
                      value: user.isEmailVerified ? 'Yes' : 'No',
                    ),
                    _DetailRow(
                      label: 'Created At',
                      value: _formatDateTime(user.createdAt),
                    ),
                    _DetailRow(
                      label: 'Last Login',
                      value: user.lastLoginAt != null
                          ? _formatDateTime(user.lastLoginAt!)
                          : 'Never',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Contact Info
                _DetailSection(
                  title: 'Contact Information',
                  children: [
                    _DetailRow(
                      label: 'Phone',
                      value: user.phone ?? 'Not provided',
                    ),
                    _DetailRow(
                      label: 'Location',
                      value: user.location?.shortAddress ?? 'Not specified',
                    ),
                  ],
                ),

                if (user.status == 'suspended') ...[
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'Suspension Details',
                    children: [
                      _DetailRow(
                        label: 'Suspended At',
                        value: user.suspendedAt != null
                            ? _formatDateTime(user.suspendedAt!)
                            : 'Unknown',
                      ),
                      _DetailRow(
                        label: 'Reason',
                        value: user.suspensionReason ?? 'Not specified',
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Stats (if job seeker)
                if (user.role == 'job_seeker')
                  _DetailSection(
                    title: 'Activity Stats',
                    children: [
                      _DetailRow(
                        label: 'Applications',
                        value: '${user.applicationsCount ?? 0}',
                      ),
                      _DetailRow(
                        label: 'Saved Jobs',
                        value: '${user.savedJobs?.length ?? 0}',
                      ),
                    ],
                  ),

                if (user.role == 'job_provider')
                  _DetailSection(
                    title: 'Activity Stats',
                    children: [
                      _DetailRow(
                        label: 'Jobs Posted',
                        value: '${user.jobsPosted ?? 0}',
                      ),
                      _DetailRow(
                        label: 'Total Hires',
                        value: '${user.totalHires ?? 0}',
                      ),
                    ],
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.labelLarge),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
