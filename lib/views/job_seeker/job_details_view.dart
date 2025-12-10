import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/application_provider.dart';
import '../../services/ai/gemini_service.dart';
import '../widgets/custom_button.dart';
import 'apply_job_view.dart';

class JobDetailsView extends StatefulWidget {
  final JobModel job;

  const JobDetailsView({super.key, required this.job});

  @override
  State<JobDetailsView> createState() => _JobDetailsViewState();
}

class _JobDetailsViewState extends State<JobDetailsView> {
  bool _hasApplied = false;
  bool _isCheckingApplication = true;
  bool _isAnalyzingMatch = false;
  JobMatchResult? _cachedMatchResult; // Cache the result

  @override
  void initState() {
    super.initState();
    _checkIfApplied();
    _incrementViews();
  }

  Future<void> _checkIfApplied() async {
    final authProvider = context.read<AuthProvider>();
    final applicationProvider = context.read<ApplicationProvider>();

    if (authProvider.currentUser != null) {
      final hasApplied = await applicationProvider.hasApplied(
        widget.job.jobId,
        authProvider.currentUser!.userId,
      );
      setState(() {
        _hasApplied = hasApplied;
        _isCheckingApplication = false;
      });
    } else {
      setState(() {
        _isCheckingApplication = false;
      });
    }
  }

  void _incrementViews() {
    context.read<JobProvider>().incrementViews(widget.job.jobId);
  }

  Future<void> _analyzeJobMatch() async {
    // If already cached, just show the result
    if (_cachedMatchResult != null) {
      _showMatchResultModal(_cachedMatchResult!);
      return;
    }

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isAnalyzingMatch = true);

