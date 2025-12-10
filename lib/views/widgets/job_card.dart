import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/job_model.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;
  final VoidCallback? onSave;
  final bool isSaved;
  final bool showCompanyLogo;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.onSave,
    this.isSaved = false,
    this.showCompanyLogo = true,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Logo
                  if (showCompanyLogo)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: job.companyLogo != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                job.companyLogo!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildLogoPlaceholder(),
                              ),
                            )
                          : _buildLogoPlaceholder(),
                    ),
                  if (showCompanyLogo) const SizedBox(width: 12),

                  // Job Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                job.title,
                                style: AppTextStyles.h6,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (job.isUrgent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.errorLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Urgent',
                                  style: AppTextStyles.overline.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.companyName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Save Button
                  if (onSave != null)
                    IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_outline,
                        color: isSaved ? AppColors.primary : AppColors.grey500,
                      ),
                      onPressed: onSave,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Tags Row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTag(job.employmentType, Icons.work_outline),
                  _buildTag(job.workLocation, Icons.location_on_outlined),
                  _buildTag(job.experienceLevel, Icons.trending_up),
                ],
              ),
              const SizedBox(height: 12),

              // Bottom Row
              Row(
                children: [
                  // Location
                  if (job.location != null) ...[
                    Icon(
                      Icons.place,
                      size: 16,
                      color: AppColors.grey500,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job.location!.shortLocation,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  // Salary
                  Text(
                    job.salaryDisplay,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // Posted Time
              const SizedBox(height: 8),
              Text(
                _getTimeAgo(job.createdAt),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Center(
      child: Text(
        job.companyName.isNotEmpty ? job.companyName[0].toUpperCase() : 'C',
        style: AppTextStyles.h5.copyWith(color: AppColors.grey500),
      ),
    );
  }

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.grey600),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.grey600,
            ),
          ),
        ],
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
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class JobCardCompact extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const JobCardCompact({
    super.key,
    required this.job,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: job.companyLogo != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    job.companyLogo!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        job.companyName.isNotEmpty
                            ? job.companyName[0].toUpperCase()
                            : 'C',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.grey500,
                        ),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    job.companyName.isNotEmpty
                        ? job.companyName[0].toUpperCase()
                        : 'C',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                ),
        ),
        title: Text(
          job.title,
          style: AppTextStyles.labelLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          job.companyName,
          style: AppTextStyles.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          job.salaryDisplay,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.secondary,
          ),
        ),
      ),
    );
  }
}
