import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/job_model.dart';
import '../../providers/admin_provider.dart';

class JobModerationView extends StatefulWidget {
  const JobModerationView({super.key});

  @override
  State<JobModerationView> createState() => _JobModerationViewState();
}

class _JobModerationViewState extends State<JobModerationView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Moderation'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'All (${adminProvider.jobs.length})'),
            Tab(text: 'Pending (${adminProvider.pendingJobs.length})'),
            Tab(text: 'Reported (${adminProvider.reportedJobs.length})'),
            Tab(
              text:
                  'Verifications (${adminProvider.pendingVerifications.length})',
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
                      hintText: 'Search jobs by title or company...',
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
                      adminProvider.setJobSearchQuery(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (value) {
                    adminProvider.setJobFilter(value);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'all', child: Text('All Jobs')),
                    const PopupMenuItem(value: 'active', child: Text('Active')),
                    const PopupMenuItem(value: 'pending', child: Text('Pending')),
                    const PopupMenuItem(value: 'closed', child: Text('Closed')),
                    const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
                  ],
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AllJobsTab(
                  jobs: adminProvider.jobs,
                  isLoading: adminProvider.isLoadingJobs,
                  onRefresh: () => adminProvider.loadJobs(),
                ),
                _PendingJobsTab(
                  jobs: adminProvider.pendingJobs,
                  onRefresh: () => adminProvider.loadPendingJobs(),
                ),
                _ReportedJobsTab(
                  jobs: adminProvider.reportedJobs,
                  onRefresh: () => adminProvider.loadReportedJobs(),
                ),
                _VerificationsTab(
                  verifications: adminProvider.pendingVerifications,
                  onRefresh: () => adminProvider.loadPendingVerifications(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllJobsTab extends StatelessWidget {
  final List<JobModel> jobs;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _AllJobsTab({
    required this.jobs,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (jobs.isEmpty) {
      return _buildEmptyState('No jobs found');
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          return _JobCard(
            job: jobs[index],
            showActions: true,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off_outlined, size: 64, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.h5.copyWith(color: AppColors.grey600),
          ),
        ],
      ),
    );
  }
}

class _PendingJobsTab extends StatelessWidget {
  final List<JobModel> jobs;
  final VoidCallback onRefresh;

  const _PendingJobsTab({
    required this.jobs,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              'No pending jobs',
              style: AppTextStyles.h5.copyWith(color: AppColors.grey600),
            ),
            const SizedBox(height: 8),
            Text(
              'All jobs have been reviewed',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          return _PendingJobCard(job: jobs[index]);
        },
      ),
    );
  }
}

class _ReportedJobsTab extends StatelessWidget {
  final List<JobModel> jobs;
  final VoidCallback onRefresh;

  const _ReportedJobsTab({
    required this.jobs,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 64, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              'No reported jobs',
              style: AppTextStyles.h5.copyWith(color: AppColors.grey600),
            ),
            const SizedBox(height: 8),
            Text(
              'All reports have been handled',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          return _ReportedJobCard(job: jobs[index]);
        },
      ),
    );
  }
}

class _VerificationsTab extends StatelessWidget {
  final List verifications;
  final VoidCallback onRefresh;

  const _VerificationsTab({
    required this.verifications,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (verifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_outlined, size: 64, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              'No pending verifications',
              style: AppTextStyles.h5.copyWith(color: AppColors.grey600),
            ),
            const SizedBox(height: 8),
            Text(
              'All company verifications are up to date',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: verifications.length,
        itemBuilder: (context, index) {
          return _VerificationCard(company: verifications[index]);
        },
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  final bool showActions;

  const _JobCard({
    required this.job,
    this.showActions = false,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.grey100,
                  backgroundImage:
                      job.companyLogo != null ? NetworkImage(job.companyLogo!) : null,
                  child: job.companyLogo == null
                      ? Text(
                          job.company[0].toUpperCase(),
                          style: AppTextStyles.h6,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title, style: AppTextStyles.labelLarge),
                      const SizedBox(height: 2),
                      Text(job.company, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                _JobStatusBadge(status: job.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.grey500),
                const SizedBox(width: 4),
                Text(job.location?.shortLocation ?? 'N/A', style: AppTextStyles.caption),
                const SizedBox(width: 16),
                Icon(Icons.work_outline, size: 16, color: AppColors.grey500),
                const SizedBox(width: 4),
                Text(job.employmentType, style: AppTextStyles.caption),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: AppColors.grey500),
                const SizedBox(width: 4),
                Text(_formatDate(job.createdAt), style: AppTextStyles.caption),
              ],
            ),
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View'),
                    onPressed: () => _showJobDetails(context),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.flag, size: 18, color: AppColors.warning),
                    label: const Text('Flag', style: TextStyle(color: AppColors.warning)),
                    onPressed: () => _flagJob(context),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                    label: const Text('Remove', style: TextStyle(color: AppColors.error)),
                    onPressed: () => _removeJob(context),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showJobDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _JobDetailsSheet(job: job),
    );
  }

