class RouteConstants {
  RouteConstants._();

  // Initial Routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // Auth Routes
  static const String login = '/login';
  static const String register = '/register';
  static const String roleSelection = '/role-selection';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';

  // Job Seeker Routes
  static const String seekerHome = '/seeker/home';
  static const String seekerProfile = '/seeker/profile';
  static const String seekerEditProfile = '/seeker/edit-profile';
  static const String jobSearch = '/seeker/job-search';
  static const String jobDetails = '/seeker/job-details';
  static const String applyJob = '/seeker/apply-job';
  static const String myApplications = '/seeker/my-applications';
  static const String applicationDetails = '/seeker/application-details';
  static const String savedJobs = '/seeker/saved-jobs';
  static const String resumeUpload = '/seeker/resume-upload';
  static const String aiProfileReview = '/seeker/ai-profile-review';
  static const String aiResumeHelper = '/seeker/ai-resume-helper';

  // Job Provider Routes
  static const String providerHome = '/provider/home';
  static const String providerProfile = '/provider/profile';
  static const String companyProfile = '/provider/company-profile';
  static const String editCompanyProfile = '/provider/edit-company-profile';
  static const String postJob = '/provider/post-job';
  static const String editJob = '/provider/edit-job';
  static const String manageJobs = '/provider/manage-jobs';
  static const String jobAnalytics = '/provider/job-analytics';
  static const String receivedApplications = '/provider/received-applications';
  static const String applicantProfile = '/provider/applicant-profile';
  static const String scheduleInterview = '/provider/schedule-interview';

  // Admin Routes
  static const String adminDashboard = '/admin/dashboard';
  static const String userManagement = '/admin/user-management';
  static const String userDetails = '/admin/user-details';
  static const String jobModeration = '/admin/job-moderation';
  static const String reportsView = '/admin/reports';
  static const String systemSettings = '/admin/system-settings';
  static const String companyManagement = '/admin/company-management';

  // Common Routes
  static const String chat = '/chat';
  static const String chatDetails = '/chat-details';
  static const String videoCall = '/video-call';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String helpSupport = '/help-support';
  static const String aboutApp = '/about-app';

  // Subscription Routes
  static const String subscriptionPlans = '/subscription/plans';
  static const String subscriptionDetails = '/subscription/details';
  static const String paymentHistory = '/subscription/payment-history';
}
