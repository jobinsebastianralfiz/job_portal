import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/application_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../models/job_model.dart';
import '../../models/application_model.dart';
import '../widgets/job_card.dart';
import 'post_job_view.dart';
import 'my_jobs_view.dart';
import 'provider_applicants_view.dart';
import 'company_profile_view.dart';
import 'provider_profile_view.dart';
import 'job_applicants_view.dart';
import 'subscription_plans_view.dart';

class ProviderMainView extends StatefulWidget {
  const ProviderMainView({super.key});

  @override
  State<ProviderMainView> createState() => _ProviderMainViewState();
}

class _ProviderMainViewState extends State<ProviderMainView> {
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

    final authProvider = context.read<AuthProvider>();
    final jobProvider = context.read<JobProvider>();
    final applicationProvider = context.read<ApplicationProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();

    if (authProvider.currentUser != null) {
      final userId = authProvider.currentUser!.userId;
      jobProvider.loadMyJobs(userId);
      applicationProvider.loadProviderApplications(userId);
      subscriptionProvider.loadCurrentSubscription(userId);
    }
  }

  void _showCannotPostDialog(BuildContext context, String? status) {
    String title;
    String message;
    String? actionLabel;
    VoidCallback? action;

    switch (status) {
      case 'pending_approval':
        title = 'Pending Approval';
        message = 'Your account is pending admin approval. You\'ll be notified once approved.';
        break;
      case 'approved':
        title = 'Subscription Required';
        message = 'Your account is approved! Please select a subscription plan to start posting jobs.';
        actionLabel = 'View Plans';
        action = () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionPlansView()),
          );
        };
        break;
      case 'rejected':
        title = 'Account Rejected';
        message = 'Your provider account was rejected. Please contact support for more information.';
        break;
      case 'suspended':
        title = 'Account Suspended';
        message = 'Your account has been suspended. Please contact support.';
        break;
      default:
        title = 'Cannot Post Jobs';
        message = 'Your account is not authorized to post jobs at this time.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              status == 'pending_approval'
                  ? Icons.hourglass_empty
                  : status == 'approved'
                      ? Icons.card_membership
                      : Icons.warning,
              color: status == 'approved' ? AppColors.primary : AppColors.warning,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (actionLabel != null && action != null)
            ElevatedButton(
              onPressed: action,
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _ProviderDashboard(),
      const MyJobsView(),
      const ProviderApplicantsView(),
      const CompanyProfileView(),
      const ProviderProfileView(),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'My Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Applicants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_outlined),
            activeIcon: Icon(Icons.business),
            label: 'Company',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          final canPost = user?.canPostJobs ?? false;

          return FloatingActionButton.extended(
            onPressed: () {
              if (!canPost) {
                _showCannotPostDialog(context, user?.providerStatus);
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostJobView()),
              ).then((_) => _loadData());
            },
            icon: Icon(canPost ? Icons.add : Icons.lock),
            label: const Text('Post Job'),
            backgroundColor: canPost ? AppColors.primary : AppColors.grey500,
          );
        },
      ),
    );
  }
}

class _ProviderDashboard extends StatelessWidget {
  const _ProviderDashboard();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final jobProvider = context.watch<JobProvider>();
    final applicationProvider = context.watch<ApplicationProvider>();
    final user = authProvider.currentUser;

