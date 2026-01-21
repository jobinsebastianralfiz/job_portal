import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/application_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/application_provider.dart';
import 'application_details_view.dart';
import 'seeker_main_view.dart';

class ApplicationsView extends StatefulWidget {
  const ApplicationsView({super.key});

  @override
  State<ApplicationsView> createState() => _ApplicationsViewState();
}

class _ApplicationsViewState extends State<ApplicationsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['All', 'Pending', 'Interview', 'Offered', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ApplicationModel> _filterApplications(
    List<ApplicationModel> applications,
    String tab,
  ) {
    switch (tab) {
      case 'Pending':
        return applications
            .where((a) => a.status == 'pending' || a.status == 'reviewed')
            .toList();
      case 'Interview':
        return applications
            .where((a) => a.status == 'shortlisted' || a.status == 'interview')
            .toList();
      case 'Offered':
        return applications
            .where((a) => a.status == 'offered' || a.status == 'accepted')
            .toList();
      case 'Rejected':
        return applications
            .where((a) => a.status == 'rejected' || a.status == 'withdrawn')
            .toList();
      default:
        return applications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicationProvider = context.watch<ApplicationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final user = context.read<AuthProvider>().currentUser;
          if (user != null) {
            await applicationProvider.loadMyApplications(user.userId);
          }
        },
        child: applicationProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) {
                  final filteredApps = _filterApplications(
                    applicationProvider.applications,
                    tab,
                  );

                  if (filteredApps.isEmpty) {
                    return _buildEmptyState(tab);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredApps.length,
                    itemBuilder: (context, index) {
                      return _ApplicationCard(
                        application: filteredApps[index],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ApplicationDetailsView(
                              application: filteredApps[index],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _buildEmptyState(String tab) {
    IconData icon;
    String message;

    switch (tab) {
      case 'All':
        icon = Icons.work_outline;
        message = 'You haven\'t applied to any jobs yet';
        break;
      case 'Interview':
        icon = Icons.event_outlined;
        message = 'No interviews scheduled';
        break;
      case 'Offered':
        icon = Icons.card_giftcard;
        message = 'No offers received yet';
        break;
      case 'Rejected':
        icon = Icons.cancel_outlined;
        message = 'No rejections (that\'s good!)';
        break;
      default:
        icon = Icons.inbox_outlined;
        message = 'No applications in this category';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey500),
          ),
          if (tab == 'All') ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to search tab
                final state = context.findAncestorStateOfType<SeekerMainViewState>();
                state?.switchToTab(1);
              },
              child: const Text('Browse Jobs'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback onTap;

  const _ApplicationCard({
    required this.application,
    required this.onTap,
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
                  // Company Logo Placeholder
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        application.companyName.isNotEmpty
                            ? application.companyName[0].toUpperCase()
                            : 'C',
                        style: AppTextStyles.h5.copyWith(color: AppColors.grey500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.jobTitle,
                          style: AppTextStyles.h6,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          application.companyName,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: application.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.grey500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Applied ${_getTimeAgo(application.appliedAt)}',
                    style: AppTextStyles.caption,
                  ),
                  const Spacer(),
                  if (application.hasInterview) ...[
                    Icon(
                      Icons.event,
                      size: 16,
                      color: AppColors.statusInterview,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Interview scheduled',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.statusInterview,
                      ),
                    ),
                  ],
                ],
              ),
              // Progress Indicator
              const SizedBox(height: 12),
              _ApplicationProgress(status: application.status),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = AppColors.statusPending;
        text = 'Pending';
        break;
      case 'reviewed':
        color = AppColors.statusReviewed;
        text = 'Reviewed';
        break;
      case 'shortlisted':
        color = AppColors.statusShortlisted;
        text = 'Shortlisted';
        break;
      case 'interview':
        color = AppColors.statusInterview;
        text = 'Interview';
        break;
      case 'offered':
        color = AppColors.statusOffered;
        text = 'Offered';
        break;
      case 'accepted':
        color = AppColors.statusAccepted;
        text = 'Accepted';
        break;
      case 'rejected':
        color = AppColors.statusRejected;
        text = 'Rejected';
        break;
      case 'withdrawn':
        color = AppColors.statusWithdrawn;
        text = 'Withdrawn';
        break;
      default:
        color = AppColors.grey500;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ApplicationProgress extends StatelessWidget {
  final String status;

  const _ApplicationProgress({required this.status});

  int _getProgressIndex() {
    switch (status) {
      case 'pending':
        return 0;
      case 'reviewed':
        return 1;
      case 'shortlisted':
        return 2;
      case 'interview':
        return 3;
      case 'offered':
      case 'accepted':
        return 4;
      case 'rejected':
      case 'withdrawn':
        return -1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressIndex = _getProgressIndex();
    final steps = ['Applied', 'Reviewed', 'Shortlisted', 'Interview', 'Offer'];

    if (progressIndex == -1) {
      return const SizedBox.shrink(); // Don't show progress for rejected/withdrawn
    }

    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= progressIndex;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? AppColors.primary : AppColors.grey300,
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      )
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: index < progressIndex
                        ? AppColors.primary
                        : AppColors.grey300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
