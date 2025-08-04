import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/education_student_model.dart';

class AddEditStudentPage extends StatefulWidget {
  final EducationStudent? student;

  const AddEditStudentPage({super.key, this.student});

  @override
  State<AddEditStudentPage> createState() => _AddEditStudentPageState();
}

class _AddEditStudentPageState extends State<AddEditStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  final _telefonController = TextEditingController();
  final _emailController = TextEditingController();
  final _veliAdiController = TextEditingController();
  final _veliTelefonController = TextEditingController();
  final _adresController = TextEditingController();
  final _sinifController = TextEditingController();
  final _ozelNotlarController = TextEditingController();

  DateTime _dogumTarihi =
      DateTime.now().subtract(const Duration(days: 365 * 10));
  DateTime _kayitTarihi = DateTime.now();
  String _seviye = 'Başlangıç';
  String _status = 'active';
  bool _vipOgrenci = false;
  bool _bursluOgrenci = false;
  double? _indirimOrani;
  List<String> _kayitliDersler = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final student = widget.student!;
    _adController.text = student.ad;
    _soyadController.text = student.soyad;
    _telefonController.text = student.telefon;
    _emailController.text = student.email ?? '';
    _veliAdiController.text = student.veliAdi ?? '';
    _veliTelefonController.text = student.veliTelefon ?? '';
    _adresController.text = student.adres ?? '';
    _sinifController.text = student.sinif;
    _ozelNotlarController.text = student.ozelNotlar ?? '';
    _dogumTarihi = student.dogumTarihi;
    _kayitTarihi = student.kayitTarihi;
    _seviye = student.seviye;
    _status = student.status;
    _vipOgrenci = student.vipOgrenci;
    _bursluOgrenci = student.bursluOgrenci;
    _indirimOrani = student.indirimOrani;
    _kayitliDersler = List<String>.from(student.kayitliDersler);
  }

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _veliAdiController.dispose();
    _veliTelefonController.dispose();
    _adresController.dispose();
    _sinifController.dispose();
    _ozelNotlarController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDogumTarihi) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDogumTarihi ? _dogumTarihi : _kayitTarihi,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      setState(() {
        if (isDogumTarihi) {
          _dogumTarihi = picked;
        } else {
          _kayitTarihi = picked;
        }
      });
    }
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı bulunamadı');

      final studentData = EducationStudent(
        id: widget.student?.id ?? '',
        userId: user.uid,
        createdAt: widget.student?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        ad: _adController.text.trim(),
        soyad: _soyadController.text.trim(),
        telefon: _telefonController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        veliAdi: _veliAdiController.text.trim().isEmpty
            ? null
            : _veliAdiController.text.trim(),
        veliTelefon: _veliTelefonController.text.trim().isEmpty
            ? null
            : _veliTelefonController.text.trim(),
        dogumTarihi: _dogumTarihi,
        adres: _adresController.text.trim().isEmpty
            ? null
            : _adresController.text.trim(),
        sinif: _sinifController.text.trim(),
        seviye: _seviye,
        kayitliDersler: _kayitliDersler,
        status: _status,
        vipOgrenci: _vipOgrenci,
        bursluOgrenci: _bursluOgrenci,
        indirimOrani: _indirimOrani,
        ozelNotlar: _ozelNotlarController.text.trim().isEmpty
            ? null
            : _ozelNotlarController.text.trim(),
        kayitTarihi: _kayitTarihi,
      );

      if (widget.student == null) {
        // Yeni öğrenci ekleme
        await FirebaseFirestore.instance
            .collection(AppConstants.educationStudentsCollection)
            .add(studentData.toMap());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Öğrenci başarıyla eklendi'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        }
      } else {
        // Mevcut öğrenciyi güncelleme
        await FirebaseFirestore.instance
            .collection(AppConstants.educationStudentsCollection)
            .doc(widget.student!.id)
            .update(studentData.toMap());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Öğrenci başarıyla güncellendi'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title:
            Text(widget.student == null ? 'Yeni Öğrenci' : 'Öğrenci Düzenle'),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveStudent,
              child: const Text(
                'KAYDET',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kişisel Bilgiler
              _buildSectionHeader('Kişisel Bilgiler', Icons.person),
              _buildPersonalInfoSection(),

              const SizedBox(height: 24),

              // İletişim Bilgileri
              _buildSectionHeader('İletişim Bilgileri', Icons.contact_phone),
              _buildContactInfoSection(),

              const SizedBox(height: 24),

              // Eğitim Bilgileri
              _buildSectionHeader('Eğitim Bilgileri', Icons.school),
              _buildEducationInfoSection(),

              const SizedBox(height: 24),

              // Özel Durumlar
              _buildSectionHeader('Özel Durumlar', Icons.star),
              _buildSpecialStatusSection(),

              const SizedBox(height: 24),

              // Notlar
              _buildSectionHeader('Notlar', Icons.note),
              _buildNotesSection(),

              const SizedBox(height: 32),

              // Kaydet Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.student == null
                              ? 'ÖĞRENCİ EKLE'
                              : 'DEĞİŞİKLİKLERİ KAYDET',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF667EEA),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _adController,
                    decoration: const InputDecoration(
                      labelText: 'Ad *',
                      hintText: 'Öğrencinin adı',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ad gerekli';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _soyadController,
                    decoration: const InputDecoration(
                      labelText: 'Soyad *',
                      hintText: 'Öğrencinin soyadı',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Soyad gerekli';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Doğum Tarihi
            InkWell(
              onTap: () => _selectDate(context, true),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cake, color: Colors.grey),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Doğum Tarihi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${_dogumTarihi.day}/${_dogumTarihi.month}/${_dogumTarihi.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Kayıt Tarihi
            InkWell(
              onTap: () => _selectDate(context, false),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kayıt Tarihi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${_kayitTarihi.day}/${_kayitTarihi.month}/${_kayitTarihi.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _telefonController,
              decoration: const InputDecoration(
                labelText: 'Telefon *',
                hintText: '0555 123 45 67',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Telefon gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                hintText: 'ornek@email.com',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _veliAdiController,
                    decoration: const InputDecoration(
                      labelText: 'Veli Adı',
                      hintText: 'Veli ad soyad',
                      prefixIcon: Icon(Icons.family_restroom),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _veliTelefonController,
                    decoration: const InputDecoration(
                      labelText: 'Veli Telefon',
                      hintText: '0555 123 45 67',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _adresController,
              decoration: const InputDecoration(
                labelText: 'Adres',
                hintText: 'Tam adres bilgisi',
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sinifController,
                    decoration: const InputDecoration(
                      labelText: 'Sınıf *',
                      hintText: '4. Sınıf, Lise 1 vs.',
                      prefixIcon: Icon(Icons.class_),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Sınıf gerekli';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _seviye,
                    decoration: const InputDecoration(
                      labelText: 'Seviye',
                      prefixIcon: Icon(Icons.star),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Başlangıç', child: Text('Başlangıç')),
                      DropdownMenuItem(value: 'Orta', child: Text('Orta')),
                      DropdownMenuItem(value: 'İleri', child: Text('İleri')),
                      DropdownMenuItem(value: 'A1', child: Text('A1')),
                      DropdownMenuItem(value: 'A2', child: Text('A2')),
                      DropdownMenuItem(value: 'B1', child: Text('B1')),
                      DropdownMenuItem(value: 'B2', child: Text('B2')),
                      DropdownMenuItem(value: 'C1', child: Text('C1')),
                      DropdownMenuItem(value: 'C2', child: Text('C2')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _seviye = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Durum',
                prefixIcon: Icon(Icons.info),
              ),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Aktif')),
                DropdownMenuItem(value: 'inactive', child: Text('Pasif')),
                DropdownMenuItem(value: 'graduated', child: Text('Mezun')),
                DropdownMenuItem(value: 'dropped', child: Text('Ayrıldı')),
              ],
              onChanged: (value) {
                setState(() {
                  _status = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialStatusSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CheckboxListTile(
              title: const Text('VIP Öğrenci'),
              subtitle: const Text('Özel hizmet alan öğrenci'),
              value: _vipOgrenci,
              onChanged: (value) {
                setState(() {
                  _vipOgrenci = value ?? false;
                });
              },
              activeColor: const Color(0xFF667EEA),
            ),
            CheckboxListTile(
              title: const Text('Burslu Öğrenci'),
              subtitle: const Text('İndirimli ücret ödeyen öğrenci'),
              value: _bursluOgrenci,
              onChanged: (value) {
                setState(() {
                  _bursluOgrenci = value ?? false;
                });
              },
              activeColor: const Color(0xFF667EEA),
            ),
            if (_bursluOgrenci) ...[
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'İndirim Oranı (%)',
                  hintText: '20',
                  prefixIcon: Icon(Icons.percent),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _indirimOrani = double.tryParse(value);
                },
                initialValue: _indirimOrani?.toString(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _ozelNotlarController,
          decoration: const InputDecoration(
            labelText: 'Özel Notlar',
            hintText: 'Öğrenci hakkında özel notlar...',
            prefixIcon: Icon(Icons.note_add),
            border: InputBorder.none,
          ),
          maxLines: 4,
        ),
      ),
    );
  }
}