    final activeJobs = jobProvider.myJobs.where((j) => j.isActive).length;
    final pendingApps = applicationProvider.applications.where((a) => a.isPending).length;
    final interviewApps = applicationProvider.applications.where((a) => a.isInterview).length;
    final acceptedApps = applicationProvider.applications.where((a) => a.isAccepted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (authProvider.currentUser != null) {
            jobProvider.loadMyJobs(authProvider.currentUser!.userId);
            applicationProvider.loadProviderApplications(authProvider.currentUser!.userId);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Banner
              if (user != null && !user.canPostJobs)
                _buildStatusBanner(context, user.providerStatus),

              // Welcome Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${authProvider.currentUser?.firstName ?? 'Employer'}!',
                      style: AppTextStyles.h5.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find the perfect candidates for your open positions',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Active Jobs',
                      value: activeJobs.toString(),
                      icon: Icons.work,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'New Applications',
                      value: pendingApps.toString(),
                      icon: Icons.description,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Interviews',
                      value: interviewApps.toString(),
                      icon: Icons.video_call,
                      color: AppColors.statusInterview,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Hired',
                      value: acceptedApps.toString(),
                      icon: Icons.check_circle,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Applications Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Applications', style: AppTextStyles.h6),
                  TextButton(
                    onPressed: () {
                      // Navigate to applicants tab
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (applicationProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (applicationProvider.applications.isEmpty)
                _buildEmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No applications yet',
                  subtitle: 'Applications will appear here once candidates apply',
                )
              else
                ...applicationProvider.applications.take(5).map((app) {
                  return _ApplicationListItem(
                    application: app,
                    onTap: () {
                      // Navigate to application details
                    },
                  );
                }),

              const SizedBox(height: 24),

              // Active Jobs Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Active Jobs', style: AppTextStyles.h6),
                  TextButton(
                    onPressed: () {
                      // Navigate to my jobs tab
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (jobProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (jobProvider.myJobs.isEmpty)
                _buildEmptyState(
                  icon: Icons.work_off_outlined,
                  title: 'No jobs posted yet',
                  subtitle: 'Post your first job to start receiving applications',
                )
              else
                ...jobProvider.myJobs.where((j) => j.isActive).take(3).map((job) {
                  return _JobListItem(
                    job: job,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobApplicantsView(job: job),
                        ),
                      );
                    },
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, String? status) {
    IconData icon;
    Color color;
    String title;
    String subtitle;
    String? actionLabel;
    VoidCallback? action;

    switch (status) {
      case 'pending_approval':
        icon = Icons.hourglass_empty;
        color = AppColors.warning;
        title = 'Account Pending Approval';
        subtitle = 'Your account is being reviewed by our team. You\'ll be notified once approved.';
        break;
      case 'approved':
        icon = Icons.card_membership;
        color = AppColors.primary;
        title = 'Select a Subscription Plan';
        subtitle = 'Your account is approved! Choose a plan to start posting jobs.';
        actionLabel = 'View Plans';
        action = () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionPlansView()),
          );
        };
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = AppColors.error;
        title = 'Account Rejected';
        subtitle = 'Your provider account was rejected. Contact support for assistance.';
        break;
      case 'suspended':
        icon = Icons.block;
        color = AppColors.error;
        title = 'Account Suspended';
        subtitle = 'Your account has been suspended. Contact support for more information.';
        break;
      default:
        icon = Icons.info_outline;
        color = AppColors.grey500;
        title = 'Setup Required';
        subtitle = 'Complete your account setup to start posting jobs.';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey600,
              ),
            ),
          ),
          if (actionLabel != null && action != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: ElevatedButton(
                onPressed: action,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                ),
                child: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.grey400),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.grey600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ApplicationListItem extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback onTap;

  const _ApplicationListItem({
    required this.application,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.grey100,
          backgroundImage: application.applicantImage != null
              ? NetworkImage(application.applicantImage!)
              : null,
          child: application.applicantImage == null
              ? Text(
                  application.applicantName.isNotEmpty
                      ? application.applicantName[0].toUpperCase()
                      : 'A',
                  style: AppTextStyles.labelLarge,
                )
              : null,
        ),
        title: Text(
          application.applicantName,
          style: AppTextStyles.labelLarge,
        ),
        subtitle: Text(
          'Applied for ${application.jobTitle}',
          style: AppTextStyles.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _StatusChip(status: application.status),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'pending':
        color = AppColors.statusPending;
        break;
      case 'reviewed':
        color = AppColors.statusReviewed;
        break;
      case 'shortlisted':
        color = AppColors.statusShortlisted;
        break;
      case 'interview':
        color = AppColors.statusInterview;
        break;
      case 'offered':
        color = AppColors.statusOffered;
        break;
      case 'accepted':
        color = AppColors.statusAccepted;
        break;
      case 'rejected':
        color = AppColors.statusRejected;
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

class _JobListItem extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const _JobListItem({
    required this.job,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          job.title,
          style: AppTextStyles.labelLarge,
        ),
        subtitle: Row(
          children: [
            Icon(Icons.people, size: 14, color: AppColors.grey500),
            const SizedBox(width: 4),
            Text(
              '${job.applications} applications',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(width: 12),
            Icon(Icons.visibility, size: 14, color: AppColors.grey500),
            const SizedBox(width: 4),
            Text(
              '${job.views} views',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
