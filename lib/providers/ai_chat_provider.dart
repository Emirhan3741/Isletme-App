import 'package:flutter/foundation.dart';
import '../models/ai_chat_models.dart';
import '../services/ai_dialogflow_service.dart';
import '../services/ai_chat_firestore_service.dart';

/// 🤖 AI Chat State Management Provider
/// Chat işlemlerini ve state'i yönetir
class AIChatProvider with ChangeNotifier {
  
  // Servisler
  final DialogflowService _dialogflowService = DialogflowService();
  final AIChatFirestoreService _firestoreService = AIChatFirestoreService();
  
  // State değişkenleri
  ChatSession? _currentSession;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  String? _errorMessage;
  ChatConfig? _config;
  
  // Getters
  ChatSession? get currentSession => _currentSession;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;
  String? get errorMessage => _errorMessage;
  ChatConfig? get config => _config;
  bool get hasActiveSession => _currentSession != null;

  /// 🚀 Chat session'ı başlat
  Future<bool> startChatSession(ChatConfig config) async {
    try {
      debugPrint('🚀 AI Chat: Session başlatılıyor...');
      
      _setLoading(true);
      _setError(null);
      _config = config;

      // Demo mode aktif et
      _dialogflowService.setDemoMode(true);

      // Firestore'da session oluştur
      final sessionId = await _firestoreService.startChatSession(config);
      
      // Session bilgilerini oluştur
      _currentSession = ChatSession(
        id: sessionId,
        userEmail: config.userEmail,
        topic: config.topic.value,
        language: config.language.code,
        startedAt: config.createdAt,
        status: 'active',
      );

      // Mesajları dinlemeye başla
      _listenToMessages(sessionId);
      
      _setLoading(false);
      debugPrint('✅ AI Chat: Session başlatıldı: $sessionId');
      
      return true;

    } catch (e) {
      debugPrint('❌ AI Chat: Session başlatma hatası: $e');
      _setError('Chat başlatılamadı: $e');
      _setLoading(false);
      return false;
    }
  }

  /// 📨 Mesaj gönder
  Future<bool> sendMessage(String content) async {
    if (_currentSession == null || content.trim().isEmpty) {
      return false;
    }

    try {
      debugPrint('📨 AI Chat: Mesaj gönderiliyor...');
      
      _setTyping(true);
      _setError(null);

      final messageContent = content.trim();
      final sessionId = _currentSession!.id;
      final languageCode = _config!.language.code;
      final topic = _config!.topic.value;

      // Kullanıcı mesajını kaydet
      await _firestoreService.saveMessage(
        sessionId: sessionId,
        sender: 'user',
        content: messageContent,
        language: languageCode,
        topic: topic,
      );

      // Dialogflow'dan yanıt al
      final response = await _dialogflowService.detectIntent(
        message: messageContent,
        sessionId: sessionId,
        languageCode: languageCode,
        topic: topic,
      );

      // AI yanıtını kaydet
      await _firestoreService.saveMessage(
        sessionId: sessionId,
        sender: 'ai',
        content: response.fulfillmentText,
        language: languageCode,
        topic: topic,
      );

      debugPrint('✅ AI Chat: Mesaj gönderildi ve yanıt alındı');
      
      _setTyping(false);
      return true;

    } catch (e) {
      debugPrint('❌ AI Chat: Mesaj gönderme hatası: $e');
      _setError('Mesaj gönderilemedi: $e');
      _setTyping(false);
      return false;
    }
  }

  /// 👂 Mesajları dinle
  void _listenToMessages(String sessionId) {
    _firestoreService.getChatMessagesStream(sessionId).listen(
      (messages) {
        debugPrint('📡 AI Chat: ${messages.length} mesaj alındı');
        _messages = messages;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('❌ AI Chat: Mesaj dinleme hatası: $e');
        _setError('Mesajlar yüklenemedi: $e');
      },
    );
  }

  /// ⏹️ Chat session'ı sonlandır
  Future<bool> endChatSession() async {
    if (_currentSession == null) return false;

    try {
      debugPrint('⏹️ AI Chat: Session sonlandırılıyor...');
      
      await _firestoreService.endChatSession(_currentSession!.id);
      
      // State'i temizle
      _currentSession = null;
      _messages.clear();
      _config = null;
      _setError(null);
      
      debugPrint('✅ AI Chat: Session sonlandırıldı');
      notifyListeners();
      
      return true;

    } catch (e) {
      debugPrint('❌ AI Chat: Session sonlandırma hatası: $e');
      _setError('Chat sonlandırılamadı: $e');
      return false;
    }
  }

