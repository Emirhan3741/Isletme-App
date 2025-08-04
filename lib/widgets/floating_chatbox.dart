import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'ai_chatbox_widget.dart';

/// Floating chat button ve overlay widget
class FloatingChatbox extends StatefulWidget {
  const FloatingChatbox({Key? key}) : super(key: key);

  @override
  State<FloatingChatbox> createState() => _FloatingChatboxState();
}

class _FloatingChatboxState extends State<FloatingChatbox>
    with TickerProviderStateMixin {
  
  bool _isExpanded = false;
  OverlayEntry? _overlayEntry;
  
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    // Sürekli pulse animasyonu
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _toggleChat() {
    if (_isExpanded) {
      _closeChat();
    } else {
      _openChat();
    }
  }

  void _openChat() {
    if (_overlayEntry != null) return;

    setState(() {
      _isExpanded = true;
    });

    _rotationController.forward();
    _pulseController.stop();

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildChatOverlay(),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeChat() {
    _removeOverlay();
    
    setState(() {
      _isExpanded = false;
    });

    _rotationController.reverse();
    _pulseController.repeat(reverse: true);

    // Chat'i temizle
    context.read<ChatProvider>().clearChat();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildChatOverlay() {
    return GestureDetector(
      onTap: _closeChat,
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping chat
            child: AIChatboxWidget(
              onClose: _closeChat,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _toggleChat,
                    child: Consumer<ChatProvider>(
                      builder: (context, chatProvider, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              _isExpanded ? Icons.close : Icons.chat_bubble,
                              color: Colors.white,
                              size: 28,
                            ),
                            
                            // Unread indicator
                            if (chatProvider.hasActiveSession && !_isExpanded)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Minimal chat button (alternative)
class ChatFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool hasNotification;

  const ChatFloatingActionButton({
    Key? key,
    this.onPressed,
    this.hasNotification = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(
            Icons.chat_bubble_outline,
            color: Colors.white,
          ),
        ),
        
        if (hasNotification)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}