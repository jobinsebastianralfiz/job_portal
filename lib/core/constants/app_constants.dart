class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'JobPortal';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Find Your Dream Job';

  // User Roles
  static const String roleJobSeeker = 'job_seeker';
  static const String roleJobProvider = 'job_provider';
  static const String roleAdmin = 'admin';

  // Job Categories
  static const List<String> jobCategories = [
    'Technology',
    'Healthcare',
    'Education',
    'Retail',
    'Hospitality',
    'Finance',
    'Marketing',
    'Customer Service',
    'Construction',
    'Transportation',
    'Other',
  ];

  // Employment Types
  static const List<String> employmentTypes = [
    'Full-time',
    'Part-time',
    'Freelance',
    'Contract',
    'Internship',
  ];

  // Experience Levels
  static const List<String> experienceLevels = [
    'Entry Level',
    'Intermediate',
    'Expert',
  ];

  // Work Location Types
  static const List<String> workLocationTypes = [
    'On-site',
    'Remote',
    'Hybrid',
  ];

  // Salary Types
  static const List<String> salaryTypes = [
    'Hourly',
    'Daily',
    'Weekly',
    'Monthly',
    'Fixed',
    'Negotiable',
  ];

  // Application Status
  static const String statusPending = 'pending';
  static const String statusReviewed = 'reviewed';
  static const String statusShortlisted = 'shortlisted';
  static const String statusInterview = 'interview';
  static const String statusOffered = 'offered';
  static const String statusAccepted = 'accepted';
  static const String statusRejected = 'rejected';
  static const String statusWithdrawn = 'withdrawn';

  // Job Status
  static const String jobStatusDraft = 'draft';
  static const String jobStatusActive = 'active';
  static const String jobStatusClosed = 'closed';
  static const String jobStatusExpired = 'expired';

  // Subscription Tiers
  static const String tierFree = 'free';
  static const String tierBasic = 'basic';
  static const String tierPremium = 'premium';
  static const String tierEnterprise = 'enterprise';

  // Company Sizes
  static const List<String> companySizes = [
    '1-10',
    '11-50',
    '51-200',
    '201-500',
    '501+',
  ];

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // File Upload Limits
  static const int maxProfileImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxResumeSize = 10 * 1024 * 1024; // 10MB
  static const int maxDocumentSize = 15 * 1024 * 1024; // 15MB

  // Allowed File Extensions
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedResumeExtensions = ['pdf', 'doc', 'docx'];
  static const List<String> allowedDocumentExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'];

  // Cache Duration
  static const Duration cacheDuration = Duration(hours: 24);

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 350);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
}
