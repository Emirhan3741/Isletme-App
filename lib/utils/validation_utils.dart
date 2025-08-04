class ValidationUtils {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta adresi gerekli';
    }

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Geçerli bir e-posta adresi girin';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }

    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Şifre onayı gerekli';
    }

    if (value != password) {
      return 'Şifreler eşleşmiyor';
    }

    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Bu alan'} gerekli';
    }
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'İsim gerekli';
    }

    if (value.trim().length < 2) {
      return 'İsim en az 2 karakter olmalı';
    }

    return null;
  }

  // Phone validation
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefon numarası gerekli';
    }

    // Remove spaces and special characters
    final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPhone.length < 10) {
      return 'Geçerli bir telefon numarası girin';
    }

    return null;
  }

  // Price/Amount validation
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Fiyat gerekli';
    }

    final price = double.tryParse(value.trim());
    if (price == null) {
      return 'Geçerli bir fiyat girin';
    }

    if (price < 0) {
      return 'Fiyat negatif olamaz';
    }

    return null;
  }

  // Positive number validation
  static String? validatePositiveNumber(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Bu alan'} gerekli';
    }

    final number = double.tryParse(value.trim());
    if (number == null) {
      return 'Geçerli bir sayı girin';
    }

    if (number <= 0) {
      return '${fieldName ?? 'Değer'} pozitif olmalı';
    }

    return null;
  }

  // Non-negative number validation
  static String? validateNonNegativeNumber(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Bu alan'} gerekli';
    }

    final number = double.tryParse(value.trim());
    if (number == null) {
      return 'Geçerli bir sayı girin';
    }

    if (number < 0) {
      return '${fieldName ?? 'Değer'} negatif olamaz';
    }

    return null;
  }

  // URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // URL optional
    }

    try {
      Uri.parse(value.trim());
      return null;
    } catch (e) {
      return 'Geçerli bir URL girin';
    }
  }

  // Date validation
  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'Tarih seçin';
    }

    return null;
  }

  // Future date validation
  static String? validateFutureDate(DateTime? date) {
    if (date == null) {
      return 'Tarih seçin';
    }

    if (date.isBefore(DateTime.now())) {
      return 'Geçmiş tarih seçilemez';
    }

    return null;
  }

  // Custom validation combiner
  static String? validateMultiple(
      String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}
