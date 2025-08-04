import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/sector_constants.dart';
import '../../services/auth_service.dart';

class SectorSelectionPage extends StatefulWidget {
  const SectorSelectionPage({super.key});

  @override
  State<SectorSelectionPage> createState() => _SectorSelectionPageState();
}

class _SectorSelectionPageState extends State<SectorSelectionPage> {
  final AuthService _authService = AuthService();
  String? _selectedSector;
  bool _isLoading = false;

  Future<void> _selectSector() async {
    if (_selectedSector == null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _authService.updateUserSector(_selectedSector!);
      
      // Sektör seçimi başarılı - dashboard'a yönlendir
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sektör seçilirken hata oluştu: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // Başlık
              Text(
                'Hoş Geldiniz! 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Hangi sektörde çalışıyorsunuz? Size uygun paneli hazırlayalım.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Sektör listesi
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: SectorConstants.allSectors.length,
                  itemBuilder: (context, index) {
                    final sector = SectorConstants.allSectors[index];
                    final displayName = SectorConstants.sectorDisplayNames[sector] ?? sector;
                    final isSelected = _selectedSector == sector;
                    
                    return _buildSectorCard(
                      sector: sector,
                      displayName: displayName,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedSector = sector;
                        });
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Devam butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedSector != null && !_isLoading ? _selectSector : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Devam Et',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectorCard({
    required String sector,
    required String displayName,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color panelColor = AppConstants.panelColors[sector] ?? AppConstants.primaryColor;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? panelColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(
            color: isSelected ? panelColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sektör ikonu
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: panelColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                _getSectorIcon(sector),
                size: 28,
                color: panelColor,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Sektör adı
            Text(
              displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? panelColor : AppConstants.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.check_circle,
                size: 16,
                color: panelColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getSectorIcon(String sector) {
    switch (sector) {
      case SectorConstants.beauty:
        return Icons.face_retouching_natural;
      case SectorConstants.psychology:
        return Icons.psychology;
      case SectorConstants.diet:
        return Icons.restaurant_menu;
      case SectorConstants.veterinary:
        return Icons.pets;
      case SectorConstants.lawyer:
        return Icons.gavel;
      case SectorConstants.education:
        return Icons.school;
      case SectorConstants.sports:
        return Icons.fitness_center;
      case SectorConstants.consulting:
        return Icons.business_center;
      case SectorConstants.realEstate:
        return Icons.home;
      default:
        return Icons.work;
    }
  }
}