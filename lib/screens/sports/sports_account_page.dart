import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/feedback_utils.dart';
import '../../utils/validation_utils.dart';
import '../auth_wrapper.dart';

class SportsAccountPage extends StatefulWidget {
  const SportsAccountPage({super.key});

  @override
  State<SportsAccountPage> createState() => _SportsAccountPageState();
}

class _SportsAccountPageState extends State<SportsAccountPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _soyadController = TextEditingController();
  final TextEditingController _telefonController = TextEditingController();
  final TextEditingController _uzmanlikController = TextEditingController();
  final TextEditingController _biographyController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // State
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isChangingPassword = false;
  Map<String, dynamic>? _userProfile;
  String? _selectedUzmanlik;

  final List<String> _uzmanlikAlanlari = [
    'Pilates Eğitmeni',
    'Yoga Eğitmeni',
    'CrossFit Antrenörü',
    'Bireysel Antrenör (PT)',
    'Fitness Antrenörü',
    'Kardiyo Uzmanı',
    'Güç Antrenmanı Uzmanı',
    'Rehabilitasyon Uzmanı',
    'Spor Psikologu',
    'Beslenme Uzmanı',
    'Genel Antrenör',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _telefonController.dispose();
    _uzmanlikController.dispose();
    _biographyController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 👤 Kullanıcı profilini yükle
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('❌ Kullanıcı oturumu bulunamadı');
      }

      // Firestore'dan profil bilgilerini çek
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        _userProfile = doc.data();

        // Form kontrollerini doldur
        _adController.text = _userProfile?['ad'] ?? '';
        _soyadController.text = _userProfile?['soyad'] ?? '';
        _telefonController.text = _userProfile?['telefon'] ?? '';
        _uzmanlikController.text = _userProfile?['uzmanlik'] ?? '';
        _biographyController.text = _userProfile?['biography'] ?? '';
        _selectedUzmanlik = _userProfile?['uzmanlik'];
      } else {
        // Yeni kullanıcı için varsayılan profil oluştur
        _userProfile = {
          'email': user.email,
          'ad': '',
          'soyad': '',
          'telefon': '',
          'uzmanlik': '',
          'biography': '',
          'createdAt': Timestamp.now(),
        };
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Profil yükleme hatası: $e');
      if (mounted) {
        FeedbackUtils.showError(context, 'Profil yüklenirken hata oluştu');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 💾 Profil güncelle
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('❌ Kullanıcı oturumu bulunamadı');
      }

      final updatedProfile = {
        'ad': _adController.text.trim(),
        'soyad': _soyadController.text.trim(),
        'telefon': _telefonController.text.trim(),
        'uzmanlik': _selectedUzmanlik ?? '',
        'biography': _biographyController.text.trim(),
        'updatedAt': Timestamp.now(),
      };

      // Firestore'da profili güncelle
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updatedProfile);

      // Firebase Auth display name güncelle
      if (_adController.text.trim().isNotEmpty ||
          _soyadController.text.trim().isNotEmpty) {
        final displayName =
            '${_adController.text.trim()} ${_soyadController.text.trim()}'
                .trim();
        await user.updateDisplayName(displayName);
      }

      _userProfile = {..._userProfile!, ...updatedProfile};

      if (mounted) {
        setState(() => _isEditing = false);
        FeedbackUtils.showSuccess(context, 'Profil başarıyla güncellendi');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Profil güncelleme hatası: $e');
      if (mounted) {
        FeedbackUtils.showError(context, 'Profil güncellenirken hata oluştu');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🔒 Şifre değiştir
  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      FeedbackUtils.showError(context, 'Tüm şifre alanlarını doldurun');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      FeedbackUtils.showError(context, 'Yeni şifreler eşleşmiyor');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      FeedbackUtils.showError(context, 'Yeni şifre en az 6 karakter olmalı');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('❌ Kullanıcı oturumu bulunamadı');
      }

      // Mevcut şifreyi doğrula
      final credential = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // Yeni şifreyi ayarla
      await user.updatePassword(_newPasswordController.text);

      if (mounted) {
        setState(() {
          _isChangingPassword = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
        FeedbackUtils.showSuccess(context, 'Şifre başarıyla değiştirildi');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Şifre değiştirme hatası: $e');
      if (mounted) {
        String errorMessage = 'Şifre değiştirilirken hata oluştu';
        if (e.toString().contains('wrong-password')) {
          errorMessage = 'Mevcut şifre yanlış';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'Yeni şifre çok zayıf';
        }
        FeedbackUtils.showError(context, errorMessage);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🚪 Çıkış yap
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Çıkış hatası: $e');
      if (mounted) {
        FeedbackUtils.showError(context, 'Çıkış yapılırken hata oluştu');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Hesabım'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing && !_isChangingPassword)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child:
                  const Text('Düzenle', style: TextStyle(color: Colors.white)),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: Text(
                _isLoading ? 'Kaydediliyor...' : 'Kaydet',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading && _userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 👤 Profil kartı
                    _buildProfileCard(),
                    const SizedBox(height: 24),

                    // 📝 Kişisel bilgiler
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 24),

                    // 🔒 Güvenlik ayarları
                    _buildSecuritySection(),
                    const SizedBox(height: 24),

                    // ⚙️ Hesap işlemleri
                    _buildAccountActionsSection(),
                    const SizedBox(
                        height: 100), // Floating action button için boşluk
                  ],
                ),
              ),
            ),
    );
  }

  // 👤 Profil kartı
  Widget _buildProfileCard() {
    final user = FirebaseAuth.instance.currentUser;
    final joinDate = _userProfile?['createdAt'] as Timestamp?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.orange[100],
            child: Icon(
              Icons.person,
              size: 40,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 16),

          // İsim
          Text(
            '${_userProfile?['ad'] ?? ''} ${_userProfile?['soyad'] ?? ''}'
                    .trim()
                    .isEmpty
                ? 'İsim Soyisim'
                : '${_userProfile!['ad'] ?? ''} ${_userProfile!['soyad'] ?? ''}'
                    .trim(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Uzmanlık
          Text(
            _userProfile?['uzmanlik'] ?? 'Spor Uzmanı',
            style: TextStyle(
              color: Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Email
          Text(
            user?.email ?? '',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),

          if (joinDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Üyelik: ${DateFormat('dd MMMM yyyy', 'tr_TR').format(joinDate.toDate())}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 📝 Kişisel bilgiler bölümü
  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text(
                'Kişisel Bilgiler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Ad
          TextFormField(
            controller: _adController,
            enabled: _isEditing,
            decoration: InputDecoration(
              labelText: 'Ad',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
            validator: _isEditing ? ValidationUtils.validateRequired : null,
          ),
          const SizedBox(height: 16),

          // Soyad
          TextFormField(
            controller: _soyadController,
            enabled: _isEditing,
            decoration: InputDecoration(
              labelText: 'Soyad',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.person_outline),
            ),
            validator: _isEditing ? ValidationUtils.validateRequired : null,
          ),
          const SizedBox(height: 16),

          // Telefon
          TextFormField(
            controller: _telefonController,
            enabled: _isEditing,
            decoration: InputDecoration(
              labelText: 'Telefon',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: _isEditing ? ValidationUtils.validatePhone : null,
          ),
          const SizedBox(height: 16),

          // Uzmanlık alanı
          DropdownButtonFormField<String>(
            value: _selectedUzmanlik,
            decoration: InputDecoration(
              labelText: 'Uzmanlık Alanı',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.fitness_center),
            ),
            items: _uzmanlikAlanlari.map((uzmanlik) {
              return DropdownMenuItem(value: uzmanlik, child: Text(uzmanlik));
            }).toList(),
            onChanged: _isEditing
                ? (value) => setState(() => _selectedUzmanlik = value)
                : null,
          ),
          const SizedBox(height: 16),

          // Biyografi
          TextFormField(
            controller: _biographyController,
            enabled: _isEditing,
            decoration: InputDecoration(
              labelText: 'Hakkımda',
              hintText: 'Kendinizi tanıtın, deneyimlerinizi paylaşın...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.description),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
          ),

          if (_isEditing) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _loadUserProfile(); // Değişiklikleri geri al
                      });
                    },
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Kaydet',
                            style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 🔒 Güvenlik bölümü
  Widget _buildSecuritySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text(
                'Güvenlik',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!_isChangingPassword) ...[
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Şifre Değiştir'),
              subtitle: const Text('Hesabınızın güvenliğini artırın'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _isChangingPassword = true),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('E-posta Adresi'),
              subtitle: Text(FirebaseAuth.instance.currentUser?.email ?? ''),
              trailing: Icon(Icons.verified, color: Colors.green[600]),
            ),
          ] else ...[
            // Şifre değiştirme formu
            TextFormField(
              controller: _currentPasswordController,
              decoration: InputDecoration(
                labelText: 'Mevcut Şifre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre Tekrar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isChangingPassword = false;
                        _currentPasswordController.clear();
                        _newPasswordController.clear();
                        _confirmPasswordController.clear();
                      });
                    },
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Şifreyi Değiştir',
                            style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ⚙️ Hesap işlemleri bölümü
  Widget _buildAccountActionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text(
                'Hesap İşlemleri',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Yardım ve Destek'),
            subtitle: const Text('SSS, iletişim ve destek'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Yardım sayfasına yönlendir
              FeedbackUtils.showInfo(
                  context, 'Yardım sayfası yakında eklenecek');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Gizlilik Politikası'),
            subtitle: const Text('Verilerinizin nasıl kullanıldığını öğrenin'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Gizlilik politikası sayfasına yönlendir
              FeedbackUtils.showInfo(
                  context, 'Gizlilik politikası yakında eklenecek');
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red[600]),
            title: Text('Çıkış Yap', style: TextStyle(color: Colors.red[600])),
            subtitle: const Text('Hesabınızdan güvenli çıkış yapın'),
            onTap: () => _showSignOutConfirmation(),
          ),
        ],
      ),
    );
  }

  // 🚪 Çıkış onayı
  void _showSignOutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text(
            'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
