import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../services/dialogflow_service.dart';

/// Chat state management provider
class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final DialogflowService _dialogflowService = DialogflowService();

  // Current state
  ChatSession? _currentSession;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  String? _error;
  
  // Chat configuration
  String _defaultLanguage = ChatLanguage.turkish;
  String _defaultTopic = ChatTopic.general;
  
  // Getters
  ChatSession? get currentSession => _currentSession;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;
  String? get error => _error;
  bool get hasActiveSession => _currentSession != null;
  String get defaultLanguage => _defaultLanguage;
  String get defaultTopic => _defaultTopic;

  /// Yeni chat session başlat
  Future<bool> startChatSession({
    required String userEmail,
    required String topic,
    required String language,
    Map<String, dynamic> additionalInfo = const {},
  }) async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint('🚀 ChatProvider: Session başlatılıyor...');

      final session = await _chatService.startChatSession(
        userEmail: userEmail,
        topic: topic,
        language: language,
        additionalInfo: additionalInfo,
      );

      _currentSession = session;
      _messages = [];
      
      // Mesajları dinlemeye başla
      _listenToMessages();

      _setLoading(false);
      
      debugPrint('✅ ChatProvider: Session başlatıldı - ${session.id}');
      return true;

    } catch (e) {
      debugPrint('❌ ChatProvider: Session başlatma hatası: $e');
      _setError('Chat başlatılamadı: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Mesajları dinle
  void _listenToMessages() {
    if (_currentSession == null) return;

    _chatService.getSessionMessagesStream(_currentSession!.id).listen(
      (messages) {
        _messages = messages;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ ChatProvider: Mesaj stream hatası: $error');
        _setError('Mesaj akışı hatası: $error');
      },
    );
  }

  /// Mesaj gönder
  Future<bool> sendMessage(String content) async {
    if (content.trim().isEmpty || _currentSession == null || _isTyping) {
      return false;
    }

    try {
      _setTyping(true);
      _clearError();

      debugPrint('💬 ChatProvider: Mesaj gönderiliyor...');

      // Kullanıcı mesajını ekle
      await _chatService.addMessage(
        sessionId: _currentSession!.id,
        content: content,
        role: ChatRole.user,
        language: _currentSession!.language,
        topic: _currentSession!.topic,
      );

      // AI yanıtını al
      final aiResponse = await _dialogflowService.sendMessage(
        message: content,
        sessionId: _currentSession!.id,
        language: _currentSession!.language,
        topic: _currentSession!.topic,
      );

      // AI yanıtını ekle
      await _chatService.addMessage(
        sessionId: _currentSession!.id,
        content: aiResponse.text,
        role: ChatRole.ai,
        language: _currentSession!.language,
        topic: _currentSession!.topic,
        metadata: {
          'intent': aiResponse.intentName,
          'confidence': aiResponse.confidence,
          'parameters': aiResponse.parameters,
          'suggestions': aiResponse.suggestions,
        },
      );

      _setTyping(false);
      
      debugPrint('✅ ChatProvider: Mesaj gönderildi ve yanıt alındı');
      return true;

    } catch (e) {
      debugPrint('❌ ChatProvider: Mesaj gönderme hatası: $e');
      _setError('Mesaj gönderilemedi: $e');
      _setTyping(false);
      return false;
    }
  }

  /// Chat session'ını sonlandır
  Future<void> endChatSession() async {
    if (_currentSession == null) return;

    try {
      debugPrint('🔚 ChatProvider: Session sonlandırılıyor...');

      await _chatService.endChatSession(_currentSession!.id);
      
      _currentSession = null;
      _messages = [];
      _clearError();
      
      notifyListeners();
      
      debugPrint('✅ ChatProvider: Session sonlandırıldı');

    } catch (e) {
      debugPrint('❌ ChatProvider: Session sonlandırma hatası: $e');
      _setError('Session sonlandırılamadı: $e');
    }
  }

  /// Varsayılan dili ayarla
  void setDefaultLanguage(String language) {
    if (ChatLanguage.supportedLanguages.contains(language)) {
      _defaultLanguage = language;
      notifyListeners();
      debugPrint('🌍 ChatProvider: Varsayılan dil: $language');
    }
  }

  /// Varsayılan konuyu ayarla
  void setDefaultTopic(String topic) {
    if (ChatTopic.allTopics.contains(topic)) {
      _defaultTopic = topic;
      notifyListeners();
      debugPrint('🎯 ChatProvider: Varsayılan konu: $topic');
    }
  }

  /// Chat'i temizle
  void clearChat() {
    _currentSession = null;
    _messages = [];
    _clearError();
    notifyListeners();
    debugPrint('🧹 ChatProvider: Chat temizlendi');
  }

  /// Mesajı okunmuş olarak işaretle
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _chatService.markMessageAsRead(messageId);
    } catch (e) {
      debugPrint('❌ ChatProvider: Mesaj okunmuş işaretleme hatası: $e');
    }
  }

  /// Kullanıcının geçmiş chat'lerini al
  Future<List<ChatSession>> getUserChatHistory(String userEmail) async {
    try {
      return await _chatService.getUserChatSessions(userEmail);
    } catch (e) {
      debugPrint('❌ ChatProvider: Chat geçmişi alma hatası: $e');
      return [];
    }
  }

  /// Chat istatistikleri al
  Future<Map<String, dynamic>> getChatStatistics() async {
    try {
      return await _chatService.getChatStatistics();
    } catch (e) {
      debugPrint('❌ ChatProvider: İstatistik alma hatası: $e');
      return {};
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setTyping(bool typing) {
    _isTyping = typing;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _dialogflowService.clearAllSessions();
    super.dispose();
  }
}