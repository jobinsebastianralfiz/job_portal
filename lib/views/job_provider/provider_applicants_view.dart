import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/application_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/application_provider.dart';
import 'applicant_details_view.dart';

class ProviderApplicantsView extends StatefulWidget {
  const ProviderApplicantsView({super.key});

  @override
  State<ProviderApplicantsView> createState() => _ProviderApplicantsViewState();
}

class _ProviderApplicantsViewState extends State<ProviderApplicantsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['All', 'Pending', 'Shortlisted', 'Interview', 'Offered'];

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
        return applications.where((a) => a.status == 'pending').toList();
      case 'Shortlisted':
        return applications.where((a) => a.status == 'shortlisted').toList();
      case 'Interview':
        return applications.where((a) => a.status == 'interview').toList();
      case 'Offered':
        return applications
            .where((a) => a.status == 'offered' || a.status == 'accepted')
            .toList();
      default:
        return applications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicationProvider = context.watch<ApplicationProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Applicants'),
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
          if (authProvider.currentUser != null) {
            await applicationProvider.loadProviderApplications(
              authProvider.currentUser!.userId,
            );
          }
        },
        child: applicationProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) {
                  final filtered = _filterApplications(
                    applicationProvider.applications,
                    tab,
                  );

                  if (filtered.isEmpty) {
                    return _buildEmptyState(tab);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _ApplicantCard(
                        application: filtered[index],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ApplicantDetailsView(
                              application: filtered[index],
                            ),
                          ),
                        ),
                        onShortlist: () => _shortlist(filtered[index]),
                        onReject: () => _reject(filtered[index]),
                      );
                    },
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _buildEmptyState(String tab) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 16),
          Text(
            'No $tab applicants',
            style: AppTextStyles.h5.copyWith(color: AppColors.grey600),
          ),
          const SizedBox(height: 8),
          Text(
            'Applicants in this category will appear here',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
          ),
        ],
      ),
    );
  }

  void _shortlist(ApplicationModel application) async {
    final provider = context.read<ApplicationProvider>();
    await provider.shortlistApplication(application.applicationId);
  }

  void _reject(ApplicationModel application) async {
    final provider = context.read<ApplicationProvider>();
    await provider.rejectApplication(application.applicationId);
  }
}

class _ApplicantCard extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback onTap;
  final VoidCallback onShortlist;
  final VoidCallback onReject;

  const _ApplicantCard({
    required this.application,
    required this.onTap,
    required this.onShortlist,
    required this.onReject,
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
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.grey100,
                    backgroundImage: application.applicantImage != null
                        ? NetworkImage(application.applicantImage!)
                        : null,
                    child: application.applicantImage == null
                        ? Text(
                            application.applicantName.isNotEmpty
                                ? application.applicantName[0].toUpperCase()
                                : 'A',
                            style: AppTextStyles.h5.copyWith(
                              color: AppColors.grey500,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.applicantName,
                          style: AppTextStyles.h6,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Applied for ${application.jobTitle}',
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

              // Application Info
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: AppColors.grey500),
                  const SizedBox(width: 4),
                  Text(
                    'Applied ${_getTimeAgo(application.appliedAt)}',
                    style: AppTextStyles.caption,
                  ),
                  const Spacer(),
                  if (application.resume != null)
                    Row(
                      children: [
                        Icon(Icons.description, size: 14, color: AppColors.grey500),
                        const SizedBox(width: 4),
                        Text('Resume attached', style: AppTextStyles.caption),
                      ],
                    ),
                ],
              ),

              // Quick Actions
              if (application.isPending) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onShortlist,
                      child: const Text('Shortlist'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
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
