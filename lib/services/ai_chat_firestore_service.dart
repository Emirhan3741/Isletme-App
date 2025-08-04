import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ai_chat_models.dart';

/// 🔥 AI Chat Firestore Veritabanı Servisi
class AIChatFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection isimleri
  static const String _chatSessionsCollection = 'ai_chat_sessions';
  static const String _chatMessagesCollection = 'ai_chat_messages';

  /// 💬 Yeni chat session başlat
  Future<String> startChatSession(ChatConfig config) async {
    try {
      debugPrint('🚀 Chat session başlatılıyor...');
      debugPrint('📧 Email: ${config.userEmail}');
      debugPrint('🎯 Konu: ${config.topic.displayName}');
      debugPrint('🌍 Dil: ${config.language.displayName}');

      // Session ID oluştur
      final sessionId = config.generateSessionId();

      // Session verisini hazırla
      final sessionData = ChatSession(
        id: sessionId,
        userEmail: config.userEmail,
        topic: config.topic.value,
        language: config.language.code,
        startedAt: config.createdAt,
        status: 'active',
      );

      // Firestore'a session kaydet
      await _firestore
          .collection(_chatSessionsCollection)
          .doc(sessionId)
          .set(sessionData.toMap());

      debugPrint('✅ Chat session oluşturuldu: $sessionId');

      // Hoş geldin mesajını ekle
      await _addWelcomeMessage(sessionId, config.language.code, config.topic.value);

      return sessionId;

    } catch (e) {
      debugPrint('❌ Session başlatma hatası: $e');
      rethrow;
    }
  }

  /// 📝 Tekil mesaj kaydetme
  Future<void> saveMessage({
    required String sessionId,
    required String sender, // 'user' veya 'ai'
    required String content,
    required String language,
    required String topic,
  }) async {
    try {
      debugPrint('💾 Mesaj kaydediliyor...');
      debugPrint('📨 Gönderen: $sender');
      debugPrint('📝 İçerik: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}');

      // Mesaj verisini hazırla
      final message = ChatMessage(
        id: '', // Firestore otomatik ID verecek
        sender: sender,
        content: content,
        timestamp: DateTime.now(),
        language: language,
        topic: topic,
      );

      // Firestore'a mesaj kaydet
      await _firestore
          .collection(_chatSessionsCollection)
          .doc(sessionId)
          .collection(_chatMessagesCollection)
          .add(message.toMap());

      // Session'ın mesaj sayısını güncelle
      await _updateSessionMessageCount(sessionId);

      debugPrint('✅ Mesaj kaydedildi');

    } catch (e) {
      debugPrint('❌ Mesaj kaydetme hatası: $e');
      rethrow;
    }
  }

  /// 📜 Session mesajlarını getir (Stream)
  Stream<List<ChatMessage>> getChatMessagesStream(String sessionId) {
    debugPrint('📡 Mesaj stream başlatılıyor: $sessionId');

    return _firestore
        .collection(_chatSessionsCollection)
        .doc(sessionId)
        .collection(_chatMessagesCollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs.map((doc) {
        return ChatMessage.fromMap(doc.data(), doc.id);
      }).toList();

      debugPrint('📨 ${messages.length} mesaj yüklendi');
      return messages;
    });
  }

  /// 🗂️ Kullanıcının session'larını getir
  Stream<List<ChatSession>> getUserSessionsStream(String userEmail) {
    debugPrint('👤 Kullanıcı sessionları yükleniyor: $userEmail');

    return _firestore
        .collection(_chatSessionsCollection)
        .where('userEmail', isEqualTo: userEmail)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final sessions = snapshot.docs.map((doc) {
        return ChatSession.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      debugPrint('📂 ${sessions.length} session bulundu');
      return sessions;
    });
  }

  /// 👨‍💼 Admin panel için tüm session'ları getir
  Stream<List<ChatSession>> getAllSessionsStream({
    String? filterEmail,
    String? filterTopic,
    String? filterLanguage,
    String? filterStatus,
  }) {
    debugPrint('🔍 Admin session filtreleri uygulanıyor...');

    Query query = _firestore.collection(_chatSessionsCollection);

    // Filtreleri uygula
    if (filterEmail != null && filterEmail.isNotEmpty) {
      query = query.where('userEmail', isEqualTo: filterEmail);
    }
    if (filterTopic != null && filterTopic.isNotEmpty) {
      query = query.where('topic', isEqualTo: filterTopic);
    }
    if (filterLanguage != null && filterLanguage.isNotEmpty) {
      query = query.where('language', isEqualTo: filterLanguage);
    }
    if (filterStatus != null && filterStatus.isNotEmpty) {
      query = query.where('status', isEqualTo: filterStatus);
    }

    return query
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final sessions = snapshot.docs.map((doc) {
        return ChatSession.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      debugPrint('📊 Admin: ${sessions.length} session bulundu');
      return sessions;
    });
  }

  /// ⏹️ Session sonlandır
  Future<void> endChatSession(String sessionId) async {
    try {
      debugPrint('🔚 Session sonlandırılıyor: $sessionId');

      await _firestore
          .collection(_chatSessionsCollection)
          .doc(sessionId)
          .update({
        'status': 'ended',
        'endedAt': Timestamp.now(),
      });

      debugPrint('✅ Session sonlandırıldı');

    } catch (e) {
      debugPrint('❌ Session sonlandırma hatası: $e');
      rethrow;
    }
  }

  /// 🗃️ Session arşivle
  Future<void> archiveChatSession(String sessionId) async {
    try {
      debugPrint('📦 Session arşivleniyor: $sessionId');

      await _firestore
          .collection(_chatSessionsCollection)
          .doc(sessionId)
          .update({
        'status': 'archived',
      });

      debugPrint('✅ Session arşivlendi');

    } catch (e) {
      debugPrint('❌ Session arşivleme hatası: $e');
      rethrow;
    }
  }

  /// 🗑️ Session sil
  Future<void> deleteChatSession(String sessionId) async {
    try {
      debugPrint('🗑️ Session siliniyor: $sessionId');

      // Önce tüm mesajları sil
      final messagesQuery = await _firestore
          .collection(_chatSessionsCollection)
          .doc(sessionId)
          .collection(_chatMessagesCollection)
          .get();

      final batch = _firestore.batch();

      // Mesajları batch ile sil
      for (final doc in messagesQuery.docs) {
        batch.delete(doc.reference);
      }

      // Session'ı da sil
      batch.delete(_firestore.collection(_chatSessionsCollection).doc(sessionId));

      await batch.commit();

      debugPrint('✅ Session ve mesajları silindi');

    } catch (e) {
      debugPrint('❌ Session silme hatası: $e');
      rethrow;
    }
  }

  /// 👋 Hoş geldin mesajı ekle
  Future<void> _addWelcomeMessage(String sessionId, String languageCode, String topic) async {
    try {
      String welcomeMessage;

      switch (languageCode) {
        case 'en':
          welcomeMessage = 'Hello! I can help you with $topic. How can I assist you today?';
          break;
        case 'de':
          welcomeMessage = 'Hallo! Ich kann Ihnen bei $topic helfen. Wie kann ich Ihnen heute helfen?';
          break;
        case 'es':
          welcomeMessage = '¡Hola! Puedo ayudarte con $topic. ¿Cómo puedo ayudarte hoy?';
          break;
        case 'fr':
          welcomeMessage = 'Bonjour! Je peux vous aider avec $topic. Comment puis-je vous aider aujourd\'hui?';
          break;
        default: // Türkçe
          welcomeMessage = 'Merhaba! $topic konusunda size yardımcı olabilirim. Size nasıl yardımcı olabilirim?';
      }

      await saveMessage(
        sessionId: sessionId,
        sender: 'ai',
        content: welcomeMessage,
        language: languageCode,
        topic: topic,
      );

    } catch (e) {
      debugPrint('❌ Hoş geldin mesajı hatası: $e');
      // Bu hata critical değil, session'ı engellemek gerekmiyor
    }
  }

  /// 🔢 Session mesaj sayısını güncelle
  Future<void> _updateSessionMessageCount(String sessionId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection(_chatSessionsCollection)
          .doc(sessionId)
          .collection(_chatMessagesCollection)
          .get();

      await _firestore
          .collection(_chatSessionsCollection)
          .doc(sessionId)
          .update({
        'messageCount': messagesSnapshot.docs.length,
      });

    } catch (e) {
      debugPrint('❌ Mesaj sayısı güncelleme hatası: $e');
      // Bu hata critical değil
    }
  }

  /// 📊 Session istatistikleri
  Future<Map<String, dynamic>> getSessionStats() async {
    try {
      final sessionsSnapshot = await _firestore
          .collection(_chatSessionsCollection)
          .get();

      final totalSessions = sessionsSnapshot.docs.length;
      final activeSessions = sessionsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'active')
          .length;

      // Dil dağılımı
      final languageStats = <String, int>{};
      for (final doc in sessionsSnapshot.docs) {
        final language = doc.data()['language'] as String;
        languageStats[language] = (languageStats[language] ?? 0) + 1;
      }

      // Konu dağılımı
      final topicStats = <String, int>{};
      for (final doc in sessionsSnapshot.docs) {
        final topic = doc.data()['topic'] as String;
        topicStats[topic] = (topicStats[topic] ?? 0) + 1;
      }

      return {
        'totalSessions': totalSessions,
        'activeSessions': activeSessions,
        'languageStats': languageStats,
        'topicStats': topicStats,
      };

    } catch (e) {
      debugPrint('❌ İstatistik alma hatası: $e');
      return {};
    }
  }

  /// 💾 Modern mesaj kaydetme metodu (user ve AI mesajları için)
  Future<void> saveConversation({
    required String sessionId,
    required String userMessage,
    required String aiResponse,
    required String languageCode,
    required String userEmail,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('💾 Mesajlar kaydediliyor...');
      debugPrint('👤 Kullanıcı: ${userMessage.length > 50 ? '${userMessage.substring(0, 50)}...' : userMessage}');
      debugPrint('🤖 AI: ${aiResponse.length > 50 ? '${aiResponse.substring(0, 50)}...' : aiResponse}');

      final batch = _firestore.batch();
      final sessionRef = _firestore.collection(_chatSessionsCollection).doc(sessionId);
      final messagesRef = sessionRef.collection(_chatMessagesCollection);

      // Kullanıcı mesajını ekle
      final userMsgRef = messagesRef.doc();
      final userMsgObj = ChatMessage(
        id: userMsgRef.id,
        sender: 'user',
        content: userMessage,
        timestamp: DateTime.now(),
        language: languageCode,
        topic: '',
      );
      batch.set(userMsgRef, userMsgObj.toMap());

      // AI mesajını ekle
      final aiMsgRef = messagesRef.doc();
      final aiMessageObj = ChatMessage(
        id: aiMsgRef.id,
        sender: 'ai',
        content: aiResponse,
        timestamp: DateTime.now(),
        language: languageCode,
        topic: '',
      );
      
      final aiMessageData = aiMessageObj.toMap();
      if (metadata != null) {
        aiMessageData['metadata'] = metadata;
      }
      batch.set(aiMsgRef, aiMessageData);

      // Session'ı güncelle
      batch.update(sessionRef, {
        'messageCount': FieldValue.increment(2),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // Log kaydı ekle (admin takibi için)
      final logRef = _firestore.collection('ai_chat_logs').doc();
      batch.set(logRef, {
        'sessionId': sessionId,
        'userEmail': userEmail,
        'userMessage': userMessage,
        'aiResponse': aiResponse,
        'language': languageCode,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      });

      await batch.commit();
      debugPrint('✅ Mesajlar başarıyla kaydedildi');

    } catch (e) {
      debugPrint('❌ Mesaj kaydetme hatası: $e');
      rethrow;
    }
  }
}