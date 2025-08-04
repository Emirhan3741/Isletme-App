import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/constants/app_constants.dart';

class LanguageSelectorWidget extends StatelessWidget {
  final bool isModal;

  const LanguageSelectorWidget({
    super.key,
    this.isModal = false,
  });

  /// Modal dil seçici göster
  static Future<void> showLanguageModal(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: const BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.borderRadiusXLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppConstants.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            // Başlık
            Text(
              AppLocalizations.of(context)!.selectLanguage,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppConstants.textDark,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Dil listesi
            ...LocaleProvider.supportedLocales.map((locale) {
              final localeProvider =
                  Provider.of<LocaleProvider>(context, listen: false);
              final isSelected =
                  localeProvider.locale.languageCode == locale.languageCode;
              final languageName =
                  LocaleProvider.languageNames[locale.languageCode] ?? '';

              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? AppConstants.primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      _getLanguageFlag(locale.languageCode),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                title: Text(
                  languageName,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppConstants.primaryColor
                        : AppConstants.textDark,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: AppConstants.primaryColor,
                      )
                    : null,
                onTap: () async {
                  await localeProvider.setLocale(locale);
                  Navigator.pop(context);
                },
              );
            }).toList(),

            const SizedBox(height: AppConstants.paddingMedium),
          ],
        ),
      ),
    );
  }

  /// Dil koduna göre bayrak emoji döndür
  static String _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return '🇹🇷';
      case 'en':
        return '🇺🇸';
      case 'de':
        return '🇩🇪';
      case 'fr':
        return '🇫🇷';
      case 'es':
        return '🇪🇸';
      case 'it':
        return '🇮🇹';
      case 'ar':
        return '🇸🇦';
      case 'ru':
        return '🇷🇺';
      default:
        return '🌐';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final localizations = AppLocalizations.of(context)!;

    if (isModal) {
      return _buildModalSelector(context, localeProvider, localizations);
    } else {
      return _buildDropdownSelector(context, localeProvider, localizations);
    }
  }

  Widget _buildDropdownSelector(
    BuildContext context,
    LocaleProvider localeProvider,
    AppLocalizations localizations,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppConstants.textLight),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        color: AppConstants.surfaceColor,
      ),
      child: DropdownButton<Locale>(
        value: localeProvider.locale,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.keyboard_arrow_down),
        items: LocaleProvider.supportedLocales.map((locale) {
          return DropdownMenuItem<Locale>(
            value: locale,
            child: Row(
              children: [
                Text(
                  _getLanguageFlag(locale.languageCode),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  LocaleProvider.languageNames[locale.languageCode] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (Locale? newLocale) {
          if (newLocale != null) {
            localeProvider.setLocale(newLocale);
          }
        },
      ),
    );
  }

  Widget _buildModalSelector(
    BuildContext context,
    LocaleProvider localeProvider,
    AppLocalizations localizations,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.selectLanguage,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppConstants.textDark,
          ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        ...LocaleProvider.supportedLocales.map((locale) {
          final isSelected =
              localeProvider.locale.languageCode == locale.languageCode;
          final languageName =
              LocaleProvider.languageNames[locale.languageCode] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => localeProvider.setLocale(locale),
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusMedium),
              child: Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppConstants.primaryColor.withValues(alpha: 0.1)
                      : AppConstants.backgroundColor,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  border: isSelected
                      ? Border.all(color: AppConstants.primaryColor)
                      : null,
                ),
                child: Row(
                  children: [
                    Text(
                      _getLanguageFlag(locale.languageCode),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        languageName,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? AppConstants.primaryColor
                              : AppConstants.textDark,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppConstants.primaryColor,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
