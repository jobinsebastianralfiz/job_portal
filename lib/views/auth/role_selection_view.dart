import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../widgets/custom_button.dart';

class RoleSelectionView extends StatefulWidget {
  const RoleSelectionView({super.key});

  @override
  State<RoleSelectionView> createState() => _RoleSelectionViewState();
}

class _RoleSelectionViewState extends State<RoleSelectionView> {
  String? _selectedRole;

  Future<void> _handleContinue() async {
    if (_selectedRole == null) {
      Helpers.showSnackBar(
        context,
        'Please select a role to continue',
        isError: true,
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.updateUserRole(_selectedRole!);

    if (!mounted) return;

    if (success) {
      String route;
      switch (_selectedRole) {
        case AppConstants.roleJobSeeker:
          route = RouteConstants.seekerHome;
          break;
        case AppConstants.roleJobProvider:
          route = RouteConstants.providerHome;
          break;
        default:
          route = RouteConstants.seekerHome;
      }
      Navigator.pushReplacementNamed(context, route);
    } else {
      Helpers.showSnackBar(
        context,
        authProvider.error ?? 'Failed to update role',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Header
              Text(
                'Choose Your Role',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Select how you want to use JobPortal',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Role Cards
              Expanded(
                child: Column(
                  children: [
                    // Job Seeker Card
                    _RoleCard(
                      title: 'Job Seeker',
                      description: 'Find and apply for jobs, build your profile, and connect with employers',
                      icon: Icons.person_search_rounded,
                      color: AppColors.jobSeekerColor,
                      isSelected: _selectedRole == AppConstants.roleJobSeeker,
                      onTap: () {
                        setState(() {
                          _selectedRole = AppConstants.roleJobSeeker;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Job Provider Card
                    _RoleCard(
                      title: 'Job Provider',
                      description: 'Post jobs, manage applications, and find the perfect candidates',
                      icon: Icons.business_center_rounded,
                      color: AppColors.jobProviderColor,
                      isSelected: _selectedRole == AppConstants.roleJobProvider,
                      onTap: () {
                        setState(() {
                          _selectedRole = AppConstants.roleJobProvider;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Continue Button
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return CustomButton(
                    text: 'Continue',
                    onPressed: _handleContinue,
                    isLoading: authProvider.isLoading,
                  );
                },
              ),
              const SizedBox(height: 16),
              // Note
              Text(
                'You can change your role later in settings',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.grey200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? AppColors.white : color,
              ),
            ),
            const SizedBox(width: 16),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.h5.copyWith(
                      color: isSelected ? color : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : AppColors.transparent,
                border: Border.all(
                  color: isSelected ? color : AppColors.grey300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
