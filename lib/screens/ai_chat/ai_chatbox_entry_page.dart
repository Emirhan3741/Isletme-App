import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/ai_chat_models.dart';
import 'ai_chat_page.dart';

/// 🎯 AI Chatbox Giriş Sayfası
/// Kullanıcıdan email, konu ve dil bilgisi alır
class AIChatboxEntryPage extends StatefulWidget {
  const AIChatboxEntryPage({super.key});

  @override
  State<AIChatboxEntryPage> createState() => _AIChatboxEntryPageState();
}

class _AIChatboxEntryPageState extends State<AIChatboxEntryPage> 
    with SingleTickerProviderStateMixin {
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  ChatTopic _selectedTopic = ChatTopic.genel;
  ChatLanguage _selectedLanguage = ChatLanguage.turkish;
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animasyon kurulumu
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Animasyonu başlat
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// 📧 Email validasyonu
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-posta adresi gerekli';
    }
    
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir e-posta adresi girin';
    }
    
    return null;
  }

  /// 🚀 Chat başlatma
  Future<void> _startChat() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Haptic feedback
      HapticFeedback.mediumImpact();

      // Chat konfigürasyonu oluştur
      final config = ChatConfig(
        userEmail: _emailController.text.trim(),
        topic: _selectedTopic,
        language: _selectedLanguage,
      );

      // Chat sayfasına geçiş
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AIChatPage(config: config),
        ),
      );

    } catch (e) {
      _showErrorSnackBar('Chat başlatılamadı: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 AI Yardımcı'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildContent(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 📱 Ana içerik
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(),
            
            const SizedBox(height: 32),
            
            // Form alanları
            _buildEmailField(),
            const SizedBox(height: 24),
            
            _buildTopicDropdown(),
            const SizedBox(height: 24),
            
            _buildLanguageDropdown(),
            const SizedBox(height: 32),
            
            // Başlat butonu
            _buildStartButton(),
            
            const SizedBox(height: 24),
            
            // Bilgi metni
            _buildInfoText(),
          ],
        ),
      ),
    );
  }

  /// 🎨 Header bölümü
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Colors.blue],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.smart_toy_rounded,
            color: Colors.white,
            size: 50,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'AI Yardımcı',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Size nasıl yardımcı olabilirim?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 📧 Email input field
  Widget _buildEmailField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: _validateEmail,
          decoration: InputDecoration(
            labelText: 'E-posta Adresiniz',
            hintText: 'ornek@email.com',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ),
    );
  }

  /// 🎯 Konu dropdown
  Widget _buildTopicDropdown() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<ChatTopic>(
          value: _selectedTopic,
          decoration: InputDecoration(
            labelText: 'Konu Seçiniz',
            prefixIcon: const Icon(Icons.topic_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: ChatTopic.values.map((topic) {
            return DropdownMenuItem(
              value: topic,
              child: Text(topic.displayName),
            );
          }).toList(),
          onChanged: (ChatTopic? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedTopic = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  /// 🌍 Dil dropdown
  Widget _buildLanguageDropdown() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<ChatLanguage>(
          value: _selectedLanguage,
          decoration: InputDecoration(
            labelText: 'Dil Seçiniz',
            prefixIcon: const Icon(Icons.language_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: ChatLanguage.values.map((language) {
            return DropdownMenuItem(
              value: language,
              child: Row(
                children: [
                  Text(
                    language.flag,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(language.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (ChatLanguage? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedLanguage = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  /// 🚀 Başlat butonu
  Widget _buildStartButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Colors.blue],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _startChat,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Sohbeti Başlat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// ℹ️ Bilgi metni
  Widget _buildInfoText() {
    return Card(
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Bilgi',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• Konuşmalarınız güvenli şekilde saklanır\n'
              '• Seçtiğiniz dilde yanıt alırsınız\n'
              '• 7/24 hizmet verir\n'
              '• Kişisel verileriniz korunur',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}