import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/constants/firebase_constants.dart';
import '../../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  CollectionReference get _notifications =>
      _db.collection(FirebaseConstants.notificationsCollection);

  // Initialize FCM
  Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        // Token will be saved when user logs in
      }
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    // Handle notification when app is in foreground
    // You can show a local notification or update UI
  }

  // Handle message opened
  void _handleMessageOpenedApp(RemoteMessage message) {
    // Navigate to appropriate screen based on notification data
  }

  // Save FCM Token
  Future<void> saveFcmToken(String userId, String token) async {
    await _db.collection(FirebaseConstants.usersCollection).doc(userId).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get FCM Token
  Future<String?> getFcmToken() async {
    return await _messaging.getToken();
  }

  // Delete FCM Token
  Future<void> deleteFcmToken(String userId) async {
    await _messaging.deleteToken();
    await _db.collection(FirebaseConstants.usersCollection).doc(userId).update({
      'fcmToken': null,
    });
  }

  // Create Notification
  Future<NotificationModel> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? actionUrl,
  }) async {
    final docRef = _notifications.doc();

    final notification = NotificationModel(
      notificationId: docRef.id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
      actionUrl: actionUrl,
      createdAt: DateTime.now(),
    );

    await docRef.set(notification.toJson());
    return notification;
  }

  // Get User Notifications
  Future<List<NotificationModel>> getUserNotifications(
    String userId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _notifications
        .where(FirebaseConstants.fieldUserId, isEqualTo: userId)
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => NotificationModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Stream User Notifications (includes user-specific and broadcast notifications)
  Stream<List<NotificationModel>> streamUserNotifications(String userId, {int limit = 50}) {
    // Get both user-specific notifications and broadcast notifications (userId = 'all')
    return _notifications
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .limit(limit * 2) // Fetch more to filter client-side
        .snapshots()
        .map((snapshot) {
          final allNotifications = snapshot.docs
              .map((doc) => NotificationModel.fromJson(doc.data() as Map<String, dynamic>))
              .where((notification) =>
                  notification.userId == userId ||
                  notification.userId == 'all' ||
                  notification.userId.isEmpty)
              .take(limit)
              .toList();
          return allNotifications;
        });
  }

  // Get Unread Notifications Count
  Future<int> getUnreadCount(String userId) async {
    final snapshot = await _notifications
        .where(FirebaseConstants.fieldUserId, isEqualTo: userId)
        .where(FirebaseConstants.fieldIsRead, isEqualTo: false)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // Stream Unread Count
  Stream<int> streamUnreadCount(String userId) {
    return _notifications
        .where(FirebaseConstants.fieldUserId, isEqualTo: userId)
        .where(FirebaseConstants.fieldIsRead, isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark Notification as Read
  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({
      FirebaseConstants.fieldIsRead: true,
    });
  }

  // Mark All as Read (handles both user-specific and broadcast notifications)
  Future<void> markAllAsRead(String userId) async {
    // Get all unread notifications
    final snapshot = await _notifications
        .where(FirebaseConstants.fieldIsRead, isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final notificationUserId = data['userId'] as String? ?? '';
      // Only mark as read if it's for this user or is a broadcast notification
      if (notificationUserId == userId ||
          notificationUserId == 'all' ||
          notificationUserId.isEmpty) {
        batch.update(doc.reference, {FirebaseConstants.fieldIsRead: true});
      }
    }
    await batch.commit();
  }

  // Delete Notification
  Future<void> deleteNotification(String notificationId) async {
    await _notifications.doc(notificationId).delete();
  }

  // Delete All Notifications
  Future<void> deleteAllNotifications(String userId) async {
    final snapshot = await _notifications
        .where(FirebaseConstants.fieldUserId, isEqualTo: userId)
        .get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Send Application Notification
  Future<void> sendApplicationNotification({
    required String userId,
    required String applicantName,
    required String jobTitle,
    required String applicationId,
    required String type, // 'new', 'status_update', 'interview'
  }) async {
    String title;
    String body;

    switch (type) {
      case 'new':
        title = 'New Application';
        body = '$applicantName applied for $jobTitle';
        break;
      case 'status_update':
        title = 'Application Update';
        body = 'Your application for $jobTitle has been updated';
        break;
      case 'interview':
        title = 'Interview Scheduled';
        body = 'You have an interview scheduled for $jobTitle';
        break;
      default:
        title = 'Application Notification';
        body = 'Update regarding your application for $jobTitle';
    }

    await createNotification(
      userId: userId,
      type: NotificationModel.typeApplication,
      title: title,
      body: body,
      data: {
        'applicationId': applicationId,
        'notificationType': type,
      },
      actionUrl: '/applications/$applicationId',
    );
  }

  // Send Message Notification
  Future<void> sendMessageNotification({
    required String userId,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationModel.typeMessage,
      title: 'New Message',
      body: '$senderName: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
      data: {'chatId': chatId},
      actionUrl: '/chat/$chatId',
    );
  }

  // Send Job Alert Notification
  Future<void> sendJobAlertNotification({
    required String userId,
    required String jobTitle,
    required String companyName,
    required String jobId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationModel.typeJobAlert,
      title: 'New Job Match',
      body: '$companyName is hiring: $jobTitle',
      data: {'jobId': jobId},
      actionUrl: '/jobs/$jobId',
    );
  }

  // Send Interview Reminder
  Future<void> sendInterviewReminder({
    required String userId,
    required String jobTitle,
    required String companyName,
    required DateTime interviewTime,
    required String applicationId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationModel.typeInterview,
      title: 'Interview Reminder',
      body: 'Your interview with $companyName for $jobTitle is coming up',
      data: {
        'applicationId': applicationId,
        'interviewTime': interviewTime.toIso8601String(),
      },
      actionUrl: '/applications/$applicationId',
    );
  }

  // Send Status Update Notification
  Future<void> sendStatusUpdateNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationModel.typeStatusUpdate,
      title: title,
      body: body,
      data: data,
    );
  }

  // Send System Notification
  Future<void> sendSystemNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationModel.typeSystem,
      title: title,
      body: body,
    );
  }

  // Get Notification Preferences
  Future<NotificationPreferences> getPreferences(String userId) async {
    final doc = await _db.collection(FirebaseConstants.usersCollection).doc(userId).get();
    if (!doc.exists) return NotificationPreferences();

    final data = doc.data() as Map<String, dynamic>;
    if (data['notificationPreferences'] == null) return NotificationPreferences();

    return NotificationPreferences.fromJson(
      data['notificationPreferences'] as Map<String, dynamic>,
    );
  }

  // Update Notification Preferences
  Future<void> updatePreferences(
    String userId,
    NotificationPreferences preferences,
  ) async {
    await _db.collection(FirebaseConstants.usersCollection).doc(userId).update({
      'notificationPreferences': preferences.toJson(),
    });
  }

  // Subscribe to Topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  // Unsubscribe from Topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  // Subscribe to Job Category
  Future<void> subscribeToJobCategory(String category) async {
    await subscribeToTopic('jobs_${category.toLowerCase().replaceAll(' ', '_')}');
  }

  // Unsubscribe from Job Category
  Future<void> unsubscribeFromJobCategory(String category) async {
    await unsubscribeFromTopic('jobs_${category.toLowerCase().replaceAll(' ', '_')}');
  }

  // Clear Old Notifications (utility for cleanup)
  Future<void> clearOldNotifications(String userId, {int daysOld = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    final snapshot = await _notifications
        .where(FirebaseConstants.fieldUserId, isEqualTo: userId)
        .where(FirebaseConstants.fieldCreatedAt, isLessThan: Timestamp.fromDate(cutoffDate))
        .get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  // Handle background message
}
