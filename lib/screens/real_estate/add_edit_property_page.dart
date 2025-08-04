import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/property_model.dart';

class AddEditPropertyPage extends StatefulWidget {
  final Property? property;

  const AddEditPropertyPage({super.key, this.property});

  @override
  State<AddEditPropertyPage> createState() => _AddEditPropertyPageState();
}

class _AddEditPropertyPageState extends State<AddEditPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  final _baslikController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _fiyatController = TextEditingController();
  final _metrekareController = TextEditingController();
  final _odaSayisiController = TextEditingController();
  final _salonSayisiController = TextEditingController();
  final _banyoSayisiController = TextEditingController();
  final _balkonSayisiController = TextEditingController();
  final _katController = TextEditingController();
  final _binaYasiController = TextEditingController();
  final _sehirController = TextEditingController();
  final _ilceController = TextEditingController();
  final _mahalleController = TextEditingController();
  final _soakController = TextEditingController();
  final _adresController = TextEditingController();

  PropertyType _selectedType = PropertyType.satilik;
  PropertyCategory _selectedCategory = PropertyCategory.ev;
  PropertyStatus _selectedStatus = PropertyStatus.aktif;
  bool _asansorVar = false;
  bool _otoparkVar = false;
  bool _bahceVar = false;
  bool _esyaliMi = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.property != null) {
      _loadPropertyData();
    }
  }

  void _loadPropertyData() {
    final property = widget.property!;
    _baslikController.text = property.baslik;
    _aciklamaController.text = property.aciklama;
    _fiyatController.text = property.fiyat.toString();
    _metrekareController.text = property.metrekare.toString();
    _odaSayisiController.text = property.odaSayisi.toString();
    _salonSayisiController.text = property.salonSayisi.toString();
    _banyoSayisiController.text = property.banyoSayisi.toString();
    _balkonSayisiController.text = property.balkonSayisi.toString();
    _katController.text = property.kat.toString();
    _binaYasiController.text = property.binaYasi.toString();
    _sehirController.text = property.sehir;
    _ilceController.text = property.ilce;
    _mahalleController.text = property.mahalle;
    _soakController.text = property.sokak;
    _adresController.text = property.adres;

    _selectedType = property.tip;
    _selectedCategory = property.kategori;
    _selectedStatus = property.durum;
    _asansorVar = property.asansorVar;
    _otoparkVar = property.otoparkVar;
    _bahceVar = property.bahceVar;
    _esyaliMi = property.esyaliMi;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.home_work,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.property == null
                            ? 'Yeni İlan Ekle'
                            : 'İlan Düzenle',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Text(
                        'İlan bilgilerini doldurun',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Temel Bilgiler
                    _buildSectionTitle('Temel Bilgiler'),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _baslikController,
                            decoration: const InputDecoration(
                              labelText: 'İlan Başlığı *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) {
                                return 'İlan başlığı gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<PropertyType>(
                            value: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'İlan Türü *',
                              border: OutlineInputBorder(),
                            ),
                            items: PropertyType.values.map((type) {
                              return DropdownMenuItem<PropertyType>(
                                value: type,
                                child: Text(type == PropertyType.satilik
                                    ? 'Satılık'
                                    : 'Kiralık'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<PropertyCategory>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Kategori *',
                              border: OutlineInputBorder(),
                            ),
                            items: PropertyCategory.values.map((category) {
                              return DropdownMenuItem<PropertyCategory>(
                                value: category,
                                child: Text(_getCategoryText(category)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fiyatController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Fiyat (TL) *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) {
                                return 'Fiyat gerekli';
                              }
                              if (double.tryParse(value!) == null) {
                                return 'Geçerli bir fiyat girin';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _metrekareController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Metrekare *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) {
                                return 'Metrekare gerekli';
                              }
                              if (double.tryParse(value!) == null) {
                                return 'Geçerli bir metrekare girin';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<PropertyStatus>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Durum',
                              border: OutlineInputBorder(),
                            ),
                            items: PropertyStatus.values.map((status) {
                              return DropdownMenuItem<PropertyStatus>(
                                value: status,
                                child: Text(_getStatusText(status)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _aciklamaController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Özellikler
                    _buildSectionTitle('Özellikler'),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _odaSayisiController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Oda Sayısı',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _salonSayisiController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Salon Sayısı',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _banyoSayisiController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Banyo Sayısı',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _balkonSayisiController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Balkon Sayısı',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _katController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Kat',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: TextFormField(
                            controller: _binaYasiController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Bina Yaşı',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),

                        // Checkboxlar
                        Expanded(
                          flex: 2,
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _buildCheckbox(
                                  'Asansör',
                                  _asansorVar,
                                  (value) =>
                                      setState(() => _asansorVar = value)),
                              _buildCheckbox(
                                  'Otopark',
                                  _otoparkVar,
                                  (value) =>
                                      setState(() => _otoparkVar = value)),
                              _buildCheckbox('Bahçe', _bahceVar,
                                  (value) => setState(() => _bahceVar = value)),
                              _buildCheckbox('Eşyalı', _esyaliMi,
                                  (value) => setState(() => _esyaliMi = value)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Konum Bilgileri
                    _buildSectionTitle('Konum Bilgileri'),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sehirController,
                            decoration: const InputDecoration(
                              labelText: 'Şehir *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) {
                                return 'Şehir gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _ilceController,
                            decoration: const InputDecoration(
                              labelText: 'İlçe *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) {
                                return 'İlçe gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _mahalleController,
                            decoration: const InputDecoration(
                              labelText: 'Mahalle *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) {
                                return 'Mahalle gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _soakController,
                            decoration: const InputDecoration(
                              labelText: 'Sokak',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _adresController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Detaylı Adres *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Adres gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Kaydet Butonu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İptal'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveProperty,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(widget.property == null
                                  ? 'İlan Ekle'
                                  : 'Güncelle'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildCheckbox(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: (val) => onChanged(val ?? false),
          activeColor: Colors.orange,
        ),
        Text(label),
      ],
    );
  }

  String _getCategoryText(PropertyCategory category) {
    switch (category) {
      case PropertyCategory.ev:
        return 'Ev';
      case PropertyCategory.apart:
        return 'Apart';
      case PropertyCategory.villa:
        return 'Villa';
      case PropertyCategory.arsaDukkaniOfis:
        return 'Arsa/Dükkan/Ofis';
      case PropertyCategory.isyeri:
        return 'İşyeri';
      case PropertyCategory.arsa:
        return 'Arsa';
    }
  }

  String _getStatusText(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.aktif:
        return 'Aktif';
      case PropertyStatus.rezerve:
        return 'Rezerve';
      case PropertyStatus.satildi:
        return 'Satıldı';
      case PropertyStatus.kiralandi:
        return 'Kiralandı';
      case PropertyStatus.pasif:
        return 'Pasif';
    }
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final propertyData = {
        'userId': user.uid,
        'baslik': _baslikController.text.trim(),
        'aciklama': _aciklamaController.text.trim(),
        'tip': _selectedType.toString().split('.').last,
        'kategori': _selectedCategory.toString().split('.').last,
        'durum': _selectedStatus.toString().split('.').last,
        'fiyat': double.parse(_fiyatController.text),
        'parabirimi': 'TL',
        'metrekare': double.parse(_metrekareController.text),
        'odaSayisi': int.tryParse(_odaSayisiController.text) ?? 0,
        'salonSayisi': int.tryParse(_salonSayisiController.text) ?? 0,
        'banyoSayisi': int.tryParse(_banyoSayisiController.text) ?? 0,
        'balkonSayisi': int.tryParse(_balkonSayisiController.text) ?? 0,
        'kat': int.tryParse(_katController.text) ?? 0,
        'binaYasi': int.tryParse(_binaYasiController.text) ?? 0,
        'asansorVar': _asansorVar,
        'otoparkVar': _otoparkVar,
        'bahceVar': _bahceVar,
        'esyaliMi': _esyaliMi,
        'sehir': _sehirController.text.trim(),
        'ilce': _ilceController.text.trim(),
        'mahalle': _mahalleController.text.trim(),
        'sokak': _soakController.text.trim(),
        'adres': _adresController.text.trim(),
        'resimler': <String>[],
        'ozellikler': <String>[],
        'guncellenmeTarihi': Timestamp.now(),
        'isActive': true,
        'goruntulemeSayisi': 0,
        'ilgilenenMusteriler': <String>[],
      };

      if (widget.property == null) {
        propertyData['olusturmaTarihi'] = Timestamp.now();
        await FirebaseFirestore.instance
            .collection(AppConstants.realEstatePropertiesCollection)
            .add(propertyData);
      } else {
        await FirebaseFirestore.instance
            .collection(AppConstants.realEstatePropertiesCollection)
            .doc(widget.property!.id)
            .update(propertyData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.property == null
                ? 'İlan başarıyla eklendi'
                : 'İlan başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
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

  @override
  void dispose() {
    _baslikController.dispose();
    _aciklamaController.dispose();
    _fiyatController.dispose();
    _metrekareController.dispose();
    _odaSayisiController.dispose();
    _salonSayisiController.dispose();
    _banyoSayisiController.dispose();
    _balkonSayisiController.dispose();
    _katController.dispose();
    _binaYasiController.dispose();
    _sehirController.dispose();
    _ilceController.dispose();
    _mahalleController.dispose();
    _soakController.dispose();
    _adresController.dispose();
    super.dispose();
  }
}
