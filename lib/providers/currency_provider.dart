import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider extends ChangeNotifier {
  String _currency = '₺'; // Varsayılan para birimi

  String get currency => _currency;

  // Desteklenen para birimleri
  static const List<Map<String, String>> supportedCurrencies = [
    {'code': 'TRY', 'symbol': '₺', 'name': 'Turkish Lira'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'RUB', 'symbol': '₽', 'name': 'Russian Ruble'},
    {'code': 'AED', 'symbol': 'د.إ', 'name': 'UAE Dirham'},
    {'code': 'SAR', 'symbol': 'ر.س', 'name': 'Saudi Riyal'},
  ];

  // Para birimi kodlarından sembol alma
  static const Map<String, String> currencySymbols = {
    'TRY': '₺',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'RUB': '₽',
    'AED': 'د.إ',
    'SAR': 'ر.س',
  };

  CurrencyProvider() {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrency = prefs.getString('currency_symbol');

      if (savedCurrency != null &&
          supportedCurrencies.any((c) => c['symbol'] == savedCurrency)) {
        _currency = savedCurrency;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading currency: $e');
    }
  }

  Future<void> setCurrency(String currencySymbol) async {
    if (_currency != currencySymbol) {
      _currency = currencySymbol;
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('currency_symbol', currencySymbol);
      } catch (e) {
        if (kDebugMode) debugPrint('Error saving currency: $e');
      }
    }
  }

  // Para birimi adı alma
  String getCurrencyName(String symbol) {
    final currency = supportedCurrencies.firstWhere(
      (c) => c['symbol'] == symbol,
      orElse: () => {'name': 'Unknown Currency'},
    );
    return currency['name'] ?? 'Unknown Currency';
  }

  // Para birimi kodu alma
  String getCurrencyCode(String symbol) {
    final currency = supportedCurrencies.firstWhere(
      (c) => c['symbol'] == symbol,
      orElse: () => {'code': 'TRY'},
    );
    return currency['code'] ?? 'TRY';
  }

  // Fiyat formatı
  String formatPrice(double price) {
    return '$_currency${price.toStringAsFixed(2)}';
  }

  // Para birimi sembolü ile fiyat formatı
  String formatPriceWithCurrency(double price, {bool showSymbol = true}) {
    if (!showSymbol) {
      return price.toStringAsFixed(2);
    }

    // Arapça para birimleri için özel formatla
    if (_currency == 'د.إ' || _currency == 'ر.س') {
      return '${price.toStringAsFixed(2)} $_currency';
    } else {
      return '$_currency${price.toStringAsFixed(2)}';
    }
  }
}
