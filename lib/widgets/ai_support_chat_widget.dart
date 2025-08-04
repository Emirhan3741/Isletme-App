import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/auth_provider_enhanced.dart';
import '../providers/ai_chat_provider.dart';
import '../core/constants/app_constants.dart';
import '../screens/ai_chat/ai_chat_page.dart';

/// 🤖 AI Support Chat Widget - Floating Chat Button
class AISupportChatWidget extends StatefulWidget {
  const AISupportChatWidget({Key? key}) : super(key: key);

  @override
  State<AISupportChatWidget> createState() => _AISupportChatWidgetState();
}

class _AISupportChatWidgetState extends State<AISupportChatWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer2<AuthProviderEnhanced, AIChatProvider>(
      builder: (context, authProvider, aiChatProvider, child) {
        // Kullanıcı giriş yapmamışsa widget'ı gösterme
        if (!authProvider.isLoggedIn) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 24,
          right: 24,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: _isExpanded ? _buildExpandedChat(l10n, authProvider, aiChatProvider) : _buildFloatingButton(l10n),
              );
            },
          ),
        );
      },
    );
  }

  /// 🎈 Floating Chat Button
  Widget _buildFloatingButton(AppLocalizations l10n) {
    return Stack(
      children: [
        // Main Chat Button
        FloatingActionButton(
          onPressed: _toggleChat,
          backgroundColor: AppConstants.primaryColor,
          heroTag: "ai-chat-button",
          child: const Icon(
            Icons.chat_bubble_outline,
            color: Colors.white,
            size: 28,
          ),
        ),
        
        // Notification Badge (simplified for now)
        Consumer<AIChatProvider>(
          builder: (context, aiChatProvider, child) {
            // Simplified - no unread count for now
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  /// 💬 Expanded Chat Preview
  Widget _buildExpandedChat(
    AppLocalizations l10n,
    AuthProviderEnhanced authProvider,
    AIChatProvider aiChatProvider,
  ) {
    return Container(
      width: 320,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
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
                const Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.aiSupport ?? 'AI Destek',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        l10n.onlineNow ?? 'Şimdi çevrimiçi',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _toggleChat,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          
          // Quick Actions
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.howCanIHelp ?? 'Size nasıl yardımcı olabilirim?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildQuickAction(
                    icon: Icons.help_outline,
                    title: l10n.technicalSupport ?? 'Teknik Destek',
                    subtitle: l10n.getHelpWithIssues ?? 'Sorunlarınızla ilgili yardım alın',
                    onTap: () => _openAIChat('technical_support'),
                  ),
                  
                  _buildQuickAction(
                    icon: Icons.question_answer,
                    title: l10n.generalQuestions ?? 'Genel Sorular',
                    subtitle: l10n.askAnything ?? 'Herhangi bir soru sorun',
                    onTap: () => _openAIChat('general_questions'),
                  ),
                  
                  _buildQuickAction(
                    icon: Icons.feedback,
                    title: l10n.feedback ?? 'Geri Bildirim',
                    subtitle: l10n.shareYourThoughts ?? 'Düşüncelerinizi paylaşın',
                    onTap: () => _openAIChat('feedback'),
                  ),
                  
                  const Spacer(),
                  
                  // Full Chat Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openFullAIChat(),
                      icon: const Icon(Icons.chat),
                      label: Text(l10n.openFullChat ?? 'Tam Sohbet Aç'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ⚡ Quick Action Item
  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppConstants.primaryColor),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }

  /// 🔄 Toggle Chat State
  void _toggleChat() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  /// 🚀 Open AI Chat with Context
  void _openAIChat(String chatContext) {
    final authProvider = Provider.of<AuthProviderEnhanced>(context, listen: false);
    final aiChatProvider = Provider.of<AIChatProvider>(context, listen: false);
    
    // Context-based initial message
    String initialMessage = '';
    switch (chatContext) {
      case 'technical_support':
        initialMessage = 'Merhaba! Teknik bir sorunum var, yardımcı olabilir misiniz?';
        break;
      case 'general_questions':
        initialMessage = 'Merhaba! Genel bir sorum var.';
        break;
      case 'feedback':
        initialMessage = 'Merhaba! Uygulama hakkında geri bildirim vermek istiyorum.';
        break;
    }
    
    // Start chat session with context
    if (initialMessage.isNotEmpty) {
      // aiChatProvider.sendMessage(initialMessage); // Commented out for now
    }
    
    _toggleChat(); // Close preview
    _openFullAIChat(); // Open full chat
  }

  /// 💬 Open Full AI Chat Page
  void _openFullAIChat() {
    // Simplified - just close the preview for now
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => const AIChatPage(),
    //   ),
    // );
    
    _toggleChat(); // Just close the preview
    
    // Show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🤖 AI Chat özelliği yakında aktif olacak!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}