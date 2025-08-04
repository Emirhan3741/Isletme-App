import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/ai_chat_provider.dart';
import '../screens/ai_chat/ai_chatbox_entry_page.dart';

/// 🤖 AI Chat Floating Action Button
/// Ana sayfalarda floating button olarak gösterilir
class AIChatFloatingButton extends StatefulWidget {
  final bool showNotificationBadge;
  final VoidCallback? onPressed;

  const AIChatFloatingButton({
    super.key,
    this.showNotificationBadge = false,
    this.onPressed,
  });

  @override
  State<AIChatFloatingButton> createState() => _AIChatFloatingButtonState();
}

class _AIChatFloatingButtonState extends State<AIChatFloatingButton> 
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _badgeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _badgeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animasyonu
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Badge animasyonu
    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _badgeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _badgeController,
      curve: Curves.elasticOut,
    ));
    
    // Pulse animasyonunu başlat
    _pulseController.repeat(reverse: true);
    
    // Badge animasyonunu başlat (eğer badge gösterilecekse)
    if (widget.showNotificationBadge) {
      _badgeController.forward();
    }
  }

  @override
  void didUpdateWidget(AIChatFloatingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Badge durumu değişti mi kontrol et
    if (widget.showNotificationBadge != oldWidget.showNotificationBadge) {
      if (widget.showNotificationBadge) {
        _badgeController.forward();
      } else {
        _badgeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  /// 🚀 AI Chat başlat
  void _openAIChat() {
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Custom callback varsa çalıştır
    if (widget.onPressed != null) {
      widget.onPressed!();
      return;
    }
    
    // AI Chat sayfasını aç
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AIChatboxEntryPage(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AIChatProvider>(
      builder: (context, chatProvider, child) {
        final hasActiveSession = chatProvider.hasActiveSession;
        
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Stack(
                children: [
                  // Ana floating button
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: hasActiveSession
                            ? [Colors.green, Colors.teal]
                            : [Theme.of(context).primaryColor, Colors.blue],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (hasActiveSession ? Colors.green : Theme.of(context).primaryColor)
                              .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      onPressed: _openAIChat,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      child: Icon(
                        hasActiveSession ? Icons.chat_bubble : Icons.smart_toy,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  
                  // Notification badge
                  if (widget.showNotificationBadge)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: AnimatedBuilder(
                        animation: _badgeAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _badgeAnimation.value,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.notifications,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  
                  // Active session indicator
                  if (hasActiveSession)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.green,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// 📱 AI Chat App Bar Action Button
/// App bar'da action button olarak kullanılır
class AIChatAppBarButton extends StatelessWidget {
  final bool showBadge;
  final VoidCallback? onPressed;

  const AIChatAppBarButton({
    super.key,
    this.showBadge = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AIChatProvider>(
      builder: (context, chatProvider, child) {
        final hasActiveSession = chatProvider.hasActiveSession;
        
        return Stack(
          children: [
            IconButton(
              onPressed: onPressed ?? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AIChatboxEntryPage(),
                  ),
                );
              },
              icon: Icon(
                hasActiveSession ? Icons.chat_bubble : Icons.smart_toy,
                color: hasActiveSession ? Colors.green[300] : null,
              ),
              tooltip: 'AI Yardımcı',
            ),
            
            // Badge
            if (showBadge)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 📋 AI Chat Drawer Item
/// Navigation drawer'da menü item olarak kullanılır
class AIChatDrawerItem extends StatelessWidget {
  final VoidCallback? onTap;

  const AIChatDrawerItem({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AIChatProvider>(
      builder: (context, chatProvider, child) {
        final hasActiveSession = chatProvider.hasActiveSession;
        final sessionSummary = chatProvider.getSessionSummary();
        
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasActiveSession
                    ? [Colors.green, Colors.teal]
                    : [Theme.of(context).primaryColor, Colors.blue],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasActiveSession ? Icons.chat_bubble : Icons.smart_toy,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: const Text('AI Yardımcı'),
          subtitle: hasActiveSession 
              ? Text(
                  sessionSummary,
                  style: const TextStyle(fontSize: 12),
                )
              : const Text('Sorularınız için AI desteği'),
          trailing: hasActiveSession
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Aktif',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap ?? () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AIChatboxEntryPage(),
              ),
            );
          },
        );
      },
    );
  }
}

/// 🎛️ AI Chat Status Widget
/// Herhangi bir yerde chat durumunu göstermek için
class AIChatStatusWidget extends StatelessWidget {
  final bool showDetails;

  const AIChatStatusWidget({
    super.key,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AIChatProvider>(
      builder: (context, chatProvider, child) {
        if (!chatProvider.hasActiveSession) {
          return const SizedBox.shrink();
        }

        final sessionStatus = chatProvider.getSessionStatus();
        final sessionSummary = chatProvider.getSessionSummary();
        
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: chatProvider.isTyping 
                        ? Colors.orange 
                        : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'AI Chat Aktif',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (showDetails) ...[
                        Text(
                          sessionSummary,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AIChatboxEntryPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  tooltip: 'Chat\'i Aç',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}