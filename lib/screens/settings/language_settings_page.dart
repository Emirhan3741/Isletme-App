import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider_enhanced.dart';
import '../../core/constants/app_constants.dart';

/// 🌐 Language Settings Page with Instant Apply
class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language ?? 'Dil Ayarları'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<LocaleProvider, AuthProviderEnhanced>(
        builder: (context, localeProvider, authProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chooseLanguage ?? 'Dil Seçin',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                
                ...LocaleProvider.supportedLocales.map((locale) {
                  final isSelected = localeProvider.locale.languageCode == locale.languageCode;
                  final languageName = _getLanguageName(locale.languageCode);
                  final flag = _getLanguageFlag(locale.languageCode);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
                    child: ListTile(
                      leading: Text(
                        flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        languageName,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected 
                        ? Icon(
                            Icons.check_circle,
                            color: AppConstants.primaryColor,
                          )
                        : null,
                      onTap: () => _changeLanguage(
                        context, 
                        locale, 
                        localeProvider, 
                        authProvider,
                      ),
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                if (authProvider.isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'tr': return 'Türkçe';
      case 'en': return 'English';
      case 'de': return 'Deutsch';
      case 'es': return 'Español';
      case 'fr': return 'Français';
      default: return languageCode.toUpperCase();
    }
  }

  String _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'tr': return '🇹🇷';
      case 'en': return '🇺🇸';
      case 'de': return '🇩🇪';
      case 'es': return '🇪🇸';
      case 'fr': return '🇫🇷';
      default: return '🌐';
    }
  }

  Future<void> _changeLanguage(
    BuildContext context,
    Locale locale,
    LocaleProvider localeProvider,
    AuthProviderEnhanced authProvider,
  ) async {
    try {
      // 1. LocaleProvider'da anında değiştir
      await localeProvider.setLocale(locale);
      
      // 2. Firebase'e kullanıcı tercihini kaydet
      final success = await authProvider.updateUserLanguage(locale.languageCode);
      
      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Text(_getLanguageFlag(locale.languageCode)),
                  const SizedBox(width: 8),
                  Text('Dil değiştirildi: ${_getLanguageName(locale.languageCode)}'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dil değişikliği kaydedilemedi: ${authProvider.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      
      debugPrint('🌐 Dil değiştirildi: ${locale.languageCode}');
      
    } catch (e) {
      debugPrint('❌ Dil değiştirme hatası: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dil değiştirme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}