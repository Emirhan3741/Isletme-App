import 'package:flutter/material.dart';
import '../../utils/firebase_debug_utils.dart';

// 🔍 Firebase Debug Sayfası
// Geliştirme sırasında Firebase bağlantı sorunlarını test etme arayüzü
class FirebaseDebugPage extends StatefulWidget {
  const FirebaseDebugPage({super.key});

  @override
  State<FirebaseDebugPage> createState() => _FirebaseDebugPageState();
}

class _FirebaseDebugPageState extends State<FirebaseDebugPage> {
  Map<String, dynamic>? _debugResults;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _runSystemCheck();
  }

  Future<void> _runSystemCheck() async {
    setState(() => _isRunning = true);

    try {
      final results = await FirebaseDebugUtils.performSystemCheck();
      setState(() {
        _debugResults = results;
        _isRunning = false;
      });

      // Console'a da yazdır
      FirebaseDebugUtils.printDebugReport(results);
    } catch (e) {
      setState(() {
        _debugResults = {
          'error': e.toString(),
          'summary': {
            'message': '❌ Sistem kontrolü başarısız',
            'allPassed': false,
            'issues': ['Sistem kontrolü sırasında hata oluştu: $e'],
          }
        };
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Firebase Debug'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isRunning ? null : _runSystemCheck,
            icon: _isRunning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Testleri Yeniden Çalıştır',
          ),
        ],
      ),
      body: _isRunning
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Firebase bağlantıları test ediliyor...'),
                ],
              ),
            )
          : _debugResults != null
              ? _buildDebugResults()
              : const Center(child: Text('Test sonuçları yükleniyor...')),
    );
  }

  Widget _buildDebugResults() {
    if (_debugResults == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genel özet
          FirebaseDebugUtils.buildDebugCard(context, _debugResults!),

          const SizedBox(height: 16),

          // Auth durumu
          _buildAuthSection(),

          const SizedBox(height: 16),

          // Firestore testleri
          _buildFirestoreSection(),

          const SizedBox(height: 16),

          // Storage testleri
          _buildStorageSection(),

          const SizedBox(height: 16),

          // Hızlı çözümler
          _buildQuickFixesSection(),
        ],
      ),
    );
  }

  Widget _buildAuthSection() {
    final authData = _debugResults!['auth'] as Map<String, dynamic>?;
    if (authData == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  authData['isLoggedIn'] ? Icons.check_circle : Icons.error,
                  color: authData['isLoggedIn'] ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Authentication Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
                'Giriş Durumu',
                authData['isLoggedIn']
                    ? '✅ Giriş yapılmış'
                    : '❌ Giriş yapılmamış'),
            if (authData['isLoggedIn']) ...[
              _buildInfoRow('User ID', authData['userId'] ?? 'N/A'),
              _buildInfoRow('Email', authData['email'] ?? 'N/A'),
              _buildInfoRow(
                  'Display Name', authData['displayName'] ?? 'Belirlenmemiş'),
              _buildInfoRow(
                  'Email Verified', authData['emailVerified'] ? '✅' : '❌'),
              if (authData['lastSignIn'] != null)
                _buildInfoRow('Son Giriş', authData['lastSignIn']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFirestoreSection() {
    final firestoreData = _debugResults!['firestore'] as Map<String, dynamic>?;
    if (firestoreData == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.storage, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Firestore Collections',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...firestoreData.entries.map((entry) {
              final collectionName = entry.key;
              final result = entry.value as Map<String, dynamic>;

              return Card(
                color: result['success'] ? Colors.green[50] : Colors.red[50],
                child: ListTile(
                  leading: Icon(
                    result['success'] ? Icons.check_circle : Icons.error,
                    color: result['success'] ? Colors.green : Colors.red,
                  ),
                  title: Text(collectionName),
                  subtitle: Text(result['message']),
                  trailing: result['success']
                      ? const Icon(Icons.thumb_up, color: Colors.green)
                      : IconButton(
                          icon: const Icon(Icons.info, color: Colors.red),
                          onPressed: () => _showErrorDetails(result),
                        ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageSection() {
    final storageData = _debugResults!['storage'] as Map<String, dynamic>?;
    if (storageData == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.cloud_upload, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Firebase Storage',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...storageData.entries.map((entry) {
              final path = entry.key;
              final result = entry.value as Map<String, dynamic>;

              return Card(
                color: result['success'] ? Colors.green[50] : Colors.red[50],
                child: ListTile(
                  leading: Icon(
                    result['success'] ? Icons.check_circle : Icons.error,
                    color: result['success'] ? Colors.green : Colors.red,
                  ),
                  title: Text(path),
                  subtitle: Text(result['message']),
                  trailing: result['success']
                      ? const Icon(Icons.thumb_up, color: Colors.green)
                      : IconButton(
                          icon: const Icon(Icons.info, color: Colors.red),
                          onPressed: () => _showErrorDetails(result),
                        ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFixesSection() {
    final summary = _debugResults!['summary'] as Map<String, dynamic>?;
    if (summary == null || summary['allPassed'] == true) {
      return Card(
        color: Colors.green[50],
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                '✅ Tüm sistemler normal çalışıyor!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.build, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '🔧 Hızlı Çözümler',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Genel Öneriler:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildFixItem('🔐 Kullanıcının login olduğundan emin olun'),
            _buildFixItem(
                '🔒 Firestore Rules\'ı kontrol edin (şu an geliştirme modu)'),
            _buildFixItem('🌐 İnternet bağlantınızı test edin'),
            _buildFixItem(
                '🔥 Firebase Console\'dan proje ayarlarını kontrol edin'),
            _buildFixItem(
                '📱 firebase_options.dart dosyasının güncel olduğunu doğrulayın'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('🔧 Manuel Debug'),
                    content: const Text(
                        'Firebase Console\'ı açın ve şunları kontrol edin:\n\n'
                        '1. Authentication > Users (kullanıcılar mevcut mu?)\n'
                        '2. Firestore Database > Rules (erişim kuralları)\n'
                        '3. Storage > Rules (dosya yükleme kuralları)\n'
                        '4. Project Settings > General (SDK yapılandırması)'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tamam'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Firebase Console\'ı Aç'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildFixItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _showErrorDetails(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            '❌ ${result['collection'] ?? result['path'] ?? 'Hata Detayları'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hata: ${result['error']}'),
              const SizedBox(height: 16),
              if (result['suggestions'] != null) ...[
                const Text('Öneriler:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...(result['suggestions'] as List<String>)
                    .map(
                      (suggestion) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('• $suggestion'),
                      ),
                    )
                    .toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
