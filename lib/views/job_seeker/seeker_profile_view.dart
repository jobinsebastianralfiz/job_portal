import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase/storage_service.dart';
import '../../services/firebase/user_service.dart';
import '../../services/ai/gemini_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class SeekerProfileView extends StatefulWidget {
  const SeekerProfileView({super.key});

  @override
  State<SeekerProfileView> createState() => _SeekerProfileViewState();
}

class _SeekerProfileViewState extends State<SeekerProfileView> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            _ProfileHeader(
              name: user.fullName,
              email: user.email,
              image: user.profileImage,
              onEditPhoto: () => _pickProfileImage(context),
            ),
            const SizedBox(height: 24),

            // Profile Completion
            _ProfileCompletionCard(
              completionPercentage: _calculateProfileCompletion(user),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.description,
                    title: 'Resume',
                    subtitle: user.resume != null ? 'Uploaded' : 'Not uploaded',
                    onTap: () => _showResumeOptions(context),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.auto_awesome,
                    title: 'AI Parse',
                    subtitle: 'Auto-fill profile',
                    onTap: () => Navigator.pushNamed(context, '/seeker/ai-resume-helper'),
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Profile Sections
            _ProfileSection(
              title: 'Personal Information',
              icon: Icons.person_outline,
              onEdit: () => _showEditPersonalInfoSheet(context),
              children: [
                _InfoItem(label: 'Full Name', value: user.fullName),
                _InfoItem(label: 'Email', value: user.email),
                _InfoItem(label: 'Phone', value: user.phoneNumber ?? 'Not provided'),
                _InfoItem(
                  label: 'Location',
                  value: user.location?.shortAddress ?? 'Not provided',
                ),
              ],
            ),
            const SizedBox(height: 16),

            _ProfileSection(
              title: 'Professional Summary',
              icon: Icons.work_outline,
              onEdit: () => _showEditSummarySheet(context),
              children: [
                Text(
                  user.summary ?? 'Add a professional summary to stand out to employers.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: user.summary != null
                        ? AppColors.textPrimaryLight
                        : AppColors.grey500,
                    fontStyle:
                        user.summary != null ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _ProfileSection(
              title: 'Skills',
              icon: Icons.psychology_outlined,
              onEdit: () => _showEditSkillsSheet(context),
              children: [
                if (user.skills?.isNotEmpty ?? false)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.skills!.map((skill) {
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
                  )
                else
                  Text(
                    'Add your skills to match with relevant jobs.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            _ProfileSection(
              title: 'Experience',
              icon: Icons.business_center_outlined,
              onEdit: () => _showEditExperienceSheet(context),
              children: [
                Text(
                  user.experience ?? 'Add your work experience.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: user.experience != null
                        ? AppColors.textPrimaryLight
                        : AppColors.grey500,
                    fontStyle:
                        user.experience != null ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _ProfileSection(
              title: 'Education',
              icon: Icons.school_outlined,
              onEdit: () => _showEditEducationSheet(context),
              children: [
                Text(
                  user.education ?? 'Add your education details.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: user.education != null
                        ? AppColors.textPrimaryLight
                        : AppColors.grey500,
                    fontStyle:
                        user.education != null ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Logout Button
            CustomButton(
              text: 'Logout',
              onPressed: () => _showLogoutDialog(context),
              isOutlined: true,
              icon: Icons.logout,
              width: double.infinity,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  int _calculateProfileCompletion(user) {
    int completed = 0;
    int total = 7;

    if (user.firstName.isNotEmpty) completed++;
    if (user.email.isNotEmpty) completed++;
    if (user.phoneNumber != null) completed++;
    if (user.skills?.isNotEmpty ?? false) completed++;
    if (user.experience != null) completed++;
    if (user.education != null) completed++;
    if (user.resume != null) completed++;

    return ((completed / total) * 100).round();
  }

  Future<void> _pickProfileImage(BuildContext context) async {
    // Get user and auth provider before any async operation
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && mounted) {
      final storageService = StorageService();
      final url = await storageService.uploadProfileImage(
        File(image.path),
        user.userId,
      );

      if (url != null && mounted) {
        final userService = UserService();
        await userService.updateProfile(userId: user.userId, profileImage: url);
        // Reload user data to show updated image
        await authProvider.refreshUserData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated')),
          );
        }
      }
    }
  }

  void _showResumeOptions(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload New Resume'),
              onTap: () {
                Navigator.pop(sheetContext);
                _uploadResume();
              },
            ),
            if (user?.resume != null)
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View Current Resume'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _viewResume(user!.resume!);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadResume() async {
    // Get user and scaffold messenger from widget's context (not sheet context)
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null && mounted) {
      final storageService = StorageService();
      final url = await storageService.uploadResume(
        File(result.files.single.path!),
        user.userId,
      );

      if (url != null && mounted) {
        final userService = UserService();
        await userService.updateJobSeekerProfile(userId: user.userId, resume: url);
        // Refresh user data to show updated resume status
        await authProvider.refreshUserData();
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Resume uploaded successfully')),
        );
      }
    }
  }

  Future<void> _viewResume(String resumeUrl) async {
    final uri = Uri.parse(resumeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open resume')),
        );
      }
    }
  }

  void _showEditPersonalInfoSheet(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);
    final phoneController = TextEditingController(text: user.phoneNumber);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Personal Info', style: AppTextStyles.h5),
              const SizedBox(height: 16),
              CustomTextField(
                controller: firstNameController,
                label: 'First Name',
                hintText: 'Enter first name',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: lastNameController,
                label: 'Last Name',
                hintText: 'Enter last name',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: phoneController,
                label: 'Phone',
                hintText: 'Enter phone number',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Save Changes',
                onPressed: () async {
                  final userService = UserService();
                  await userService.updateProfile(
                    userId: user.userId,
                    firstName: firstNameController.text,
                    lastName: lastNameController.text,
                    phone: phoneController.text,
                  );
                  if (context.mounted) {
                    context.read<AuthProvider>().refreshUserData();
                    Navigator.pop(context);
                  }
                },
                width: double.infinity,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSummarySheet(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final summaryController = TextEditingController(text: user.summary);
    bool isGenerating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Professional Summary', style: AppTextStyles.h5),
                    TextButton.icon(
                      onPressed: isGenerating
                          ? null
                          : () async {
                              setModalState(() => isGenerating = true);
                              final geminiService = GeminiService();
                              final summary = await geminiService.generateProfessionalSummary(
                                skills: user.skills,
                                experience: user.experience,
                                education: user.education,
                              );
                              if (summary != null) {
                                summaryController.text = summary;
                              }
                              setModalState(() => isGenerating = false);
                            },
                      icon: isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(isGenerating ? 'Generating...' : 'AI Generate'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: summaryController,
                  hintText: 'Write a brief summary about yourself...',
                  maxLines: 5,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Save',
                  onPressed: () async {
                    final userService = UserService();
                    await userService.updateJobSeekerProfile(
                      userId: user.userId,
                      summary: summaryController.text,
                    );
                    // Refresh user data
                    if (context.mounted) {
                      context.read<AuthProvider>().refreshUserData();
                      Navigator.pop(context);
                    }
                  },
                  width: double.infinity,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditSkillsSheet(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final skills = List<String>.from(user.skills ?? []);
    final skillController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Skills', style: AppTextStyles.h5),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: skillController,
                        hintText: 'Add a skill',
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primary),
                      onPressed: () {
                        if (skillController.text.isNotEmpty) {
                          setModalState(() {
                            skills.add(skillController.text.trim());
                            skillController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills.map((skill) {
                    return Chip(
                      label: Text(skill),
                      onDeleted: () {
                        setModalState(() {
                          skills.remove(skill);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Save Skills',
                  onPressed: () async {
                    final userService = UserService();
                    await userService.updateJobSeekerProfile(
                      userId: user.userId,
                      skills: skills,
                    );
                    if (context.mounted) {
                      context.read<AuthProvider>().refreshUserData();
                      Navigator.pop(context);
                    }
                  },
                  width: double.infinity,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditExperienceSheet(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final experienceController = TextEditingController(text: user.experience);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Work Experience', style: AppTextStyles.h5),
              const SizedBox(height: 16),
              CustomTextField(
                controller: experienceController,
                hintText: 'Describe your work experience...',
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Save',
                onPressed: () async {
                  final userService = UserService();
                  await userService.updateJobSeekerProfile(
                    userId: user.userId,
                    experience: experienceController.text,
                  );
                  if (context.mounted) {
                    context.read<AuthProvider>().refreshUserData();
                    Navigator.pop(context);
                  }
                },
                width: double.infinity,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditEducationSheet(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final educationController = TextEditingController(text: user.education);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Education', style: AppTextStyles.h5),
              const SizedBox(height: 16),
              CustomTextField(
                controller: educationController,
                hintText: 'Describe your education...',
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Save',
                onPressed: () async {
                  final userService = UserService();
                  await userService.updateJobSeekerProfile(
                    userId: user.userId,
                    education: educationController.text,
                  );
                  if (context.mounted) {
                    context.read<AuthProvider>().refreshUserData();
                    Navigator.pop(context);
                  }
                },
                width: double.infinity,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? image;
  final VoidCallback onEditPhoto;

  const _ProfileHeader({
    required this.name,
    required this.email,
    this.image,
    required this.onEditPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.grey200,
              backgroundImage: image != null ? NetworkImage(image!) : null,
              child: image == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: AppTextStyles.h1.copyWith(color: AppColors.grey500),
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: onEditPhoto,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(name, style: AppTextStyles.h4),
        Text(email, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500)),
      ],
    );
  }
}

class _ProfileCompletionCard extends StatelessWidget {
  final int completionPercentage;

  const _ProfileCompletionCard({required this.completionPercentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completionPercentage < 100
            ? AppColors.warningLight
            : AppColors.successLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: completionPercentage / 100,
                  strokeWidth: 4,
                  backgroundColor: AppColors.grey300,
                  valueColor: AlwaysStoppedAnimation(
                    completionPercentage < 100 ? AppColors.warning : AppColors.success,
                  ),
                ),
              ),
              Text(
                '$completionPercentage%',
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completionPercentage < 100
                      ? 'Complete Your Profile'
                      : 'Profile Complete!',
                  style: AppTextStyles.labelLarge,
                ),
                Text(
                  completionPercentage < 100
                      ? 'A complete profile increases your visibility'
                      : 'Your profile looks great!',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: AppTextStyles.labelLarge),
            Text(subtitle, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onEdit;
  final List<Widget> children;

  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.onEdit,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: AppTextStyles.h6),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.bodySmall,
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
