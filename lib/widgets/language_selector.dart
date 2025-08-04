import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../core/constants/app_constants.dart';

/// 🌐 Dil Seçici Widget
/// Kullanıcı kayıt sırasında dil seçimi için kullanılır
class LanguageSelector extends StatelessWidget {
  final Function(String)? onLanguageSelected;
  final String? selectedLanguageCode;
  final bool showTitle;
  final bool isCompact;

  const LanguageSelector({
    Key? key,
    this.onLanguageSelected,
    this.selectedLanguageCode,
    this.showTitle = true,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final supportedLanguages = localeProvider.getSupportedLanguages();

    if (isCompact) {
      return _buildCompactSelector(context, supportedLanguages);
    }

    return _buildFullSelector(context, supportedLanguages);
  }

  /// Compact dropdown selector
  Widget _buildCompactSelector(BuildContext context, List<Map<String, String>> languages) {
    return DropdownButtonFormField<String>(
      value: selectedLanguageCode ?? context.read<LocaleProvider>().languageCode,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.selectLanguage,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        prefixIcon: const Icon(Icons.language),
      ),
      items: languages.map((language) {
        return DropdownMenuItem<String>(
          value: language['code'],
          child: Row(
            children: [
              _getLanguageFlag(language['code']!),
              const SizedBox(width: 8),
              Text(language['name']!),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null && onLanguageSelected != null) {
          onLanguageSelected!(value);
        }
      },
    );
  }

  /// Full card-based selector
  Widget _buildFullSelector(BuildContext context, List<Map<String, String>> languages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            AppLocalizations.of(context)!.selectLanguage,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
        ],
        Wrap(
          spacing: AppConstants.paddingSmall,
          runSpacing: AppConstants.paddingSmall,
          children: languages.map((language) {
            final isSelected = selectedLanguageCode == language['code'] ||
                (selectedLanguageCode == null && 
                 language['code'] == context.read<LocaleProvider>().languageCode);
            
            return _buildLanguageCard(
              context,
              language['code']!,
              language['name']!,
              isSelected,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Language selection card
  Widget _buildLanguageCard(BuildContext context, String code, String name, bool isSelected) {
    return InkWell(
      onTap: () {
        if (onLanguageSelected != null) {
          onLanguageSelected!(code);
        }
      },
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : AppConstants.borderColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _getLanguageFlag(code),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : AppConstants.textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Language flag icon
  Widget _getLanguageFlag(String languageCode) {
    final flagIcons = {
      'tr': '🇹🇷',
      'en': '🇺🇸',
      'de': '🇩🇪',
      'es': '🇪🇸',
      'fr': '🇫🇷',
    };

    return Text(
      flagIcons[languageCode] ?? '🌐',
      style: const TextStyle(fontSize: 20),
    );
  }
}

/// 🌐 Dil Seçimi Dialog
/// Modal olarak dil seçimi için kullanılır
class LanguageSelectionDialog extends StatefulWidget {
  final String? currentLanguageCode;

  const LanguageSelectionDialog({
    Key? key,
    this.currentLanguageCode,
  }) : super(key: key);

  @override
  State<LanguageSelectionDialog> createState() => _LanguageSelectionDialogState();
}

class _LanguageSelectionDialogState extends State<LanguageSelectionDialog> {
  String? selectedLanguageCode;

  @override
  void initState() {
    super.initState();
    selectedLanguageCode = widget.currentLanguageCode ?? 
        context.read<LocaleProvider>().languageCode;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      title: Row(
        children: [
          Icon(
            Icons.language,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.selectLanguage),
        ],
      ),
      content: LanguageSelector(
        selectedLanguageCode: selectedLanguageCode,
        showTitle: false,
        onLanguageSelected: (code) {
          setState(() {
            selectedLanguageCode = code;
          });
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(selectedLanguageCode);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}