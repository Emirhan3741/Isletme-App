import 'package:cloud_firestore/cloud_firestore.dart';

/// 🤖 AI Chat Mesaj Modeli
class ChatMessage {
  final String id;
  final String sender; // "user" veya "ai"
  final String content;
  final DateTime timestamp;
  final String language;
  final String topic;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    required this.language,
    required this.topic,
  });

  // Firestore'dan veri çekme
  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      sender: map['sender'] ?? 'user',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      language: map['language'] ?? 'tr',
      topic: map['topic'] ?? 'general',
    );
  }

  // Firestore'a veri yazma
  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'language': language,
      'topic': topic,
    };
  }

  // User mesajı mı kontrol
  bool get isUser => sender == 'user';

  // AI mesajı mı kontrol
  bool get isAI => sender == 'ai';
}

/// 📝 Chat Oturumu Modeli
class ChatSession {
  final String id;
  final String userEmail;
  final String topic;
  final String language;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int messageCount;
  final String status; // "active", "ended", "archived"

  ChatSession({
    required this.id,
    required this.userEmail,
    required this.topic,
    required this.language,
    required this.startedAt,
    this.endedAt,
    this.messageCount = 0,
    this.status = 'active',
  });

  // Firestore'dan veri çekme
  factory ChatSession.fromMap(Map<String, dynamic> map, String id) {
    return ChatSession(
      id: id,
      userEmail: map['userEmail'] ?? '',
      topic: map['topic'] ?? 'general',
      language: map['language'] ?? 'tr',
      startedAt: (map['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endedAt: (map['endedAt'] as Timestamp?)?.toDate(),
      messageCount: map['messageCount'] ?? 0,
      status: map['status'] ?? 'active',
    );
  }

  // Firestore'a veri yazma
  Map<String, dynamic> toMap() {
    return {
      'userEmail': userEmail,
      'topic': topic,
      'language': language,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'messageCount': messageCount,
      'status': status,
    };
  }

  // Oturum aktif mi
  bool get isActive => status == 'active';

  // Oturum süresini hesapla
  Duration get sessionDuration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }
}

/// 🎯 Desteklenen Konular
enum ChatTopic {
  randevu('randevu', 'Randevu İşlemleri'),
  destek('destek', 'Teknik Destek'),
  bilgi('bilgi', 'Bilgi Alma'),
  oneri('oneri', 'Öneri/Şikayet'),
  genel('genel', 'Genel Sorular'),
  beauty('beauty', 'Güzellik Salonu'),
  lawyer('lawyer', 'Avukatlık'),
  clinic('clinic', 'Klinik'),
  psychology('psychology', 'Psikoloji'),
  veterinary('veterinary', 'Veterinerlik'),
  sports('sports', 'Spor'),
  education('education', 'Eğitim'),
  realEstate('real_estate', 'Emlak');

  const ChatTopic(this.value, this.displayName);
  final String value;
  final String displayName;

  static ChatTopic fromString(String value) {
    return ChatTopic.values.firstWhere(
      (topic) => topic.value == value,
      orElse: () => ChatTopic.genel,
    );
  }

  /// Sektörden konuya çeviri
  static ChatTopic fromSector(String? sector) {
    if (sector == null) return ChatTopic.genel;
    
    switch (sector.toLowerCase()) {
      case 'beauty':
        return ChatTopic.beauty;
      case 'lawyer':
        return ChatTopic.lawyer;
      case 'clinic':
        return ChatTopic.clinic;
      case 'psychology':
        return ChatTopic.psychology;
      case 'veterinary':
        return ChatTopic.veterinary;
      case 'sports':
        return ChatTopic.sports;
      case 'education':
        return ChatTopic.education;
      case 'real_estate':
        return ChatTopic.realEstate;
      default:
        return ChatTopic.genel;
    }
  }
}

/// 🌍 Desteklenen Diller
enum ChatLanguage {
  turkish('tr', 'Türkçe', '🇹🇷'),
  english('en', 'English', '🇺🇸'),
  german('de', 'Deutsch', '🇩🇪'),
  spanish('es', 'Español', '🇪🇸'),
  french('fr', 'Français', '🇫🇷');

  const ChatLanguage(this.code, this.displayName, this.flag);
  final String code;
  final String displayName;
  final String flag;

  static ChatLanguage fromCode(String code) {
    return ChatLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => ChatLanguage.turkish,
    );
  }
}

/// 📨 Dialogflow API Yanıt Modeli
class DialogflowResponse {
  final String queryText;
  final String fulfillmentText;
  final String intentDisplayName;
  final Map<String, dynamic> parameters;
  final String languageCode;
  final bool isFallback;

  DialogflowResponse({
    required this.queryText,
    required this.fulfillmentText,
    required this.intentDisplayName,
    this.parameters = const {},
    required this.languageCode,
    this.isFallback = false,
  });

  factory DialogflowResponse.fromJson(Map<String, dynamic> json) {
    final result = json['queryResult'] ?? {};
    
    return DialogflowResponse(
      queryText: result['queryText'] ?? '',
      fulfillmentText: result['fulfillmentText'] ?? '',
      intentDisplayName: result['intent']?['displayName'] ?? '',
      parameters: result['parameters'] ?? {},
      languageCode: result['languageCode'] ?? 'tr',
      isFallback: result['intent']?['isFallback'] ?? false,
    );
  }

  // Boş yanıt oluşturma
  factory DialogflowResponse.empty(String queryText, String languageCode) {
    return DialogflowResponse(
      queryText: queryText,
      fulfillmentText: _getDefaultResponse(languageCode),
      intentDisplayName: 'Default Fallback Intent',
      languageCode: languageCode,
      isFallback: true,
    );
  }

  static String _getDefaultResponse(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return 'Üzgünüm, bu konuda size yardımcı olamıyorum. Daha detaylı bilgi verebilir misiniz?';
      case 'en':
        return 'Sorry, I cannot help you with this. Could you provide more details?';
      case 'de':
        return 'Entschuldigung, ich kann Ihnen dabei nicht helfen. Können Sie mehr Details angeben?';
      case 'es':
        return 'Lo siento, no puedo ayudarte con esto. ¿Podrías dar más detalles?';
      case 'fr':
        return 'Désolé, je ne peux pas vous aider avec cela. Pourriez-vous donner plus de détails?';
      default:
        return 'Üzgünüm, bu konuda size yardımcı olamıyorum.';
    }
  }
}

/// 🔐 Chat Oturum Konfigürasyonu
class ChatConfig {
  final String userEmail;
  final ChatTopic topic;
  final ChatLanguage language;
  final DateTime createdAt;
  final Map<String, dynamic> additionalInfo;

  ChatConfig({
    required this.userEmail,
    required this.topic,
    required this.language,
    DateTime? createdAt,
    this.additionalInfo = const {},
  }) : createdAt = createdAt ?? DateTime.now();

  // Validation - Email kontrolü
  bool get isValidEmail {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(userEmail);
  }

  // Session ID oluştur
  String generateSessionId() {
    final timestamp = createdAt.millisecondsSinceEpoch;
    final emailHash = userEmail.hashCode.abs();
    return '${language.code}_${topic.value}_${emailHash}_$timestamp';
  }

  Map<String, dynamic> toMap() {
    return {
      'userEmail': userEmail,
      'topic': topic.value,
      'language': language.code,
      'createdAt': Timestamp.fromDate(createdAt),
      'additionalInfo': additionalInfo,
    };
  }
}