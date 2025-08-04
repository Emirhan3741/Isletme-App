import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/ai_chat_models.dart';
import '../../services/ai_dialogflow_service.dart';
import '../../services/ai_chat_firestore_service.dart';

/// 💬 AI Chat Ana Sayfası
/// Kullanıcı ile AI arasında mesajlaşma sağlar
class AIChatPage extends StatefulWidget {
  final ChatConfig config;

  const AIChatPage({
    super.key,
    required this.config,
  });

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> 
    with TickerProviderStateMixin {
  
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  
  // Servisler
  late final DialogflowService _dialogflowService;
  late final AIChatFirestoreService _firestoreService;
  
  // State
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  String? _sessionId;
  String? _errorMessage;
  
  // Animasyon
  late AnimationController _messageAnimationController;
  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimations();
    _startChatSession();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _messageAnimationController.dispose();
    _typingAnimationController.dispose();
    _dialogflowService.dispose();
    super.dispose();
  }

  /// ⚙️ Servisleri başlat
  void _initializeServices() {
    _dialogflowService = DialogflowService();
    _firestoreService = AIChatFirestoreService();
    
    // Demo mode aktif (gerçek API yokken)
    _dialogflowService.setDemoMode(true);
  }

  /// 🎭 Animasyonları ayarla
  void _setupAnimations() {
    _messageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  /// 🚀 Chat oturumunu başlat
  Future<void> _startChatSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Firestore'da session oluştur
      final sessionId = await _firestoreService.startChatSession(widget.config);
      
      setState(() {
        _sessionId = sessionId;
        _isLoading = false;
      });

      // Mesajları dinlemeye başla
      _listenToMessages();
      
      debugPrint('✅ Chat session başlatıldı: $sessionId');

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Chat başlatılamadı: $e';
      });
      
      debugPrint('❌ Chat session hatası: $e');
    }
  }

  /// 👂 Mesajları dinle
  void _listenToMessages() {
    if (_sessionId == null) return;

    _firestoreService.getChatMessagesStream(_sessionId!).listen(
      (messages) {
        setState(() {
          _messages = messages;
        });
        
        // En son mesaja scroll
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      },
      onError: (e) {
        debugPrint('❌ Mesaj dinleme hatası: $e');
        _showErrorSnackBar('Mesajlar yüklenemedi: $e');
      },
    );
  }

  /// 📤 Mesaj gönder
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _sessionId == null) return;

    // Input temizle
    _messageController.clear();
    
    // Haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _isTyping = true;
    });

    try {
      // Kullanıcı mesajını kaydet
      await _firestoreService.saveMessage(
        sessionId: _sessionId!,
        sender: 'user',
        content: messageText,
        language: widget.config.language.code,
        topic: widget.config.topic.value,
      );

      // Typing animasyonu başlat
      _typingAnimationController.repeat();

      // Dialogflow'dan yanıt al
      final response = await _dialogflowService.detectIntent(
        message: messageText,
        sessionId: _sessionId!,
        languageCode: widget.config.language.code,
        topic: widget.config.topic.value,
      );

      // AI yanıtını kaydet
      await _firestoreService.saveMessage(
        sessionId: _sessionId!,
        sender: 'ai',
        content: response.fulfillmentText,
        language: widget.config.language.code,
        topic: widget.config.topic.value,
      );

    } catch (e) {
      debugPrint('❌ Mesaj gönderme hatası: $e');
      _showErrorSnackBar('Mesaj gönderilemedi: $e');
    } finally {
      setState(() {
        _isTyping = false;
      });
      _typingAnimationController.stop();
    }
  }

  /// 📜 En alta scroll
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// ❌ Hata mesajı göster
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 🔚 Chat'i sonlandır
  Future<void> _endChat() async {
    if (_sessionId == null) return;

    try {
      await _firestoreService.endChatSession(_sessionId!);
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('Chat sonlandırılamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// 📱 App Bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.config.language.flag} AI Yardımcı',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            widget.config.topic.displayName,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      actions: [
        // Demo mode göstergesi
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'DEMO',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        
        // Chat sonlandır
        IconButton(
          onPressed: _endChat,
          icon: const Icon(Icons.close),
          tooltip: 'Sohbeti Sonlandır',
        ),
      ],
    );
  }

  /// 🏗️ Ana gövde
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingScreen();
    }
    
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    return Column(
      children: [
        // Mesaj listesi
        Expanded(
          child: _buildMessagesList(),
        ),
        
        // Typing göstergesi
        if (_isTyping) _buildTypingIndicator(),
        
        // Mesaj input
        _buildMessageInput(),
      ],
    );
  }

  /// ⏳ Loading ekranı
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Chat başlatılıyor...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// ❌ Hata ekranı
  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Bir hata oluştu',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startChatSession,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  /// 💬 Mesajlar listesi
  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz mesaj yok',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Merhaba yazarak başlayabilirsiniz',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message, index);
      },
    );
  }

  /// 💭 Mesaj baloncuğu
  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isUser = message.isUser;
    final isLastMessage = index == _messages.length - 1;
    
    return AnimatedBuilder(
      animation: _messageAnimationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: isUser 
                ? MainAxisAlignment.end 
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // AI avatar (sol taraf)
              if (!isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              // Mesaj baloncuğu
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? Theme.of(context).primaryColor
                        : Colors.grey[100],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: isUser 
                              ? Colors.white70 
                              : Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // User avatar (sağ taraf)
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// ⌨️ Typing göstergesi
  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypingDot(0),
                    const SizedBox(width: 4),
                    _buildTypingDot(1),
                    const SizedBox(width: 4),
                    _buildTypingDot(2),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// • Typing dot
  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        final double animationValue = _typingAnimationController.value;
        final double opacity = (animationValue + index * 0.3) % 1.0;
        
        return Opacity(
          opacity: opacity,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  /// ✍️ Mesaj input alanı
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Mesajınızı yazın...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColor, Colors.blue],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isTyping ? null : _sendMessage,
              icon: Icon(
                _isTyping ? Icons.hourglass_empty : Icons.send,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🕒 Zaman formatla
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}d önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}s önce';
    } else {
      return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}