import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import 'post_job_view.dart';
import 'job_applicants_view.dart';

class MyJobsView extends StatefulWidget {
  const MyJobsView({super.key});

  @override
  State<MyJobsView> createState() => _MyJobsViewState();
}

class _MyJobsViewState extends State<MyJobsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<JobModel> _filterJobs(List<JobModel> jobs, int tabIndex) {
    switch (tabIndex) {
      case 0:
        return jobs.where((j) => j.isActive).toList();
      case 1:
        return jobs.where((j) => j.isDraft).toList();
      case 2:
        return jobs.where((j) => j.isClosed).toList();
      default:
        return jobs;
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              text: 'Active (${jobProvider.myJobs.where((j) => j.isActive).length})',
            ),
            Tab(
              text: 'Draft (${jobProvider.myJobs.where((j) => j.isDraft).length})',
            ),
            Tab(
              text: 'Closed (${jobProvider.myJobs.where((j) => j.isClosed).length})',
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (authProvider.currentUser != null) {
            await jobProvider.loadMyJobs(authProvider.currentUser!.userId);
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: List.generate(3, (tabIndex) {
            final filteredJobs = _filterJobs(jobProvider.myJobs, tabIndex);

            if (jobProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (filteredJobs.isEmpty) {
              return _buildEmptyState(tabIndex);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredJobs.length,
              itemBuilder: (context, index) {
                return _JobCard(
                  job: filteredJobs[index],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobApplicantsView(job: filteredJobs[index]),
                    ),
                  ),
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostJobView(existingJob: filteredJobs[index]),
                    ),
                  ).then((_) {
                    if (authProvider.currentUser != null) {
                      jobProvider.loadMyJobs(authProvider.currentUser!.userId);
                    }
                  }),
                  onStatusChange: (status) =>
                      _changeJobStatus(filteredJobs[index], status),
                  onDelete: () => _confirmDelete(filteredJobs[index]),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmptyState(int tabIndex) {
    String title;
    String subtitle;
    IconData icon;

    switch (tabIndex) {
      case 0:
        icon = Icons.work_off_outlined;
        title = 'No active jobs';
        subtitle = 'Post a job to start receiving applications';
        break;
      case 1:
        icon = Icons.drafts_outlined;
        title = 'No draft jobs';
        subtitle = 'Save jobs as drafts to publish later';
        break;
      case 2:
        icon = Icons.archive_outlined;
        title = 'No closed jobs';
        subtitle = 'Closed jobs will appear here';
        break;
      default:
        icon = Icons.work_off_outlined;
        title = 'No jobs';
        subtitle = '';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.h5.copyWith(color: AppColors.grey600),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
          ),
        ],
      ),
    );
  }

  void _changeJobStatus(JobModel job, String status) async {
    final jobProvider = context.read<JobProvider>();

    final updates = {'status': status};
    if (status == 'active') {
      updates['publishedAt'] = DateTime.now().toIso8601String();
    }

    final success = await jobProvider.updateJob(job.jobId, updates);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Job ${status == 'active' ? 'published' : status}'),
          backgroundColor: AppColors.success,
        ),
      );

      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null) {
        jobProvider.loadMyJobs(authProvider.currentUser!.userId);
      }
    }
  }

  void _confirmDelete(JobModel job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job?'),
        content: Text('Are you sure you want to delete "${job.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<JobProvider>().deleteJob(job.jobId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final Function(String) onStatusChange;
  final VoidCallback onDelete;

  const _JobCard({
    required this.job,
    required this.onTap,
    required this.onEdit,
    required this.onStatusChange,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.title, style: AppTextStyles.h6),
                        const SizedBox(height: 4),
                        Text(
                          '${job.employmentType} - ${job.workLocation}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: job.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Stats Row
              Row(
                children: [
                  _StatItem(
                    icon: Icons.visibility,
                    value: job.views.toString(),
                    label: 'Views',
                  ),
                  const SizedBox(width: 24),
                  _StatItem(
                    icon: Icons.people,
                    value: job.applications.toString(),
                    label: 'Applications',
                  ),
                  const SizedBox(width: 24),
                  _StatItem(
                    icon: Icons.bookmark,
                    value: job.saves.toString(),
                    label: 'Saved',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    onPressed: onEdit,
                  ),
                  if (job.isDraft)
                    TextButton.icon(
                      icon: const Icon(Icons.publish, size: 18),
                      label: const Text('Publish'),
                      onPressed: () => onStatusChange('active'),
                    )
                  else if (job.isActive)
                    TextButton.icon(
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Close'),
                      onPressed: () => onStatusChange('closed'),
                    )
                  else if (job.isClosed)
                    TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reopen'),
                      onPressed: () => onStatusChange('active'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
        color = AppColors.jobActive;
        break;
      case 'draft':
        color = AppColors.jobDraft;
        break;
      case 'closed':
        color = AppColors.jobClosed;
        break;
      default:
        color = AppColors.grey500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey500),
        const SizedBox(width: 4),
        Text(value, style: AppTextStyles.labelLarge),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
