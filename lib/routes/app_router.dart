import 'package:flutter/material.dart';
import '../core/constants/route_constants.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/auth/role_selection_view.dart';
import '../views/auth/forgot_password_view.dart';
import '../views/common/splash_view.dart';
import '../views/common/settings_view.dart';
import '../views/common/notifications_view.dart';
import '../views/job_seeker/seeker_main_view.dart';
import '../views/job_provider/provider_main_view.dart';
import '../views/job_provider/subscription_plans_view.dart';
import '../views/admin/admin_main_view.dart';
import '../views/admin/provider_approvals_view.dart';
import '../views/job_seeker/ai_resume_helper_view.dart';
import '../views/job_seeker/saved_jobs_view.dart';
import '../views/job_seeker/applications_view.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Initial Routes
      case RouteConstants.splash:
        return _buildRoute(const SplashView(), settings);

      // Auth Routes
      case RouteConstants.login:
        return _buildRoute(const LoginView(), settings);

      case RouteConstants.register:
        return _buildRoute(const RegisterView(), settings);

      case RouteConstants.roleSelection:
        return _buildRoute(const RoleSelectionView(), settings);

      case RouteConstants.forgotPassword:
        return _buildRoute(const ForgotPasswordView(), settings);

      // Job Seeker Routes
      case RouteConstants.seekerHome:
        return _buildRoute(const SeekerMainView(), settings);

      case RouteConstants.savedJobs:
        return _buildRoute(const SavedJobsView(), settings);

      case RouteConstants.myApplications:
        return _buildRoute(const ApplicationsView(), settings);

      case RouteConstants.aiResumeHelper:
        return _buildRoute(const AIResumeHelperView(), settings);

      // Job Provider Routes
      case RouteConstants.providerHome:
        return _buildRoute(const ProviderMainView(), settings);

      case RouteConstants.subscriptionPlans:
        return _buildRoute(const SubscriptionPlansView(), settings);

      // Admin Routes
      case RouteConstants.adminDashboard:
        return _buildRoute(const AdminMainView(), settings);

      case '/admin/provider-approvals':
        return _buildRoute(const ProviderApprovalsView(), settings);

      // Common Routes
      case RouteConstants.settings:
        return _buildRoute(const SettingsView(), settings);

      case RouteConstants.notifications:
        return _buildRoute(const NotificationsView(), settings);

      // Default - Unknown Route
      default:
        return _buildRoute(
          Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }

  // Navigation Helpers
  static void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static void navigateAndReplace(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  static void navigateAndClearStack(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static void pop(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }

  static void popUntil(BuildContext context, String routeName) {
    Navigator.popUntil(context, ModalRoute.withName(routeName));
  }
}
