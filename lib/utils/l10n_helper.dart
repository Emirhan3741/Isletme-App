import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// L10n erişimini kolaylaştıran yardımcı sınıf
/// Build metodu dışındaki fonksiyonlarda context ile birlikte kullanılabilir
class L10nHelper {
  /// Context'ten AppLocalizations örneğini güvenli şekilde alır
  static AppLocalizations of(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      throw Exception(
          'AppLocalizations context\'e erişilemiyor. MaterialApp\'de localizationsDelegates tanımlı mı?');
    }
    return localizations;
  }

  /// Nullable versiyonu - test ortamlarında kullanılabilir
  static AppLocalizations? maybeOf(BuildContext context) {
    return AppLocalizations.of(context);
  }
}
