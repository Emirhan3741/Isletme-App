import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../services/dialogflow_service.dart';
import '../core/constants/app_constants.dart';

/// Ana AI Chatbox Widget
class AIChatboxWidget extends StatefulWidget {
  final bool isFullScreen;
  final VoidCallback? onClose;

  const AIChatboxWidget({
    Key? key,
    this.isFullScreen = false,
    this.onClose,
  }) : super(key: key);

  @override
  State<AIChatboxWidget> createState() => _AIChatboxWidgetState();
}

class _AIChatboxWidgetState extends State<AIChatboxWidget> 
    with TickerProviderStateMixin {
  
  final ChatService _chatService = ChatService();
  final DialogflowService _dialogflowService = DialogflowService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  ChatSession? _currentSession;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  String? _error;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _showChatInitDialog();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// Chat başlatma dialog'u göster
  Future<void> _showChatInitDialog() async {
    final result = await showDialog<ChatInitInfo>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ChatInitDialog(),
    );

    if (result != null) {
      await _initializeChat(result);
    } else {
      widget.onClose?.call();
    }
  }

  /// Chat'i başlat
  Future<void> _initializeChat(ChatInitInfo initInfo) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('🚀 Chat başlatılıyor: ${initInfo.userEmail}');

      final session = await _chatService.startChatSession(
        userEmail: initInfo.userEmail,
        topic: initInfo.topic,
        language: initInfo.language,
        additionalInfo: initInfo.additionalInfo,
      );

      setState(() {
        _currentSession = session;
        _isLoading = false;
      });

      // Mesajları dinlemeye başla
      _listenToMessages();
      
      // Animasyonu başlat
      _slideController.forward();

      debugPrint('✅ Chat başlatıldı: ${session.id}');

    } catch (e) {
      debugPrint('❌ Chat başlatma hatası: $e');
      setState(() {
        _error = 'Chat başlatılamadı: $e';
        _isLoading = false;
      });
    }
  }

  /// Mesajları dinle
  void _listenToMessages() {
    if (_currentSession == null) return;

    _chatService.getSessionMessagesStream(_currentSession!.id).listen(
      (messages) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      },
      onError: (error) {
        debugPrint('❌ Mesaj stream hatası: $error');
        setState(() {
          _error = 'Mesaj akışında hata: $error';
        });
      },
    );
  }

  /// Mesaj gönder
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentSession == null || _isTyping) return;

    setState(() {
      _isTyping = true;
      _error = null;
    });

    try {
      // Kullanıcı mesajını ekle
      await _chatService.addMessage(
        sessionId: _currentSession!.id,
        content: text,
        role: ChatRole.user,
        language: _currentSession!.language,
        topic: _currentSession!.topic,
      );

      _messageController.clear();

      // AI yanıtını al
      final aiResponse = await _dialogflowService.sendMessage(
        message: text,
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
        },
      );

    } catch (e) {
      debugPrint('❌ Mesaj gönderme hatası: $e');
      setState(() {
        _error = 'Mesaj gönderilemedi: $e';
      });
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  /// En alta scroll et
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

  /// Chat'i kapat
  Future<void> _closeChat() async {
    if (_currentSession != null) {
      await _chatService.endChatSession(_currentSession!.id);
    }
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFullScreen) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: _buildChatBody(),
      );
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              height: 600,
              width: 400,
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
                  _buildHeader(),
                  Expanded(child: _buildChatBody()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// App bar (full screen mode)
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text('AI Asistan'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _closeChat,
        ),
      ],
    );
  }

  /// Header (widget mode)
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'AI Asistan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_currentSession != null) ...[
            Text(
              ChatLanguage.getFlag(_currentSession!.language),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: _closeChat,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Chat body
  Widget _buildChatBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chat başlatılıyor...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showChatInitDialog,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _buildMessagesList(),
        ),
        if (_isTyping) _buildTypingIndicator(),
        _buildMessageInput(),
      ],
    );
  }

  /// Mesajlar listesi
  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text('Henüz mesaj yok. Yazışmaya başlayın!'),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return ChatMessageBubble(
          message: message,
          isUser: message.role == ChatRole.user,
        );
      },
    );
  }

  /// Typing indicator
  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppConstants.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI yazıyor...',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mesaj input alanı
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Mesajınızı yazın...',
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
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
              enabled: !_isTyping,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _isTyping ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chat mesaj balonu
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;

  const ChatMessageBubble({
    Key? key,
    required this.message,
    required this.isUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppConstants.primaryColor,
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppConstants.primaryColor
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isUser 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: Icon(
                Icons.person,
                color: Colors.grey.shade600,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays}g önce';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}s önce';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}dk önce';
    } else {
      return 'Şimdi';
    }
  }
}

/// Chat başlatma dialog'u
class ChatInitDialog extends StatefulWidget {
  const ChatInitDialog({Key? key}) : super(key: key);

  @override
  State<ChatInitDialog> createState() => _ChatInitDialogState();
}

class _ChatInitDialogState extends State<ChatInitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  String _selectedTopic = ChatTopic.general;
  String _selectedLanguage = ChatLanguage.turkish;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI Asistan'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Size daha iyi yardımcı olabilmek için aşağıdaki bilgileri paylaşın:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            
            // E-posta
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta adresiniz',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'E-posta gerekli';
                }
                if (!value.contains('@')) {
                  return 'Geçerli e-posta girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Konu
            DropdownButtonFormField<String>(
              value: _selectedTopic,
              decoration: const InputDecoration(
                labelText: 'Konu',
                prefixIcon: Icon(Icons.topic),
                border: OutlineInputBorder(),
              ),
              items: ChatTopic.allTopics.map((topic) {
                return DropdownMenuItem(
                  value: topic,
                  child: Text(ChatTopic.getDisplayName(topic)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTopic = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Dil
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Dil',
                prefixIcon: Icon(Icons.language),
                border: OutlineInputBorder(),
              ),
              items: ChatLanguage.supportedLanguages.map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Row(
                    children: [
                      Text(ChatLanguage.getFlag(lang)),
                      const SizedBox(width: 8),
                      Text(ChatLanguage.getDisplayName(lang)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final initInfo = ChatInitInfo(
                userEmail: _emailController.text.trim(),
                topic: _selectedTopic,
                language: _selectedLanguage,
              );
              Navigator.of(context).pop(initInfo);
            }
          },
          child: const Text('Başlat'),
        ),
      ],
    );
  }
}