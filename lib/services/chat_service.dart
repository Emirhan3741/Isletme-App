import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import '../core/constants/app_constants.dart';

/// Firestore chat kayıt ve yönetim servisi
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String _chatSessionsCollection = 'chat_sessions';
  static const String _chatMessagesCollection = 'chat_messages';

  /// Yeni chat session'ı başlat
  Future<ChatSession> startChatSession({
    required String userEmail,
    required String topic,
    required String language,
    Map<String, dynamic> additionalInfo = const {},
  }) async {
    try {
      debugPrint('🚀 ChatService: Yeni chat session başlatılıyor...');
      debugPrint('   👤 User: $userEmail');
      debugPrint('   🎯 Topic: $topic');
      debugPrint('   🌍 Language: $language');

      final sessionData = {
        'userEmail': userEmail,
        'topic': topic,
        'language': language,
        'startTime': FieldValue.serverTimestamp(),
        'endTime': null,
        'status': ChatStatus.active.value,
        'messageIds': <String>[],
        'userInfo': {
          'email': userEmail,
          'language': language,
          'topic': topic,
          'startedAt': DateTime.now().toIso8601String(),
          ...additionalInfo,
        },
        'messageCount': 0,
        'lastActivity': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection(_chatSessionsCollection)
          .add(sessionData);

      debugPrint('✅ ChatService: Session oluşturuldu - ${docRef.id}');

      // Welcome message ekle
      await _addWelcomeMessage(docRef.id, language, topic);

      // Session'ı döndür
      final session = ChatSession(
        id: docRef.id,
        userEmail: userEmail,
        topic: topic,
        language: language,
        startTime: DateTime.now(),
        status: ChatStatus.active,
        userInfo: Map<String, dynamic>.from(sessionData['userInfo'] as Map),
        messageCount: 1, // Welcome message
      );

      return session;

    } catch (e) {
      debugPrint('❌ ChatService: Session başlatma hatası: $e');
      rethrow;
    }
  }

  /// Chat session'ına mesaj ekle
  Future<ChatMessage> addMessage({
    required String sessionId,
    required String content,
    required ChatRole role,
    String? language,
    String? topic,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('💬 ChatService: Mesaj ekleniyor...');
      debugPrint('   📝 Content: ${content.length > 50 ? "${content.substring(0, 50)}..." : content}');
      debugPrint('   👤 Role: ${role.displayName}');

      final messageData = {
        'content': content,
        'role': role.value,
        'timestamp': FieldValue.serverTimestamp(),
        'language': language,
        'topic': topic,
        'isRead': role == ChatRole.user, // User mesajları okunmuş sayılır
        'metadata': metadata ?? {},
        'sessionId': sessionId,
      };

      // Mesajı ekle
      final messageRef = await _firestore
          .collection(_chatMessagesCollection)
          .add(messageData);

      // Session'ı güncelle
      await _updateSessionAfterMessage(sessionId, messageRef.id);

      debugPrint('✅ ChatService: Mesaj eklendi - ${messageRef.id}');

      // ChatMessage objesi oluştur
      final message = ChatMessage(
        id: messageRef.id,
        content: content,
        role: role,
        timestamp: DateTime.now(),
        language: language,
        topic: topic,
        isRead: role == ChatRole.user,
        metadata: metadata,
      );

      return message;

    } catch (e) {
      debugPrint('❌ ChatService: Mesaj ekleme hatası: $e');
      rethrow;
    }
  }

  /// Session'ı mesaj sonrası güncelle
  Future<void> _updateSessionAfterMessage(String sessionId, String messageId) async {
    try {
      await _firestore
          .collection(_chatSessionsCollection)
          .doc(sessionId)
          .update({
        'messageIds': FieldValue.arrayUnion([messageId]),
        'messageCount': FieldValue.increment(1),
        'lastActivity': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ ChatService: Session güncelleme hatası: $e');
    }
  }

  /// Welcome message ekle
  Future<void> _addWelcomeMessage(String sessionId, String language, String topic) async {
    try {
      final welcomeText = _getWelcomeMessage(language, topic);
      
      await addMessage(
        sessionId: sessionId,
        content: welcomeText,
        role: ChatRole.ai,
        language: language,
        topic: topic,
        metadata: {'isWelcome': true},
      );

      debugPrint('👋 ChatService: Welcome message eklendi');
    } catch (e) {
      debugPrint('❌ ChatService: Welcome message hatası: $e');
    }
  }

  /// Dile göre hoş geldin mesajı
  String _getWelcomeMessage(String language, String topic) {
    final topicDisplay = ChatTopic.getDisplayName(topic);
    
    final messages = {
      'tr': 'Merhaba! $topicDisplay konusunda size nasıl yardımcı olabilirim?',
      'en': 'Hello! How can I help you with $topicDisplay?',
      'de': 'Hallo! Wie kann ich Ihnen bei $topicDisplay helfen?',
      'es': 'Hola! ¿Cómo puedo ayudarte con $topicDisplay?',
      'fr': 'Bonjour! Comment puis-je vous aider avec $topicDisplay?',
    };

    return messages[language] ?? messages['tr']!;
  }

  /// Chat session'ını sonlandır
  Future<void> endChatSession(String sessionId) async {
    try {
      debugPrint('🔚 ChatService: Session sonlandırılıyor - $sessionId');

      await _firestore
          .collection(_chatSessionsCollection)
          .doc(sessionId)
          .update({
        'endTime': FieldValue.serverTimestamp(),
        'status': ChatStatus.ended.value,
        'lastActivity': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ ChatService: Session sonlandırıldı');
    } catch (e) {
      debugPrint('❌ ChatService: Session sonlandırma hatası: $e');
      rethrow;
    }
  }

  /// Chat session'ını al
  Future<ChatSession?> getChatSession(String sessionId) async {
    try {
      final doc = await _firestore
          .collection(_chatSessionsCollection)
          .doc(sessionId)
          .get();

      if (doc.exists) {
        return ChatSession.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ ChatService: Session alma hatası: $e');
      return null;
    }
  }

  /// Session'ın mesajlarını al
  Future<List<ChatMessage>> getSessionMessages(String sessionId) async {
    try {
      debugPrint('📥 ChatService: Session mesajları alınıyor - $sessionId');

      final query = _firestore
          .collection(_chatMessagesCollection)
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('timestamp', descending: false);

      final snapshot = await query.get();

      final messages = snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();

      debugPrint('✅ ChatService: ${messages.length} mesaj alındı');
      return messages;

    } catch (e) {
      debugPrint('❌ ChatService: Mesaj alma hatası: $e');
      return [];
    }
  }

  /// Session mesajlarını stream olarak al
  Stream<List<ChatMessage>> getSessionMessagesStream(String sessionId) {
    try {
      debugPrint('📡 ChatService: Mesaj stream\'i başlatılıyor - $sessionId');

      return _firestore
          .collection(_chatMessagesCollection)
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
            final messages = snapshot.docs
                .map((doc) => ChatMessage.fromFirestore(doc))
                .toList();
            
            debugPrint('📨 ChatService: Stream güncellendi - ${messages.length} mesaj');
            return messages;
          });

    } catch (e) {
      debugPrint('❌ ChatService: Stream hatası: $e');
      return Stream.value([]);
    }
  }

  /// Kullanıcının chat session'larını al
  Future<List<ChatSession>> getUserChatSessions(String userEmail) async {
    try {
      debugPrint('👤 ChatService: Kullanıcı session\'ları alınıyor - $userEmail');

      final query = _firestore
          .collection(_chatSessionsCollection)
          .where('userEmail', isEqualTo: userEmail)
          .orderBy('startTime', descending: true)
          .limit(50);

      final snapshot = await query.get();

      final sessions = snapshot.docs
          .map((doc) => ChatSession.fromFirestore(doc))
          .toList();

      debugPrint('✅ ChatService: ${sessions.length} session alındı');
      return sessions;

    } catch (e) {
      debugPrint('❌ ChatService: Kullanıcı session\'ları alma hatası: $e');
      return [];
    }
  }

  /// Admin için tüm chat session'larını al (filtrelenmiş)
  Future<List<ChatSession>> getAdminChatSessions({
    String? userEmail,
    String? topic,
    String? language,
    DateTime? startDate,
    DateTime? endDate,
    ChatStatus? status,
    int limit = 100,
  }) async {
    try {
      debugPrint('👨‍💼 ChatService: Admin session\'ları alınıyor...');

      Query query = _firestore.collection(_chatSessionsCollection);

      // Filtreleri uygula
      if (userEmail != null && userEmail.isNotEmpty) {
        query = query.where('userEmail', isEqualTo: userEmail);
      }
      
      if (topic != null && topic.isNotEmpty) {
        query = query.where('topic', isEqualTo: topic);
      }
      
      if (language != null && language.isNotEmpty) {
        query = query.where('language', isEqualTo: language);
      }
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }
      
      if (startDate != null) {
        query = query.where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      query = query.orderBy('startTime', descending: true).limit(limit);

      final snapshot = await query.get();

      final sessions = snapshot.docs
          .map((doc) => ChatSession.fromFirestore(doc))
          .toList();

      debugPrint('✅ ChatService: Admin - ${sessions.length} session alındı');
      return sessions;

    } catch (e) {
      debugPrint('❌ ChatService: Admin session\'ları alma hatası: $e');
      return [];
    }
  }

  /// Mesajı okunmuş olarak işaretle
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore
          .collection(_chatMessagesCollection)
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('❌ ChatService: Mesaj okunmuş işaretleme hatası: $e');
    }
  }

  /// Session'daki okunmamış mesaj sayısı
  Future<int> getUnreadMessageCount(String sessionId) async {
    try {
      final query = _firestore
          .collection(_chatMessagesCollection)
          .where('sessionId', isEqualTo: sessionId)
          .where('isRead', isEqualTo: false)
          .where('role', isEqualTo: ChatRole.ai.value);

      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ ChatService: Okunmamış mesaj sayısı hatası: $e');
      return 0;
    }
  }

  /// Chat session'ını arşivle
  Future<void> archiveChatSession(String sessionId) async {
    try {
      debugPrint('📦 ChatService: Session arşivleniyor - $sessionId');

      await _firestore
          .collection(_chatSessionsCollection)
          .doc(sessionId)
          .update({
        'status': ChatStatus.archived.value,
        'lastActivity': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ ChatService: Session arşivlendi');
    } catch (e) {
      debugPrint('❌ ChatService: Session arşivleme hatası: $e');
      rethrow;
    }
  }

  /// Chat session'ını engelle
  Future<void> blockChatSession(String sessionId, String reason) async {
    try {
      debugPrint('🚫 ChatService: Session engelleniyor - $sessionId');

      await _firestore
          .collection(_chatSessionsCollection)
          .doc(sessionId)
          .update({
        'status': ChatStatus.blocked.value,
        'blockReason': reason,
        'blockedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ ChatService: Session engellendi');
    } catch (e) {
      debugPrint('❌ ChatService: Session engelleme hatası: $e');
      rethrow;
    }
  }

  /// Chat istatistikleri al
  Future<Map<String, dynamic>> getChatStatistics() async {
    try {
      debugPrint('📊 ChatService: İstatistikler alınıyor...');

      // Bugünkü session'lar
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final todaySessions = await _firestore
          .collection(_chatSessionsCollection)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      // Toplam session'lar
      final totalSessions = await _firestore
          .collection(_chatSessionsCollection)
          .count()
          .get();

      // Aktif session'lar
      final activeSessions = await _firestore
          .collection(_chatSessionsCollection)
          .where('status', isEqualTo: ChatStatus.active.value)
          .get();

      // Toplam mesajlar
      final totalMessages = await _firestore
          .collection(_chatMessagesCollection)
          .count()
          .get();

      final stats = {
        'todaySessions': todaySessions.docs.length,
        'totalSessions': totalSessions.count ?? 0,
        'activeSessions': activeSessions.docs.length,
        'totalMessages': totalMessages.count ?? 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      debugPrint('✅ ChatService: İstatistikler alındı');
      return stats;

    } catch (e) {
      debugPrint('❌ ChatService: İstatistik alma hatası: $e');
      return {};
    }
  }

  /// Chat session'ını sil (Admin only)
  Future<void> deleteChatSession(String sessionId) async {
    try {
      debugPrint('🗑️ ChatService: Session siliniyor - $sessionId');

      // Önce mesajları sil
      final messagesQuery = _firestore
          .collection(_chatMessagesCollection)
          .where('sessionId', isEqualTo: sessionId);

      final messagesSnapshot = await messagesQuery.get();
      
      final batch = _firestore.batch();
      
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Session'ı sil
      batch.delete(_firestore.collection(_chatSessionsCollection).doc(sessionId));

      await batch.commit();

      debugPrint('✅ ChatService: Session ve mesajları silindi');
    } catch (e) {
      debugPrint('❌ ChatService: Session silme hatası: $e');
      rethrow;
    }
  }
}