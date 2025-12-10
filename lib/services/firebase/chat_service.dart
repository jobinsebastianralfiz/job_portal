import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';
import '../../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _chats => _db.collection(FirebaseConstants.chatsCollection);

  // Create or Get Chat
  Future<ChatModel> getOrCreateChat({
    required String user1Id,
    required String user1Name,
    String? user1Image,
    required String user1Role,
    required String user2Id,
    required String user2Name,
    String? user2Image,
    required String user2Role,
    String? relatedJobId,
    String? relatedApplicationId,
  }) async {
    // Check if chat already exists between these users
    final existingChat = await _chats
        .where(FirebaseConstants.fieldParticipants, arrayContains: user1Id)
        .get();

    for (var doc in existingChat.docs) {
      final participants = (doc.data() as Map<String, dynamic>)[FirebaseConstants.fieldParticipants] as List<dynamic>;
      if (participants.contains(user2Id)) {
        return ChatModel.fromJson(doc.data() as Map<String, dynamic>);
      }
    }

    // Create new chat
    final docRef = _chats.doc();
    final now = DateTime.now();

    final newChat = ChatModel(
      chatId: docRef.id,
      participants: [user1Id, user2Id],
      participantsData: {
        user1Id: ParticipantData(
          name: user1Name,
          image: user1Image,
          role: user1Role,
        ),
        user2Id: ParticipantData(
          name: user2Name,
          image: user2Image,
          role: user2Role,
        ),
      },
      unreadCount: {user1Id: 0, user2Id: 0},
      createdAt: now,
      updatedAt: now,
      relatedJobId: relatedJobId,
      relatedApplicationId: relatedApplicationId,
    );

    await docRef.set(newChat.toJson());
    return newChat;
  }

  // Get Chat by ID
  Future<ChatModel?> getChat(String chatId) async {
    final doc = await _chats.doc(chatId).get();
    if (!doc.exists) return null;
    return ChatModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  // Stream Chat
  Stream<ChatModel?> streamChat(String chatId) {
    return _chats.doc(chatId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChatModel.fromJson(doc.data() as Map<String, dynamic>);
    });
  }

  // Get User's Chats
  Future<List<ChatModel>> getUserChats(String userId, {int limit = 50}) async {
    final snapshot = await _chats
        .where(FirebaseConstants.fieldParticipants, arrayContains: userId)
        .where(FirebaseConstants.fieldIsActive, isEqualTo: true)
        .orderBy(FirebaseConstants.fieldUpdatedAt, descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ChatModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Stream User's Chats
  Stream<List<ChatModel>> streamUserChats(String userId) {
    return _chats
        .where(FirebaseConstants.fieldParticipants, arrayContains: userId)
        .where(FirebaseConstants.fieldIsActive, isEqualTo: true)
        .orderBy(FirebaseConstants.fieldUpdatedAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Send Message
  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String type = 'text',
    String? fileUrl,
    String? fileName,
    int? fileSize,
    MessageModel? replyTo,
  }) async {
    final messagesRef = _chats.doc(chatId).collection(FirebaseConstants.messagesSubcollection);
    final docRef = messagesRef.doc();
    final now = DateTime.now();

    final message = MessageModel(
      messageId: docRef.id,
      chatId: chatId,
      senderId: senderId,
      text: text,
      type: type,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      createdAt: now,
      replyTo: replyTo,
    );

    await docRef.set(message.toJson());

    // Update chat's last message and unread counts
    final chat = await getChat(chatId);
    if (chat != null) {
      final otherUserId = chat.getOtherParticipantId(senderId);

      await _chats.doc(chatId).update({
        FirebaseConstants.fieldLastMessage: LastMessage(
          text: type == 'text' ? text : '[$type]',
          senderId: senderId,
          timestamp: now,
          type: type,
        ).toJson(),
        FirebaseConstants.fieldUpdatedAt: Timestamp.fromDate(now),
        '${FirebaseConstants.fieldUnreadCount}.$otherUserId': FieldValue.increment(1),
      });
    }

    return message;
  }

  // Get Messages
  Future<List<MessageModel>> getMessages(
    String chatId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _chats
        .doc(chatId)
        .collection(FirebaseConstants.messagesSubcollection)
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => MessageModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Stream Messages
  Stream<List<MessageModel>> streamMessages(String chatId, {int limit = 100}) {
    return _chats
        .doc(chatId)
        .collection(FirebaseConstants.messagesSubcollection)
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Mark Messages as Read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    // Reset unread count for user
    await _chats.doc(chatId).update({
      '${FirebaseConstants.fieldUnreadCount}.$userId': 0,
    });

    // Mark individual messages as read
    final messagesRef = _chats.doc(chatId).collection(FirebaseConstants.messagesSubcollection);
    final unreadMessages = await messagesRef
        .where(FirebaseConstants.fieldSenderId, isNotEqualTo: userId)
        .where(FirebaseConstants.fieldIsRead, isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {
        FirebaseConstants.fieldIsRead: true,
        'readBy': FieldValue.arrayUnion([userId]),
      });
    }
    await batch.commit();
  }

  // Get Unread Count for User
  Future<int> getTotalUnreadCount(String userId) async {
    final snapshot = await _chats
        .where(FirebaseConstants.fieldParticipants, arrayContains: userId)
        .where(FirebaseConstants.fieldIsActive, isEqualTo: true)
        .get();

    int total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final unreadCount = data[FirebaseConstants.fieldUnreadCount] as Map<String, dynamic>?;
      total += (unreadCount?[userId] as int?) ?? 0;
    }
    return total;
  }

  // Stream Unread Count
  Stream<int> streamTotalUnreadCount(String userId) {
    return _chats
        .where(FirebaseConstants.fieldParticipants, arrayContains: userId)
        .where(FirebaseConstants.fieldIsActive, isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final unreadCount = data[FirebaseConstants.fieldUnreadCount] as Map<String, dynamic>?;
        total += (unreadCount?[userId] as int?) ?? 0;
      }
      return total;
    });
  }

  // Delete Message
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _chats
        .doc(chatId)
        .collection(FirebaseConstants.messagesSubcollection)
        .doc(messageId)
        .delete();
  }

  // Archive Chat
  Future<void> archiveChat(String chatId) async {
    await _chats.doc(chatId).update({
      FirebaseConstants.fieldIsActive: false,
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Unarchive Chat
  Future<void> unarchiveChat(String chatId) async {
    await _chats.doc(chatId).update({
      FirebaseConstants.fieldIsActive: true,
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Delete Chat
  Future<void> deleteChat(String chatId) async {
    // Delete all messages first
    final messagesRef = _chats.doc(chatId).collection(FirebaseConstants.messagesSubcollection);
    final messages = await messagesRef.get();

    final batch = _db.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Delete chat document
    await _chats.doc(chatId).delete();
  }

  // Send System Message
  Future<void> sendSystemMessage(String chatId, String text) async {
    final messagesRef = _chats.doc(chatId).collection(FirebaseConstants.messagesSubcollection);
    final docRef = messagesRef.doc();
    final now = DateTime.now();

    final message = MessageModel(
      messageId: docRef.id,
      chatId: chatId,
      senderId: 'system',
      text: text,
      type: 'system',
      createdAt: now,
    );

    await docRef.set(message.toJson());

    await _chats.doc(chatId).update({
      FirebaseConstants.fieldLastMessage: LastMessage(
        text: text,
        senderId: 'system',
        timestamp: now,
        type: 'system',
      ).toJson(),
      FirebaseConstants.fieldUpdatedAt: Timestamp.fromDate(now),
    });
  }

  // Update Participant Data
  Future<void> updateParticipantData(
    String chatId,
    String participantId,
    ParticipantData data,
  ) async {
    await _chats.doc(chatId).update({
      'participantsData.$participantId': data.toJson(),
    });
  }

  // Get Chat by Application
  Future<ChatModel?> getChatByApplication(String applicationId) async {
    final snapshot = await _chats
        .where('relatedApplicationId', isEqualTo: applicationId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return ChatModel.fromJson(snapshot.docs.first.data() as Map<String, dynamic>);
  }

  // Get Archived Chats
  Future<List<ChatModel>> getArchivedChats(String userId, {int limit = 50}) async {
    final snapshot = await _chats
        .where(FirebaseConstants.fieldParticipants, arrayContains: userId)
        .where(FirebaseConstants.fieldIsActive, isEqualTo: false)
        .orderBy(FirebaseConstants.fieldUpdatedAt, descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ChatModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Search Messages in Chat
  Future<List<MessageModel>> searchMessages(String chatId, String query) async {
    final queryLower = query.toLowerCase();

    final snapshot = await _chats
        .doc(chatId)
        .collection(FirebaseConstants.messagesSubcollection)
        .where(FirebaseConstants.fieldType, isEqualTo: 'text')
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .get();

    return snapshot.docs
        .map((doc) => MessageModel.fromJson(doc.data() as Map<String, dynamic>))
        .where((msg) => msg.text?.toLowerCase().contains(queryLower) ?? false)
        .toList();
  }
}
