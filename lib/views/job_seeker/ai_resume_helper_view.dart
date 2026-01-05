import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/ai/gemini_service.dart';
import '../../services/firebase/user_service.dart';
import '../../services/firebase/storage_service.dart';

class AIResumeHelperView extends StatefulWidget {
  const AIResumeHelperView({super.key});

  @override
  State<AIResumeHelperView> createState() => _AIResumeHelperViewState();
}

class _AIResumeHelperViewState extends State<AIResumeHelperView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  File? _selectedFile;
  String? _existingResumeUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadExistingResume();
  }

  void _loadExistingResume() {
    final user = context.read<AuthProvider>().currentUser;
    if (user?.resume != null && _existingResumeUrl == null) {
      _existingResumeUrl = user!.resume;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Resume Assistant'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Parse Resume'),
            Tab(text: 'Job Fit'),
            Tab(text: 'Improve'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ParseResumeTab(
            selectedFile: _selectedFile,
            existingResumeUrl: _existingResumeUrl,
            onFileSelected: (file) {
              setState(() => _selectedFile = file);
            },
          ),
          _JobFitTab(selectedFile: _selectedFile, existingResumeUrl: _existingResumeUrl),
          _ImproveTab(selectedFile: _selectedFile, existingResumeUrl: _existingResumeUrl),
        ],
      ),
    );
  }
}

class _ParseResumeTab extends StatefulWidget {
  final File? selectedFile;
  final String? existingResumeUrl;
  final Function(File) onFileSelected;

  const _ParseResumeTab({
    required this.selectedFile,
    required this.existingResumeUrl,
    required this.onFileSelected,
  });

  @override
  State<_ParseResumeTab> createState() => _ParseResumeTabState();
}

