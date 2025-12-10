import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/firebase/company_service.dart';
import '../../services/ai/gemini_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class PostJobView extends StatefulWidget {
  final JobModel? existingJob;

  const PostJobView({super.key, this.existingJob});

  @override
  State<PostJobView> createState() => _PostJobViewState();
}

class _PostJobViewState extends State<PostJobView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skillsController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();

  String _selectedCategory = 'Technology';
  String _selectedEmploymentType = 'Full-time';
  String _selectedExperienceLevel = 'Mid Level';
  String _selectedWorkLocation = 'On-site';
  String _selectedSalaryType = 'monthly';
  String _selectedCurrency = 'USD';

  List<String> _skills = [];
  List<String> _requirements = [];
  List<ScreeningQuestion> _screeningQuestions = [];

  bool _isLoading = false;
  bool _isEdit = false;
  bool _isGeneratingDescription = false;
  bool _isGeneratingSkills = false;
  bool _isGeneratingRequirements = false;
  bool _isGeneratingQuestions = false;

  final List<String> _categories = [
    'Technology',
    'Design',
    'Marketing',
    'Finance',
    'Healthcare',
    'Education',
    'Sales',
    'Engineering',
    'Other',
  ];

  final List<String> _employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
    'Internship',
  ];

  final List<String> _experienceLevels = [
    'Entry Level',
    'Mid Level',
    'Senior Level',
    'Lead',
    'Manager',
  ];

  final List<String> _workLocations = ['On-site', 'Remote', 'Hybrid'];

  final List<String> _salaryTypes = ['hourly', 'daily', 'weekly', 'monthly', 'negotiable'];

  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'INR', 'AUD', 'CAD'];

  @override
  void initState() {
    super.initState();
    if (widget.existingJob != null) {
      _isEdit = true;
      _populateFields(widget.existingJob!);
    }
  }

  void _populateFields(JobModel job) {
    _titleController.text = job.title;
    _descriptionController.text = job.description;
    _selectedCategory = job.category;
    _selectedEmploymentType = job.employmentType;
    _selectedExperienceLevel = job.experienceLevel;
    _selectedWorkLocation = job.workLocation;
    _selectedSalaryType = job.salaryType;
    _selectedCurrency = job.currency;
    _salaryMinController.text = job.salaryMin?.toString() ?? '';
    _salaryMaxController.text = job.salaryMax?.toString() ?? '';
    _skills = List.from(job.skills);
    _requirements = List.from(job.requirements);
    _screeningQuestions = List.from(job.screeningQuestions ?? []);

    if (job.location != null) {
      _cityController.text = job.location!.city;
      _stateController.text = job.location!.state;
      _countryController.text = job.location!.country;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _skillsController.dispose();
    _requirementsController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _addSkill() {
    if (_skillsController.text.isNotEmpty) {
      setState(() {
        _skills.add(_skillsController.text.trim());
        _skillsController.clear();
      });
    }
  }

  void _addRequirement() {
    if (_requirementsController.text.isNotEmpty) {
      setState(() {
        _requirements.add(_requirementsController.text.trim());
        _requirementsController.clear();
      });
    }
  }

  bool _validateJobTitle() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a job title first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return false;
    }
    return true;
  }

  bool get _hasAIAccess {
    final subscriptionProvider = context.read<SubscriptionProvider>();
    return subscriptionProvider.hasAIAccess;
  }

  Widget _buildAIButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    final hasAccess = _hasAIAccess;
    return TextButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 18),
                if (!hasAccess) ...[
                  const SizedBox(width: 2),
                  const Icon(Icons.lock, size: 12),
                ],
              ],
            ),
      label: Text(isLoading ? 'Generating...' : label),
      style: TextButton.styleFrom(
        foregroundColor: hasAccess ? AppColors.primary : AppColors.grey500,
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primary),
            SizedBox(width: 8),
            Text('AI Features'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI-powered features are available with Pro and Enterprise plans.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Upgrade your subscription to unlock:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check, color: AppColors.success, size: 18),
                SizedBox(width: 8),
                Text('AI Job Description Generator'),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check, color: AppColors.success, size: 18),
                SizedBox(width: 8),
                Text('AI Skills Suggestions'),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check, color: AppColors.success, size: 18),
                SizedBox(width: 8),
                Text('AI Requirements Generator'),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check, color: AppColors.success, size: 18),
                SizedBox(width: 8),
                Text('AI Screening Questions'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/subscription-plans');
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateJobSkills() async {
    if (!_hasAIAccess) {
      _showUpgradeDialog();
      return;
    }
    if (!_validateJobTitle()) return;

    setState(() => _isGeneratingSkills = true);

    try {
      final geminiService = GeminiService();
      final skills = await geminiService.generateJobSkills(
        jobTitle: _titleController.text,
        category: _selectedCategory,
        experienceLevel: _selectedExperienceLevel,
      );

      if (skills != null) {
        setState(() {
          _skills = skills;
        });
      } else {
        _showErrorSnackBar('Failed to generate skills');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isGeneratingSkills = false);
    }
  }

  Future<void> _generateJobRequirements() async {
    if (!_hasAIAccess) {
      _showUpgradeDialog();
      return;
    }
    if (!_validateJobTitle()) return;

    setState(() => _isGeneratingRequirements = true);

    try {
      final geminiService = GeminiService();
      final requirements = await geminiService.generateJobRequirements(
        jobTitle: _titleController.text,
        category: _selectedCategory,
        experienceLevel: _selectedExperienceLevel,
        employmentType: _selectedEmploymentType,
      );

      if (requirements != null) {
        setState(() {
          _requirements = requirements;
        });
      } else {
        _showErrorSnackBar('Failed to generate requirements');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isGeneratingRequirements = false);
    }
  }

  Future<void> _generateScreeningQuestions() async {
    if (!_hasAIAccess) {
      _showUpgradeDialog();
      return;
    }
    if (!_validateJobTitle()) return;

    setState(() => _isGeneratingQuestions = true);

    try {
      final geminiService = GeminiService();
      final questions = await geminiService.generateJobScreeningQuestions(
        jobTitle: _titleController.text,
        category: _selectedCategory,
        experienceLevel: _selectedExperienceLevel,
      );

      if (questions != null) {
        setState(() {
          _screeningQuestions = questions.map((q) => ScreeningQuestion(
            id: DateTime.now().millisecondsSinceEpoch.toString() + q['question'].hashCode.toString(),
            question: q['question'] ?? '',
            type: q['type'] ?? 'text',
            isRequired: true,
          )).toList();
        });
      } else {
        _showErrorSnackBar('Failed to generate questions');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isGeneratingQuestions = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _generateJobDescription() async {
    if (!_hasAIAccess) {
      _showUpgradeDialog();
      return;
    }
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a job title first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isGeneratingDescription = true);

    try {
      final geminiService = GeminiService();
      final description = await geminiService.generateJobDescription(
        jobTitle: _titleController.text,
        category: _selectedCategory,
        employmentType: _selectedEmploymentType,
        experienceLevel: _selectedExperienceLevel,
        workLocation: _selectedWorkLocation,
      );

      if (description != null) {
        _descriptionController.text = description;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate description. Please try again.'),
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
        setState(() => _isGeneratingDescription = false);
      }
    }
  }

  void _addScreeningQuestion() {
    showDialog(
      context: context,
      builder: (context) {
        final questionController = TextEditingController();
        String questionType = 'text';

        return AlertDialog(
          title: const Text('Add Screening Question'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  hintText: 'Enter your question',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: questionType,
                decoration: const InputDecoration(labelText: 'Answer Type'),
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('Text')),
                  DropdownMenuItem(value: 'yes_no', child: Text('Yes/No')),
                  DropdownMenuItem(value: 'number', child: Text('Number')),
                ],
                onChanged: (value) {
                  questionType = value ?? 'text';
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (questionController.text.isNotEmpty) {
                  setState(() {
                    _screeningQuestions.add(ScreeningQuestion(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      question: questionController.text,
                      type: questionType,
                      isRequired: true,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveJob({bool asDraft = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final jobProvider = context.read<JobProvider>();
      final user = authProvider.currentUser;

      if (user == null) return;

      // Get company info
      final companyService = CompanyService();
      final company = await companyService.getCompanyByOwner(user.userId);

      final job = JobModel(
        jobId: widget.existingJob?.jobId ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        companyId: company?.companyId ?? '',
        companyName: company?.name ?? 'Your Company',
        companyLogo: company?.logo,
        providerId: user.userId,
        category: _selectedCategory,
        employmentType: _selectedEmploymentType,
        experienceLevel: _selectedExperienceLevel,
        skills: _skills,
        requirements: _requirements,
        salaryType: _selectedSalaryType,
        salaryMin: double.tryParse(_salaryMinController.text),
        salaryMax: double.tryParse(_salaryMaxController.text),
        currency: _selectedCurrency,
        workLocation: _selectedWorkLocation,
        location: _cityController.text.isNotEmpty
            ? JobLocation(
                city: _cityController.text.trim(),
                state: _stateController.text.trim(),
                country: _countryController.text.trim(),
              )
            : null,
        status: asDraft ? 'draft' : 'active',
        screeningQuestions: _screeningQuestions.isNotEmpty ? _screeningQuestions : null,
        createdAt: widget.existingJob?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        publishedAt: asDraft ? null : DateTime.now(),
      );

      bool success;
      if (_isEdit) {
        success = await jobProvider.updateJob(job.jobId, job.toJson());
      } else {
        success = await jobProvider.createJob(job);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              asDraft
                  ? 'Job saved as draft'
                  : _isEdit
                      ? 'Job updated successfully'
                      : 'Job posted successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Job' : 'Post a Job'),
        actions: [
          if (!_isEdit)
            TextButton(
              onPressed: () => _saveJob(asDraft: true),
              child: const Text('Save Draft'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info
              Text('Basic Information', style: AppTextStyles.h6),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _titleController,
                label: 'Job Title',
                hintText: 'e.g., Senior Flutter Developer',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Job Description'),
                  _buildAIButton(
                    label: 'AI Generate',
                    isLoading: _isGeneratingDescription,
                    onPressed: _generateJobDescription,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _descriptionController,
                hintText: 'Describe the role, responsibilities, and what you\'re looking for...',
                maxLines: 6,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 24),

              // Employment Details
              Text('Employment Details', style: AppTextStyles.h6),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedEmploymentType,
                      decoration: InputDecoration(
                        labelText: 'Employment Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _employmentTypes
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedEmploymentType = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedWorkLocation,
                      decoration: InputDecoration(
                        labelText: 'Work Location',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _workLocations
                          .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedWorkLocation = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedExperienceLevel,
                decoration: InputDecoration(
                  labelText: 'Experience Level',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _experienceLevels
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedExperienceLevel = v!),
              ),
              const SizedBox(height: 24),

              // Location
              Text('Location', style: AppTextStyles.h6),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _cityController,
                      label: 'City',
                      hintText: 'e.g., New York',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _stateController,
                      label: 'State',
                      hintText: 'e.g., NY',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _countryController,
                label: 'Country',
                hintText: 'e.g., United States',
              ),
              const SizedBox(height: 24),

              // Salary
              Text('Compensation', style: AppTextStyles.h6),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSalaryType,
                      decoration: InputDecoration(
                        labelText: 'Salary Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _salaryTypes
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedSalaryType = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _currencies
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCurrency = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_selectedSalaryType != 'negotiable')
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _salaryMinController,
                        label: 'Minimum',
                        hintText: '50000',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _salaryMaxController,
                        label: 'Maximum',
                        hintText: '80000',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // Skills
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Required Skills', style: AppTextStyles.h6),
                  _buildAIButton(
                    label: 'AI Generate',
                    isLoading: _isGeneratingSkills,
                    onPressed: _generateJobSkills,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _skillsController,
                      hintText: 'Add a skill',
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                    onPressed: _addSkill,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _skills.map((skill) {
                  return Chip(
                    label: Text(skill),
                    onDeleted: () {
                      setState(() => _skills.remove(skill));
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Requirements
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Requirements', style: AppTextStyles.h6),
                  _buildAIButton(
                    label: 'AI Generate',
                    isLoading: _isGeneratingRequirements,
                    onPressed: _generateJobRequirements,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _requirementsController,
                      hintText: 'Add a requirement',
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                    onPressed: _addRequirement,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...(_requirements.asMap().entries.map((entry) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle, color: AppColors.secondary),
                  title: Text(entry.value),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() => _requirements.removeAt(entry.key));
                    },
                  ),
                );
              })),
              const SizedBox(height: 24),

              // Screening Questions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Screening Questions', style: AppTextStyles.h6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAIButton(
                        label: 'AI Generate',
                        isLoading: _isGeneratingQuestions,
                        onPressed: _generateScreeningQuestions,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                        onPressed: _addScreeningQuestion,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...(_screeningQuestions.asMap().entries.map((entry) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(entry.value.question),
                    subtitle: Text('Type: ${entry.value.type}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () {
                        setState(() => _screeningQuestions.removeAt(entry.key));
                      },
                    ),
                  ),
                );
              })),
              const SizedBox(height: 32),

              // Submit Button
              CustomButton(
                text: _isEdit ? 'Update Job' : 'Post Job',
                onPressed: () => _saveJob(),
                isLoading: _isLoading,
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
