import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/veterinary_patient_model.dart';
import '../../widgets/file_upload_widget.dart';
import '../../utils/feedback_utils.dart';
import '../../utils/validation_utils.dart';

class AddEditPatientPage extends StatefulWidget {
  final VeterinaryPatient? patient;

  const AddEditPatientPage({super.key, this.patient});

  @override
  State<AddEditPatientPage> createState() => _AddEditPatientPageState();
}

class _AddEditPatientPageState extends State<AddEditPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _hayvanAdiController = TextEditingController();
  final _chipNumarasiController = TextEditingController();
  final _agirlikController = TextEditingController();
  final _renkController = TextEditingController();
  final _ozelNotlarController = TextEditingController();
  final _sahipAdiController = TextEditingController();
  final _sahipSoyadiController = TextEditingController();
  final _sahipTelefonController = TextEditingController();
  final _sahipEmailController = TextEditingController();
  final _sahipAdresController = TextEditingController();
  final _alerjiController = TextEditingController();
  final _kronikHastalikController = TextEditingController();
  final _ilacController = TextEditingController();
  final _veterinerNotuController = TextEditingController();

  String _selectedHayvanTuru = 'köpek';
  String _selectedHayvanCinsi = '';
  String _selectedCinsiyet = 'erkek';
  String _selectedSaglikDurumu = 'sağlıklı';
  DateTime? _dogumTarihi;
  DateTime? _kisirlastirmaTarihi;
  bool _kisirlastirilmis = false;
  bool _isLoading = false;

  // Belge yükleme durumları
  bool _hasMedicalRecords = false;
  bool _hasVaccineRecords = false;
  bool _hasXrayImages = false;

  final List<Map<String, dynamic>> _hayvanTurleri = [
    {
      'value': 'köpek',
      'label': 'Köpek',
      'cinsler': [
        'Golden Retriever',
        'Labrador',
        'Poodle',
        'Husky',
        'Bulldog',
        'Chihuahua',
        'Melez'
      ]
    },
    {
      'value': 'kedi',
      'label': 'Kedi',
      'cinsler': [
        'Persian',
        'British Shorthair',
        'Siamese',
        'Maine Coon',
        'Scottish Fold',
        'Tekir'
      ]
    },
    {
      'value': 'kuş',
      'label': 'Kuş',
      'cinsler': [
        'Muhabbet Kuşu',
        'Kanarya',
        'Sultan Papağanı',
        'Cennet Papağanı',
        'Java Finch'
      ]
    },
    {
      'value': 'tavşan',
      'label': 'Tavşan',
      'cinsler': ['Angora', 'Lop', 'Dutch', 'Mini Rex', 'Lionhead']
    },
    {
      'value': 'hamster',
      'label': 'Hamster',
      'cinsler': ['Suriye', 'Roborovski', 'Campbell', 'Chinese']
    },
    {
      'value': 'diğer',
      'label': 'Diğer',
      'cinsler': ['Belirtilmemiş']
    },
  ];

  @override
  void initState() {
    super.initState();
    _setSelectedCins();
    _loadPatientData();
  }

  void _setSelectedCins() {
    final turleri =
        _hayvanTurleri.firstWhere((t) => t['value'] == _selectedHayvanTuru);
    _selectedHayvanCinsi = turleri['cinsler'][0];
  }

  void _loadPatientData() {
    if (widget.patient != null) {
      final patient = widget.patient!;
      _hayvanAdiController.text = patient.hayvanAdi;
      _chipNumarasiController.text = patient.chipNumarasi ?? '';
      _agirlikController.text = patient.agirlik.toString();
      _renkController.text = patient.renk;
      _ozelNotlarController.text = patient.ozelNotlar ?? '';
      _sahipAdiController.text = patient.sahipAdi;
      _sahipSoyadiController.text = patient.sahipSoyadi;
      _sahipTelefonController.text = patient.sahipTelefon;
      _sahipEmailController.text = patient.sahipEmail ?? '';
      _sahipAdresController.text = patient.sahipAdres ?? '';
      _alerjiController.text = patient.alerjiler ?? '';
      _kronikHastalikController.text = patient.kronikHastalik ?? '';
      _ilacController.text = patient.kullandigiIlaclar ?? '';
      _veterinerNotuController.text = patient.veterinerNotu ?? '';

      _selectedHayvanTuru = patient.hayvanTuru;
      _selectedHayvanCinsi = patient.hayvanCinsi;
      _selectedCinsiyet = patient.cinsiyet;
      _selectedSaglikDurumu = patient.saglikDurumu;
      _dogumTarihi = patient.dogumTarihi;
      _kisirlastirmaTarihi = patient.kisirlastirmaTarihi;
      _kisirlastirilmis = patient.kisirlastirilmis;
    }
  }

  @override
  void dispose() {
    _hayvanAdiController.dispose();
    _chipNumarasiController.dispose();
    _agirlikController.dispose();
    _renkController.dispose();
    _ozelNotlarController.dispose();
    _sahipAdiController.dispose();
    _sahipSoyadiController.dispose();
    _sahipTelefonController.dispose();
    _sahipEmailController.dispose();
    _sahipAdresController.dispose();
    _alerjiController.dispose();
    _kronikHastalikController.dispose();
    _ilacController.dispose();
    _veterinerNotuController.dispose();
    super.dispose();
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final patientData = {
        'kullaniciId': user.uid,
        'hayvanAdi': _hayvanAdiController.text.trim(),
        'hayvanTuru': _selectedHayvanTuru,
        'hayvanCinsi': _selectedHayvanCinsi,
        'chipNumarasi': _chipNumarasiController.text.trim().isNotEmpty
            ? _chipNumarasiController.text.trim()
            : null,
        'dogumTarihi':
            _dogumTarihi != null ? Timestamp.fromDate(_dogumTarihi!) : null,
        'cinsiyet': _selectedCinsiyet,
        'agirlik': double.parse(_agirlikController.text),
        'renk': _renkController.text.trim(),
        'ozelNotlar': _ozelNotlarController.text.trim().isNotEmpty
            ? _ozelNotlarController.text.trim()
            : null,
        'sahipAdi': _sahipAdiController.text.trim(),
        'sahipSoyadi': _sahipSoyadiController.text.trim(),
        'sahipTelefon': _sahipTelefonController.text.trim(),
        'sahipEmail': _sahipEmailController.text.trim().isNotEmpty
            ? _sahipEmailController.text.trim()
            : null,
        'sahipAdres': _sahipAdresController.text.trim().isNotEmpty
            ? _sahipAdresController.text.trim()
            : null,
        'saglikDurumu': _selectedSaglikDurumu,
        'alerjiler': _alerjiController.text.trim().isNotEmpty
            ? _alerjiController.text.trim()
            : null,
        'kronikHastalik': _kronikHastalikController.text.trim().isNotEmpty
            ? _kronikHastalikController.text.trim()
            : null,
        'kullandigiIlaclar': _ilacController.text.trim().isNotEmpty
            ? _ilacController.text.trim()
            : null,
        'kisirlastirilmis': _kisirlastirilmis,
        'kisirlastirmaTarihi': _kisirlastirilmis && _kisirlastirmaTarihi != null
            ? Timestamp.fromDate(_kisirlastirmaTarihi!)
            : null,
        'aktif': true,
        'veterinerNotu': _veterinerNotuController.text.trim().isNotEmpty
            ? _veterinerNotuController.text.trim()
            : null,
        'guncellemeTarihi': Timestamp.now(),
      };

      if (widget.patient == null) {
        // Yeni hasta ekleme
        patientData['kayitTarihi'] = Timestamp.now();
        await FirebaseFirestore.instance
            .collection('veterinary_patients')
            .add(patientData);

        if (mounted) {
          FeedbackUtils.showSuccess(context, 'Hasta başarıyla eklendi');
          Navigator.pop(context, true);
        }
      } else {
        // Mevcut hasta güncelleme
        await FirebaseFirestore.instance
            .collection('veterinary_patients')
            .doc(widget.patient!.id)
            .update(patientData);

        if (mounted) {
          FeedbackUtils.showSuccess(context, 'Hasta bilgileri güncellendi');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(context, 'Hata: $e');
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.patient == null ? 'Yeni Hasta Ekle' : 'Hasta Düzenle',
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _savePatient,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(widget.patient == null ? 'Kaydet' : 'Güncelle'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF059669),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Hayvan Bilgileri', Icons.pets),
              const SizedBox(height: 16),
              _buildHayvanBilgileriSection(),
              const SizedBox(height: 32),
              _buildSectionHeader('Sahip Bilgileri', Icons.person),
              const SizedBox(height: 16),
              _buildSahipBilgileriSection(),
              const SizedBox(height: 32),
              _buildSectionHeader('Sağlık Bilgileri', Icons.medical_services),
              const SizedBox(height: 16),
              _buildSaglikBilgileriSection(),
              const SizedBox(height: 32),
              _buildSectionHeader('Notlar', Icons.note),
              const SizedBox(height: 16),
              _buildNotlarSection(),
              const SizedBox(height: 32),
              _buildSectionHeader('Tıbbi Belgeler', Icons.folder_special),
              const SizedBox(height: 16),
              _buildTibbiBelgelerSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black.withValues(alpha: 0.05),
          ),
          child: Icon(icon, color: const Color(0xFF059669), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildHayvanBilgileriSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _hayvanAdiController,
            decoration: const InputDecoration(
              labelText: 'Hayvan Adı *',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                ValidationUtils.validateRequired(value, 'Hayvan adı'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedHayvanTuru,
                  decoration: const InputDecoration(
                    labelText: 'Hayvan Türü *',
                    border: OutlineInputBorder(),
                  ),
                  items: _hayvanTurleri.map((tur) {
                    return DropdownMenuItem<String>(
                      value: tur['value'],
                      child: Text(tur['label']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedHayvanTuru = value!;
                      _setSelectedCins();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedHayvanCinsi,
                  decoration: const InputDecoration(
                    labelText: 'Cins *',
                    border: OutlineInputBorder(),
                  ),
                  items: _hayvanTurleri
                      .firstWhere(
                          (t) => t['value'] == _selectedHayvanTuru)['cinsler']
                      .map<DropdownMenuItem<String>>((cins) {
                    return DropdownMenuItem<String>(
                      value: cins,
                      child: Text(cins),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedHayvanCinsi = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCinsiyet,
                  decoration: const InputDecoration(
                    labelText: 'Cinsiyet *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'erkek', child: Text('Erkek')),
                    DropdownMenuItem(value: 'dişi', child: Text('Dişi')),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedCinsiyet = value!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildDatePicker('Doğum Tarihi', _dogumTarihi,
                      (date) => setState(() => _dogumTarihi = date))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _agirlikController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ağırlık (kg) *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      ValidationUtils.validatePositiveNumber(value, 'Ağırlık'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _renkController,
                  decoration: const InputDecoration(
                    labelText: 'Renk *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      ValidationUtils.validateRequired(value, 'Renk'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _chipNumarasiController,
            decoration: const InputDecoration(
              labelText: 'Mikroçip Numarası',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ozelNotlarController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Özel Notlar',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSahipBilgileriSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _sahipAdiController,
                  decoration: const InputDecoration(
                    labelText: 'Sahip Adı *',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidationUtils.validateName,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _sahipSoyadiController,
                  decoration: const InputDecoration(
                    labelText: 'Sahip Soyadı *',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidationUtils.validateName,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _sahipTelefonController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefon *',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidationUtils.validatePhone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _sahipEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      return ValidationUtils.validateEmail(value);
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _sahipAdresController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Adres',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaglikBilgileriSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedSaglikDurumu,
            decoration: const InputDecoration(
              labelText: 'Sağlık Durumu *',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'sağlıklı', child: Text('Sağlıklı')),
              DropdownMenuItem(
                  value: 'kronik_hasta', child: Text('Kronik Hasta')),
              DropdownMenuItem(
                  value: 'tedavi_altında', child: Text('Tedavi Altında')),
            ],
            onChanged: (value) =>
                setState(() => _selectedSaglikDurumu = value!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _alerjiController,
            decoration: const InputDecoration(
              labelText: 'Alerjiler',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _kronikHastalikController,
            decoration: const InputDecoration(
              labelText: 'Kronik Hastalıklar',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ilacController,
            decoration: const InputDecoration(
              labelText: 'Kullandığı İlaçlar',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _kisirlastirilmis,
                onChanged: (value) => setState(() {
                  _kisirlastirilmis = value!;
                  if (!_kisirlastirilmis) {
                    _kisirlastirmaTarihi = null;
                  }
                }),
              ),
              const Text('Kısırlaştırılmış'),
              const Spacer(),
              if (_kisirlastirilmis)
                Expanded(
                  flex: 2,
                  child: _buildDatePicker(
                      'Kısırlaştırma Tarihi',
                      _kisirlastirmaTarihi,
                      (date) => setState(() => _kisirlastirmaTarihi = date)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotlarSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _veterinerNotuController,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Veteriner Notları',
          hintText: 'Hasta hakkında özel notlar...',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildTibbiBelgelerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hastanın tıbbi kayıtlarını, aşı belgelerini ve röntgen görüntülerini yükleyebilirsiniz.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          // Tıbbi Kayıtlar
          Text(
            'Tıbbi Kayıtlar',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          FileUploadWidget(
            onUploadComplete: (result) {
              setState(() {
                _hasMedicalRecords = true;
              });
            },
            module: 'veterinary',
            collection: 'medical_records',
            additionalData: {
              'patientId': widget.patient?.id ?? 'new',
              'patientName': _hayvanAdiController.text.trim(),
              'ownerName':
                  '${_sahipAdiController.text.trim()} ${_sahipSoyadiController.text.trim()}',
              'documentType': 'medical_records',
            },
            allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
            onUploadSuccess: () {
              setState(() {
                _hasMedicalRecords = true;
              });
            },
            onUploadError: (error) {
              setState(() {
                _hasMedicalRecords = false;
              });
            },
            isRequired: false,
            showPreview: true,
          ),

          const SizedBox(height: 20),

          // Aşı Kayıtları
          Text(
            'Aşı Kayıtları',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          FileUploadWidget(
            onUploadComplete: (result) {},
            module: 'veterinary',
            collection: 'vaccine_records',
            additionalData: {
              'patientId': widget.patient?.id ?? 'new',
              'patientName': _hayvanAdiController.text.trim(),
              'animalType': _selectedHayvanTuru,
              'documentType': 'vaccine_records',
            },
            allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
            onUploadSuccess: () {
              setState(() {
                _hasVaccineRecords = true;
              });
            },
            onUploadError: (error) {
              setState(() {
                _hasVaccineRecords = false;
              });
            },
            isRequired: false,
            showPreview: true,
          ),

          const SizedBox(height: 20),

          // Röntgen/Görüntüleme
          Text(
            'Röntgen ve Görüntüleme',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          FileUploadWidget(
            onUploadComplete: (result) {},
            module: 'veterinary',
            collection: 'xray_images',
            additionalData: {
              'patientId': widget.patient?.id ?? 'new',
              'patientName': _hayvanAdiController.text.trim(),
              'animalType': _selectedHayvanTuru,
              'documentType': 'xray_images',
            },
            allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'dcm'],
            onUploadSuccess: () {
              setState(() {
                _hasXrayImages = true;
              });
            },
            onUploadError: (error) {
              setState(() {
                _hasXrayImages = false;
              });
            },
            isRequired: false,
            showPreview: true,
          ),

          // Yüklenen Belge Özeti
          if (_hasMedicalRecords || _hasVaccineRecords || _hasXrayImages) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF059669).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: const Color(0xFF059669),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tıbbi belgeler başarıyla yüklendi. Kaydetmek için "Kaydet" butonuna basın.',
                      style: TextStyle(
                        color: const Color(0xFF059669),
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
    );
  }

  Widget _buildDatePicker(String label, DateTime? selectedDate,
      Function(DateTime?) onDateSelected) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          selectedDate != null
              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
              : 'Tarih seçin',
          style: TextStyle(
            color: selectedDate != null ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
