import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String notificationId;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final String? actionUrl;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    this.actionUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'actionUrl': actionUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      actionUrl: json['actionUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  NotificationModel copyWith({
    String? notificationId,
    String? userId,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    String? actionUrl,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Notification Types
  static const String typeApplication = 'application';
  static const String typeMessage = 'message';
  static const String typeJobAlert = 'job_alert';
  static const String typeInterview = 'interview';
  static const String typeStatusUpdate = 'status_update';
  static const String typeSystem = 'system';
  static const String typePromotion = 'promotion';
}

class NotificationPreferences {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool applicationUpdates;
  final bool messageNotifications;
  final bool jobAlerts;
  final bool interviewReminders;
  final bool promotionalMessages;

  NotificationPreferences({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.applicationUpdates = true,
    this.messageNotifications = true,
    this.jobAlerts = true,
    this.interviewReminders = true,
    this.promotionalMessages = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'applicationUpdates': applicationUpdates,
      'messageNotifications': messageNotifications,
      'jobAlerts': jobAlerts,
      'interviewReminders': interviewReminders,
      'promotionalMessages': promotionalMessages,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? true,
      applicationUpdates: json['applicationUpdates'] as bool? ?? true,
      messageNotifications: json['messageNotifications'] as bool? ?? true,
      jobAlerts: json['jobAlerts'] as bool? ?? true,
      interviewReminders: json['interviewReminders'] as bool? ?? true,
      promotionalMessages: json['promotionalMessages'] as bool? ?? false,
    );
  }
}
