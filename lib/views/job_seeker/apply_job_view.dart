import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/job_model.dart';
import '../../models/application_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/application_provider.dart';
import '../../services/firebase/storage_service.dart';
import '../../services/ai/gemini_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ApplyJobView extends StatefulWidget {
  final JobModel job;

  const ApplyJobView({super.key, required this.job});

  @override
  State<ApplyJobView> createState() => _ApplyJobViewState();
}

class _ApplyJobViewState extends State<ApplyJobView> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  final _storageService = StorageService();

  File? _resumeFile;
  String? _existingResumeUrl;
  bool _useExistingResume = true;
  bool _isSubmitting = false;
  bool _isGeneratingCoverLetter = false;
  final Map<String, TextEditingController> _answerControllers = {};

  @override
  void initState() {
    super.initState();
    _loadExistingResume();
    _initializeAnswerControllers();
  }

  void _loadExistingResume() {
    final user = context.read<AuthProvider>().currentUser;
    if (user?.resume != null) {
      _existingResumeUrl = user!.resume;
    }
  }

  void _initializeAnswerControllers() {
    if (widget.job.screeningQuestions != null) {
      for (var question in widget.job.screeningQuestions!) {
        _answerControllers[question.id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    for (var controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _generateCoverLetter() async {
    final user = context.read<AuthProvider>().currentUser;

    setState(() => _isGeneratingCoverLetter = true);

    try {
      final geminiService = GeminiService();
      final coverLetter = await geminiService.generateCoverLetter(
        jobTitle: widget.job.title,
        companyName: widget.job.companyName,
        jobDescription: widget.job.description,
        userName: user?.fullName,
        userSummary: user?.summary,
        userSkills: user?.skills,
        userExperience: user?.experience,
        userEducation: user?.education,
      );

      if (coverLetter != null) {
        _coverLetterController.text = coverLetter;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate cover letter. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingCoverLetter = false);
      }
    }
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _resumeFile = File(result.files.single.path!);
        _useExistingResume = false;
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final applicationProvider = context.read<ApplicationProvider>();
    final user = authProvider.currentUser;

    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Upload new resume if selected
      String? resumeUrl = _existingResumeUrl;
      if (_resumeFile != null && !_useExistingResume) {
        resumeUrl = await _storageService.uploadResume(_resumeFile!, user.userId);
      }

      // Prepare screening answers
      List<ScreeningAnswer>? answers;
      if (widget.job.screeningQuestions != null) {
        answers = widget.job.screeningQuestions!.map((q) {
          return ScreeningAnswer(
            questionId: q.id,
            question: q.question,
            answer: _answerControllers[q.id]?.text ?? '',
          );
        }).toList();
      }

      // Create application
      final application = ApplicationModel(
        applicationId: '',
        jobId: widget.job.jobId,
        jobTitle: widget.job.title,
        applicantId: user.userId,
        applicantName: user.fullName,
        applicantImage: user.profileImage,
        providerId: widget.job.providerId,
        companyId: widget.job.companyId,
        companyName: widget.job.companyName,
        coverLetter: _coverLetterController.text.trim(),
        resume: resumeUrl,
        answers: answers,
        status: 'pending',
        statusHistory: [],
        appliedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await applicationProvider.submitApplication(application);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(applicationProvider.error ?? 'Failed to submit application'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Job'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: widget.job.companyLogo != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.job.companyLogo!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    widget.job.companyName[0].toUpperCase(),
                                    style: AppTextStyles.h5,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                widget.job.companyName[0].toUpperCase(),
                                style: AppTextStyles.h5,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.job.title,
                            style: AppTextStyles.h6,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.job.companyName,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Resume Section
              Text('Resume', style: AppTextStyles.h6),
              const SizedBox(height: 8),

              if (_existingResumeUrl != null) ...[
                RadioListTile<bool>(
                  value: true,
                  groupValue: _useExistingResume,
                  onChanged: (value) {
                    setState(() => _useExistingResume = value!);
                  },
                  title: const Text('Use existing resume'),
                  subtitle: const Text('Your profile resume will be used'),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<bool>(
                  value: false,
                  groupValue: _useExistingResume,
                  onChanged: (value) {
                    setState(() => _useExistingResume = value!);
                  },
                  title: const Text('Upload new resume'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],

              if (!_useExistingResume || _existingResumeUrl == null) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickResume,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.grey300,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _resumeFile != null
                              ? Icons.description
                              : Icons.cloud_upload_outlined,
                          size: 48,
                          color: _resumeFile != null
                              ? AppColors.secondary
                              : AppColors.grey400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _resumeFile != null
                              ? _resumeFile!.path.split('/').last
                              : 'Tap to upload resume',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _resumeFile != null
                                ? AppColors.textPrimaryLight
                                : AppColors.grey500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_resumeFile == null)
                          Text(
                            'PDF, DOC, DOCX (Max 5MB)',
                            style: AppTextStyles.caption,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Cover Letter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cover Letter (Optional)', style: AppTextStyles.h6),
                  TextButton.icon(
                    onPressed: _isGeneratingCoverLetter ? null : _generateCoverLetter,
                    icon: _isGeneratingCoverLetter
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(_isGeneratingCoverLetter ? 'Generating...' : 'AI Generate'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _coverLetterController,
                hintText: 'Write a brief cover letter or use AI to generate one...',
                maxLines: 8,
              ),
              const SizedBox(height: 24),

              // Screening Questions
              if (widget.job.screeningQuestions?.isNotEmpty ?? false) ...[
                Text('Screening Questions', style: AppTextStyles.h6),
                const SizedBox(height: 16),
                ...widget.job.screeningQuestions!.map((question) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                question.question,
                                style: AppTextStyles.labelLarge,
                              ),
                            ),
                            if (question.isRequired)
                              Text(
                                '*',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (question.type == 'multiple_choice' &&
                            question.options != null)
                          ...question.options!.map((option) => RadioListTile(
                                value: option,
                                groupValue: _answerControllers[question.id]?.text,
                                onChanged: (value) {
                                  setState(() {
                                    _answerControllers[question.id]?.text =
                                        value as String;
                                  });
                                },
                                title: Text(option),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ))
                        else
                          CustomTextField(
                            controller: _answerControllers[question.id],
                            hintText: 'Your answer',
                            maxLines: question.type == 'text' ? 3 : 1,
                            validator: question.isRequired
                                ? (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'This question is required';
                                    }
                                    return null;
                                  }
                                : null,
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],

              // Submit Button
              CustomButton(
                text: 'Submit Application',
                onPressed: _submitApplication,
                isLoading: _isSubmitting,
                width: double.infinity,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
