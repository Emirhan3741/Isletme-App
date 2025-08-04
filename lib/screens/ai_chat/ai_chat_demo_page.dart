import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_chat_provider.dart';
import '../../widgets/ai_chat_floating_button.dart';
import 'ai_chatbox_entry_page.dart';
import 'admin_support_page.dart';

/// 🧪 AI Chat Demo ve Test Sayfası
/// AI Chatbot sisteminin tüm özelliklerini test etmek için
class AIChatDemoPage extends StatefulWidget {
  const AIChatDemoPage({super.key});

  @override
  State<AIChatDemoPage> createState() => _AIChatDemoPageState();
}

class _AIChatDemoPageState extends State<AIChatDemoPage> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 AI Chat Demo'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // App bar'da AI chat butonu
          const AIChatAppBarButton(showBadge: true),
        ],
      ),
      
      drawer: _buildDemoDrawer(),
      
      body: _buildDemoContent(),
      
      // Floating AI chat button
      floatingActionButton: const AIChatFloatingButton(
        showNotificationBadge: true,
      ),
    );
  }

  /// 📱 Demo drawer
  Widget _buildDemoDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColor, Colors.blue],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🤖 AI Chat Demo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Yapay Zeka Destekli\nMüşteri Hizmetleri',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // AI Chat drawer item
          const AIChatDrawerItem(),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Admin Panel'),
            subtitle: const Text('Konuşmaları yönet'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminSupportPage(),
                ),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Demo Ayarları'),
            subtitle: const Text('Test konfigürasyonu'),
            onTap: () {
              Navigator.pop(context);
              _showDemoSettings();
            },
          ),
        ],
      ),
    );
  }

  /// 📋 Demo content
  Widget _buildDemoContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chat status widget
          const AIChatStatusWidget(showDetails: true),
          
          const SizedBox(height: 24),
          
          // Özellikler kartları
          Text(
            '🎯 AI Chatbot Özellikleri',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          
          const SizedBox(height: 16),
          
          _buildFeatureCard(
            icon: Icons.language,
            title: '5 Dil Desteği',
            description: 'Türkçe, İngilizce, Almanca, İspanyolca, Fransızca',
            color: Colors.blue,
          ),
          
          _buildFeatureCard(
            icon: Icons.topic,
            title: 'Konu Bazlı Yanıtlar',
            description: 'Randevu, destek, bilgi alma, öneri konularında uzman',
            color: Colors.green,
          ),
          
          _buildFeatureCard(
            icon: Icons.cloud,
            title: 'Firestore Entegrasyonu',
            description: 'Tüm konuşmalar güvenli şekilde saklanır',
            color: Colors.orange,
          ),
          
          _buildFeatureCard(
            icon: Icons.admin_panel_settings,
            title: 'Admin Panel',
            description: 'Konuşmaları izle, filtrele ve yönet',
            color: Colors.purple,
          ),
          
          const SizedBox(height: 24),
          
          // Hızlı başlatma butonları
          Text(
            '🚀 Hızlı Başlatma',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AIChatboxEntryPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Yeni Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminSupportPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Admin Panel'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Provider durumu
          _buildProviderStatus(),
        ],
      ),
    );
  }

  /// 🎴 Özellik kartı
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 Provider durumu
  Widget _buildProviderStatus() {
    return Consumer<AIChatProvider>(
      builder: (context, chatProvider, child) {
        final debugInfo = chatProvider.getDebugInfo();
        
        return ExpansionTile(
          title: const Text('🔧 Debug Bilgileri'),
          subtitle: Text('Provider Status: ${chatProvider.getSessionStatus()}'),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: debugInfo.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          '${entry.key}:',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${entry.value}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ⚙️ Demo ayarları
  void _showDemoSettings() {
    showDialog(
      context: context,
      builder: (context) => Consumer<AIChatProvider>(
        builder: (context, chatProvider, child) {
          return AlertDialog(
            title: const Text('🎛️ Demo Ayarları'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Demo Mode'),
                  subtitle: const Text('Gerçek API yerine demo yanıtları'),
                  value: true, // Demo mode always true for now
                  onChanged: (value) {
                    chatProvider.setDemoMode(value);
                  },
                ),
                
                const Divider(),
                
                ListTile(
                  title: const Text('Chat Temizle'),
                  subtitle: const Text('Aktif chat session\'ını sonlandır'),
                  trailing: const Icon(Icons.clear),
                  onTap: () {
                    chatProvider.clearChat();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat temizlendi'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
          );
        },
      ),
    );
  }
}