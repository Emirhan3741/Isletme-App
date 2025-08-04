import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/floating_chatbox.dart';

/// Ana sayfa - AI Chat entegrasyonu ile
class HomePageWithChat extends StatefulWidget {
  const HomePageWithChat({Key? key}) : super(key: key);

  @override
  State<HomePageWithChat> createState() => _HomePageWithChatState();
}

class _HomePageWithChatState extends State<HomePageWithChat> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevu ERP'),
        actions: [
          // Chat istatistikleri göstergesi
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (chatProvider.hasActiveSession) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${chatProvider.messages.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      
      body: Stack(
        children: [
          // Ana sayfa içeriği
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.business_center,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Randevu ERP Sistemi',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'AI Chat Sistemi ile Destekleniyor',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Chat durumu göstergesi
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.smart_toy,
                                  color: chatProvider.hasActiveSession ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Asistan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: chatProvider.hasActiveSession ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              chatProvider.hasActiveSession
                                  ? 'Aktif Chat: ${chatProvider.messages.length} mesaj'
                                  : 'Yardım için sağ alttaki chat butonuna tıklayın',
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Quick actions
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildQuickAction(
                      icon: Icons.calendar_today,
                      label: 'Randevular',
                      onTap: () {
                        // Navigate to appointments
                      },
                    ),
                    _buildQuickAction(
                      icon: Icons.people,
                      label: 'Müşteriler',
                      onTap: () {
                        // Navigate to customers
                      },
                    ),
                    _buildQuickAction(
                      icon: Icons.settings,
                      label: 'Ayarlar',
                      onTap: () {
                        // Navigate to settings
                      },
                    ),
                    _buildQuickAction(
                      icon: Icons.admin_panel_settings,
                      label: 'Admin Panel',
                      onTap: () {
                        // Navigate to admin
                        Navigator.pushNamed(context, '/admin-support');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Floating AI Chat Button
          const FloatingChatbox(),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Demo page - AI Chat test sayfası
class ChatTestPage extends StatelessWidget {
  const ChatTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'AI Chat Sistemi Test Sayfası',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return Column(
                  children: [
                    Text('Aktif Session: ${chatProvider.hasActiveSession ? "Var" : "Yok"}'),
                    Text('Mesaj Sayısı: ${chatProvider.messages.length}'),
                    Text('Loading: ${chatProvider.isLoading}'),
                    Text('Typing: ${chatProvider.isTyping}'),
                    if (chatProvider.error != null)
                      Text('Hata: ${chatProvider.error}', style: const TextStyle(color: Colors.red)),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/admin-support');
              },
              child: const Text('Admin Support Panel'),
            ),
          ],
        ),
      ),
      floatingActionButton: const FloatingChatbox(),
    );
  }
}