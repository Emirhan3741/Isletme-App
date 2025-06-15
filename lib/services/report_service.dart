// CodeRabbit analyze fix: Dosya düzenlendi
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../models/expense_model.dart';
import '../models/appointment_model.dart';
import '../models/note_model.dart';
import '../models/customer_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _transactionsCollection = 'transactions';
  static const String _expensesCollection = 'expenses';
  static const String _appointmentsCollection = 'appointments';
  static const String _notesCollection = 'notes';
  static const String _customersCollection = 'customers';
  static const String _usersCollection = 'users';

  // Mevcut kullanıcı bilgilerini al
  User? get currentUser => _auth.currentUser;

  // Kullanıcının rolünü kontrol et
  Future<bool> isOwner() async {
    if (currentUser == null) return false;
    
    try {
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(currentUser!.uid)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['role'] == 'owner';
      }
      return false;
    } catch (e) {
      print('Rol kontrolü hatası: $e');
      return false;
    }
  }

  // Bugünün toplam geliri
  Future<double> getTodayTotalIncome() async {
    if (currentUser == null) return 0.0;

    try {
      final bool userIsOwner = await isOwner();
      final DateTime today = DateTime.now();
      final DateTime startOfDay = DateTime(today.year, today.month, today.day);
      final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      Query query = _firestore
          .collection(_transactionsCollection)
          .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('tarih', isLessThan: Timestamp.fromDate(endOfDay))
          .where('odemeDurumu', isEqualTo: IslemOdemeDurumu.odendi);

      // Worker sadece kendi işlemlerini görebilir
      if (!userIsOwner) {
        query = query.where('ekleyenKullaniciId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      double totalIncome = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalIncome += (data['tutar'] ?? 0.0).toDouble();
      }

      return totalIncome;
    } catch (e) {
      print('Bugünün geliri hesaplama hatası: $e');
      return 0.0;
    }
  }

  // Bu ayın toplam gideri
  Future<double> getThisMonthTotalExpenses() async {
    if (currentUser == null) return 0.0;

    try {
      final bool userIsOwner = await isOwner();
      final DateTime now = DateTime.now();
      final DateTime startOfMonth = DateTime(now.year, now.month, 1);
      final DateTime endOfMonth = DateTime(now.year, now.month + 1, 1);

      Query query = _firestore
          .collection(_expensesCollection)
          .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('tarih', isLessThan: Timestamp.fromDate(endOfMonth));

      // Worker sadece kendi giderlerini görebilir
      if (!userIsOwner) {
        query = query.where('ekleyenKullaniciId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      double totalExpenses = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalExpenses += (data['tutar'] ?? 0.0).toDouble();
      }

      return totalExpenses;
    } catch (e) {
      print('Bu ayın gideri hesaplama hatası: $e');
      return 0.0;
    }
  }

  // Toplam borç (ödeme durumu Borç olan işlemler)
  Future<double> getTotalDebt() async {
    if (currentUser == null) return 0.0;

    try {
      final bool userIsOwner = await isOwner();
      Query query = _firestore
          .collection(_transactionsCollection)
          .where('odemeDurumu', isEqualTo: IslemOdemeDurumu.borc);

      // Worker sadece kendi işlemlerini görebilir
      if (!userIsOwner) {
        query = query.where('ekleyenKullaniciId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      double totalDebt = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalDebt += (data['tutar'] ?? 0.0).toDouble();
      }

      return totalDebt;
    } catch (e) {
      print('Toplam borç hesaplama hatası: $e');
      return 0.0;
    }
  }

  // Bugünkü randevu sayısı
  Future<int> getTodayAppointmentCount() async {
    if (currentUser == null) return 0;

    try {
      final bool userIsOwner = await isOwner();
      final DateTime today = DateTime.now();
      final DateTime startOfDay = DateTime(today.year, today.month, today.day);
      final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      Query query = _firestore
          .collection(_appointmentsCollection)
          .where('baslangicTarihi', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('baslangicTarihi', isLessThan: Timestamp.fromDate(endOfDay));

      // Worker sadece kendi randevularını görebilir
      if (!userIsOwner) {
        query = query.where('calisanId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      print('Bugünkü randevu sayısı hatası: $e');
      return 0;
    }
  }

  // Bu haftanın randevu sayısı
  Future<int> getThisWeekAppointmentCount() async {
    if (currentUser == null) return 0;

    try {
      final bool userIsOwner = await isOwner();
      final DateTime now = DateTime.now();
      final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final DateTime startOfWeekMidnight = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final DateTime endOfWeek = startOfWeekMidnight.add(const Duration(days: 7));

      Query query = _firestore
          .collection(_appointmentsCollection)
          .where('baslangicTarihi', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeekMidnight))
          .where('baslangicTarihi', isLessThan: Timestamp.fromDate(endOfWeek));

      // Worker sadece kendi randevularını görebilir
      if (!userIsOwner) {
        query = query.where('calisanId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      print('Bu haftanın randevu sayısı hatası: $e');
      return 0;
    }
  }

  // En çok yapılan işlem türü
  Future<Map<String, dynamic>> getMostCommonTransactionType() async {
    if (currentUser == null) return {'type': 'Bilinmiyor', 'count': 0};

    try {
      final bool userIsOwner = await isOwner();
      Query query = _firestore.collection(_transactionsCollection);

      // Worker sadece kendi işlemlerini görebilir
      if (!userIsOwner) {
        query = query.where('ekleyenKullaniciId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      Map<String, int> typeCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final islemTuru = data['islemTuru'] ?? 'Bilinmiyor';
        typeCounts[islemTuru] = (typeCounts[islemTuru] ?? 0) + 1;
      }

      if (typeCounts.isEmpty) {
        return {'type': 'Bilinmiyor', 'count': 0};
      }

      // En çok tekrar eden işlem türünü bul
      final mostCommon = typeCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      return {'type': mostCommon.key, 'count': mostCommon.value};
    } catch (e) {
      print('En çok yapılan işlem türü hatası: $e');
      return {'type': 'Bilinmiyor', 'count': 0};
    }
  }

  // En çok randevu alan müşteri
  Future<Map<String, dynamic>> getMostFrequentCustomer() async {
    if (currentUser == null) return {'name': 'Bilinmiyor', 'count': 0};

    try {
      final bool userIsOwner = await isOwner();
      Query query = _firestore.collection(_appointmentsCollection);

      // Worker sadece kendi randevularını görebilir
      if (!userIsOwner) {
        query = query.where('calisanId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      Map<String, int> customerCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final musteriId = data['musteriId'] ?? '';
        if (musteriId.isNotEmpty) {
          customerCounts[musteriId] = (customerCounts[musteriId] ?? 0) + 1;
        }
      }

      if (customerCounts.isEmpty) {
        return {'name': 'Bilinmiyor', 'count': 0};
      }

      // En çok randevu alan müşteri ID'sini bul
      final mostFrequentCustomerId = customerCounts.entries.reduce((a, b) => a.value > b.value ? a : b);

      // Müşteri ismini getir
      try {
        final customerDoc = await _firestore
            .collection(_customersCollection)
            .doc(mostFrequentCustomerId.key)
            .get();

        if (customerDoc.exists) {
          final customerData = customerDoc.data() as Map<String, dynamic>;
          final customerName = '${customerData['isim']} ${customerData['soyisim']}';
          return {'name': customerName, 'count': mostFrequentCustomerId.value};
        }
      } catch (e) {
        print('Müşteri bilgisi getirme hatası: $e');
      }

      return {'name': 'Müşteri #${mostFrequentCustomerId.key.substring(0, 8)}', 'count': mostFrequentCustomerId.value};
    } catch (e) {
      print('En çok randevu alan müşteri hatası: $e');
      return {'name': 'Bilinmiyor', 'count': 0};
    }
  }

  // Aylık gelir/gider karşılaştırması (son 6 ay)
  Future<List<Map<String, dynamic>>> getMonthlyIncomeExpenseComparison() async {
    if (currentUser == null) return [];

    try {
      final bool userIsOwner = await isOwner();
      final DateTime now = DateTime.now();
      List<Map<String, dynamic>> monthlyData = [];

      for (int i = 5; i >= 0; i--) {
        final DateTime monthStart = DateTime(now.year, now.month - i, 1);
        final DateTime monthEnd = DateTime(now.year, now.month - i + 1, 1);

        // Gelir hesapla
        Query incomeQuery = _firestore
            .collection(_transactionsCollection)
            .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
            .where('tarih', isLessThan: Timestamp.fromDate(monthEnd))
            .where('odemeDurumu', isEqualTo: IslemOdemeDurumu.odendi);

        if (!userIsOwner) {
          incomeQuery = incomeQuery.where('ekleyenKullaniciId', isEqualTo: currentUser!.uid);
        }

        // Gider hesapla
        Query expenseQuery = _firestore
            .collection(_expensesCollection)
            .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
            .where('tarih', isLessThan: Timestamp.fromDate(monthEnd));

        if (!userIsOwner) {
          expenseQuery = expenseQuery.where('ekleyenKullaniciId', isEqualTo: currentUser!.uid);
        }

        final incomeSnapshot = await incomeQuery.get();
        final expenseSnapshot = await expenseQuery.get();

        double monthlyIncome = 0.0;
        double monthlyExpense = 0.0;

        for (var doc in incomeSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          monthlyIncome += (data['tutar'] ?? 0.0).toDouble();
        }

        for (var doc in expenseSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          monthlyExpense += (data['tutar'] ?? 0.0).toDouble();
        }

        monthlyData.add({
          'month': _getMonthName(monthStart.month),
          'income': monthlyIncome,
          'expense': monthlyExpense,
          'profit': monthlyIncome - monthlyExpense,
        });
      }

      return monthlyData;
    } catch (e) {
      print('Aylık gelir/gider karşılaştırması hatası: $e');
      return [];
    }
  }

  // İşlem türü dağılımı (pasta grafik için)
  Future<List<Map<String, dynamic>>> getTransactionTypeDistribution() async {
    if (currentUser == null) return [];

    try {
      final bool userIsOwner = await isOwner();
      Query query = _firestore.collection(_transactionsCollection);

      if (!userIsOwner) {
        query = query.where('ekleyenKullaniciId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      Map<String, double> typeAmounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final islemTuru = data['islemTuru'] ?? 'Bilinmiyor';
        final tutar = (data['tutar'] ?? 0.0).toDouble();
        typeAmounts[islemTuru] = (typeAmounts[islemTuru] ?? 0.0) + tutar;
      }

      List<Map<String, dynamic>> distribution = [];
      double total = typeAmounts.values.fold(0.0, (sum, amount) => sum + amount);

      typeAmounts.forEach((type, amount) {
        distribution.add({
          'type': type,
          'amount': amount,
          'percentage': total > 0 ? (amount / total * 100) : 0.0,
        });
      });

      // Tutara göre büyükten küçüğe sırala
      distribution.sort((a, b) => b['amount'].compareTo(a['amount']));

      return distribution;
    } catch (e) {
      print('İşlem türü dağılımı hatası: $e');
      return [];
    }
  }

  // Günlük randevu sayıları (son 7 gün)
  Future<List<Map<String, dynamic>>> getDailyAppointmentCounts() async {
    if (currentUser == null) return [];

    try {
      final bool userIsOwner = await isOwner();
      final DateTime now = DateTime.now();
      List<Map<String, dynamic>> dailyData = [];

      for (int i = 6; i >= 0; i--) {
        final DateTime day = now.subtract(Duration(days: i));
        final DateTime startOfDay = DateTime(day.year, day.month, day.day);
        final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

        Query query = _firestore
            .collection(_appointmentsCollection)
            .where('baslangicTarihi', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('baslangicTarihi', isLessThan: Timestamp.fromDate(endOfDay));

        if (!userIsOwner) {
          query = query.where('calisanId', isEqualTo: currentUser!.uid);
        }

        final snapshot = await query.get();

        dailyData.add({
          'day': _getDayName(day.weekday),
          'date': '${day.day}/${day.month}',
          'count': snapshot.docs.length,
        });
      }

      return dailyData;
    } catch (e) {
      print('Günlük randevu sayıları hatası: $e');
      return [];
    }
  }

  // Note kategorilerine göre dağılım
  Future<List<Map<String, dynamic>>> getNotesCategoryDistribution() async {
    if (currentUser == null) return [];

    try {
      final bool userIsOwner = await isOwner();
      Query query = _firestore.collection(_notesCollection);

      if (!userIsOwner) {
        query = query.where('kullaniciId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      Map<String, int> categoryCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final kategori = data['kategori'] ?? 'Bilinmiyor';
        categoryCounts[kategori] = (categoryCounts[kategori] ?? 0) + 1;
      }

      List<Map<String, dynamic>> distribution = [];
      int total = categoryCounts.values.fold(0, (sum, count) => sum + count);

      categoryCounts.forEach((category, count) {
        distribution.add({
          'category': category,
          'count': count,
          'percentage': total > 0 ? (count / total * 100) : 0.0,
          'icon': NoteCategory.kategoriIkonlari[category] ?? '📝',
        });
      });

      // Sayıya göre büyükten küçüğe sırala
      distribution.sort((a, b) => b['count'].compareTo(a['count']));

      return distribution;
    } catch (e) {
      print('Not kategori dağılımı hatası: $e');
      return [];
    }
  }

  // Top 5 müşteri (en çok harcama yapan)
  Future<List<Map<String, dynamic>>> getTopCustomersBySpending() async {
    if (currentUser == null) return [];

    try {
      final bool userIsOwner = await isOwner();
      Query query = _firestore.collection(_transactionsCollection);

      if (!userIsOwner) {
        query = query.where('ekleyenKullaniciId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      Map<String, double> customerSpending = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final musteriId = data['musteriId'] ?? '';
        final tutar = (data['tutar'] ?? 0.0).toDouble();

        if (musteriId.isNotEmpty) {
          customerSpending[musteriId] = (customerSpending[musteriId] ?? 0.0) + tutar;
        }
      }

      // En çok harcama yapan 5 müşteriyi al
      final sortedCustomers = customerSpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      List<Map<String, dynamic>> topCustomers = [];

      for (int i = 0; i < sortedCustomers.length && i < 5; i++) {
        final customerId = sortedCustomers[i].key;
        final amount = sortedCustomers[i].value;

        try {
          final customerDoc = await _firestore
              .collection(_customersCollection)
              .doc(customerId)
              .get();

          String customerName = 'Müşteri #${customerId.substring(0, 8)}';
          if (customerDoc.exists) {
            final customerData = customerDoc.data() as Map<String, dynamic>;
            customerName = '${customerData['isim']} ${customerData['soyisim']}';
          }

          topCustomers.add({
            'name': customerName,
            'amount': amount,
            'rank': i + 1,
          });
        } catch (e) {
          print('Müşteri bilgisi getirme hatası: $e');
          topCustomers.add({
            'name': 'Müşteri #${customerId.substring(0, 8)}',
            'amount': amount,
            'rank': i + 1,
          });
        }
      }

      return topCustomers;
    } catch (e) {
      print('Top müşteriler hatası: $e');
      return [];
    }
  }

  // Yardımcı metodlar
  String _getMonthName(int month) {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month];
  }

  String _getDayName(int weekday) {
    const days = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[weekday];
  }

  // Genel özet raporu
  Future<Map<String, dynamic>> getOverallSummary() async {
    try {
      final results = await Future.wait([
        getTodayTotalIncome(),
        getThisMonthTotalExpenses(),
        getTotalDebt(),
        getTodayAppointmentCount(),
        getThisWeekAppointmentCount(),
        getMostCommonTransactionType(),
        getMostFrequentCustomer(),
      ]);

      return {
        'todayIncome': results[0],
        'monthExpenses': results[1],
        'totalDebt': results[2],
        'todayAppointments': results[3],
        'weekAppointments': results[4],
        'mostCommonTransactionType': results[5],
        'mostFrequentCustomer': results[6],
      };
    } catch (e) {
      print('Genel özet raporu hatası: $e');
      return {};
    }
  }
}