class _ParseResumeTabState extends State<_ParseResumeTab> {
  bool _useExistingResume = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    // Auto-select existing resume if available
    if (widget.existingResumeUrl != null && widget.selectedFile == null) {
      _useExistingResume = true;
    }
  }

  bool get _hasResumeReady => widget.selectedFile != null || (_useExistingResume && widget.existingResumeUrl != null);

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AIProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.accent.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI-Powered Resume Parser', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Upload your resume and let AI extract and organize your information',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Existing Resume Option
          if (widget.existingResumeUrl != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _useExistingResume ? AppColors.success.withOpacity(0.1) : AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _useExistingResume ? AppColors.success : AppColors.grey300,
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _useExistingResume = true;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      _useExistingResume ? Icons.check_circle : Icons.description,
                      color: _useExistingResume ? AppColors.success : AppColors.grey500,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Use Uploaded Resume', style: AppTextStyles.labelLarge),
                          const SizedBox(height: 4),
                          Text(
                            'Parse your previously uploaded resume',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (_useExistingResume)
                      const Icon(Icons.check, color: AppColors.success),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('OR', style: AppTextStyles.labelMedium.copyWith(color: AppColors.grey500)),
            ),
            const SizedBox(height: 16),
          ],

          // Upload Section
          Text('Upload New Resume', style: AppTextStyles.h6),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _pickFile(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.selectedFile != null
                      ? AppColors.success
                      : AppColors.grey300,
                  style: BorderStyle.solid,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: widget.selectedFile != null
                    ? AppColors.success.withOpacity(0.05)
                    : AppColors.grey50,
              ),
              child: Column(
                children: [
                  Icon(
                    widget.selectedFile != null
                        ? Icons.check_circle
                        : Icons.cloud_upload_outlined,
                    size: 48,
                    color: widget.selectedFile != null
                        ? AppColors.success
                        : AppColors.grey400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.selectedFile != null
                        ? widget.selectedFile!.path.split('/').last
                        : 'Tap to upload resume',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: widget.selectedFile != null
                          ? AppColors.success
                          : AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.selectedFile != null
                        ? 'Tap to change file'
                        : 'Supports PDF, DOC, DOCX, TXT',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Parse Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _hasResumeReady && !aiProvider.isLoading && !_isDownloading
                  ? () => _parseResume(context)
                  : null,
              icon: (aiProvider.isLoading || _isDownloading)
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isDownloading
                  ? 'Downloading Resume...'
                  : (aiProvider.isLoading ? 'Parsing...' : 'Parse Resume')),
            ),
          ),
          const SizedBox(height: 24),

          // Results
          if (aiProvider.parsedResume != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Parsed Information', style: AppTextStyles.h6),
                _SaveToProfileButton(
                  parsedResume: aiProvider.parsedResume!,
                  selectedFile: widget.selectedFile,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ParsedResumeCard(result: aiProvider.parsedResume!),
          ],
        ],
      ),
    );
  }

  void _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      try {
        // Copy file to a stable location to avoid cache issues
        final originalFile = File(result.files.single.path!);
        final bytes = await originalFile.readAsBytes();

        final tempDir = await getTemporaryDirectory();
        final fileName = result.files.single.name;
        final stableFile = File('${tempDir.path}/resume_$fileName');
        await stableFile.writeAsBytes(bytes);

        debugPrint('File copied to stable path: ${stableFile.path}');

        setState(() {
          _useExistingResume = false;
        });
        widget.onFileSelected(stableFile);
      } catch (e) {
        debugPrint('Error copying file: $e');
        // Fallback to original path
        setState(() {
          _useExistingResume = false;
        });
        widget.onFileSelected(File(result.files.single.path!));
      }
    }
  }

  void _parseResume(BuildContext context) async {
    final aiProvider = context.read<AIProvider>();

    // If using existing resume URL, download and parse it
    if (_useExistingResume && widget.existingResumeUrl != null && widget.selectedFile == null) {
      setState(() => _isDownloading = true);

      try {
        // Parse directly from URL using the resume parser service
        final success = await aiProvider.parseResumeFromUrl(widget.existingResumeUrl!);

        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(aiProvider.error ?? 'Failed to parse resume'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDownloading = false);
        }
      }
      return;
    }

    // Parse from selected file
    if (widget.selectedFile == null) return;

    final success = await aiProvider.parseResume(widget.selectedFile!);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aiProvider.error ?? 'Failed to parse resume'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _ParsedResumeCard extends StatelessWidget {
  final ResumeParseResult result;

  const _ParsedResumeCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Info
          if (result.personalInfo.fullName != null) ...[
            _SectionHeader(title: 'Personal Information', icon: Icons.person),
            const SizedBox(height: 8),
            _InfoRow('Name', result.personalInfo.fullName!),
            if (result.personalInfo.email != null)
              _InfoRow('Email', result.personalInfo.email!),
            if (result.personalInfo.phone != null)
              _InfoRow('Phone', result.personalInfo.phone!),
            if (result.personalInfo.location != null)
              _InfoRow('Location', result.personalInfo.location!),
            const SizedBox(height: 16),
          ],

          // Summary
          if (result.summary.isNotEmpty) ...[
            _SectionHeader(title: 'Summary', icon: Icons.description),
            const SizedBox(height: 8),
            Text(result.summary, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
          ],

          // Skills
          if (result.skills.isNotEmpty) ...[
            _SectionHeader(title: 'Skills', icon: Icons.star),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.skills
                  .map((skill) => Chip(
                        label: Text(skill),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        labelStyle: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Experience
          if (result.experience.isNotEmpty) ...[
            _SectionHeader(title: 'Experience', icon: Icons.work),
            const SizedBox(height: 8),
            ...result.experience.map((exp) => _ExperienceItem(experience: exp)),
            const SizedBox(height: 16),
          ],

          // Education
          if (result.education.isNotEmpty) ...[
            _SectionHeader(title: 'Education', icon: Icons.school),
            const SizedBox(height: 8),
            ...result.education.map((edu) => _EducationItem(education: edu)),
            const SizedBox(height: 16),
          ],

          // Suggested Job Titles
          if (result.suggestedJobTitles.isNotEmpty) ...[
            _SectionHeader(title: 'Suggested Job Titles', icon: Icons.lightbulb),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.suggestedJobTitles
                  .map((title) => Chip(
                        label: Text(title),
                        backgroundColor: AppColors.accent.withOpacity(0.1),
                        labelStyle: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.accent,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _JobFitTab extends StatefulWidget {
  final File? selectedFile;
  final String? existingResumeUrl;

  const _JobFitTab({required this.selectedFile, this.existingResumeUrl});

  @override
  State<_JobFitTab> createState() => _JobFitTabState();
}

class _JobFitTabState extends State<_JobFitTab> {
  final _jobDescriptionController = TextEditingController();

  bool get _hasResume => widget.selectedFile != null || widget.existingResumeUrl != null;

  @override
  void initState() {
    super.initState();
    _jobDescriptionController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _jobDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AIProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.compare_arrows, color: AppColors.secondary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Job Fit Analysis', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 4),
                      Text(
                        'See how well your resume matches a job description',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // File Status
          if (!_hasResume)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please upload a resume in the "Parse Resume" tab first',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Job Description Input
            Text('Job Description', style: AppTextStyles.h6),
            const SizedBox(height: 12),
            TextField(
              controller: _jobDescriptionController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Paste the job description here...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Analyze Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: !aiProvider.isLoading &&
                        _jobDescriptionController.text.isNotEmpty
                    ? () => _analyzeJobFit(context)
                    : null,
                icon: aiProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.analytics),
                label: Text(aiProvider.isLoading ? 'Analyzing...' : 'Analyze Fit'),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Results
          if (aiProvider.jobFitAnalysis != null)
            _JobFitResultCard(analysis: aiProvider.jobFitAnalysis!),
        ],
      ),
    );
  }

  void _analyzeJobFit(BuildContext context) async {
    final aiProvider = context.read<AIProvider>();
    bool success = false;

    // Use file if available, otherwise use URL
    if (widget.selectedFile != null) {
      success = await aiProvider.analyzeJobFit(
        resumeFile: widget.selectedFile!,
        jobDescription: _jobDescriptionController.text,
      );
    } else if (widget.existingResumeUrl != null) {
      success = await aiProvider.analyzeJobFitFromUrl(
        resumeUrl: widget.existingResumeUrl!,
        jobDescription: _jobDescriptionController.text,
      );
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aiProvider.error ?? 'Failed to analyze job fit'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _JobFitResultCard extends StatelessWidget {
  final JobFitAnalysis analysis;

  const _JobFitResultCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Score
          Center(
            child: Column(
              children: [
                Text('Overall Match Score', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                _ScoreCircle(score: analysis.overallScore),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Matching Skills
          if (analysis.matchingSkills.isNotEmpty) ...[
            _SectionHeader(
              title: 'Matching Skills',
              icon: Icons.check_circle,
              color: AppColors.success,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.matchingSkills
                  .map((skill) => Chip(
                        label: Text(skill),
                        backgroundColor: AppColors.success.withOpacity(0.1),
                        labelStyle: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.success,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Missing Skills
          if (analysis.missingSkills.isNotEmpty) ...[
            _SectionHeader(
              title: 'Missing Skills',
              icon: Icons.warning,
              color: AppColors.warning,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.missingSkills
                  .map((skill) => Chip(
                        label: Text(skill),
                        backgroundColor: AppColors.warning.withOpacity(0.1),
                        labelStyle: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.warning,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Strengths
          if (analysis.strengths.isNotEmpty) ...[
            _SectionHeader(
              title: 'Your Strengths',
              icon: Icons.thumb_up,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            ...analysis.strengths.map((s) => _BulletPoint(text: s, color: AppColors.success)),
            const SizedBox(height: 16),
          ],

          // Concerns
          if (analysis.concerns.isNotEmpty) ...[
            _SectionHeader(
              title: 'Areas of Concern',
              icon: Icons.info,
              color: AppColors.error,
            ),
            const SizedBox(height: 8),
            ...analysis.concerns.map((c) => _BulletPoint(text: c, color: AppColors.error)),
            const SizedBox(height: 16),
          ],

          // Recommendation
          if (analysis.recommendation.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Recommendation', style: AppTextStyles.labelLarge),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(analysis.recommendation, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImproveTab extends StatelessWidget {
  final File? selectedFile;
  final String? existingResumeUrl;

  const _ImproveTab({required this.selectedFile, this.existingResumeUrl});

  bool get _hasResume => selectedFile != null || existingResumeUrl != null;

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AIProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withOpacity(0.1),
                  AppColors.success.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: AppColors.accent, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resume Improvement', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Get AI suggestions to improve your resume',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (!_hasResume)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please upload a resume in the "Parse Resume" tab first',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Improve Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: !aiProvider.isLoading
                    ? () => _getImprovements(context)
                    : null,
                icon: aiProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: Text(
                    aiProvider.isLoading ? 'Analyzing...' : 'Get Improvement Suggestions'),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Results
          if (aiProvider.resumeImprovement != null)
            _ImprovementResultCard(improvement: aiProvider.resumeImprovement!),
        ],
      ),
    );
  }

  void _getImprovements(BuildContext context) async {
    final aiProvider = context.read<AIProvider>();
    bool success = false;

    if (selectedFile != null) {
      success = await aiProvider.getResumeImprovements(selectedFile!);
    } else if (existingResumeUrl != null) {
      success = await aiProvider.getResumeImprovementsFromUrl(existingResumeUrl!);
    }

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aiProvider.error ?? 'Failed to get improvements'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _ImprovementResultCard extends StatelessWidget {
  final ResumeImprovement improvement;

  const _ImprovementResultCard({required this.improvement});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scores
          Row(
            children: [
              Expanded(
                child: _MiniScoreCard(
                  title: 'Overall Score',
                  score: improvement.overallScore,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniScoreCard(
                  title: 'ATS Score',
                  score: improvement.atsScore,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // General Feedback
          if (improvement.generalFeedback.isNotEmpty) ...[
            _SectionHeader(title: 'General Feedback', icon: Icons.feedback),
            const SizedBox(height: 8),
            ...improvement.generalFeedback.map((f) => _BulletPoint(text: f)),
            const SizedBox(height: 16),
          ],

          // Skills to Add
          if (improvement.skillsToAdd.isNotEmpty) ...[
            _SectionHeader(title: 'Recommended Skills to Add', icon: Icons.add_circle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: improvement.skillsToAdd
                  .map((skill) => Chip(
                        label: Text(skill),
                        backgroundColor: AppColors.success.withOpacity(0.1),
                        labelStyle: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.success,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // ATS Tips
          if (improvement.atsTips.isNotEmpty) ...[
            _SectionHeader(
              title: 'ATS Optimization Tips',
              icon: Icons.auto_fix_high,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 8),
            ...improvement.atsTips.map((t) => _BulletPoint(text: t, color: AppColors.secondary)),
            const SizedBox(height: 16),
          ],

          // Formatting Tips
          if (improvement.formattingTips.isNotEmpty) ...[
            _SectionHeader(title: 'Formatting Tips', icon: Icons.format_align_left),
            const SizedBox(height: 8),
            ...improvement.formattingTips.map((t) => _BulletPoint(text: t)),
          ],
        ],
      ),
    );
  }
}

// ==================== Helper Widgets ====================

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.labelLarge),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.grey600),
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

class _ExperienceItem extends StatelessWidget {
  final Experience experience;

  const _ExperienceItem({required this.experience});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(experience.title, style: AppTextStyles.labelLarge),
          Text(
            '${experience.company} ${experience.location != null ? '- ${experience.location}' : ''}',
            style: AppTextStyles.bodySmall,
          ),
          if (experience.startDate != null)
            Text(
              '${experience.startDate} - ${experience.endDate ?? 'Present'}',
              style: AppTextStyles.caption,
            ),
          if (experience.description != null) ...[
            const SizedBox(height: 8),
            Text(experience.description!, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _EducationItem extends StatelessWidget {
  final Education education;

  const _EducationItem({required this.education});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            education.degree ?? education.institution,
            style: AppTextStyles.labelLarge,
          ),
          if (education.degree != null)
            Text(education.institution, style: AppTextStyles.bodySmall),
          if (education.field != null)
            Text(education.field!, style: AppTextStyles.caption),
          if (education.graduationDate != null)
            Text(education.graduationDate!, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final int score;

  const _ScoreCircle({required this.score});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (score >= 80) {
      color = AppColors.success;
    } else if (score >= 60) {
      color = AppColors.warning;
    } else {
      color = AppColors.error;
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 4),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$score%',
              style: AppTextStyles.h3.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniScoreCard extends StatelessWidget {
  final String title;
  final int score;
  final Color color;

  const _MiniScoreCard({
    required this.title,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Text(
            '$score%',
            style: AppTextStyles.h4.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  final Color? color;

  const _BulletPoint({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color ?? AppColors.grey500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _SaveToProfileButton extends StatefulWidget {
  final ResumeParseResult parsedResume;
  final File? selectedFile;

  const _SaveToProfileButton({
    required this.parsedResume,
    required this.selectedFile,
  });

  @override
  State<_SaveToProfileButton> createState() => _SaveToProfileButtonState();
}

class _SaveToProfileButtonState extends State<_SaveToProfileButton> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isSaving ? null : () => _saveToProfile(context),
      icon: _isSaving
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save, size: 18),
      label: Text(_isSaving ? 'Saving...' : 'Save to Profile'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _saveToProfile(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final userService = UserService();
      String? resumeUrl;

      // Upload resume file if available
      if (widget.selectedFile != null) {
        final storageService = StorageService();
        resumeUrl = await storageService.uploadResume(
          widget.selectedFile!,
          user.userId,
        );
      }

      // Build experience string from parsed data
      String? experienceStr;
      if (widget.parsedResume.experience.isNotEmpty) {
        experienceStr = widget.parsedResume.experience.map((exp) {
          final parts = <String>[exp.title, exp.company];
          if (exp.location != null) parts.add(exp.location!);
          if (exp.startDate != null) {
            parts.add('${exp.startDate} - ${exp.endDate ?? "Present"}');
          }
          if (exp.description != null) parts.add(exp.description!);
          return parts.join(' | ');
        }).join('\n\n');
      }

      // Build education string from parsed data
      String? educationStr;
      if (widget.parsedResume.education.isNotEmpty) {
        educationStr = widget.parsedResume.education.map((edu) {
          final parts = <String>[];
          if (edu.degree != null) parts.add(edu.degree!);
          parts.add(edu.institution);
          if (edu.field != null) parts.add(edu.field!);
          if (edu.graduationDate != null) parts.add(edu.graduationDate!);
          return parts.join(' | ');
        }).join('\n\n');
      }

      // Get current job title from first experience or suggested titles
      String? currentJobTitle;
      if (widget.parsedResume.experience.isNotEmpty) {
        currentJobTitle = widget.parsedResume.experience.first.title;
      } else if (widget.parsedResume.suggestedJobTitles.isNotEmpty) {
        currentJobTitle = widget.parsedResume.suggestedJobTitles.first;
      }

      // Save parsed data to user profile
      await userService.updateResumeWithAIData(
        userId: user.userId,
        resumeUrl: resumeUrl ?? user.resume ?? '',
        parsedData: {
          'skills': widget.parsedResume.skills,
          'experience': experienceStr,
          'education': educationStr,
          'currentJobTitle': currentJobTitle,
        },
        confidenceScore: 0.85, // Default confidence score
      );

      // Refresh user data
      await authProvider.refreshUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated from resume successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
