import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  // E-posta şablonları
  static const String _welcomeEmailTemplate = '''
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hoş Geldiniz - Randevu ERP</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .email-container {
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            color: #1A73E8;
            border-bottom: 2px solid #1A73E8;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        .welcome-text {
            font-size: 18px;
            margin-bottom: 20px;
        }
        .features {
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 5px;
            margin: 20px 0;
        }
        .feature-item {
            margin: 10px 0;
            padding-left: 20px;
            position: relative;
        }
        .feature-item:before {
            content: "✓";
            position: absolute;
            left: 0;
            color: #28a745;
            font-weight: bold;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            color: #666;
            font-size: 14px;
        }
        .cta-button {
            display: inline-block;
            background-color: #1A73E8;
            color: white;
            padding: 12px 30px;
            text-decoration: none;
            border-radius: 5px;
            margin: 20px 0;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1>🎉 Hoş Geldiniz!</h1>
            <h2>Randevu ERP'ye Katıldığınız İçin Teşekkürler</h2>
        </div>
        
        <p class="welcome-text">
            Merhaba <strong>{{USER_NAME}}</strong>,
        </p>
        
        <p>
            Randevu ERP ailesine hoş geldiniz! Hesabınız başarıyla oluşturulmuştur ve artık 
            modern işletme yönetim sistemimizin tüm özelliklerinden faydalanabilirsiniz.
        </p>
        
        <div class="features">
            <h3>🚀 Neler Yapabilirsiniz:</h3>
            <div class="feature-item">Randevu yönetimi ve takvim entegrasyonu</div>
            <div class="feature-item">Müşteri takibi ve iletişim yönetimi</div>
            <div class="feature-item">Finansal raporlar ve gelir takibi</div>
            <div class="feature-item">Çalışan yönetimi ve rol bazlı erişim</div>
            <div class="feature-item">Otomatik bildirimler ve hatırlatmalar</div>
            <div class="feature-item">Çoklu dil ve para birimi desteği</div>
        </div>
        
        <p>
            <strong>Kayıt Bilgileriniz:</strong><br>
            📧 E-posta: {{USER_EMAIL}}<br>
            📅 Kayıt Tarihi: {{REGISTER_DATE}}<br>
            🔐 Giriş Yöntemi: {{AUTH_PROVIDER}}
        </p>
        
        <div style="text-align: center;">
            <a href="{{APP_URL}}" class="cta-button">
                Hemen Başlayın
            </a>
        </div>
        
        <p>
            Herhangi bir sorunuz varsa veya yardıma ihtiyacınız olursa, 
            lütfen bizimle iletişime geçmekten çekinmeyin.
        </p>
        
        <div class="footer">
            <p>
                <strong>Randevu ERP Ekibi</strong><br>
                Modern İşletme Yönetim Çözümleri<br>
                <em>Bu e-posta otomatik olarak gönderilmiştir.</em>
            </p>
        </div>
    </div>
</body>
</html>
''';

  // Hoş geldin e-postası gönder
  Future<bool> sendWelcomeEmail({
    required String userEmail,
    required String userName,
    required String authProvider,
    String? userId,
  }) async {
    try {
      // E-posta daha önce gönderilmiş mi kontrol et
      if (userId != null && await _isWelcomeEmailSent(userId)) {
        if (kDebugMode) {
          debugPrint('Hoş geldin e-postası zaten gönderilmiş: $userEmail');
        }
        return true;
      }

      // E-posta şablonunu özelleştir
      final emailContent = _welcomeEmailTemplate
          .replaceAll('{{USER_NAME}}', userName)
          .replaceAll('{{USER_EMAIL}}', userEmail)
          .replaceAll('{{REGISTER_DATE}}', _formatDate(DateTime.now()))
          .replaceAll(
              '{{AUTH_PROVIDER}}', _getProviderDisplayName(authProvider))
          .replaceAll('{{APP_URL}}',
              'https://randevu-erp.web.app'); // Uygulamanızın URL'si

      // E-posta gönderim kaydını Firestore'a ekle
      await _logEmailSent(
        userId: userId,
        userEmail: userEmail,
        emailType: 'welcome',
        subject: 'Hoş Geldiniz - Randevu ERP',
        content: emailContent,
      );

      // Gerçek e-posta gönderimi burada olacak
      // Bu demo için console'a yazdırıyoruz
      if (kDebugMode) {
        if (kDebugMode) debugPrint('=== HOŞ GELDİN E-POSTASI GÖNDERİLDİ ===');
        if (kDebugMode) debugPrint('Alıcı: $userEmail');
        if (kDebugMode) debugPrint('Konu: Hoş Geldiniz - Randevu ERP');
        if (kDebugMode)
          debugPrint('İçerik uzunluğu: ${emailContent.length} karakter');
        if (kDebugMode) debugPrint('========================================');
      }

      // Production'da burada gerçek e-posta servisi çağrılır
      // await _sendEmailViaService(userEmail, 'Hoş Geldiniz - Randevu ERP', emailContent);

      return true;
    } catch (e) {
      if (kDebugMode) if (kDebugMode)
        debugPrint('Hoş geldin e-postası gönderme hatası: $e');
      return false;
    }
  }

  // E-posta gönderim kaydını Firestore'a kaydet
  Future<void> _logEmailSent({
    String? userId,
    required String userEmail,
    required String emailType,
    required String subject,
    required String content,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('email_logs').add({
        'userId': userId,
        'userEmail': userEmail,
        'emailType': emailType,
        'subject': subject,
        'contentLength': content.length,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'sent',
        'provider': 'system',
      });

      // Kullanıcının e-posta geçmişini de güncelle
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'emails.${emailType}Sent': true,
          'emails.${emailType}SentAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) if (kDebugMode)
        debugPrint('E-posta log kaydetme hatası: $e');
    }
  }

  // Hoş geldin e-postası daha önce gönderilmiş mi kontrol et
  Future<bool> _isWelcomeEmailSent(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final emails = data?['emails'] as Map<String, dynamic>?;
        return emails?['welcomeSent'] == true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) if (kDebugMode)
        debugPrint('E-posta gönderim kontrolü hatası: $e');
      return false;
    }
  }

  // Auth provider görünen adını al
  String _getProviderDisplayName(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return 'Google ile Giriş';
      case 'email':
      case 'password':
        return 'E-posta ile Kayıt';
      case 'apple':
        return 'Apple ile Giriş';
      case 'facebook':
        return 'Facebook ile Giriş';
      default:
        return 'Sistem Kaydı';
    }
  }

  // Tarih formatlama
  String _formatDate(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Diğer e-posta türleri için genel metod
  Future<bool> sendCustomEmail({
    required String userEmail,
    required String subject,
    required String content,
    String? userId,
    String emailType = 'custom',
  }) async {
    try {
      // E-posta gönderim kaydını Firestore'a ekle
      await _logEmailSent(
        userId: userId,
        userEmail: userEmail,
        emailType: emailType,
        subject: subject,
        content: content,
      );

      if (kDebugMode) {
        if (kDebugMode) debugPrint('=== ÖZEL E-POSTA GÖNDERİLDİ ===');
        if (kDebugMode) debugPrint('Alıcı: $userEmail');
        if (kDebugMode) debugPrint('Konu: $subject');
        if (kDebugMode) debugPrint('Tip: $emailType');
        if (kDebugMode) debugPrint('===============================');
      }

      // Production'da gerçek e-posta servisi
      // await _sendEmailViaService(userEmail, subject, content);

      return true;
    } catch (e) {
      if (kDebugMode) if (kDebugMode)
        debugPrint('Özel e-posta gönderme hatası: $e');
      return false;
    }
  }

  // Kullanıcının e-posta geçmişini al
  Future<List<Map<String, dynamic>>> getUserEmailHistory(String userId) async {
    try {
      final emailLogs = await FirebaseFirestore.instance
          .collection('email_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('sentAt', descending: true)
          .limit(50)
          .get();

      return emailLogs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) if (kDebugMode)
        debugPrint('E-posta geçmişi alma hatası: $e');
      return [];
    }
  }

  // E-posta istatistikleri
  Future<Map<String, int>> getEmailStats() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisWeek = today.subtract(Duration(days: 7));
      final thisMonth = DateTime(now.year, now.month, 1);

      final stats = <String, int>{};

      // Bugün gönderilen e-postalar
      final todayEmails = await FirebaseFirestore.instance
          .collection('email_logs')
          .where('sentAt', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .get();
      stats['today'] = todayEmails.docs.length;

      // Bu hafta gönderilen e-postalar
      final weekEmails = await FirebaseFirestore.instance
          .collection('email_logs')
          .where('sentAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thisWeek))
          .get();
      stats['week'] = weekEmails.docs.length;

      // Bu ay gönderilen e-postalar
      final monthEmails = await FirebaseFirestore.instance
          .collection('email_logs')
          .where('sentAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thisMonth))
          .get();
      stats['month'] = monthEmails.docs.length;

      // Toplam e-postalar
      final totalEmails =
          await FirebaseFirestore.instance.collection('email_logs').get();
      stats['total'] = totalEmails.docs.length;

      return stats;
    } catch (e) {
      if (kDebugMode) if (kDebugMode)
        debugPrint('E-posta istatistikleri alma hatası: $e');
      return {};
    }
  }

  /* 
  // Production'da kullanılacak gerçek e-posta gönderim servisi
  // SMTP, SendGrid, AWS SES vb. servisler kullanılabilir
  
  Future<bool> _sendEmailViaService(String to, String subject, String content) async {
    try {
      // SMTP örneği (mailer paketi ile)
      /*
      import 'package:mailer/mailer.dart';
      import 'package:mailer/smtp_server.dart';
      
      final smtpServer = gmail('your-email@gmail.com', 'your-app-password');
      
      final message = Message()
        ..from = Address('your-email@gmail.com', 'Randevu ERP')
        ..recipients.add(to)
        ..subject = subject
        ..html = content;
      
      final sendReport = await send(message, smtpServer);
      if (kDebugMode) debugPrint('E-posta gönderildi: ${sendReport.toString()}');
      return true;
      */
      
      // SendGrid API örneği
      /*
      final response = await http.post(
        Uri.parse('https://api.sendgrid.com/v3/mail/send'),
        headers: {
          'Authorization': 'Bearer YOUR_SENDGRID_API_KEY',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'personalizations': [
            {
              'to': [{'email': to}],
              'subject': subject
            }
          ],
          'from': {'email': 'noreply@randevu-erp.com', 'name': 'Randevu ERP'},
          'content': [
            {
              'type': 'text/html',
              'value': content
            }
          ]
        }),
      );
      
      return response.statusCode == 202;
      */
      
      return true;
    } catch (e) {
      if (kDebugMode) if (kDebugMode) debugPrint('E-posta servisi hatası: $e');
      return false;
    }
  }
  */
}
