import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final List<String> participants;
  final Map<String, ParticipantData> participantsData;
  final LastMessage? lastMessage;
  final Map<String, int> unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? relatedJobId;
  final String? relatedApplicationId;
  final bool isActive;

  ChatModel({
    required this.chatId,
    required this.participants,
    required this.participantsData,
    this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    this.relatedJobId,
    this.relatedApplicationId,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'participants': participants,
      'participantsData': participantsData.map((key, value) => MapEntry(key, value.toJson())),
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'relatedJobId': relatedJobId,
      'relatedApplicationId': relatedApplicationId,
      'isActive': isActive,
    };
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final participantsDataMap = <String, ParticipantData>{};
    if (json['participantsData'] != null) {
      (json['participantsData'] as Map<String, dynamic>).forEach((key, value) {
        participantsDataMap[key] = ParticipantData.fromJson(value as Map<String, dynamic>);
      });
    }

    final unreadCountMap = <String, int>{};
    if (json['unreadCount'] != null) {
      (json['unreadCount'] as Map<String, dynamic>).forEach((key, value) {
        unreadCountMap[key] = value as int;
      });
    }

    return ChatModel(
      chatId: json['chatId'] as String? ?? '',
      participants: (json['participants'] as List<dynamic>?)?.cast<String>() ?? [],
      participantsData: participantsDataMap,
      lastMessage: json['lastMessage'] != null
          ? LastMessage.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: unreadCountMap,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      relatedJobId: json['relatedJobId'] as String?,
      relatedApplicationId: json['relatedApplicationId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  ParticipantData? getOtherParticipantData(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantsData[otherId];
  }

  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }
}

class ParticipantData {
  final String name;
  final String? image;
  final String role;

  ParticipantData({
    required this.name,
    this.image,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'image': image,
      'role': role,
    };
  }

  factory ParticipantData.fromJson(Map<String, dynamic> json) {
    return ParticipantData(
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      role: json['role'] as String? ?? '',
    );
  }
}

class LastMessage {
  final String text;
  final String senderId;
  final DateTime timestamp;
  final String type;

  LastMessage({
    required this.text,
    required this.senderId,
    required this.timestamp,
    this.type = 'text',
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
    };
  }

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      text: json['text'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      type: json['type'] as String? ?? 'text',
    );
  }
}

class MessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final String? text;
  final String type;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final bool isRead;
  final List<String> readBy;
  final DateTime createdAt;
  final MessageModel? replyTo;

  MessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    this.text,
    required this.type,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.isRead = false,
    this.readBy = const [],
    required this.createdAt,
    this.replyTo,
  });

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'type': type,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'isRead': isRead,
      'readBy': readBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'replyTo': replyTo?.toJson(),
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['messageId'] as String? ?? '',
      chatId: json['chatId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      text: json['text'] as String?,
      type: json['type'] as String? ?? 'text',
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      isRead: json['isRead'] as bool? ?? false,
      readBy: (json['readBy'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      replyTo: json['replyTo'] != null
          ? MessageModel.fromJson(json['replyTo'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isText => type == 'text';
  bool get isImage => type == 'image';
  bool get isFile => type == 'file';
  bool get isSystem => type == 'system';
}
