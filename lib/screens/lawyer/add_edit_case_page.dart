import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/case_model.dart';
import '../../core/models/lawyer_client_model.dart';
import '../../core/widgets/common_widgets.dart';
import '../../widgets/file_upload_widget.dart';

class AddEditCasePage extends StatefulWidget {
  final CaseModel? caseModel;
  final List<LawyerClientModel> clients;

  const AddEditCasePage({super.key, this.caseModel, required this.clients});

  @override
  State<AddEditCasePage> createState() => _AddEditCasePageState();
}

class _AddEditCasePageState extends State<AddEditCasePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool get isEditing => widget.caseModel != null;

  // Form Controllers
  final _davaAdiController = TextEditingController();
  final _davaKoduController = TextEditingController();
  final _mahkemeAdiController = TextEditingController();
  final _esasNoController = TextEditingController();
  final _karanNoController = TextEditingController();
  final _davacilarController = TextEditingController();
  final _davalilarController = TextEditingController();
  final _davaKonusuController = TextEditingController();
  final _davaciVekiliController = TextEditingController();
  final _davaliVekiliController = TextEditingController();
  final _hakimController = TextEditingController();
  final _savciController = TextEditingController();
  final _davaSerahiController = TextEditingController();
  final _sonucController = TextEditingController();
  final _notlarController = TextEditingController();
  final _davaUcretiController = TextEditingController();
  final _odenecekHarcController = TextEditingController();
  final _odenenHarcController = TextEditingController();
  final _vekaleUcretiController = TextEditingController();
  final _odenenVekaleUcretiController = TextEditingController();

  // Form values
  String? _selectedClientId;
  String _selectedDavaTuru = DavaTuruConstants.hukuk;
  String _selectedDavaDurumu = DavaDurumuConstants.hazirlik;
  DateTime? _selectedDavaBaslangicTarihi;
  DateTime? _selectedDavaBitisTarihi;

  // Belge yükleme durumları
  bool _hasCaseDocuments = false;
  bool _hasContractDocuments = false;
  bool _hasEvidenceDocuments = false;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadCaseData();
    } else {
      _generateDavaKodu();
    }
  }

  void _loadCaseData() {
    final caseModel = widget.caseModel!;
    _davaAdiController.text = caseModel.davaAdi;
    _davaKoduController.text = caseModel.davaKodu;
    _mahkemeAdiController.text = caseModel.mahkemeAdi;
    _esasNoController.text = caseModel.esasNo;
    _karanNoController.text = caseModel.karanNo;
    _davacilarController.text = caseModel.davacilar ?? '';
    _davalilarController.text = caseModel.davalilar ?? '';
    _davaKonusuController.text = caseModel.davaKonusu ?? '';
    _davaciVekiliController.text = caseModel.davaciVekili ?? '';
    _davaliVekiliController.text = caseModel.davaliVekili ?? '';
    _hakimController.text = caseModel.hakim ?? '';
    _savciController.text = caseModel.savci ?? '';
    _davaSerahiController.text = caseModel.davaSerhi ?? '';
    _sonucController.text = caseModel.sonuc ?? '';
    _notlarController.text = caseModel.notlar ?? '';
    _davaUcretiController.text = caseModel.davaUcreti?.toString() ?? '';
    _odenecekHarcController.text = caseModel.odenecekHarc?.toString() ?? '';
    _odenenHarcController.text = caseModel.odenenHarc?.toString() ?? '';
    _vekaleUcretiController.text = caseModel.vekaleUcreti?.toString() ?? '';
    _odenenVekaleUcretiController.text =
        caseModel.odenenVekaleUcreti?.toString() ?? '';

    _selectedClientId = caseModel.clientId;
    _selectedDavaTuru = caseModel.davaTuru;
    _selectedDavaDurumu = caseModel.davaDurumu;
    _selectedDavaBaslangicTarihi = caseModel.davaBaslangicTarihi;
    _selectedDavaBitisTarihi = caseModel.davaBitisTarihi;
  }

  void _generateDavaKodu() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final randomNumber = (DateTime.now().millisecondsSinceEpoch % 1000)
        .toString()
        .padLeft(3, '0');
    _davaKoduController.text = 'DVA-$year$month-$randomNumber';
  }

  @override
  void dispose() {
    _davaAdiController.dispose();
    _davaKoduController.dispose();
    _mahkemeAdiController.dispose();
    _esasNoController.dispose();
    _karanNoController.dispose();
    _davacilarController.dispose();
    _davalilarController.dispose();
    _davaKonusuController.dispose();
    _davaciVekiliController.dispose();
    _davaliVekiliController.dispose();
    _hakimController.dispose();
    _savciController.dispose();
    _davaSerahiController.dispose();
    _sonucController.dispose();
    _notlarController.dispose();
    _davaUcretiController.dispose();
    _odenecekHarcController.dispose();
    _odenenHarcController.dispose();
    _vekaleUcretiController.dispose();
    _odenenVekaleUcretiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(isEditing ? 'Dava Düzenle' : 'Dava Ekle'),
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
              onPressed: _saveCase,
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
              // Temel Dava Bilgileri
              _buildSectionCard(
                'Temel Dava Bilgileri',
                Icons.gavel,
                [
                  _buildTextFormField(
                    controller: _davaAdiController,
                    label: 'Dava Başlığı *',
                    hint: 'Dava dosyasının adı',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Dava başlığı zorunludur';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _davaKoduController,
                          label: 'Dava Kodu',
                          hint: 'DVA-24XX-XXX',
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildDropdownField<String?>(
                          value: _selectedClientId,
                          label: 'Müvekkil *',
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Müvekkil seçin'),
                            ),
                            ...widget.clients
                                .map((client) => DropdownMenuItem<String?>(
                                      value: client.id,
                                      child: Text(client.name),
                                    ))
                                .toList(),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedClientId = value),
                          validator: (value) {
                            if (value == null) {
                              return 'Müvekkil seçimi zorunludur';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField<String>(
                          value: _selectedDavaTuru,
                          label: 'Dava Türü',
                          items: DavaTuruConstants.tumTurler
                              .map<DropdownMenuItem<String>>(
                                  (tur) => DropdownMenuItem(
                                        value: tur,
                                        child: Text(
                                            DavaTuruConstants.getTurDisplayName(
                                                tur)),
                                      ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedDavaTuru = value!),
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildDropdownField<String>(
                          value: _selectedDavaDurumu,
                          label: 'Dava Durumu',
                          items: DavaDurumuConstants.tumDurumlar
                              .map((durum) => DropdownMenuItem(
                                    value: durum,
                                    child: Text(
                                        DavaDurumuConstants.getDurumDisplayName(
                                            durum)),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedDavaDurumu = value!),
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
                        child: _buildDateField(
                          label: 'Dava Bitiş Tarihi',
                          selectedDate: _selectedDavaBitisTarihi,
                          onDateSelected: (date) =>
                              setState(() => _selectedDavaBitisTarihi = date),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Mahkeme Bilgileri
              _buildSectionCard(
                'Mahkeme Bilgileri',
                Icons.account_balance,
                [
                  _buildTextFormField(
                    controller: _mahkemeAdiController,
                    label: 'Mahkeme Adı *',
                    hint: 'İstanbul 1. Asliye Hukuk Mahkemesi',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Mahkeme adı zorunludur';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _esasNoController,
                          label: 'Esas No',
                          hint: '2024/123',
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _karanNoController,
                          label: 'Karar No',
                          hint: '2024/456',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _hakimController,
                          label: 'Hakim',
                          hint: 'Hakim adı',
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _savciController,
                          label: 'Savcı',
                          hint: 'Savcı adı',
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Taraflar
              _buildSectionCard(
                'Dava Tarafları',
                Icons.people,
                [
                  _buildTextFormField(
                    controller: _davacilarController,
                    label: 'Davacılar',
                    hint: 'Davacı taraf bilgileri',
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildTextFormField(
                    controller: _davalilarController,
                    label: 'Davalılar',
                    hint: 'Davalı taraf bilgileri',
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _davaciVekiliController,
                          label: 'Davacı Vekili',
                          hint: 'Davacı vekili',
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _davaliVekiliController,
                          label: 'Davalı Vekili',
                          hint: 'Davalı vekili',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildTextFormField(
                    controller: _davaKonusuController,
                    label: 'Dava Konusu',
                    hint: 'Dava konusu detayı',
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Mali Bilgiler
              _buildSectionCard(
                'Mali Bilgiler',
                Icons.attach_money,
                [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _vekaleUcretiController,
                          label: 'Vekalet Ücreti (₺)',
                          hint: '5000',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _odenenVekaleUcretiController,
                          label: 'Ödenen Vekalet (₺)',
                          hint: '2500',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _davaUcretiController,
                          label: 'Dava Ücreti (₺)',
                          hint: '1000',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: Container(), // Boş alan
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _odenecekHarcController,
                          label: 'Ödenecek Harç (₺)',
                          hint: '500',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _odenenHarcController,
                          label: 'Ödenen Harç (₺)',
                          hint: '500',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Sonuç ve Notlar
              _buildSectionCard(
                'Sonuç ve Notlar',
                Icons.note,
                [
                  _buildTextFormField(
                    controller: _davaSerahiController,
                    label: 'Dava Şerhi',
                    hint: 'Dava ile ilgili özel notlar',
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildTextFormField(
                    controller: _sonucController,
                    label: 'Sonuç',
                    hint: 'Dava sonucu (varsa)',
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildTextFormField(
                    controller: _notlarController,
                    label: 'Genel Notlar',
                    hint: 'Dava hakkında genel notlar...',
                    maxLines: 4,
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Dava Belgeleri
              _buildSectionCard(
                'Dava Belgeleri',
                Icons.folder,
                [
                  Text(
                    'Dava ile ilgili belgeleri yükleyerek dosyanızı tamamlayabilirsiniz.',
                    style: TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Dava Dosyaları
                  Text(
                    'Dava Dosyaları',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  FileUploadWidget(
                    onUploadComplete: (result) {},
                    module: 'lawyer',
                    collection: 'case_documents',
                    additionalData: {
                      'caseId': widget.caseModel?.id ?? 'new',
                      'caseTitle': _davaAdiController.text.trim(),
                      'caseCode': _davaKoduController.text.trim(),
                      'documentType': 'case_files',
                    },
                    allowedExtensions: [
                      'pdf',
                      'doc',
                      'docx',
                      'jpg',
                      'jpeg',
                      'png'
                    ],
                    onUploadSuccess: () {
                      setState(() {
                        _hasCaseDocuments = true;
                      });
                    },
                    onUploadError: (error) {
                      setState(() {
                        _hasCaseDocuments = false;
                      });
                    },
                    isRequired: false,
                    showPreview: true,
                  ),

                  const SizedBox(height: AppConstants.paddingMedium),

                  // Sözleşme Belgeleri
                  Text(
                    'Sözleşme Belgeleri',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  FileUploadWidget(
                    onUploadComplete: (result) {},
                    module: 'lawyer',
                    collection: 'contract_documents',
                    additionalData: {
                      'caseId': widget.caseModel?.id ?? 'new',
                      'caseTitle': _davaAdiController.text.trim(),
                      'clientId': _selectedClientId ?? '',
                      'documentType': 'contracts',
                    },
                    allowedExtensions: ['pdf', 'doc', 'docx'],
                    onUploadSuccess: () {
                      setState(() {
                        _hasContractDocuments = true;
                      });
                    },
                    onUploadError: (error) {
                      setState(() {
                        _hasContractDocuments = false;
                      });
                    },
                    isRequired: false,
                    showPreview: true,
                  ),

                  const SizedBox(height: AppConstants.paddingMedium),

                  // Delil Belgeleri
                  Text(
                    'Delil ve Ek Belgeler',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  FileUploadWidget(
                    onUploadComplete: (result) {},
                    module: 'lawyer',
                    collection: 'evidence_documents',
                    additionalData: {
                      'caseId': widget.caseModel?.id ?? 'new',
                      'caseTitle': _davaAdiController.text.trim(),
                      'documentType': 'evidence',
                    },
                    allowedExtensions: [
                      'pdf',
                      'doc',
                      'docx',
                      'jpg',
                      'jpeg',
                      'png',
                      'mp4',
                      'mp3'
                    ],
                    onUploadSuccess: () {
                      setState(() {
                        _hasEvidenceDocuments = true;
                      });
                    },
                    onUploadError: (error) {
                      setState(() {
                        _hasEvidenceDocuments = false;
                      });
                    },
                    isRequired: false,
                    showPreview: true,
                  ),

                  // Yüklenen Belge Özeti
                  if (_hasCaseDocuments ||
                      _hasContractDocuments ||
                      _hasEvidenceDocuments) ...[
                    const SizedBox(height: AppConstants.paddingMedium),
                    Container(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      decoration: BoxDecoration(
                        color: AppConstants.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              AppConstants.successColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppConstants.successColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Belgeler başarıyla yüklendi. Kaydetmek için "Kaydet" butonuna basın.',
                              style: TextStyle(
                                color: AppConstants.successColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      readOnly: readOnly,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: readOnly ? const Color(0xFFF3F4F6) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
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
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
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
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
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
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
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

  Future<void> _saveCase() async {
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
      final caseData = CaseModel(
        id: isEditing
            ? widget.caseModel!.id
            : FirebaseFirestore.instance.collection('temp').doc().id,
        userId: user.uid,
        createdAt: isEditing ? widget.caseModel!.createdAt : now,
        updatedAt: now,
        clientId: _selectedClientId!,
        davaAdi: _davaAdiController.text.trim(),
        davaKodu: _davaKoduController.text.trim(),
        davaTuru: _selectedDavaTuru,
        mahkemeAdi: _mahkemeAdiController.text.trim(),
        esasNo: _esasNoController.text.trim(),
        karanNo: _karanNoController.text.trim(),
        davaBaslangicTarihi: _selectedDavaBaslangicTarihi,
        davaBitisTarihi: _selectedDavaBitisTarihi,
        davaDurumu: _selectedDavaDurumu,
        davacilar: _davacilarController.text.trim().isEmpty
            ? null
            : _davacilarController.text.trim(),
        davalilar: _davalilarController.text.trim().isEmpty
            ? null
            : _davalilarController.text.trim(),
        davaKonusu: _davaKonusuController.text.trim().isEmpty
            ? null
            : _davaKonusuController.text.trim(),
        davaciVekili: _davaciVekiliController.text.trim().isEmpty
            ? null
            : _davaciVekiliController.text.trim(),
        davaliVekili: _davaliVekiliController.text.trim().isEmpty
            ? null
            : _davaliVekiliController.text.trim(),
        hakim: _hakimController.text.trim().isEmpty
            ? null
            : _hakimController.text.trim(),
        savci: _savciController.text.trim().isEmpty
            ? null
            : _savciController.text.trim(),
        davaSerhi: _davaSerahiController.text.trim().isEmpty
            ? null
            : _davaSerahiController.text.trim(),
        sonuc: _sonucController.text.trim().isEmpty
            ? null
            : _sonucController.text.trim(),
        notlar: _notlarController.text.trim().isEmpty
            ? null
            : _notlarController.text.trim(),
        davaUcreti: _davaUcretiController.text.trim().isEmpty
            ? null
            : double.tryParse(_davaUcretiController.text.trim()),
        odenecekHarc: _odenecekHarcController.text.trim().isEmpty
            ? null
            : double.tryParse(_odenecekHarcController.text.trim()),
        odenenHarc: _odenenHarcController.text.trim().isEmpty
            ? null
            : double.tryParse(_odenenHarcController.text.trim()),
        vekaleUcreti: _vekaleUcretiController.text.trim().isEmpty
            ? null
            : double.tryParse(_vekaleUcretiController.text.trim()),
        odenenVekaleUcreti: _odenenVekaleUcretiController.text.trim().isEmpty
            ? null
            : double.tryParse(_odenenVekaleUcretiController.text.trim()),
      );

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection(AppConstants.lawyerCasesCollection)
            .doc(widget.caseModel!.id)
            .update(caseData.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection(AppConstants.lawyerCasesCollection)
            .doc(caseData.id)
            .set(caseData.toMap());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? 'Dava başarıyla güncellendi'
                : 'Dava başarıyla eklendi'),
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
