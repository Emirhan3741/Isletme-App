import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/auth_provider_enhanced.dart';
import '../providers/locale_provider.dart';
import '../services/ai_dialogflow_service.dart';
import '../services/ai_chat_firestore_service.dart';
import '../models/ai_chat_models.dart';

/// 🤖 Modern AI Chatbox Widget - Kullanıcı bilgilerini otomatik alır
class ModernAIChatboxWidget extends StatefulWidget {
  const ModernAIChatboxWidget({Key? key}) : super(key: key);

  @override
  State<ModernAIChatboxWidget> createState() => _ModernAIChatboxWidgetState();
}

class _ModernAIChatboxWidgetState extends State<ModernAIChatboxWidget>
    with TickerProviderStateMixin {
  
  final DialogflowService _dialogflowService = DialogflowService();
  final AIChatFirestoreService _firestoreService = AIChatFirestoreService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isOpen = false;
  bool _isLoading = false;
  bool _isTyping = false;
  List<Map<String, dynamic>> _messages = [];
  String? _sessionId;
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    // Demo mode aktif et
    _dialogflowService.setDemoMode(true);
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _slideController.dispose();
    _dialogflowService.dispose();
    super.dispose();
  }

  /// 💬 Chat'i aç/kapat
  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
    });

    if (_isOpen) {
      _slideController.forward();
      _initializeChatIfNeeded();
    } else {
      _slideController.reverse();
    }
  }

  /// 🚀 Chat'i başlat (kullanıcı bilgilerini otomatik al)
  Future<void> _initializeChatIfNeeded() async {
    if (_sessionId != null) return; // Zaten başlatılmış

    final authProvider = context.read<AuthProviderEnhanced>();
    final localeProvider = context.read<LocaleProvider>();
    
    final user = authProvider.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Kullanıcı bilgilerini otomatik al
      final chatConfig = ChatConfig(
        userEmail: user.email,
        language: ChatLanguage.fromCode(localeProvider.locale.languageCode),
        topic: ChatTopic.fromSector(authProvider.getCurrentUserSelectedPanel() ?? 'general'),
        additionalInfo: {
          'userName': user.name,
          'userRole': user.role,
          'selectedPanel': authProvider.getCurrentUserSelectedPanel(),
          'companyId': user.companyId,
        },
      );

      // Chat session başlat
      _sessionId = await _firestoreService.startChatSession(chatConfig);
      
      // Hoş geldin mesajını ekle
      _addWelcomeMessage();

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('❌ Chat başlatma hatası: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 👋 Hoş geldin mesajı ekle
  void _addWelcomeMessage() {
    final localization = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProviderEnhanced>();
    final user = authProvider.currentUser;
    
    String welcomeMessage;
    switch (localization.localeName) {
      case 'en':
        welcomeMessage = 'Hello ${user?.name ?? 'User'}! How can I help you today?';
        break;
      case 'de':
        welcomeMessage = 'Hallo ${user?.name ?? 'Benutzer'}! Wie kann ich Ihnen heute helfen?';
        break;
      case 'es':
        welcomeMessage = '¡Hola ${user?.name ?? 'Usuario'}! ¿Cómo puedo ayudarte hoy?';
        break;
      case 'fr':
        welcomeMessage = 'Bonjour ${user?.name ?? 'Utilisateur'}! Comment puis-je vous aider aujourd\'hui?';
        break;
      default: // 'tr'
        welcomeMessage = 'Merhaba ${user?.name ?? 'Kullanıcı'}! Size nasıl yardımcı olabilirim?';
    }

    setState(() {
      _messages.add({
        'text': welcomeMessage,
        'isUser': false,
        'timestamp': DateTime.now(),
      });
    });
  }

  /// 📤 Mesaj gönder
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sessionId == null || _isTyping) return;

    final localeProvider = context.read<LocaleProvider>();
    final authProvider = context.read<AuthProviderEnhanced>();

    setState(() {
      _isTyping = true;
      _messages.add({
        'text': text,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // AI yanıtını al
      final response = await _dialogflowService.detectIntent(
        message: text,
        sessionId: _sessionId!,
        languageCode: localeProvider.locale.languageCode,
        topic: authProvider.getCurrentUserSelectedPanel() ?? 'general',
      );

      // Firestore'a mesajları kaydet
      await _firestoreService.saveConversation(
        sessionId: _sessionId!,
        userMessage: text,
        aiResponse: response.fulfillmentText,
        languageCode: localeProvider.locale.languageCode,
        userEmail: authProvider.currentUser?.email ?? 'unknown',
        metadata: {
          'intent': response.intentDisplayName,
          'parameters': response.parameters,
        },
      );

      setState(() {
        _messages.add({
          'text': response.fulfillmentText,
          'isUser': false,
          'timestamp': DateTime.now(),
        });
        _isTyping = false;
      });

      _scrollToBottom();

    } catch (e) {
      debugPrint('❌ Mesaj gönderme hatası: $e');
      setState(() {
        _messages.add({
          'text': AppLocalizations.of(context)!.error,
          'isUser': false,
          'timestamp': DateTime.now(),
        });
        _isTyping = false;
      });
    }
  }

  /// 📜 Scroll en alta
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    
    return Positioned(
      bottom: 24,
      right: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Chat penceresi
          if (_isOpen)
            SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: 320,
                height: 450,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(localization),
                    
                    // Mesajlar listesi
                    Expanded(
                      child: _isLoading
                          ? _buildLoadingView(localization)
                          : _buildMessagesList(),
                    ),
                    
                    // Mesaj yazma alanı
                    _buildMessageInput(localization),
                  ],
                ),
              ),
            ),
          
          // Chat butonu
          FloatingActionButton(
            backgroundColor: Theme.of(context).primaryColor,
            child: Icon(
              _isOpen ? Icons.close : Icons.chat,
              color: Colors.white,
            ),
            onPressed: _toggleChat,
          ),
        ],
      ),
    );
  }

  /// 📋 Header widget
  Widget _buildHeader(AppLocalizations localization) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              localization.aiSupport,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            localization.onlineNow,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// ⏳ Loading view
  Widget _buildLoadingView(AppLocalizations localization) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            localization.loading,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// 💬 Mesajlar listesi
  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTyping && index == _messages.length) {
          return _buildTypingIndicator();
        }
        
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  /// 💭 Mesaj balonu
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser 
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message['text'] as String,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person, size: 16, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  /// ⌨️ Yazıyor göstergesi
  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              width: 40,
              height: 20,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
        ],
      ),
    );
  }

  /// ✏️ Mesaj yazma alanı
  Widget _buildMessageInput(AppLocalizations localization) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: localization.writeMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.send, color: Colors.white),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}