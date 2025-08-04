import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat mesajı modeli
class ChatMessage {
  final String id;
  final String content;
  final ChatRole role;
  final DateTime timestamp;
  final String? language;
  final String? topic;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.language,
    this.topic,
    this.isRead = false,
    this.metadata,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      content: data['content'] ?? '',
      role: ChatRole.fromString(data['role'] ?? 'user'),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      language: data['language'],
      topic: data['topic'],
      isRead: data['isRead'] ?? false,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      'role': role.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'language': language,
      'topic': topic,
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    ChatRole? role,
    DateTime? timestamp,
    String? language,
    String? topic,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      language: language ?? this.language,
      topic: topic ?? this.topic,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Chat rolü enum'u
enum ChatRole {
  user('user'),
  ai('ai'),
  admin('admin'),
  system('system');

  const ChatRole(this.value);
  final String value;

  String get name => value;
  
  static ChatRole fromString(String value) {
    return ChatRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => ChatRole.user,
    );
  }

  String get displayName {
    switch (this) {
      case ChatRole.user:
        return 'Kullanıcı';
      case ChatRole.ai:
        return 'AI Asistan';
      case ChatRole.admin:
        return 'Admin';
      case ChatRole.system:
        return 'Sistem';
    }
  }
}

/// Chat oturumu modeli
class ChatSession {
  final String id;
  final String userEmail;
  final String topic;
  final String language;
  final DateTime startTime;
  final DateTime? endTime;
  final ChatStatus status;
  final List<String> messageIds;
  final Map<String, dynamic> userInfo;
  final int messageCount;

  const ChatSession({
    required this.id,
    required this.userEmail,
    required this.topic,
    required this.language,
    required this.startTime,
    this.endTime,
    this.status = ChatStatus.active,
    this.messageIds = const [],
    this.userInfo = const {},
    this.messageCount = 0,
  });

  factory ChatSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatSession(
      id: doc.id,
      userEmail: data['userEmail'] ?? '',
      topic: data['topic'] ?? '',
      language: data['language'] ?? 'tr',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null ? (data['endTime'] as Timestamp).toDate() : null,
      status: ChatStatus.fromString(data['status'] ?? 'active'),
      messageIds: List<String>.from(data['messageIds'] ?? []),
      userInfo: Map<String, dynamic>.from(data['userInfo'] ?? {}),
      messageCount: data['messageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userEmail': userEmail,
      'topic': topic,
      'language': language,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'status': status.value,
      'messageIds': messageIds,
      'userInfo': userInfo,
      'messageCount': messageCount,
    };
  }

  ChatSession copyWith({
    String? id,
    String? userEmail,
    String? topic,
    String? language,
    DateTime? startTime,
    DateTime? endTime,
    ChatStatus? status,
    List<String>? messageIds,
    Map<String, dynamic>? userInfo,
    int? messageCount,
  }) {
    return ChatSession(
      id: id ?? this.id,
      userEmail: userEmail ?? this.userEmail,
      topic: topic ?? this.topic,
      language: language ?? this.language,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      messageIds: messageIds ?? this.messageIds,
      userInfo: userInfo ?? this.userInfo,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  String get sessionDisplayName => '$userEmail - $topic';
  Duration get duration => endTime?.difference(startTime) ?? 
      DateTime.now().difference(startTime);
}

/// Chat durumu enum'u
enum ChatStatus {
  active('active'),
  ended('ended'),
  archived('archived'),
  blocked('blocked');

  const ChatStatus(this.value);
  final String value;

  String get name => value;
  
  static ChatStatus fromString(String value) {
    return ChatStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ChatStatus.active,
    );
  }

  String get displayName {
    switch (this) {
      case ChatStatus.active:
        return 'Aktif';
      case ChatStatus.ended:
        return 'Sonlandırıldı';
      case ChatStatus.archived:
        return 'Arşivlendi';
      case ChatStatus.blocked:
        return 'Engellendi';
    }
  }
}

/// Chat konuları
class ChatTopic {
  static const String appointment = 'appointment';
  static const String support = 'support';
  static const String information = 'information';
  static const String suggestion = 'suggestion';
  static const String complaint = 'complaint';
  static const String general = 'general';

  static List<String> get allTopics => [
    appointment,
    support,
    information,
    suggestion,
    complaint,
    general,
  ];

  static String getDisplayName(String topic) {
    switch (topic) {
      case appointment:
        return 'Randevu';
      case support:
        return 'Teknik Destek';
      case information:
        return 'Bilgi Alma';
      case suggestion:
        return 'Öneri';
      case complaint:
        return 'Şikayet';
      case general:
        return 'Genel';
      default:
        return 'Diğer';
    }
  }
}

/// Desteklenen diller
class ChatLanguage {
  static const String turkish = 'tr';
  static const String english = 'en';
  static const String german = 'de';
  static const String spanish = 'es';
  static const String french = 'fr';

  static List<String> get supportedLanguages => [
    turkish,
    english,
    german,
    spanish,
    french,
  ];

  static String getDisplayName(String languageCode) {
    switch (languageCode) {
      case turkish:
        return 'Türkçe';
      case english:
        return 'English';
      case german:
        return 'Deutsch';
      case spanish:
        return 'Español';
      case french:
        return 'Français';
      default:
        return 'Unknown';
    }
  }

  static String getFlag(String languageCode) {
    switch (languageCode) {
      case turkish:
        return '🇹🇷';
      case english:
        return '🇺🇸';
      case german:
        return '🇩🇪';
      case spanish:
        return '🇪🇸';
      case french:
        return '🇫🇷';
      default:
        return '🌍';
    }
  }
}

/// Chat başlatma bilgileri
class ChatInitInfo {
  final String userEmail;
  final String topic;
  final String language;
  final Map<String, dynamic> additionalInfo;

  const ChatInitInfo({
    required this.userEmail,
    required this.topic,
    required this.language,
    this.additionalInfo = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'userEmail': userEmail,
      'topic': topic,
      'language': language,
      'additionalInfo': additionalInfo,
    };
  }

  factory ChatInitInfo.fromMap(Map<String, dynamic> map) {
    return ChatInitInfo(
      userEmail: map['userEmail'] ?? '',
      topic: map['topic'] ?? ChatTopic.general,
      language: map['language'] ?? ChatLanguage.turkish,
      additionalInfo: Map<String, dynamic>.from(map['additionalInfo'] ?? {}),
    );
  }
}

/// Dialogflow yanıt modeli
class DialogflowResponse {
  final String text;
  final String intentName;
  final Map<String, dynamic> parameters;
  final double confidence;
  final String? followupEvent;
  final List<String>? suggestions;

  const DialogflowResponse({
    required this.text,
    required this.intentName,
    this.parameters = const {},
    this.confidence = 0.0,
    this.followupEvent,
    this.suggestions,
  });

  factory DialogflowResponse.fromMap(Map<String, dynamic> data) {
    return DialogflowResponse(
      text: data['fulfillmentText'] ?? data['text'] ?? '',
      intentName: data['intent']?['displayName'] ?? '',
      parameters: Map<String, dynamic>.from(data['parameters'] ?? {}),
      confidence: (data['intentDetectionConfidence'] ?? 0.0).toDouble(),
      followupEvent: data['followupEventInput']?['name'],
      suggestions: data['suggestions']?.cast<String>(),
    );
  }

  factory DialogflowResponse.error(String message) {
    return DialogflowResponse(
      text: message,
      intentName: 'error',
      confidence: 0.0,
    );
  }

  bool get isError => intentName == 'error';
  bool get hasHighConfidence => confidence > 0.7;
}