    try {
      final geminiService = GeminiService();
      final result = await geminiService.analyzeJobMatch(
        jobTitle: widget.job.title,
        jobDescription: widget.job.description,
        jobSkills: widget.job.skills,
        jobRequirements: widget.job.requirements,
        experienceLevel: widget.job.experienceLevel,
        userSummary: user.summary,
        userSkills: user.skills,
        userExperience: user.experience,
        userEducation: user.education,
      );

      if (mounted) {
        setState(() {
          _isAnalyzingMatch = false;
          _cachedMatchResult = result; // Cache the result
        });

        if (result != null) {
          _showMatchResultModal(result);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to analyze job match. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzingMatch = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showMatchResultModal(JobMatchResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header with score
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildScoreCircle(result.matchScore),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Job Match Analysis',
                            style: AppTextStyles.h5,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRecommendationColor(result.recommendation).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              result.recommendationText,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: _getRecommendationColor(result.recommendation),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary
                    Text(
                      result.summary,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.grey700,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Matching Skills
                    if (result.matchingSkills.isNotEmpty) ...[
                      _buildSectionHeader(
                        'Matching Skills',
                        Icons.check_circle,
                        AppColors.success,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: result.matchingSkills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.success.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              skill,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Missing Skills
                    if (result.missingSkills.isNotEmpty) ...[
                      _buildSectionHeader(
                        'Skills to Develop',
                        Icons.school,
                        AppColors.warning,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: result.missingSkills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.warning.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              skill,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Strengths
                    if (result.strengths.isNotEmpty) ...[
                      _buildSectionHeader(
                        'Your Strengths',
                        Icons.star,
                        AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      ...result.strengths.map((strength) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.arrow_right,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                strength,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 24),
                    ],

                    // Areas for Improvement
                    if (result.improvements.isNotEmpty) ...[
                      _buildSectionHeader(
                        'Areas for Improvement',
                        Icons.trending_up,
                        AppColors.secondary,
                      ),
                      const SizedBox(height: 8),
                      ...result.improvements.map((improvement) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.arrow_right,
                              color: AppColors.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                improvement,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 24),
                    ],

                    // Tips
                    if (result.tips.isNotEmpty) ...[
                      _buildSectionHeader(
                        'Application Tips',
                        Icons.lightbulb,
                        AppColors.info,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: result.tips.map((tip) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.tips_and_updates,
                                  color: AppColors.info,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Apply button
                    if (!_hasApplied)
                      CustomButton(
                        text: 'Apply Now',
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToApply(context);
                        },
                        width: double.infinity,
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCircle(int score) {
    Color scoreColor;
    if (score >= 80) {
      scoreColor = AppColors.success;
    } else if (score >= 60) {
      scoreColor = AppColors.primary;
    } else if (score >= 40) {
      scoreColor = AppColors.warning;
    } else {
      scoreColor = AppColors.error;
    }

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: scoreColor,
          width: 4,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$score%',
              style: AppTextStyles.h5.copyWith(
                color: scoreColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Match',
              style: AppTextStyles.caption.copyWith(
                color: scoreColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRecommendationColor(String recommendation) {
    switch (recommendation) {
      case 'highly_recommended':
        return AppColors.success;
      case 'recommended':
        return AppColors.primary;
      case 'consider':
        return AppColors.warning;
      case 'not_recommended':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.h6.copyWith(color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final jobProvider = context.watch<JobProvider>();
    final isSaved = jobProvider.savedJobs.any((j) => j.jobId == widget.job.jobId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Company Logo
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: widget.job.companyLogo != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        widget.job.companyLogo!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _buildLogoPlaceholder(),
                                      ),
                                    )
                                  : _buildLogoPlaceholder(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.job.title,
                                    style: AppTextStyles.h4.copyWith(
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.job.companyName,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (authProvider.currentUser != null) {
                    jobProvider.toggleSaveJob(
                      widget.job.jobId,
                      authProvider.currentUser!.userId,
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  // Share job
                },
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.work_outline,
                          title: 'Type',
                          value: widget.job.employmentType,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.location_on_outlined,
                          title: 'Location',
                          value: widget.job.workLocation,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.trending_up,
                          title: 'Experience',
                          value: widget.job.experienceLevel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.attach_money,
                          title: 'Salary',
                          value: widget.job.salaryDisplay,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // AI Job Match Button - Only show if not already applied
                  if (!_hasApplied)
                    InkWell(
                      onTap: _isAnalyzingMatch ? null : _analyzeJobMatch,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.1),
                              AppColors.secondary.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: _isAnalyzingMatch
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      _cachedMatchResult != null
                                          ? Icons.check_circle
                                          : Icons.auto_awesome,
                                      color: _cachedMatchResult != null
                                          ? AppColors.success
                                          : AppColors.primary,
                                      size: 24,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isAnalyzingMatch
                                        ? 'Analyzing your profile...'
                                        : _cachedMatchResult != null
                                            ? 'Match: ${_cachedMatchResult!.matchScore}% - ${_cachedMatchResult!.recommendationText}'
                                            : 'AI Job Match Analysis',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: _cachedMatchResult != null
                                          ? AppColors.success
                                          : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _cachedMatchResult != null
                                        ? 'Tap to view full analysis'
                                        : 'See how well your skills match this job',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.grey600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!_isAnalyzingMatch)
                              Icon(
                                Icons.arrow_forward_ios,
                                color: _cachedMatchResult != null
                                    ? AppColors.success
                                    : AppColors.primary,
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Location
                  if (widget.job.location != null) ...[
                    Text('Location', style: AppTextStyles.h6),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.place,
                          color: AppColors.grey500,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.job.location!.fullLocation,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Description
                  Text('Job Description', style: AppTextStyles.h6),
                  const SizedBox(height: 8),
                  Text(
                    widget.job.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Requirements
                  if (widget.job.requirements.isNotEmpty) ...[
                    Text('Requirements', style: AppTextStyles.h6),
                    const SizedBox(height: 8),
                    ...widget.job.requirements.map((req) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  req,
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // Skills
                  if (widget.job.skills.isNotEmpty) ...[
                    Text('Skills', style: AppTextStyles.h6),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.job.skills.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            skill,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Schedule
                  if (widget.job.schedule != null) ...[
                    Text('Schedule', style: AppTextStyles.h6),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.schedule,
                      label: 'Flexibility',
                      value: widget.job.schedule!.flexibility,
                    ),
                    if (widget.job.schedule!.preferredDays != null)
                      _InfoRow(
                        icon: Icons.calendar_today,
                        label: 'Preferred Days',
                        value: widget.job.schedule!.preferredDays!.join(', '),
                      ),
                    if (widget.job.hoursPerWeek != null)
                      _InfoRow(
                        icon: Icons.access_time,
                        label: 'Hours per Week',
                        value: '${widget.job.hoursPerWeek} hours',
                      ),
                    const SizedBox(height: 24),
                  ],

                  // Screening Questions
                  if (widget.job.screeningQuestions?.isNotEmpty ?? false) ...[
                    Text('Screening Questions', style: AppTextStyles.h6),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.job.screeningQuestions!.length} questions to answer when applying',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey600,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: Icons.visibility,
                          value: widget.job.views.toString(),
                          label: 'Views',
                        ),
                        _StatItem(
                          icon: Icons.people,
                          value: widget.job.applications.toString(),
                          label: 'Applications',
                        ),
                        _StatItem(
                          icon: Icons.bookmark,
                          value: widget.job.saves.toString(),
                          label: 'Saved',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.job.salaryDisplay,
                      style: AppTextStyles.h5.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Posted ${_getTimeAgo(widget.job.createdAt)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _isCheckingApplication
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        text: _hasApplied ? 'Applied' : 'Apply Now',
                        onPressed: _hasApplied
                            ? null
                            : () => _navigateToApply(context),
                        isDisabled: _hasApplied,
                        backgroundColor:
                            _hasApplied ? AppColors.grey400 : AppColors.primary,
                      ),
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
        widget.job.companyName.isNotEmpty
            ? widget.job.companyName[0].toUpperCase()
            : 'C',
        style: AppTextStyles.h4.copyWith(color: AppColors.grey500),
      ),
    );
  }

  void _navigateToApply(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplyJobView(job: widget.job),
      ),
    ).then((applied) {
      if (applied == true) {
        setState(() {
          _hasApplied = true;
        });
      }
    });
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.labelLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
    return Column(
      children: [
        Icon(icon, color: AppColors.grey500, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.h6,
        ),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
