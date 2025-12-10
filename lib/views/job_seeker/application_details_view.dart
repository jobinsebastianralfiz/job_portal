import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/application_model.dart';
import '../../providers/application_provider.dart';
import '../widgets/custom_button.dart';

class ApplicationDetailsView extends StatelessWidget {
  final ApplicationModel application;

  const ApplicationDetailsView({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        actions: [
          if (application.status != 'withdrawn' && application.status != 'rejected')
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'withdraw',
                  child: Row(
                    children: [
                      Icon(Icons.close, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Withdraw Application'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'withdraw') {
                  _showWithdrawDialog(context);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application.jobTitle,
                    style: AppTextStyles.h4.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    application.companyName,
                    style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  _StatusChip(status: application.status),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Timeline
            Text('Application Timeline', style: AppTextStyles.h6),
            const SizedBox(height: 16),
            ...application.statusHistory.reversed.map((history) {
              return _TimelineItem(
                status: history.status,
                timestamp: history.timestamp,
                note: history.note,
                isFirst: history == application.statusHistory.last,
                isLast: history == application.statusHistory.first,
              );
            }),
            const SizedBox(height: 24),

            // Interview Details
            if (application.interview != null) ...[
              _buildSection(
                'Interview Details',
                [
                  if (application.interview!.scheduledAt != null)
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label: 'Date & Time',
                      value: DateFormat('MMM dd, yyyy - hh:mm a')
                          .format(application.interview!.scheduledAt!),
                    ),
                  if (application.interview!.type != null)
                    _InfoRow(
                      icon: Icons.videocam,
                      label: 'Type',
                      value: application.interview!.type!,
                    ),
                  if (application.interview!.duration != null)
                    _InfoRow(
                      icon: Icons.access_time,
                      label: 'Duration',
                      value: '${application.interview!.duration} minutes',
                    ),
                  if (application.interview!.location != null)
                    _InfoRow(
                      icon: Icons.location_on,
                      label: 'Location',
                      value: application.interview!.location!,
                    ),
                  if (application.interview!.meetingLink != null) ...[
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Join Meeting',
                      icon: Icons.video_call,
                      onPressed: () {
                        // Open meeting link
                      },
                      width: double.infinity,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Cover Letter
            if (application.coverLetter?.isNotEmpty ?? false) ...[
              _buildSection(
                'Cover Letter',
                [
                  Text(
                    application.coverLetter!,
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Resume
            if (application.resume != null) ...[
              _buildSection(
                'Resume',
                [
                  InkWell(
                    onTap: () {
                      // Open resume
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.description,
                            color: AppColors.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resume.pdf',
                                  style: AppTextStyles.labelLarge,
                                ),
                                Text(
                                  'Tap to view',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.open_in_new,
                            color: AppColors.grey500,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Screening Answers
            if (application.answers?.isNotEmpty ?? false) ...[
              _buildSection(
                'Your Answers',
                application.answers!
                    .map((answer) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                answer.question,
                                style: AppTextStyles.labelLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                answer.answer,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Application Info
            _buildSection(
              'Application Info',
              [
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'Applied On',
                  value: DateFormat('MMM dd, yyyy').format(application.appliedAt),
                ),
                _InfoRow(
                  icon: Icons.update,
                  label: 'Last Updated',
                  value: DateFormat('MMM dd, yyyy').format(application.updatedAt),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Action Buttons
            if (application.status == 'offered') ...[
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Decline',
                      isOutlined: true,
                      onPressed: () => _showDeclineDialog(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Accept Offer',
                      onPressed: () => _acceptOffer(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h6),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Application?'),
        content: const Text(
          'Are you sure you want to withdraw this application? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<ApplicationProvider>();
              await provider.withdrawApplication(application.applicationId);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Application withdrawn')),
                );
              }
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  void _showDeclineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Offer?'),
        content: const Text(
          'Are you sure you want to decline this offer? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<ApplicationProvider>();
              await provider.withdrawApplication(application.applicationId);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  void _acceptOffer(BuildContext context) async {
    final provider = context.read<ApplicationProvider>();
    await provider.acceptOffer(application.applicationId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Congratulations! Offer accepted!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String status;
  final DateTime timestamp;
  final String? note;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.status,
    required this.timestamp,
    this.note,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor(),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.grey300,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusText(),
                    style: AppTextStyles.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp),
                    style: AppTextStyles.caption,
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      note!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case 'pending':
        return AppColors.statusPending;
      case 'reviewed':
        return AppColors.statusReviewed;
      case 'shortlisted':
        return AppColors.statusShortlisted;
      case 'interview':
        return AppColors.statusInterview;
      case 'offered':
        return AppColors.statusOffered;
      case 'accepted':
        return AppColors.statusAccepted;
      case 'rejected':
        return AppColors.statusRejected;
      case 'withdrawn':
        return AppColors.statusWithdrawn;
      default:
        return AppColors.grey500;
    }
  }

  String _getStatusText() {
    switch (status) {
      case 'pending':
        return 'Application Submitted';
      case 'reviewed':
        return 'Application Reviewed';
      case 'shortlisted':
        return 'Shortlisted';
      case 'interview':
        return 'Interview Scheduled';
      case 'offered':
        return 'Offer Extended';
      case 'accepted':
        return 'Offer Accepted';
      case 'rejected':
        return 'Application Rejected';
      case 'withdrawn':
        return 'Application Withdrawn';
      default:
        return status;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.grey500),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey600,
            ),
          ),
          Expanded(
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
