import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/lawyer_client_model.dart' hide DosyaDurumuConstants;
import '../../core/models/lawyer_client_model.dart' as LawyerModels
    show DosyaDurumuConstants;
import '../../core/models/case_model.dart';

class AddEditClientPage extends StatefulWidget {
  final LawyerClientModel? client;

  const AddEditClientPage({super.key, this.client});

  @override
  State<AddEditClientPage> createState() => _AddEditClientPageState();
}

class _AddEditClientPageState extends State<AddEditClientPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool get isEditing => widget.client != null;

  // Form Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _tcNoController = TextEditingController();
  final _pasaportNoController = TextEditingController();
  final _dosyaNoController = TextEditingController();
  final _mahkemeBilgisiController = TextEditingController();
  final _notesController = TextEditingController();
  final _meslekController = TextEditingController();
  final _dogumYeriController = TextEditingController();
  final _babaAdiController = TextEditingController();
  final _anneAdiController = TextEditingController();

  // Form values
  String _selectedGender = 'other';
  String _selectedDavaYazisi = DavaTuruConstants.hukuk;
  String _selectedDosyaDurumu = LawyerModels.DosyaDurumuConstants.devamEdiyor;
  String _selectedMedeniDurum = 'bekar';
  DateTime? _selectedBirthDate;
  DateTime? _selectedDavaBaslangicTarihi;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadClientData();
    } else {
      // Yeni müvekkil için otomatik dosya no oluştur
      _generateDosyaNo();
    }
  }

  void _loadClientData() {
    final client = widget.client!;
    _nameController.text = client.name;
    _phoneController.text = client.phone;
    _emailController.text = client.email ?? '';
    _addressController.text = client.address ?? '';
    _tcNoController.text = client.tcNo ?? '';
    _pasaportNoController.text = client.pasaportNo ?? '';
    _dosyaNoController.text = client.dosyaNo ?? '';
    _mahkemeBilgisiController.text = client.mahkemeBilgisi ?? '';
    _notesController.text = client.notes ?? '';
    _meslekController.text = client.meslek ?? '';
    _dogumYeriController.text = client.dogumYeri ?? '';
    _babaAdiController.text = client.babaAdi ?? '';
    _anneAdiController.text = client.anneAdi ?? '';

    _selectedGender = client.gender;

    // ✅ Dava yazısını normalize et - DavaTuruConstants listesinde varsa kullan, yoksa default
    String normalizedDavaYazisi = DavaTuruConstants.hukuk;
    if (client.davaYazisi != null) {
      // Veritabanından gelen değeri constants listesinde ara
      final matchingTur = DavaTuruConstants.tumTurler.firstWhere(
        (tur) =>
            tur == client.davaYazisi ||
            DavaTuruConstants.getTurDisplayName(tur) == client.davaYazisi,
        orElse: () => DavaTuruConstants.hukuk,
      );
      normalizedDavaYazisi = matchingTur;
    }
    _selectedDavaYazisi = normalizedDavaYazisi;

    _selectedDosyaDurumu = client.dosyaDurumu;
    _selectedMedeniDurum = client.medeniDurum ?? 'bekar';
    _selectedBirthDate = client.birthDate;
    _selectedDavaBaslangicTarihi = client.davaBaslangicTarihi;
  }

  void _generateDosyaNo() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final randomNumber = (DateTime.now().millisecondsSinceEpoch % 1000)
        .toString()
        .padLeft(3, '0');
    _dosyaNoController.text = 'DVA-$year$month-$randomNumber';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _tcNoController.dispose();
    _pasaportNoController.dispose();
    _dosyaNoController.dispose();
    _mahkemeBilgisiController.dispose();
    _notesController.dispose();
    _meslekController.dispose();
    _dogumYeriController.dispose();
    _babaAdiController.dispose();
    _anneAdiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(isEditing ? 'Müvekkil Düzenle' : 'Müvekkil Ekle'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveClient,
              child: Text(
                'Kaydet',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Temel Bilgiler
              _buildSectionCard(
                'Temel Bilgiler',
                Icons.person,
                [
                  _buildTextFormField(
                    controller: _nameController,
                    label: 'Ad Soyad *',
                    hint: 'Müvekkil adını ve soyadını giriniz',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ad soyad zorunludur';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _phoneController,
                          label: 'Telefon *',
                          hint: '0532 123 45 67',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Telefon zorunludur';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildDropdownField<String>(
                          value: _selectedGender,
                          label: 'Cinsiyet',
                          items: const [
                            DropdownMenuItem(
                                value: 'erkek', child: Text('Erkek')),
                            DropdownMenuItem(
                                value: 'kadın', child: Text('Kadın')),
                            DropdownMenuItem(
                                value: 'other',
                                child: Text('Belirtmek İstemiyorum')),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedGender = value!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildTextFormField(
                    controller: _emailController,
                    label: 'E-posta',
                    hint: 'ornek@email.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildTextFormField(
                    controller: _addressController,
                    label: 'Adres',
                    hint: 'Tam adres bilgisi',
                    maxLines: 2,
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Kimlik Bilgileri
              _buildSectionCard(
                'Kimlik Bilgileri',
                Icons.badge,
                [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _tcNoController,
                          label: 'TC Kimlik No',
                          hint: '12345678901',
                          keyboardType: TextInputType.number,
                          maxLength: 11,
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                value.length != 11) {
                              return 'TC No 11 haneli olmalıdır';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _pasaportNoController,
                          label: 'Pasaport No',
                          hint: 'U1234567',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Doğum Tarihi',
                          selectedDate: _selectedBirthDate,
                          onDateSelected: (date) =>
                              setState(() => _selectedBirthDate = date),
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _dogumYeriController,
                          label: 'Doğum Yeri',
                          hint: 'İstanbul',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _babaAdiController,
                          label: 'Baba Adı',
                          hint: 'Mehmet',
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _anneAdiController,
                          label: 'Anne Adı',
                          hint: 'Fatma',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _meslekController,
                          label: 'Meslek',
                          hint: 'Mühendis',
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildDropdownField<String>(
                          value: _selectedMedeniDurum,
                          label: 'Medeni Durum',
                          items: const [
                            DropdownMenuItem(
                                value: 'bekar', child: Text('Bekar')),
                            DropdownMenuItem(
                                value: 'evli', child: Text('Evli')),
                            DropdownMenuItem(
                                value: 'bosanmis', child: Text('Boşanmış')),
                            DropdownMenuItem(value: 'dul', child: Text('Dul')),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedMedeniDurum = value!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Dava Bilgileri
              _buildSectionCard(
                'Dava Bilgileri',
                Icons.gavel,
                [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _dosyaNoController,
                          label: 'Dosya No',
                          hint: 'DVA-24XX-XXX',
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildDropdownField<String>(
                          value: _selectedDavaYazisi,
                          label: 'Dava Türü',
                          items: DavaTuruConstants.tumTurler
                              .map((tur) => DropdownMenuItem(
                                    value: tur,
                                    child: Text(
                                        DavaTuruConstants.getTurDisplayName(
                                            tur)),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedDavaYazisi = value!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Dava Başlangıç Tarihi',
                          selectedDate: _selectedDavaBaslangicTarihi,
                          onDateSelected: (date) => setState(
                              () => _selectedDavaBaslangicTarihi = date),
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildDropdownField<String>(
                          value: _selectedDosyaDurumu,
                          label: 'Dosya Durumu',
                          items: LawyerModels.DosyaDurumuConstants.tumDurumlar
                              .map((durum) => DropdownMenuItem(
                                    value: durum,
                                    child: Text(
                                        LawyerModels.DosyaDurumuConstants
                                            .getDurumDisplayName(durum)),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedDosyaDurumu = value!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildTextFormField(
                    controller: _mahkemeBilgisiController,
                    label: 'Mahkeme Bilgisi',
                    hint: 'İstanbul 1. Asliye Hukuk Mahkemesi',
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Notlar
              _buildSectionCard(
                'Notlar',
                Icons.note,
                [
                  _buildTextFormField(
                    controller: _notesController,
                    label: 'Notlar',
                    hint: 'Müvekkil hakkında önemli notlar...',
                    maxLines: 4,
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingXLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int? maxLines,
    int? maxLength,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      maxLength: maxLength,
      readOnly: readOnly,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: readOnly ? const Color(0xFFF3F4F6) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T value,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    final safeValue = items.any((item) => item.value == value) ? value : null;

    return DropdownButtonFormField<T>(
      value: safeValue,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required void Function(DateTime?) onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(1920),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingMedium + 2,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedDate != null
                        ? '${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}'
                        : 'Tarih seçin',
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedDate != null
                          ? Colors.black
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.calendar_today,
              color: Color(0xFF6B7280),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'Kullanıcı oturumu bulunamadı';
      }

      final now = DateTime.now();
      final clientData = LawyerClientModel(
        id: isEditing
            ? widget.client!.id
            : FirebaseFirestore.instance.collection('temp').doc().id,
        userId: user.uid,
        createdAt: isEditing ? widget.client!.createdAt : now,
        updatedAt: now,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        gender: _selectedGender,
        birthDate: _selectedBirthDate,
        sector: 'lawyer',
        tcNo: _tcNoController.text.trim().isEmpty
            ? null
            : _tcNoController.text.trim(),
        pasaportNo: _pasaportNoController.text.trim().isEmpty
            ? null
            : _pasaportNoController.text.trim(),
        dosyaNo: _dosyaNoController.text.trim().isEmpty
            ? null
            : _dosyaNoController.text.trim(),
        davaYazisi: _selectedDavaYazisi,
        mahkemeBilgisi: _mahkemeBilgisiController.text.trim().isEmpty
            ? null
            : _mahkemeBilgisiController.text.trim(),
        dosyaDurumu: _selectedDosyaDurumu,
        davaBaslangicTarihi: _selectedDavaBaslangicTarihi,
        meslek: _meslekController.text.trim().isEmpty
            ? null
            : _meslekController.text.trim(),
        dogumYeri: _dogumYeriController.text.trim().isEmpty
            ? null
            : _dogumYeriController.text.trim(),
        babaAdi: _babaAdiController.text.trim().isEmpty
            ? null
            : _babaAdiController.text.trim(),
        anneAdi: _anneAdiController.text.trim().isEmpty
            ? null
            : _anneAdiController.text.trim(),
        medeniDurum: _selectedMedeniDurum,
      );

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection(AppConstants.lawyerClientsCollection)
            .doc(widget.client!.id)
            .update(clientData.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection(AppConstants.lawyerClientsCollection)
            .doc(clientData.id)
            .set(clientData.toMap());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? 'Müvekkil başarıyla güncellendi'
                : 'Müvekkil başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
