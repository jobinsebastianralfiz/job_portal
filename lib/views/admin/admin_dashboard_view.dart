import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  // Generate labels for last 7 days (6 days ago to today)
  List<String> _getLast7DaysLabels() {
    final now = DateTime.now();
    // DateTime.weekday: 1=Mon, 2=Tue, ..., 7=Sun
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final labels = <String>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      labels.add(dayNames[day.weekday - 1]);
    }

    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final authProvider = context.watch<AuthProvider>();
    final stats = adminProvider.dashboardStats;
    final weeklyStats = adminProvider.weeklyStats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => adminProvider.loadDashboardStats(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => adminProvider.loadDashboardStats(),
        child: adminProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: const Icon(
                                  Icons.admin_panel_settings,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Welcome, Admin',
                                style: AppTextStyles.h5.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Manage your job portal platform',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Main Stats
                    Text('Overview', style: AppTextStyles.h6),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
                      children: [
                        _StatCard(
                          title: 'Total Users',
                          value: (stats['totalUsers'] ?? 0).toString(),
                          icon: Icons.people,
                          color: AppColors.primary,
                          trend: '+${stats['newUsersToday'] ?? 0} today',
                        ),
                        _StatCard(
                          title: 'Job Seekers',
                          value: (stats['jobSeekers'] ?? 0).toString(),
                          icon: Icons.person_search,
                          color: AppColors.jobSeekerColor,
                        ),
                        _StatCard(
                          title: 'Employers',
                          value: (stats['jobProviders'] ?? 0).toString(),
                          icon: Icons.business,
                          color: AppColors.jobProviderColor,
                        ),
                        _StatCard(
                          title: 'Total Jobs',
                          value: (stats['totalJobs'] ?? 0).toString(),
                          icon: Icons.work,
                          color: AppColors.secondary,
                          trend: '${stats['activeJobs'] ?? 0} active',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
                      children: [
                        _StatCard(
                          title: 'Applications',
                          value: (stats['totalApplications'] ?? 0).toString(),
                          icon: Icons.description,
                          color: AppColors.accent,
                          trend: '${stats['pendingApplications'] ?? 0} pending',
                        ),
                        _StatCard(
                          title: 'Companies',
                          value: (stats['totalCompanies'] ?? 0).toString(),
                          icon: Icons.business_center,
                          color: AppColors.success,
                          trend: '${stats['verifiedCompanies'] ?? 0} verified',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Pending Actions
                    Text('Pending Actions', style: AppTextStyles.h6),
                    const SizedBox(height: 12),
                    _ActionCard(
                      title: 'Jobs Pending Review',
                      count: stats['pendingJobs'] ?? 0,
                      icon: Icons.pending_actions,
                      color: AppColors.warning,
                      onTap: () {
                        // Navigate to pending jobs
                      },
                    ),
                    const SizedBox(height: 8),
                    _ActionCard(
                      title: 'Company Verifications',
                      count: adminProvider.pendingVerifications.length,
                      icon: Icons.verified_user,
                      color: AppColors.info,
                      onTap: () {
                        // Navigate to verifications
                      },
                    ),
                    const SizedBox(height: 8),
                    _ActionCard(
                      title: 'Reported Content',
                      count: adminProvider.reportedJobs.length,
                      icon: Icons.flag,
                      color: AppColors.error,
                      onTap: () {
                        // Navigate to reports
                      },
                    ),
                    const SizedBox(height: 24),

                    // Weekly Activity Chart
                    Text('Weekly Activity', style: AppTextStyles.h6),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _LegendItem(
                                color: AppColors.primary,
                                label: 'Users',
                              ),
                              _LegendItem(
                                color: AppColors.secondary,
                                label: 'Jobs',
                              ),
                              _LegendItem(
                                color: AppColors.accent,
                                label: 'Applications',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 120,
                            child: _SimpleBarChart(weeklyStats: weeklyStats),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _getLast7DaysLabels()
                                .map((day) => Text(
                                      day,
                                      style: AppTextStyles.caption,
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Recent Activity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Activity', style: AppTextStyles.h6),
                        TextButton(
                          onPressed: () {},
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (adminProvider.recentActivity.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 48,
                              color: AppColors.grey400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No recent activity',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...adminProvider.recentActivity.take(5).map((activity) {
                        return _ActivityItem(activity: activity);
                      }),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (trend != null)
                Text(
                  trend!,
                  style: AppTextStyles.caption.copyWith(color: color),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: count > 0 ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: count > 0 ? color.withOpacity(0.1) : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: count > 0 ? color.withOpacity(0.3) : AppColors.grey200,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: count > 0 ? color : AppColors.grey400),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  color: count > 0 ? color : AppColors.grey500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: count > 0 ? color : AppColors.grey300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count.toString(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final Map<String, List<int>> weeklyStats;

  const _SimpleBarChart({required this.weeklyStats});

  @override
  Widget build(BuildContext context) {
    final users = weeklyStats['users'] ?? List.filled(7, 0);
    final jobs = weeklyStats['jobs'] ?? List.filled(7, 0);
    final applications = weeklyStats['applications'] ?? List.filled(7, 0);

    final maxValue = [
      ...users,
      ...jobs,
      ...applications,
    ].fold<int>(1, (a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Bar(
                  height: (users[index] / maxValue) * 80,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 2),
                _Bar(
                  height: (jobs[index] / maxValue) * 80,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 2),
                _Bar(
                  height: (applications[index] / maxValue) * 80,
                  color: AppColors.accent,
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;

  const _Bar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: height > 0 ? height : 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final type = activity['type'] as String;
    final data = activity['data'] as Map<String, dynamic>;
    final timestamp = DateTime.parse(activity['timestamp']);

    IconData icon;
    Color color;
    String title;
    String subtitle;

    switch (type) {
      case 'user_registered':
        icon = Icons.person_add;
        color = AppColors.primary;
        title = 'New user registered';
        subtitle = data['email'] ?? 'Unknown user';
        break;
      case 'job_posted':
        icon = Icons.work;
        color = AppColors.secondary;
        title = 'Job posted';
        subtitle = data['title'] ?? 'Unknown job';
        break;
      case 'application_submitted':
        icon = Icons.description;
        color = AppColors.accent;
        title = 'Application submitted';
        subtitle = 'For ${data['jobTitle'] ?? 'Unknown job'}';
        break;
      default:
        icon = Icons.info;
        color = AppColors.grey500;
        title = 'Activity';
        subtitle = 'Unknown activity';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelMedium),
                Text(
                  subtitle,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            _getTimeAgo(timestamp),
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