  void _flagJob(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag Job'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for flagging',
            hintText: 'Enter reason...',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () async {
              final adminProvider = context.read<AdminProvider>();
              await adminProvider.flagJob(job.jobId, reasonController.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job flagged for review')),
                );
              }
            },
            child: const Text('Flag'),
          ),
        ],
      ),
    );
  }

  void _removeJob(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Job'),
        content: Text('Are you sure you want to remove "${job.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final adminProvider = context.read<AdminProvider>();
      await adminProvider.removeJob(job.jobId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job removed')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _PendingJobCard extends StatelessWidget {
  final JobModel job;

  const _PendingJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.warning.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pending, size: 16, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    'Pending Review',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.grey100,
                  child: Text(job.company[0].toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title, style: AppTextStyles.labelLarge),
                      Text(job.company, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              job.description,
              style: AppTextStyles.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectJob(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveJob(context),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _approveJob(BuildContext context) async {
    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.approveJob(job.jobId);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job approved and published'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _rejectJob(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Job'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Enter reason...',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final adminProvider = context.read<AdminProvider>();
              await adminProvider.rejectJob(job.jobId, reasonController.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job rejected')),
                );
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

class _ReportedJobCard extends StatelessWidget {
  final JobModel job;

  const _ReportedJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.error.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag, size: 16, color: AppColors.error),
                  const SizedBox(width: 4),
                  Text(
                    'Reported',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.grey100,
                  child: Text(job.company[0].toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title, style: AppTextStyles.labelLarge),
                      Text(job.company, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Report Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Reason',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.reportReason ?? 'No reason provided',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _clearReport(context),
                    child: const Text('Dismiss Report'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    onPressed: () => _removeJob(context),
                    child: const Text('Remove Job'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _clearReport(BuildContext context) async {
    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.clearJobReport(job.jobId);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report dismissed')),
      );
    }
  }

  void _removeJob(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Job'),
        content: Text('Are you sure you want to remove "${job.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final adminProvider = context.read<AdminProvider>();
      await adminProvider.removeJob(job.jobId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job removed')),
        );
      }
    }
  }
}

class _VerificationCard extends StatelessWidget {
  final dynamic company;

  const _VerificationCard({required this.company});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.info.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user, size: 16, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text(
                    'Verification Request',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.grey100,
                  backgroundImage:
                      company.logo != null ? NetworkImage(company.logo!) : null,
                  child: company.logo == null
                      ? Text(company.name[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(company.name, style: AppTextStyles.labelLarge),
                      Text(
                        company.industry ?? 'No industry specified',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (company.description != null)
              Text(
                company.description!,
                style: AppTextStyles.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectVerification(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _verifyCompany(context),
                    icon: const Icon(Icons.verified, size: 18),
                    label: const Text('Verify'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _verifyCompany(BuildContext context) async {
    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.verifyCompany(company.companyId);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company verified'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _rejectVerification(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Verification'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Enter reason...',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final adminProvider = context.read<AdminProvider>();
              await adminProvider.rejectCompanyVerification(
                company.companyId,
                reasonController.text,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verification rejected')),
                );
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

class _JobStatusBadge extends StatelessWidget {
  final String status;

  const _JobStatusBadge({required this.status});

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
      case 'closed':
        color = AppColors.grey500;
        break;
      case 'rejected':
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

class _JobDetailsSheet extends StatelessWidget {
  final JobModel job;

  const _JobDetailsSheet({required this.job});

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
                Text('Job Details', style: AppTextStyles.h5),
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
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.grey100,
                      backgroundImage: job.companyLogo != null
                          ? NetworkImage(job.companyLogo!)
                          : null,
                      child: job.companyLogo == null
                          ? Text(job.company[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job.title, style: AppTextStyles.h5),
                          Text(job.company, style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                    _JobStatusBadge(status: job.status),
                  ],
                ),
                const SizedBox(height: 24),

                // Job Info
                _DetailRow(label: 'Location', value: job.location?.shortLocation ?? 'N/A'),
                _DetailRow(label: 'Employment Type', value: job.employmentType),
                _DetailRow(label: 'Work Location', value: job.workLocation),
                if (job.salaryMin != null && job.salaryMax != null)
                  _DetailRow(
                    label: 'Salary Range',
                    value: '\$${job.salaryMin} - \$${job.salaryMax}',
                  ),
                _DetailRow(
                  label: 'Posted',
                  value: _formatDate(job.createdAt),
                ),
                const SizedBox(height: 16),

                // Description
                Text('Description', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                Text(job.description, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 16),

                // Requirements
                if (job.requirements.isNotEmpty) ...[
                  Text('Requirements', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  ...job.requirements.map((req) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(req)),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}
