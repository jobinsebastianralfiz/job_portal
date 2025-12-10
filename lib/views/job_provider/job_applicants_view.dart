import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/job_model.dart';
import '../../models/application_model.dart';
import '../../providers/application_provider.dart';
import 'applicant_details_view.dart';

class JobApplicantsView extends StatefulWidget {
  final JobModel job;

  const JobApplicantsView({super.key, required this.job});

  @override
  State<JobApplicantsView> createState() => _JobApplicantsViewState();
}

class _JobApplicantsViewState extends State<JobApplicantsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'newest';
  final List<String> _tabs = ['All', 'Pending', 'Shortlisted', 'Interview', 'Offered'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadApplications();
  }

  void _loadApplications() {
    context.read<ApplicationProvider>().loadJobApplications(widget.job.jobId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ApplicationModel> _filterAndSort(List<ApplicationModel> applications, String tab) {
    List<ApplicationModel> filtered;

    switch (tab) {
      case 'Pending':
        filtered = applications.where((a) => a.status == 'pending').toList();
        break;
      case 'Shortlisted':
        filtered = applications.where((a) => a.status == 'shortlisted').toList();
        break;
      case 'Interview':
        filtered = applications.where((a) => a.status == 'interview').toList();
        break;
      case 'Offered':
        filtered = applications
            .where((a) => a.status == 'offered' || a.status == 'accepted')
            .toList();
        break;
      default:
        filtered = applications;
    }

    switch (_sortBy) {
      case 'newest':
        filtered.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.appliedAt.compareTo(b.appliedAt));
        break;
      case 'name':
        filtered.sort((a, b) => a.applicantName.compareTo(b.applicantName));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final applicationProvider = context.watch<ApplicationProvider>();
    final jobApplications = applicationProvider.applications
        .where((a) => a.jobId == widget.job.jobId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.job.title, style: AppTextStyles.h6),
            Text(
              '${jobApplications.length} applicants',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'newest',
                child: Row(
                  children: [
                    if (_sortBy == 'newest')
                      const Icon(Icons.check, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Newest first'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'oldest',
                child: Row(
                  children: [
                    if (_sortBy == 'oldest')
                      const Icon(Icons.check, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Oldest first'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    if (_sortBy == 'name')
                      const Icon(Icons.check, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('By name'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          tabs: _tabs.map((tab) {
            final count = _filterAndSort(jobApplications, tab).length;
            return Tab(text: '$tab ($count)');
          }).toList(),
        ),
      ),
      body: applicationProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final filtered = _filterAndSort(jobApplications, tab);

                if (filtered.isEmpty) {
                  return _buildEmptyState(tab);
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadApplications(),
                  child: ListView.builder(
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
                        ).then((_) => _loadApplications()),
                        onShortlist: () => _updateStatus(filtered[index], 'shortlisted'),
                        onScheduleInterview: () => _scheduleInterview(filtered[index]),
                        onReject: () => _updateStatus(filtered[index], 'rejected'),
                      );
                    },
                  ),
                );
              }).toList(),
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
            tab == 'All' ? 'No applicants yet' : 'No $tab applicants',
            style: AppTextStyles.h5.copyWith(color: AppColors.grey600),
          ),
          const SizedBox(height: 8),
          Text(
            tab == 'All'
                ? 'Applicants will appear here once they apply'
                : 'Applicants in this category will appear here',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _updateStatus(ApplicationModel application, String status) async {
    final provider = context.read<ApplicationProvider>();

    if (status == 'rejected') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject Applicant?'),
          content: Text(
            'Are you sure you want to reject ${application.applicantName}\'s application?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reject'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
      await provider.rejectApplication(application.applicationId);
    } else if (status == 'shortlisted') {
      await provider.shortlistApplication(application.applicationId);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application ${status == 'rejected' ? 'rejected' : 'shortlisted'}'),
          backgroundColor: status == 'rejected' ? AppColors.error : AppColors.success,
        ),
      );
    }
  }

  void _scheduleInterview(ApplicationModel application) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ScheduleInterviewSheet(
        application: application,
        onScheduled: () {
          _loadApplications();
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback onTap;
  final VoidCallback onShortlist;
  final VoidCallback onScheduleInterview;
  final VoidCallback onReject;

  const _ApplicantCard({
    required this.application,
    required this.onTap,
    required this.onShortlist,
    required this.onScheduleInterview,
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
                    radius: 28,
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppColors.grey500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Applied ${_getTimeAgo(application.appliedAt)}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: application.status),
                ],
              ),

              if (application.coverLetter != null && application.coverLetter!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    application.coverLetter!,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Info Row
              Row(
                children: [
                  if (application.resume != null) ...[
                    Icon(Icons.description, size: 16, color: AppColors.grey500),
                    const SizedBox(width: 4),
                    Text('Resume', style: AppTextStyles.caption),
                    const SizedBox(width: 16),
                  ],
                  if (application.expectedSalary != null) ...[
                    Icon(Icons.attach_money, size: 16, color: AppColors.grey500),
                    const SizedBox(width: 4),
                    Text(
                      '\$${application.expectedSalary}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ],
              ),

              // Action Buttons based on status
              if (application.isPending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onShortlist,
                        child: const Text('Shortlist'),
                      ),
                    ),
                  ],
                ),
              ] else if (application.status == 'shortlisted') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onScheduleInterview,
                        icon: const Icon(Icons.event, size: 18),
                        label: const Text('Schedule'),
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

class _ScheduleInterviewSheet extends StatefulWidget {
  final ApplicationModel application;
  final VoidCallback onScheduled;

  const _ScheduleInterviewSheet({
    required this.application,
    required this.onScheduled,
  });

  @override
  State<_ScheduleInterviewSheet> createState() => _ScheduleInterviewSheetState();
}

class _ScheduleInterviewSheetState extends State<_ScheduleInterviewSheet> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  String _interviewType = 'video';
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Schedule Interview', style: AppTextStyles.h5),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'with ${widget.application.applicantName}',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600),
          ),
          const SizedBox(height: 24),

          // Interview Type
          Text('Interview Type', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              _TypeChip(
                label: 'Video Call',
                icon: Icons.video_call,
                isSelected: _interviewType == 'video',
                onTap: () => setState(() => _interviewType = 'video'),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Phone',
                icon: Icons.phone,
                isSelected: _interviewType == 'phone',
                onTap: () => setState(() => _interviewType = 'phone'),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'In Person',
                icon: Icons.person,
                isSelected: _interviewType == 'in_person',
                onTap: () => setState(() => _interviewType = 'in_person'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date & Time
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Time', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (time != null) {
                          setState(() => _selectedTime = time);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTime.format(context),
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Location/Link
          if (_interviewType == 'in_person') ...[
            Text('Location', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'Enter interview location',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Notes
          Text('Notes (Optional)', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Add any notes for the candidate',
            ),
          ),
          const SizedBox(height: 24),

          // Schedule Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _scheduleInterview,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Schedule Interview'),
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleInterview() async {
    setState(() => _isLoading = true);

    final provider = context.read<ApplicationProvider>();
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final success = await provider.scheduleInterview(
      widget.application.applicationId,
      scheduledDateTime,
      _interviewType,
      location: _interviewType == 'in_person' ? _locationController.text : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Interview scheduled successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onScheduled();
    }
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.grey600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
