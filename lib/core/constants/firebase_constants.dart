class FirebaseConstants {
  FirebaseConstants._();

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String companiesCollection = 'companies';
  static const String jobsCollection = 'jobs';
  static const String applicationsCollection = 'applications';
  static const String chatsCollection = 'chats';
  static const String messagesSubcollection = 'messages';
  static const String notificationsCollection = 'notifications';
  static const String subscriptionsCollection = 'subscriptions';
  static const String reviewsCollection = 'reviews';
  static const String analyticsCollection = 'analytics';
  static const String reportsCollection = 'reports';

  // Storage Paths
  static const String usersStoragePath = 'users';
  static const String companiesStoragePath = 'companies';
  static const String resumesStoragePath = 'resumes';
  static const String jobsStoragePath = 'jobs';
  static const String documentsStoragePath = 'documents';
  static const String chatAttachmentsPath = 'chat_attachments';

  // Firestore Field Names
  static const String fieldUserId = 'userId';
  static const String fieldEmail = 'email';
  static const String fieldRole = 'role';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldUpdatedAt = 'updatedAt';
  static const String fieldStatus = 'status';
  static const String fieldIsActive = 'isActive';
  static const String fieldIsVerified = 'isVerified';

  // Job Fields
  static const String fieldJobId = 'jobId';
  static const String fieldProviderId = 'providerId';
  static const String fieldCompanyId = 'companyId';
  static const String fieldTitle = 'title';
  static const String fieldDescription = 'description';
  static const String fieldCategory = 'category';
  static const String fieldViews = 'views';
  static const String fieldApplications = 'applications';
  static const String fieldSaves = 'saves';

  // Application Fields
  static const String fieldApplicationId = 'applicationId';
  static const String fieldApplicantId = 'applicantId';
  static const String fieldAppliedAt = 'appliedAt';

  // Chat Fields
  static const String fieldChatId = 'chatId';
  static const String fieldParticipants = 'participants';
  static const String fieldLastMessage = 'lastMessage';
  static const String fieldUnreadCount = 'unreadCount';

  // Message Fields
  static const String fieldMessageId = 'messageId';
  static const String fieldSenderId = 'senderId';
  static const String fieldText = 'text';
  static const String fieldType = 'type';
  static const String fieldIsRead = 'isRead';
}
