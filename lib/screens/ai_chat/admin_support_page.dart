import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/ai_chat_models.dart';
import '../../services/ai_chat_firestore_service.dart';

/// 👨‍💼 Admin Chat Destek Paneli
/// Tüm chat session'larını görüntüler ve filtreler
class AdminSupportPage extends StatefulWidget {
  const AdminSupportPage({super.key});

  @override
  State<AdminSupportPage> createState() => _AdminSupportPageState();
}

class _AdminSupportPageState extends State<AdminSupportPage> 
    with TickerProviderStateMixin {
  
  // Servisler
  late final AIChatFirestoreService _firestoreService;
  
  // State
  List<ChatSession> _sessions = [];
  ChatSession? _selectedSession;
  List<ChatMessage> _selectedSessionMessages = [];
  
  // Filtreler
  String _filterEmail = '';
  String _filterTopic = '';
  String _filterLanguage = '';
  String _filterStatus = '';
  
  // Controllers
  final _emailFilterController = TextEditingController();
  late TabController _tabController;
  
  // Loading states
  bool _isLoadingSessions = false;
  bool _isLoadingMessages = false;
  
  // Stats
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _firestoreService = AIChatFirestoreService();
    _tabController = TabController(length: 2, vsync: this);
    _loadSessions();
    _loadStats();
  }

  @override
  void dispose() {
    _emailFilterController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// 📋 Session'ları yükle
  void _loadSessions() {
    setState(() {
      _isLoadingSessions = true;
    });

    _firestoreService.getAllSessionsStream(
      filterEmail: _filterEmail.isNotEmpty ? _filterEmail : null,
      filterTopic: _filterTopic.isNotEmpty ? _filterTopic : null,
      filterLanguage: _filterLanguage.isNotEmpty ? _filterLanguage : null,
      filterStatus: _filterStatus.isNotEmpty ? _filterStatus : null,
    ).listen(
      (sessions) {
        setState(() {
          _sessions = sessions;
          _isLoadingSessions = false;
        });
      },
      onError: (e) {
        setState(() {
          _isLoadingSessions = false;
        });
        _showErrorSnackBar('Session\'lar yüklenemedi: $e');
      },
    );
  }

  /// 📊 İstatistikleri yükle
  void _loadStats() async {
    try {
      final stats = await _firestoreService.getSessionStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      debugPrint('❌ İstatistik yükleme hatası: $e');
    }
  }

  /// 🔍 Session seç ve mesajlarını yükle
  void _selectSession(ChatSession session) {
    setState(() {
      _selectedSession = session;
      _isLoadingMessages = true;
    });

    _firestoreService.getChatMessagesStream(session.id).listen(
      (messages) {
        setState(() {
          _selectedSessionMessages = messages;
          _isLoadingMessages = false;
        });
      },
      onError: (e) {
        setState(() {
          _isLoadingMessages = false;
        });
        _showErrorSnackBar('Mesajlar yüklenemedi: $e');
      },
    );
  }

  /// 🔄 Filtreleri uygula
  void _applyFilters() {
    _loadSessions();
  }

  /// 🧹 Filtreleri temizle
  void _clearFilters() {
    setState(() {
      _filterEmail = '';
      _filterTopic = '';
      _filterLanguage = '';
      _filterStatus = '';
      _emailFilterController.clear();
    });
    _loadSessions();
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

  /// ✅ Başarı mesajı göster
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSessionsTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  /// 📱 App Bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('🎧 Admin Chat Destek'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(icon: Icon(Icons.chat), text: 'Konuşmalar'),
          Tab(icon: Icon(Icons.analytics), text: 'İstatistikler'),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            _loadSessions();
            _loadStats();
          },
          icon: const Icon(Icons.refresh),
          tooltip: 'Yenile',
        ),
      ],
    );
  }

  /// 💬 Session'lar tab
  Widget _buildSessionsTab() {
    return Row(
      children: [
        // Sol panel - Session listesi
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                _buildFiltersSection(),
                Expanded(
                  child: _buildSessionsList(),
                ),
              ],
            ),
          ),
        ),
        
        // Sağ panel - Mesaj detayları
        Expanded(
          flex: 2,
          child: _buildMessageDetails(),
        ),
      ],
    );
  }

  /// 🔍 Filtreler bölümü
  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Filtreler',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Temizle'),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Email filtresi
          TextField(
            controller: _emailFilterController,
            decoration: const InputDecoration(
              hintText: 'E-posta ile filtrele',
              prefixIcon: Icon(Icons.email, size: 20),
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _filterEmail = value;
            },
          ),
          
          const SizedBox(height: 8),
          
          // Konu filtresi
          DropdownButtonFormField<String>(
            value: _filterTopic.isEmpty ? null : _filterTopic,
            hint: const Text('Konu'),
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.topic, size: 20),
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: ChatTopic.values.map((topic) {
              return DropdownMenuItem(
                value: topic.value,
                child: Text(topic.displayName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _filterTopic = value ?? '';
              });
            },
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              // Dil filtresi
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterLanguage.isEmpty ? null : _filterLanguage,
                  hint: const Text('Dil'),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.language, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: ChatLanguage.values.map((lang) {
                    return DropdownMenuItem(
                      value: lang.code,
                      child: Text('${lang.flag} ${lang.displayName}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterLanguage = value ?? '';
                    });
                  },
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Durum filtresi
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterStatus.isEmpty ? null : _filterStatus,
                  hint: const Text('Durum'),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.status_change, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Aktif')),
                    DropdownMenuItem(value: 'ended', child: Text('Bitti')),
                    DropdownMenuItem(value: 'archived', child: Text('Arşiv')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value ?? '';
                    });
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Filtrele'),
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Session'lar listesi
  Widget _buildSessionsList() {
    if (_isLoadingSessions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Henüz konuşma yok'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final isSelected = _selectedSession?.id == session.id;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: _getStatusColor(session.status),
              child: Text(
                session.userEmail.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              session.userEmail,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ChatLanguage.fromCode(session.language).flag} ${ChatTopic.fromString(session.topic).displayName}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  DateFormat('dd/MM HH:mm').format(session.startedAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(session.status),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getStatusText(session.status),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.messageCount} msg',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
            onTap: () => _selectSession(session),
          ),
        );
      },
    );
  }

  /// 💬 Mesaj detayları
  Widget _buildMessageDetails() {
    if (_selectedSession == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.select_all, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Bir konuşma seçin'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Session bilgileri
        _buildSessionHeader(),
        
        // Mesajlar
        Expanded(
          child: _buildMessagesView(),
        ),
        
        // Aksiyon butonları
        _buildActionButtons(),
      ],
    );
  }

  /// 📄 Session header
  Widget _buildSessionHeader() {
    if (_selectedSession == null) return const SizedBox.shrink();

    final session = _selectedSession!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.userEmail,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ChatLanguage.fromCode(session.language).flag} ${ChatTopic.fromString(session.topic).displayName}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Başlatılma: ${DateFormat('dd/MM/yyyy HH:mm').format(session.startedAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (session.endedAt != null)
                  Text(
                    'Bitirilme: ${DateFormat('dd/MM/yyyy HH:mm').format(session.endedAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(session.status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusText(session.status),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// 📜 Mesajlar görünümü
  Widget _buildMessagesView() {
    if (_isLoadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedSessionMessages.isEmpty) {
      return const Center(
        child: Text('Bu konuşmada henüz mesaj yok'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedSessionMessages.length,
      itemBuilder: (context, index) {
        final message = _selectedSessionMessages[index];
        return _buildAdminMessageBubble(message);
      },
    );
  }

  /// 💭 Admin mesaj baloncuğu
  Widget _buildAdminMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser 
                    ? Colors.blue[100]
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
                    isUser ? 'Kullanıcı' : 'AI Yardımcı',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isUser ? Colors.blue[700] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.content,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue[300],
                shape: BoxShape.circle,
              ),
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
  }

  /// ⚡ Aksiyon butonları
  Widget _buildActionButtons() {
    if (_selectedSession == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _archiveSession(_selectedSession!),
              icon: const Icon(Icons.archive),
              label: const Text('Arşivle'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _endSession(_selectedSession!),
              icon: const Icon(Icons.stop),
              label: const Text('Sonlandır'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _deleteSession(_selectedSession!),
              icon: const Icon(Icons.delete),
              label: const Text('Sil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 İstatistikler tab
  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Genel İstatistikler',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Genel sayılar
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Toplam Konuşma',
                  '${_stats['totalSessions'] ?? 0}',
                  Icons.chat,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Aktif Konuşma',
                  '${_stats['activeSessions'] ?? 0}',
                  Icons.chat_bubble,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Dil dağılımı
          if (_stats['languageStats'] != null) ...[
            Text(
              'Dil Dağılımı',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ..._buildLanguageStats(),
          ],
          
          const SizedBox(height: 24),
          
          // Konu dağılımı
          if (_stats['topicStats'] != null) ...[
            Text(
              'Konu Dağılımı',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ..._buildTopicStats(),
          ],
        ],
      ),
    );
  }

  /// 📈 İstatistik kartı
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 🌍 Dil istatistikleri
  List<Widget> _buildLanguageStats() {
    final languageStats = _stats['languageStats'] as Map<String, dynamic>? ?? {};
    
    return languageStats.entries.map((entry) {
      final lang = ChatLanguage.fromCode(entry.key);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(lang.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(lang.displayName),
            const Spacer(),
            Text(
              '${entry.value}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// 🎯 Konu istatistikleri
  List<Widget> _buildTopicStats() {
    final topicStats = _stats['topicStats'] as Map<String, dynamic>? ?? {};
    
    return topicStats.entries.map((entry) {
      final topic = ChatTopic.fromString(entry.key);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(Icons.topic, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(topic.displayName),
            const Spacer(),
            Text(
              '${entry.value}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// 🗃️ Session arşivle
  Future<void> _archiveSession(ChatSession session) async {
    try {
      await _firestoreService.archiveChatSession(session.id);
      _showSuccessSnackBar('Konuşma arşivlendi');
      setState(() {
        _selectedSession = null;
      });
    } catch (e) {
      _showErrorSnackBar('Arşivleme başarısız: $e');
    }
  }

  /// ⏹️ Session sonlandır
  Future<void> _endSession(ChatSession session) async {
    try {
      await _firestoreService.endChatSession(session.id);
      _showSuccessSnackBar('Konuşma sonlandırıldı');
    } catch (e) {
      _showErrorSnackBar('Sonlandırma başarısız: $e');
    }
  }

  /// 🗑️ Session sil
  Future<void> _deleteSession(ChatSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konuşmayı Sil'),
        content: Text('${session.userEmail} kullanıcısının konuşmasını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteChatSession(session.id);
        _showSuccessSnackBar('Konuşma silindi');
        setState(() {
          _selectedSession = null;
        });
      } catch (e) {
        _showErrorSnackBar('Silme başarısız: $e');
      }
    }
  }

  /// 🎨 Durum rengini getir
  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'ended':
        return Colors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  /// 📝 Durum metnini getir
  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'ended':
        return 'Bitti';
      case 'archived':
        return 'Arşiv';
      default:
        return status;
    }
  }
}