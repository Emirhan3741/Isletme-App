import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class EmployeeInviteGenerator {
  static const String _baseUrl = 'https://randevuapp.com';

  /// Rastgele davet kodu üretir
  static String _generateCode() {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
        8, (index) => characters[random.nextInt(characters.length)]).join();
  }

  /// Çalışan davet linki üretir
  static String generateEmployeeInviteLink(
      String baseUrl, String employeeCode) {
    final Uri inviteUri =
        Uri.parse('$baseUrl/register').replace(queryParameters: {
      'role': 'employee',
      'code': employeeCode,
    });

    return inviteUri.toString();
  }

  /// Tam davet süreci: kod üret, Firebase'e kaydet, link oluştur
  static Future<String> createEmployeeInvite({
    String? customCode,
    String? businessId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final code = customCode ?? _generateCode();

      // Firebase'e davet kodunu kaydet
      await FirebaseFirestore.instance
          .collection('employee_invites')
          .doc(code)
          .set({
        'role': 'employee',
        'createdAt': Timestamp.now(),
        'used': false,
        'businessId': businessId,
        'metadata': metadata ?? {},
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)), // 7 gün geçerli
        ),
      });

      // Link üret
      final link = generateEmployeeInviteLink(_baseUrl, code);
      return link;
    } catch (e) {
      throw Exception('Davet linki oluşturulurken hata: $e');
    }
  }

  /// WhatsApp'ta link paylaş
  static Future<void> shareViaWhatsApp(String inviteLink,
      {String? message}) async {
    try {
      final defaultMessage = 'Merhaba! Çalışan kaydı için davet linkiniz:';
      final fullMessage =
          Uri.encodeComponent('${message ?? defaultMessage}\n\n$inviteLink');
      final whatsappUrl = 'https://wa.me/?text=$fullMessage';

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
      } else {
        throw Exception('WhatsApp açılamadı');
      }
    } catch (e) {
      throw Exception('WhatsApp paylaşımı başarısız: $e');
    }
  }

  /// Davet kodunun geçerliliğini kontrol et
  static Future<bool> verifyInviteCode(String code) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('employee_invites')
          .doc(code)
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final bool isUsed = data['used'] ?? true;
      final Timestamp? expiresAt = data['expiresAt'];

      // Kullanılmış mı?
      if (isUsed) return false;

      // Süresi dolmuş mu?
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Davet kodunu kullanıldı olarak işaretle
  static Future<void> markInviteAsUsed(String code) async {
    try {
      await FirebaseFirestore.instance
          .collection('employee_invites')
          .doc(code)
          .update({'used': true, 'usedAt': Timestamp.now()});
    } catch (e) {
      throw Exception('Davet kodu güncellenemedi: $e');
    }
  }
}
