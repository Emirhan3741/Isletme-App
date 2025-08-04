import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/chat_models.dart';
import '../../services/chat_service.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/ai_chatbox_widget.dart';

/// Admin support paneli - Tüm chat session'larını yönetir
class AdminSupportPage extends StatefulWidget {
  const AdminSupportPage({Key? key}) : super(key: key);

  @override
  State<AdminSupportPage> createState() => _AdminSupportPageState();
}

class _AdminSupportPageState extends State<AdminSupportPage> {
  final ChatService _chatService = ChatService();
  
  List<ChatSession> _sessions = [];
  List<ChatMessage> _selectedSessionMessages = [];
  ChatSession? _selectedSession;
  
  bool _isLoading = false;
  bool _isLoadingMessages = false;
  String? _error;
  
  // Filters
  String? _filterEmail;
  String? _filterTopic;
  String? _filterLanguage;
  DateTimeRange? _filterDateRange;
  ChatStatus? _filterStatus;
  
  final _emailFilterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _loadStatistics();
  }

  @override
  void dispose() {
    _emailFilterController.dispose();
    super.dispose();
  }

  /// Session'ları yükle
  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sessions = await _chatService.getAdminChatSessions(
        userEmail: _filterEmail,
        topic: _filterTopic,
        language: _filterLanguage,
        startDate: _filterDateRange?.start,
        endDate: _filterDateRange?.end,
        status: _filterStatus,
        limit: 200,
      );

      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });

      debugPrint('✅ Admin: ${sessions.length} session yüklendi');

    } catch (e) {
      debugPrint('❌ Admin: Session yükleme hatası: $e');
      setState(() {
        _error = 'Session\'lar yüklenemedi: $e';
        _isLoading = false;
      });
    }
  }

  /// İstatistikleri yükle
  Map<String, dynamic> _statistics = {};
  Future<void> _loadStatistics() async {
    try {
      final stats = await _chatService.getChatStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      debugPrint('❌ Admin: İstatistik yükleme hatası: $e');
    }
  }

  /// Session mesajlarını yükle
  Future<void> _loadSessionMessages(ChatSession session) async {
    setState(() {
      _isLoadingMessages = true;
      _selectedSession = session;
      _selectedSessionMessages = [];
    });

    try {
      final messages = await _chatService.getSessionMessages(session.id);
      
      setState(() {
        _selectedSessionMessages = messages;
        _isLoadingMessages = false;
      });

      debugPrint('✅ Admin: ${messages.length} mesaj yüklendi');

    } catch (e) {
      debugPrint('❌ Admin: Mesaj yükleme hatası: $e');
      setState(() {
        _error = 'Mesajlar yüklenemedi: $e';
        _isLoadingMessages = false;
      });
    }
  }

  /// Filtreleri uygula
  void _applyFilters() {
    _filterEmail = _emailFilterController.text.trim().isEmpty 
        ? null 
        : _emailFilterController.text.trim();
    _loadSessions();
  }

  /// Filtreleri temizle
  void _clearFilters() {
    setState(() {
      _filterEmail = null;
      _filterTopic = null;
      _filterLanguage = null;
      _filterDateRange = null;
      _filterStatus = null;
    });
    _emailFilterController.clear();
    _loadSessions();
  }

  /// Session'ı arşivle
  Future<void> _archiveSession(ChatSession session) async {
    try {
      await _chatService.archiveChatSession(session.id);
      _loadSessions();
      _showSnackBar('Session arşivlendi', isError: false);
    } catch (e) {
      _showSnackBar('Arşivleme hatası: $e', isError: true);
    }
  }

  /// Session'ı engelle
  Future<void> _blockSession(ChatSession session) async {
    final reason = await _showBlockReasonDialog();
    if (reason != null) {
      try {
        await _chatService.blockChatSession(session.id, reason);
        _loadSessions();
        _showSnackBar('Session engellendi', isError: false);
      } catch (e) {
        _showSnackBar('Engelleme hatası: $e', isError: true);
      }
    }
  }

  /// Session'ı sil
  Future<void> _deleteSession(ChatSession session) async {
    final confirmed = await _showDeleteConfirmDialog(session);
    if (confirmed == true) {
      try {
        await _chatService.deleteChatSession(session.id);
        _loadSessions();
        if (_selectedSession?.id == session.id) {
          setState(() {
            _selectedSession = null;
            _selectedSessionMessages = [];
          });
        }
        _showSnackBar('Session silindi', isError: false);
      } catch (e) {
        _showSnackBar('Silme hatası: $e', isError: true);
      }
    }
  }

  /// Block reason dialog
  Future<String?> _showBlockReasonDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Engelleme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bu session\'ı neden engelliyorsunuz?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Engelleme sebebi',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isNotEmpty) {
                Navigator.pop(context, reason);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Engelle'),
          ),
        ],
      ),
    );
  }

  /// Delete confirmation dialog
  Future<bool?> _showDeleteConfirmDialog(ChatSession session) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Silme'),
        content: Text(
          '${session.userEmail} kullanıcısının chat session\'ını kalıcı olarak silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.',
        ),
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
  }

  /// SnackBar göster
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Support Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadSessions();
              _loadStatistics();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Sol panel - Session listesi ve filtreler
          Expanded(
            flex: 1,
            child: _buildLeftPanel(),
          ),
          
          // Sağ panel - Seçili session detayı
          Expanded(
            flex: 2,
            child: _buildRightPanel(),
          ),
        ],
      ),
    );
  }

  /// Sol panel - Session listesi
  Widget _buildLeftPanel() {
    return Column(
      children: [
        // İstatistikler
        _buildStatisticsCard(),
        
        // Filtreler
        _buildFiltersCard(),
        
        // Session listesi
        Expanded(child: _buildSessionsList()),
      ],
    );
  }

  /// İstatistikler kartı
  Widget _buildStatisticsCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İstatistikler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem('Bugün', _statistics['todaySessions']?.toString() ?? '0'),
                const SizedBox(width: 16),
                _buildStatItem('Toplam', _statistics['totalSessions']?.toString() ?? '0'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatItem('Aktif', _statistics['activeSessions']?.toString() ?? '0'),
                const SizedBox(width: 16),
                _buildStatItem('Mesajlar', _statistics['totalMessages']?.toString() ?? '0'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  /// Filtreler kartı
  Widget _buildFiltersCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtreler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // E-posta filtresi
            TextField(
              controller: _emailFilterController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            
            // Konu filtresi
            DropdownButtonFormField<String>(
              value: _filterTopic,
              decoration: const InputDecoration(
                labelText: 'Konu',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Tümü'),
                ),
                ...ChatTopic.allTopics.map((topic) => DropdownMenuItem(
                  value: topic,
                  child: Text(ChatTopic.getDisplayName(topic)),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _filterTopic = value;
                });
              },
            ),
            const SizedBox(height: 8),
            
            // Dil filtresi
            DropdownButtonFormField<String>(
              value: _filterLanguage,
              decoration: const InputDecoration(
                labelText: 'Dil',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Tümü'),
                ),
                ...ChatLanguage.supportedLanguages.map((lang) => DropdownMenuItem(
                  value: lang,
                  child: Row(
                    children: [
                      Text(ChatLanguage.getFlag(lang)),
                      const SizedBox(width: 8),
                      Text(ChatLanguage.getDisplayName(lang)),
                    ],
                  ),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _filterLanguage = value;
                });
              },
            ),
            const SizedBox(height: 8),
            
            // Status filtresi
            DropdownButtonFormField<ChatStatus>(
              value: _filterStatus,
              decoration: const InputDecoration(
                labelText: 'Durum',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<ChatStatus>(
                  value: null,
                  child: Text('Tümü'),
                ),
                ...ChatStatus.values.map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status.displayName),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _filterStatus = value;
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Filter butonları
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Filtrele'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    child: const Text('Temizle'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Session'lar listesi
  Widget _buildSessionsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSessions,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_sessions.isEmpty) {
      return const Center(
        child: Text('Henüz chat session\'ı yok'),
      );
    }

    return ListView.builder(
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final isSelected = _selectedSession?.id == session.id;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: isSelected ? AppConstants.primaryColor.withOpacity(0.1) : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(session.status),
              child: Text(
                session.userEmail.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            title: Text(
              session.userEmail,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${ChatTopic.getDisplayName(session.topic)} • ${ChatLanguage.getDisplayName(session.language)}'),
                Text(
                  '${session.messageCount} mesaj • ${_formatDate(session.startTime)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'view':
                    _loadSessionMessages(session);
                    break;
                  case 'archive':
                    _archiveSession(session);
                    break;
                  case 'block':
                    _blockSession(session);
                    break;
                  case 'delete':
                    _deleteSession(session);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('Görüntüle'),
                    ],
                  ),
                ),
                if (session.status == ChatStatus.active)
                  const PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(Icons.archive),
                        SizedBox(width: 8),
                        Text('Arşivle'),
                      ],
                    ),
                  ),
                if (session.status != ChatStatus.blocked)
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Engelle'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sil'),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _loadSessionMessages(session),
          ),
        );
      },
    );
  }

  /// Sağ panel - Session detayı
  Widget _buildRightPanel() {
    if (_selectedSession == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chat session\'ı seçin',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Session bilgileri
        _buildSessionInfo(),
        
        // Mesajlar
        Expanded(child: _buildMessagesList()),
      ],
    );
  }

  /// Session bilgileri
  Widget _buildSessionInfo() {
    final session = _selectedSession!;
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.userEmail,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(session.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    session.status.displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.topic, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(ChatTopic.getDisplayName(session.topic)),
                const SizedBox(width: 16),
                Text(ChatLanguage.getFlag(session.language)),
                const SizedBox(width: 4),
                Text(ChatLanguage.getDisplayName(session.language)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${_formatDate(session.startTime)} • ${session.messageCount} mesaj'),
                const Spacer(),
                Text(
                  'Süre: ${_formatDuration(session.duration)}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Mesajlar listesi
  Widget _buildMessagesList() {
    if (_isLoadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedSessionMessages.isEmpty) {
      return const Center(child: Text('Henüz mesaj yok'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedSessionMessages.length,
      itemBuilder: (context, index) {
        final message = _selectedSessionMessages[index];
        return ChatMessageBubble(
          message: message,
          isUser: message.role == ChatRole.user,
        );
      },
    );
  }

  /// Status rengi
  Color _getStatusColor(ChatStatus status) {
    switch (status) {
      case ChatStatus.active:
        return Colors.green;
      case ChatStatus.ended:
        return Colors.blue;
      case ChatStatus.archived:
        return Colors.orange;
      case ChatStatus.blocked:
        return Colors.red;
    }
  }

  /// Tarih formatla
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) {
      return '${diff.inDays} gün önce';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} saat önce';
    } else {
      return '${diff.inMinutes} dakika önce';
    }
  }

  /// Süre formatla
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}s ${duration.inMinutes % 60}dk';
    } else {
      return '${duration.inMinutes}dk';
    }
  }
}