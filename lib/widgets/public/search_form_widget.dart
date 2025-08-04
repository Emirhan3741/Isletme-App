import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// 🔍 Arama/Rezervasyon Form Widget
/// Ana sayfada hizmet arama ve randevu alma formu
class SearchFormWidget extends StatefulWidget {
  const SearchFormWidget({Key? key}) : super(key: key);

  @override
  State<SearchFormWidget> createState() => _SearchFormWidgetState();
}

class _SearchFormWidgetState extends State<SearchFormWidget> {
  // Form değişkenleri
  String? _selectedCategory;
  String? _selectedLocation;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Hizmet kategorileri
  final List<Map<String, dynamic>> _categories = [
    {'value': 'temizlik', 'label': '🧹 Ev Temizliği', 'icon': Icons.cleaning_services},
    {'value': 'tamir', 'label': '🔧 Tamir/Onarım', 'icon': Icons.build},
    {'value': 'tasima', 'label': '📦 Taşıma/Nakliye', 'icon': Icons.local_shipping},
    {'value': 'bahce', 'label': '🌱 Bahçe Bakımı', 'icon': Icons.grass},
    {'value': 'boyama', 'label': '🎨 Boyama/Badana', 'icon': Icons.format_paint},
    {'value': 'elektrik', 'label': '⚡ Elektrik İşleri', 'icon': Icons.electrical_services},
    {'value': 'su', 'label': '🚰 Su Tesisatı', 'icon': Icons.plumbing},
    {'value': 'klima', 'label': '❄️ Klima Servisi', 'icon': Icons.ac_unit},
  ];

  // Şehirler
  final List<String> _cities = [
    'İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Antalya', 'Adana', 'Konya', 'Gaziantep',
    'Şanlıurfa', 'Kocaeli', 'Mersin', 'Diyarbakır', 'Hatay', 'Manisa', 'Kayseri'
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 40,
      ),
      color: Colors.grey.shade50,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              // 📋 Form başlığı
              Text(
                'Hemen Rezervasyon Yapın',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Size en uygun uzmanı bulalım ve randevunuzu ayarlayalım',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // 📝 Form
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isMobile 
                    ? _buildMobileForm(context)
                    : _buildDesktopForm(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🖥️ Desktop Form Layout
  Widget _buildDesktopForm(BuildContext context) {
    return Column(
      children: [
        // İlk satır - Kategori ve Konum
        Row(
          children: [
            Expanded(child: _buildCategoryDropdown()),
            const SizedBox(width: 16),
            Expanded(child: _buildLocationDropdown()),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // İkinci satır - Tarih, Saat ve Buton
        Row(
          children: [
            Expanded(flex: 2, child: _buildDatePicker()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildTimePicker()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildSearchButton()),
          ],
        ),
      ],
    );
  }

  /// 📱 Mobile Form Layout
  Widget _buildMobileForm(BuildContext context) {
    return Column(
      children: [
        _buildCategoryDropdown(),
        const SizedBox(height: 16),
        _buildLocationDropdown(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDatePicker()),
            const SizedBox(width: 12),
            Expanded(child: _buildTimePicker()),
          ],
        ),
        const SizedBox(height: 20),
        _buildSearchButton(),
      ],
    );
  }

  /// 🏷️ Kategori Dropdown
  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Hizmet Kategorisi',
        prefixIcon: Icon(
          _selectedCategory != null 
              ? _categories.firstWhere((c) => c['value'] == _selectedCategory)['icon']
              : Icons.category,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: _categories.map((category) {
        return DropdownMenuItem<String>(
          value: category['value'],
          child: Row(
            children: [
              Icon(category['icon'], size: 20),
              const SizedBox(width: 8),
              Text(category['label']),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen bir kategori seçin';
        }
        return null;
      },
    );
  }

  /// 📍 Lokasyon Dropdown
  Widget _buildLocationDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedLocation,
      decoration: InputDecoration(
        labelText: 'Şehir/İlçe',
        prefixIcon: const Icon(Icons.location_on),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: _cities.map((city) {
        return DropdownMenuItem<String>(
          value: city,
          child: Text(city),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedLocation = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen bir şehir seçin';
        }
        return null;
      },
    );
  }

  /// 📅 Tarih Seçici
  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDate != null
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : 'Tarih Seçin',
                style: TextStyle(
                  color: _selectedDate != null ? Colors.black87 : Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⏰ Saat Seçici
  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedTime != null
                    ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                    : 'Saat Seçin',
                style: TextStyle(
                  color: _selectedTime != null ? Colors.black87 : Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔍 Arama Butonu
  Widget _buildSearchButton() {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _onSearchPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: const Icon(Icons.search, size: 20),
        label: const Text(
          'Fiyatları Göster / Randevu Al',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 📅 Tarih seçme
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppConstants.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// ⏰ Saat seçme
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppConstants.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  /// 🔍 Arama butonuna basıldığında
  void _onSearchPressed() {
    // Form validasyonu
    if (_selectedCategory == null) {
      _showSnackBar('Lütfen bir hizmet kategorisi seçin');
      return;
    }
    
    if (_selectedLocation == null) {
      _showSnackBar('Lütfen bir şehir seçin');
      return;
    }

    // Rezervasyon verilerini hazırla
    final reservationData = {
      'category': _selectedCategory,
      'location': _selectedLocation,
      'date': _selectedDate,
      'time': _selectedTime,
      'timestamp': DateTime.now(),
    };

    // Rezervasyon sayfasına yönlendir
    Navigator.pushNamed(
      context,
      '/public/reservation',
      arguments: reservationData,
    );
  }

  /// 📢 SnackBar göster
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}