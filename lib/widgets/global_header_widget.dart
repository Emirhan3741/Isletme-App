import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/locale_provider.dart';
import '../providers/currency_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/constants/app_constants.dart';

class GlobalHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData sectorIcon;
  final List<Color> gradientColors;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final bool showLanguageSelector;
  final bool showCurrencyInfo;

  const GlobalHeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sectorIcon,
    required this.gradientColors,
    this.onNotificationTap,
    this.onProfileTap,
    this.showLanguageSelector = true,
    this.showCurrencyInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Row(
        children: [
          // Sol: Logo ve Başlık
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusLarge),
            ),
            child: Icon(
              sectorIcon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.textMedium,
                  ),
                ),
              ],
            ),
          ),

          // Sağ: Bilgi ve Aksiyonlar
          Row(
            children: [
              // Para birimi bilgisi
              if (showCurrencyInfo) ...[
                Consumer<CurrencyProvider>(
                  builder: (context, currencyProvider, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingMedium,
                        vertical: AppConstants.paddingSmall,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 16,
                            color: AppConstants.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currencyProvider.currency,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: AppConstants.paddingMedium),
              ],

              // Hızlı dil değiştirme
              if (showLanguageSelector) ...[
                Consumer<LocaleProvider>(
                  builder: (context, localeProvider, child) {
                    return PopupMenuButton<String>(
                      tooltip: AppLocalizations.of(context)!.changeLanguage,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              AppConstants.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                              AppConstants.radiusMedium),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              localeProvider.getLanguageFlag(
                                  localeProvider.locale.languageCode),
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: AppConstants.primaryColor,
                            ),
                          ],
                        ),
                      ),
                      onSelected: (String languageCode) {
                        localeProvider.setLocale(Locale(languageCode));
                      },
                      itemBuilder: (BuildContext context) {
                        return LocaleProvider.supportedLocales.map((locale) {
                          final isSelected =
                              localeProvider.locale.languageCode ==
                                  locale.languageCode;

                          return PopupMenuItem<String>(
                            value: locale.languageCode,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Text(
                                    localeProvider
                                        .getLanguageFlag(locale.languageCode),
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      localeProvider
                                          .getLanguageName(locale.languageCode),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? AppConstants.primaryColor
                                            : AppConstants.textDark,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check,
                                      size: 18,
                                      color: AppConstants.primaryColor,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList();
                      },
                    );
                  },
                ),
                const SizedBox(width: AppConstants.paddingMedium),
              ],

              // Bildirimler
              IconButton(
                onPressed: onNotificationTap,
                tooltip: AppLocalizations.of(context)!.notifications,
                icon: Stack(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: AppConstants.textMedium,
                      size: 24,
                    ),
                    // Bildirim sayısı badge'i (opsiyonel)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppConstants.errorColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppConstants.paddingSmall),

              // Profil
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppConstants.primaryColor,
                        child: Text(
                          (user?.displayName?.isNotEmpty == true
                              ? (user?.displayName?[0] ?? 'U').toUpperCase()
                              : (user?.email?[0] ?? 'U').toUpperCase()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user?.displayName ?? 'Kullanıcı',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: AppConstants.textDark,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppConstants.textMedium,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Kolay kullanım için factory constructors
  factory GlobalHeaderWidget.beauty({
    String? title,
    String? subtitle,
    VoidCallback? onNotificationTap,
    VoidCallback? onProfileTap,
  }) {
    return GlobalHeaderWidget(
      title: title ?? 'Güzellik Salonu',
      subtitle: subtitle ?? 'Yönetim Sistemi',
      sectorIcon: Icons.content_cut,
      gradientColors: const [Color(0xFFEC4899), Color(0xFFF472B6)],
      onNotificationTap: onNotificationTap,
      onProfileTap: onProfileTap,
    );
  }

  factory GlobalHeaderWidget.sports({
    String? title,
    String? subtitle,
    VoidCallback? onNotificationTap,
    VoidCallback? onProfileTap,
  }) {
    return GlobalHeaderWidget(
      title: title ?? 'Spor & Fitness',
      subtitle: subtitle ?? 'Yönetim Sistemi',
      sectorIcon: Icons.fitness_center,
      gradientColors: const [Color(0xFFF97316), Color(0xFFEAB308)],
      onNotificationTap: onNotificationTap,
      onProfileTap: onProfileTap,
    );
  }

  factory GlobalHeaderWidget.psychology({
    String? title,
    String? subtitle,
    VoidCallback? onNotificationTap,
    VoidCallback? onProfileTap,
  }) {
    return GlobalHeaderWidget(
      title: title ?? 'Psikoloji',
      subtitle: subtitle ?? 'Danışmanlık Sistemi',
      sectorIcon: Icons.psychology,
      gradientColors: const [Color(0xFF8B5CF6), Color(0xFFA855F7)],
      onNotificationTap: onNotificationTap,
      onProfileTap: onProfileTap,
    );
  }

  factory GlobalHeaderWidget.lawyer({
    String? title,
    String? subtitle,
    VoidCallback? onNotificationTap,
    VoidCallback? onProfileTap,
  }) {
    return GlobalHeaderWidget(
      title: title ?? 'Hukuk Bürosu',
      subtitle: subtitle ?? 'Yönetim Sistemi',
      sectorIcon: Icons.gavel,
      gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      onNotificationTap: onNotificationTap,
      onProfileTap: onProfileTap,
    );
  }

  factory GlobalHeaderWidget.veterinary({
    String? title,
    String? subtitle,
    VoidCallback? onNotificationTap,
    VoidCallback? onProfileTap,
  }) {
    return GlobalHeaderWidget(
      title: title ?? 'Veteriner Kliniği',
      subtitle: subtitle ?? 'Yönetim Sistemi',
      sectorIcon: Icons.pets,
      gradientColors: const [Color(0xFF059669), Color(0xFF10B981)],
      onNotificationTap: onNotificationTap,
      onProfileTap: onProfileTap,
    );
  }

  factory GlobalHeaderWidget.clinic({
    String? title,
    String? subtitle,
    VoidCallback? onNotificationTap,
    VoidCallback? onProfileTap,
  }) {
    return GlobalHeaderWidget(
      title: title ?? 'Sağlık Kliniği',
      subtitle: subtitle ?? 'Yönetim Sistemi',
      sectorIcon: Icons.local_hospital,
      gradientColors: const [Color(0xFF10B981), Color(0xFF34D399)],
      onNotificationTap: onNotificationTap,
      onProfileTap: onProfileTap,
    );
  }

  factory GlobalHeaderWidget.education({
    String? title,
    String? subtitle,
    VoidCallback? onNotificationTap,
    VoidCallback? onProfileTap,
  }) {
    return GlobalHeaderWidget(
      title: title ?? 'Eğitim Merkezi',
      subtitle: subtitle ?? 'Yönetim Sistemi',
      sectorIcon: Icons.school,
      gradientColors: const [Color(0xFF0891B2), Color(0xFF06B6D4)],
      onNotificationTap: onNotificationTap,
      onProfileTap: onProfileTap,
    );
  }

  factory GlobalHeaderWidget.realEstate({
    String? title,
    String? subtitle,
    VoidCallback? onNotificationTap,
    VoidCallback? onProfileTap,
  }) {
    return GlobalHeaderWidget(
      title: title ?? 'Emlak Ofisi',
      subtitle: subtitle ?? 'Yönetim Sistemi',
      sectorIcon: Icons.business,
      gradientColors: const [Color(0xFFEA580C), Color(0xFFF97316)],
      onNotificationTap: onNotificationTap,
      onProfileTap: onProfileTap,
    );
  }
}
