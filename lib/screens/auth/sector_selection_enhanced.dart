import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider_enhanced.dart';
import '../../providers/locale_provider.dart';

/// 🎯 Enhanced Sector Selection with Auto-Navigation
class SectorSelectionEnhanced extends StatefulWidget {
  const SectorSelectionEnhanced({Key? key}) : super(key: key);

  @override
  State<SectorSelectionEnhanced> createState() => _SectorSelectionEnhancedState();
}

class _SectorSelectionEnhancedState extends State<SectorSelectionEnhanced> {
  bool _isLoading = false;
  String? _selectedSector;

  @override
  void initState() {
    super.initState();
    // Kullanıcının dil tercihini yükle
    _loadUserLanguagePreference();
  }

  Future<void> _loadUserLanguagePreference() async {
    final authProvider = Provider.of<AuthProviderEnhanced>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    
    final userLanguage = authProvider.getCurrentUserLanguage();
    if (userLanguage != null && userLanguage.isNotEmpty) {
      // Kullanıcının kaydedilmiş dil tercihini uygula
      localeProvider.setLocale(Locale(userLanguage));
    }
  }

  Future<void> _selectSector(String sectorKey, String sectorRoute) async {
    setState(() {
      _isLoading = true;
      _selectedSector = sectorKey;
    });

    try {
      final authProvider = Provider.of<AuthProviderEnhanced>(context, listen: false);
      
      // Seçilen panel'i kaydet
      final success = await authProvider.updateUserSelectedPanel(sectorKey);
      
      if (success && mounted) {
        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${_getSectorName(sectorKey)} paneli seçildi!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // 1 saniye bekle ve yönlendir
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(sectorRoute);
        }
      } else {
        throw Exception('Panel seçimi kaydedilemedi');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedSector = null;
        });
      }
    }
  }

  String _getSectorName(String sectorKey) {
    switch (sectorKey) {
      case 'beauty': return 'Güzellik Salonu';
      case 'lawyer': return 'Avukatlık';
      case 'psychology': return 'Psikoloji';
      case 'veterinary': return 'Veterinarianism';
      case 'sports': return 'Spor';
      case 'clinic': return 'Klinik';
      case 'education': return 'Eğitim';
      case 'real_estate': return 'Emlak';
      default: return sectorKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(l10n.selectSector ?? 'Sektör Seçimi'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<AuthProviderEnhanced>(
            builder: (context, auth, child) {
              return IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await auth.signOut();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Text(
                  l10n.choosePanelSubtitle ?? 'İşletmeniz için uygun paneli seçin',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Text(
                  l10n.choosePanelDescription ?? 'Seçtiğiniz panel size özel dashboard ve özellikleri açacaktır.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLarge * 2),
                
                // Sektör Grid'i
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppConstants.paddingMedium,
                  mainAxisSpacing: AppConstants.paddingMedium,
                  childAspectRatio: 1.2,
                  children: [
                    _buildSectorCard(
                      title: 'Güzellik Salonu',
                      icon: Icons.face_retouching_natural,
                      color: Colors.pink,
                      onTap: () => _selectSector('beauty', '/beauty-dashboard'),
                      isSelected: _selectedSector == 'beauty',
                    ),
                    _buildSectorCard(
                      title: 'Avukatlık',
                      icon: Icons.gavel,
                      color: Colors.blue,
                      onTap: () => _selectSector('lawyer', '/lawyer-dashboard'),
                      isSelected: _selectedSector == 'lawyer',
                    ),
                    _buildSectorCard(
                      title: 'Psikoloji',
                      icon: Icons.psychology,
                      color: Colors.purple,
                      onTap: () => _selectSector('psychology', '/psychology-dashboard'),
                      isSelected: _selectedSector == 'psychology',
                    ),
                    _buildSectorCard(
                      title: 'Veterinarianism',
                      icon: Icons.pets,
                      color: Colors.green,
                      onTap: () => _selectSector('veterinary', '/veterinary-dashboard'),
                      isSelected: _selectedSector == 'veterinary',
                    ),
                    _buildSectorCard(
                      title: 'Spor',
                      icon: Icons.fitness_center,
                      color: Colors.orange,
                      onTap: () => _selectSector('sports', '/sports-dashboard'),
                      isSelected: _selectedSector == 'sports',
                    ),
                    _buildSectorCard(
                      title: 'Klinik',
                      icon: Icons.local_hospital,
                      color: Colors.red,
                      onTap: () => _selectSector('clinic', '/clinic-dashboard'),
                      isSelected: _selectedSector == 'clinic',
                    ),
                    _buildSectorCard(
                      title: 'Eğitim',
                      icon: Icons.school,
                      color: Colors.indigo,
                      onTap: () => _selectSector('education', '/education-dashboard'),
                      isSelected: _selectedSector == 'education',
                    ),
                    _buildSectorCard(
                      title: 'Emlak',
                      icon: Icons.home,
                      color: Colors.brown,
                      onTap: () => _selectSector('real_estate', '/real-estate-dashboard'),
                      isSelected: _selectedSector == 'real_estate',
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSectorCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: color,
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: AppConstants.paddingSmall),
                  const CircularProgressIndicator(strokeWidth: 2),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}