  /// 🧹 Chat'i temizle (local state)
  void clearChat() {
    debugPrint('🧹 AI Chat: Local state temizleniyor...');
    
    _currentSession = null;
    _messages.clear();
    _config = null;
    _setError(null);
    _setLoading(false);
    _setTyping(false);
    
    notifyListeners();
  }

  /// 🔄 Chat'i yeniden başlat
  Future<bool> restartChat() async {
    if (_config == null) return false;

    debugPrint('🔄 AI Chat: Yeniden başlatılıyor...');
    
    await endChatSession();
    return await startChatSession(_config!);
  }

  /// 📊 Session istatistikleri al
  Future<Map<String, dynamic>> getSessionStats() async {
    try {
      return await _firestoreService.getSessionStats();
    } catch (e) {
      debugPrint('❌ AI Chat: İstatistik alma hatası: $e');
      return {};
    }
  }

  /// 📜 Kullanıcı session'larını al
  Stream<List<ChatSession>> getUserSessionsStream(String userEmail) {
    return _firestoreService.getUserSessionsStream(userEmail);
  }

  /// 👨‍💼 Admin için tüm session'ları al
  Stream<List<ChatSession>> getAllSessionsStream({
    String? filterEmail,
    String? filterTopic,
    String? filterLanguage,
    String? filterStatus,
  }) {
    return _firestoreService.getAllSessionsStream(
      filterEmail: filterEmail,
      filterTopic: filterTopic,
      filterLanguage: filterLanguage,
      filterStatus: filterStatus,
    );
  }

  /// 🎛️ Demo mode kontrol
  void setDemoMode(bool enabled) {
    _dialogflowService.setDemoMode(enabled);
    debugPrint('🎭 AI Chat: Demo mode ${enabled ? "açık" : "kapalı"}');
  }

  /// 🌍 Dil desteği kontrol
  bool isLanguageSupported(String languageCode) {
    return _dialogflowService.isLanguageSupported(languageCode);
  }

  /// 📧 Email validasyonu
  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  /// 🎯 Konu validasyonu
  bool isValidTopic(ChatTopic topic) {
    return ChatTopic.values.contains(topic);
  }

  /// 🌐 Dil validasyonu
  bool isValidLanguage(ChatLanguage language) {
    return ChatLanguage.values.contains(language);
  }

  /// 📝 Private state setter'ları
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setTyping(bool typing) {
    if (_isTyping != typing) {
      _isTyping = typing;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      notifyListeners();
    }
  }

  /// 🧹 Temizlik
  @override
  void dispose() {
    debugPrint('🧹 AI Chat Provider: Temizleniyor...');
    
    _dialogflowService.dispose();
    _currentSession = null;
    _messages.clear();
    _config = null;
    
    super.dispose();
  }

  /// 📊 Debug bilgileri
  Map<String, dynamic> getDebugInfo() {
    return {
      'hasActiveSession': hasActiveSession,
      'sessionId': _currentSession?.id,
      'userEmail': _config?.userEmail,
      'topic': _config?.topic.value,
      'language': _config?.language.code,
      'messageCount': _messages.length,
      'isLoading': _isLoading,
      'isTyping': _isTyping,
      'hasError': _errorMessage != null,
      'errorMessage': _errorMessage,
    };
  }

  /// 📝 Session durumu
  String getSessionStatus() {
    if (_currentSession == null) {
      return 'No active session';
    }
    
    if (_isLoading) {
      return 'Loading...';
    }
    
    if (_isTyping) {
      return 'AI is typing...';
    }
    
    if (_errorMessage != null) {
      return 'Error: $_errorMessage';
    }
    
    return 'Active - ${_messages.length} messages';
  }

  /// 🔔 Notification için özet
  String getSessionSummary() {
    if (_currentSession == null) return 'No active chat';
    
    final config = _config!;
    final lastMessage = _messages.isNotEmpty ? _messages.last : null;
    
    return '${config.language.flag} ${config.topic.displayName} - '
           '${_messages.length} msg - '
           '${lastMessage != null ? 'Last: ${lastMessage.sender}' : 'No messages'}';
  }
}