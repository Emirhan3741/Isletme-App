/// AI Chat sistemi için yerelleştirme sabitleri
class ChatLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'tr': {
      // Chat başlatma
      'chat_start_title': 'AI Asistan',
      'chat_start_description': 'Size daha iyi yardımcı olabilmek için aşağıdaki bilgileri paylaşın:',
      'email_label': 'E-posta adresiniz',
      'topic_label': 'Konu',
      'language_label': 'Dil',
      'start_button': 'Başlat',
      'cancel_button': 'İptal',
      
      // Validations
      'email_required': 'E-posta gerekli',
      'valid_email_required': 'Geçerli e-posta girin',
      
      // Chat UI
      'type_message': 'Mesajınızı yazın...',
      'ai_typing': 'AI yazıyor...',
      'chat_ended': 'Chat sonlandırıldı',
      'no_messages': 'Henüz mesaj yok. Yazışmaya başlayın!',
      
      // Topics
      'topic_appointment': 'Randevu',
      'topic_support': 'Teknik Destek',
      'topic_information': 'Bilgi Alma',
      'topic_suggestion': 'Öneri',
      'topic_complaint': 'Şikayet',
      'topic_general': 'Genel',
      
      // Languages
      'lang_turkish': 'Türkçe',
      'lang_english': 'English',
      'lang_german': 'Deutsch',
      'lang_spanish': 'Español',
      'lang_french': 'Français',
      
      // Chat roles
      'role_user': 'Kullanıcı',
      'role_ai': 'AI Asistan',
      'role_admin': 'Admin',
      'role_system': 'Sistem',
      
      // Chat status
      'status_active': 'Aktif',
      'status_ended': 'Sonlandırıldı',
      'status_archived': 'Arşivlendi',
      'status_blocked': 'Engellendi',
      
      // Errors
      'chat_start_error': 'Chat başlatılamadı',
      'message_send_error': 'Mesaj gönderilemedi',
      'connection_error': 'Bağlantı sorunu yaşanıyor',
      'retry_button': 'Tekrar Dene',
      
      // Admin panel
      'admin_title': 'AI Support Paneli',
      'statistics_title': 'İstatistikler',
      'filters_title': 'Filtreler',
      'today': 'Bugün',
      'total': 'Toplam',
      'active': 'Aktif',
      'messages': 'Mesajlar',
      'filter_button': 'Filtrele',
      'clear_button': 'Temizle',
      'all': 'Tümü',
      'view': 'Görüntüle',
      'archive': 'Arşivle',
      'block': 'Engelle',
      'delete': 'Sil',
      'block_reason_title': 'Session Engelleme',
      'block_reason_description': 'Bu session\'ı neden engelliyorsunuz?',
      'block_reason_label': 'Engelleme sebebi',
      'delete_confirm_title': 'Session Silme',
      'delete_confirm_description': 'kullanıcısının chat session\'ını kalıcı olarak silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.',
      'session_archived': 'Session arşivlendi',
      'session_blocked': 'Session engellendi',
      'session_deleted': 'Session silindi',
      'archive_error': 'Arşivleme hatası',
      'block_error': 'Engelleme hatası',
      'delete_error': 'Silme hatası',
      'no_sessions': 'Henüz chat session\'ı yok',
      'select_session': 'Chat session\'ı seçin',
      'session_duration': 'Süre',
      'hours_short': 's',
      'minutes_short': 'dk',
      'days_ago': 'gün önce',
      'hours_ago': 'saat önce',
      'minutes_ago': 'dakika önce',
      'just_now': 'Şimdi',
    },
    
    'en': {
      // Chat başlatma
      'chat_start_title': 'AI Assistant',
      'chat_start_description': 'Please share the following information to help you better:',
      'email_label': 'Your email address',
      'topic_label': 'Topic',
      'language_label': 'Language',
      'start_button': 'Start',
      'cancel_button': 'Cancel',
      
      // Validations
      'email_required': 'Email is required',
      'valid_email_required': 'Enter a valid email',
      
      // Chat UI
      'type_message': 'Type your message...',
      'ai_typing': 'AI is typing...',
      'chat_ended': 'Chat ended',
      'no_messages': 'No messages yet. Start the conversation!',
      
      // Topics
      'topic_appointment': 'Appointment',
      'topic_support': 'Technical Support',
      'topic_information': 'Information',
      'topic_suggestion': 'Suggestion',
      'topic_complaint': 'Complaint',
      'topic_general': 'General',
      
      // Languages
      'lang_turkish': 'Türkçe',
      'lang_english': 'English',
      'lang_german': 'Deutsch',
      'lang_spanish': 'Español',
      'lang_french': 'Français',
      
      // Chat roles
      'role_user': 'User',
      'role_ai': 'AI Assistant',
      'role_admin': 'Admin',
      'role_system': 'System',
      
      // Chat status
      'status_active': 'Active',
      'status_ended': 'Ended',
      'status_archived': 'Archived',
      'status_blocked': 'Blocked',
      
      // Errors
      'chat_start_error': 'Could not start chat',
      'message_send_error': 'Could not send message',
      'connection_error': 'Connection problem',
      'retry_button': 'Try Again',
      
      // Admin panel
      'admin_title': 'AI Support Panel',
      'statistics_title': 'Statistics',
      'filters_title': 'Filters',
      'today': 'Today',
      'total': 'Total',
      'active': 'Active',
      'messages': 'Messages',
      'filter_button': 'Filter',
      'clear_button': 'Clear',
      'all': 'All',
      'view': 'View',
      'archive': 'Archive',
      'block': 'Block',
      'delete': 'Delete',
      'block_reason_title': 'Block Session',
      'block_reason_description': 'Why are you blocking this session?',
      'block_reason_label': 'Block reason',
      'delete_confirm_title': 'Delete Session',
      'delete_confirm_description': 'Are you sure you want to permanently delete the chat session?\n\nThis action cannot be undone.',
      'session_archived': 'Session archived',
      'session_blocked': 'Session blocked',
      'session_deleted': 'Session deleted',
      'archive_error': 'Archive error',
      'block_error': 'Block error',
      'delete_error': 'Delete error',
      'no_sessions': 'No chat sessions yet',
      'select_session': 'Select a chat session',
      'session_duration': 'Duration',
      'hours_short': 'h',
      'minutes_short': 'm',
      'days_ago': 'days ago',
      'hours_ago': 'hours ago',
      'minutes_ago': 'minutes ago',
      'just_now': 'Just now',
    }
  };

  /// Mevcut dil için yerelleştirilmiş string al
  static String getString(String key, String languageCode) {
    return _localizedValues[languageCode]?[key] ?? 
           _localizedValues['tr']?[key] ?? 
           key;
  }

  /// Desteklenen dillerin listesi
  static List<String> get supportedLanguages => _localizedValues.keys.toList();

  /// Dil kodu geçerli mi?
  static bool isLanguageSupported(String languageCode) {
    return _localizedValues.containsKey(languageCode);
  }

  /// Topic display name al
  static String getTopicDisplayName(String topic, String languageCode) {
    return getString('topic_$topic', languageCode);
  }

  /// Language display name al
  static String getLanguageDisplayName(String langCode, String currentLanguage) {
    return getString('lang_${langCode.toLowerCase()}', currentLanguage);
  }

  /// Role display name al
  static String getRoleDisplayName(String role, String languageCode) {
    return getString('role_$role', languageCode);
  }

  /// Status display name al
  static String getStatusDisplayName(String status, String languageCode) {
    return getString('status_$status', languageCode);
  }
}