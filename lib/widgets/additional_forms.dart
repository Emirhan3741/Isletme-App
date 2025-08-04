import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constants.dart';
import 'modern_forms.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// ==================== SERVICE FORM ====================

class BeautyServiceForm extends StatefulWidget {
  final String? serviceId;
  final Map<String, dynamic>? initialData;

  const BeautyServiceForm({
    super.key,
    this.serviceId,
    this.initialData,
  });

  @override
  State<BeautyServiceForm> createState() => _BeautyServiceFormState();
}

class _BeautyServiceFormState extends State<BeautyServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Saç';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    final data = widget.initialData!;
    _nameController.text = data['name'] ?? '';
    _priceController.text = (data['price'] ?? 0).toString();
    _durationController.text = (data['duration'] ?? 0).toString();
    _descriptionController.text = data['description'] ?? '';
    _selectedCategory = data['category'] ?? 'Saç';
    _isActive = data['isActive'] ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3366FF).withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                    border: Border.all(
                      color: const Color(0xFF3366FF),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.content_cut,
                    color: Color(0xFF3366FF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.serviceId == null ? 'Yeni Hizmet' : 'Hizmet Düzenle',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ModernTextField(
              controller: _nameController,
              label: 'Hizmet Adı',
              hint: 'Saç kesimi, manikür vb.',
              icon: Icons.content_cut,
              validator: (value) =>
                  value?.isEmpty == true ? 'Hizmet adı gerekli' : null,
            ),
            ModernDropdown<String>(
              value: _selectedCategory,
              label: 'Kategori',
              icon: Icons.category,
              items: const [
                DropdownMenuItem(value: 'Saç', child: Text('Saç')),
                DropdownMenuItem(value: 'Manikür', child: Text('Manikür')),
                DropdownMenuItem(value: 'Pedikür', child: Text('Pedikür')),
                DropdownMenuItem(
                    value: 'Cilt Bakımı', child: Text('Cilt Bakımı')),
                DropdownMenuItem(value: 'Makyaj', child: Text('Makyaj')),
                DropdownMenuItem(value: 'Masaj', child: Text('Masaj')),
                DropdownMenuItem(value: 'Epilasyon', child: Text('Epilasyon')),
                DropdownMenuItem(value: 'Diğer', child: Text('Diğer')),
              ],
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            ModernTextField(
              controller: _priceController,
              label: 'Fiyat (₺)',
              hint: '0',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
              validator: (value) =>
                  value?.isEmpty == true ? 'Fiyat gerekli' : null,
            ),
            ModernTextField(
              controller: _durationController,
              label: 'Süre (dakika)',
              hint: '60',
              icon: Icons.timer,
              keyboardType: TextInputType.number,
              validator: (value) =>
                  value?.isEmpty == true ? 'Süre gerekli' : null,
            ),
            ModernTextField(
              controller: _descriptionController,
              label: 'Açıklama',
              hint: 'Hizmet detayları',
              icon: Icons.description,
              maxLines: 3,
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Icon(Icons.toggle_on, color: Color(0xFF3366FF)),
                  const SizedBox(width: 12),
                  const Text(
                    'Aktif Hizmet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    activeColor: const Color(0xFF3366FF),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ModernButton(
                    text: 'İptal',
                    isPrimary: false,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ModernButton(
                    text: widget.serviceId == null ? 'Hizmet Ekle' : 'Güncelle',
                    icon: Icons.save,
                    isLoading: _isLoading,
                    onPressed: _saveService,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw 'Kullanıcı girişi gerekli';

      final serviceData = {
        'userId': userId,
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'duration': int.tryParse(_durationController.text) ?? 0,
        'description': _descriptionController.text.trim(),
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.serviceId == null) {
        serviceData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('services').add(serviceData);
      } else {
        await _firestore
            .collection('services')
            .doc(widget.serviceId)
            .update(serviceData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.serviceId == null
                ? 'Hizmet eklendi'
                : 'Hizmet güncellendi'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

// ==================== EMPLOYEE FORM ====================

class BeautyEmployeeForm extends StatefulWidget {
  final String? employeeId;
  final Map<String, dynamic>? initialData;

  const BeautyEmployeeForm({
    super.key,
    this.employeeId,
    this.initialData,
  });

  @override
  State<BeautyEmployeeForm> createState() => _BeautyEmployeeFormState();
}

class _BeautyEmployeeFormState extends State<BeautyEmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _salaryController = TextEditingController();
  final _skillsController = TextEditingController();

  String _selectedPosition = 'Kuaför';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    final data = widget.initialData!;
    _nameController.text = data['name'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _emailController.text = data['email'] ?? '';
    _salaryController.text = (data['salary'] ?? 0).toString();
    _skillsController.text = data['skills'] ?? '';
    _selectedPosition = data['position'] ?? 'Kuaför';
    _isActive = data['isActive'] ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA78BFA).withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                    border: Border.all(
                      color: const Color(0xFFA78BFA),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.badge,
                    color: Color(0xFFA78BFA),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.employeeId == null
                      ? 'Yeni Çalışan'
                      : 'Çalışan Düzenle',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ModernTextField(
              controller: _nameController,
              label: 'Ad Soyad',
              hint: 'Çalışan adını girin',
              icon: Icons.person,
              validator: (value) =>
                  value?.isEmpty == true ? 'Ad Soyad gerekli' : null,
            ),
            ModernTextField(
              controller: _phoneController,
              label: 'Telefon',
              hint: '05XX XXX XX XX',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value?.isEmpty == true ? 'Telefon gerekli' : null,
            ),
            ModernTextField(
              controller: _emailController,
              label: 'E-posta',
              hint: 'ornek@email.com',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            ModernDropdown<String>(
              value: _selectedPosition,
              label: 'Pozisyon',
              icon: Icons.work,
              items: const [
                DropdownMenuItem(value: 'Kuaför', child: Text('Kuaför')),
                DropdownMenuItem(
                    value: 'Estetisyen', child: Text('Estetisyen')),
                DropdownMenuItem(
                    value: 'Nail Artist', child: Text('Nail Artist')),
                DropdownMenuItem(value: 'Masöz', child: Text('Masöz')),
                DropdownMenuItem(
                    value: 'Resepsiyon', child: Text('Resepsiyon')),
                DropdownMenuItem(value: 'Temizlik', child: Text('Temizlik')),
                DropdownMenuItem(value: 'Diğer', child: Text('Diğer')),
              ],
              onChanged: (value) => setState(() => _selectedPosition = value!),
            ),
            ModernTextField(
              controller: _salaryController,
              label: 'Maaş (₺)',
              hint: '0',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
            ),
            ModernTextField(
              controller: _skillsController,
              label: 'Yetenekler',
              hint: 'Saç kesimi, boyama, makyaj vb.',
              icon: Icons.star,
              maxLines: 2,
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Icon(Icons.toggle_on, color: Color(0xFF3366FF)),
                  const SizedBox(width: 12),
                  const Text(
                    'Aktif Çalışan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    activeColor: const Color(0xFF3366FF),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ModernButton(
                    text: 'İptal',
                    isPrimary: false,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ModernButton(
                    text:
                        widget.employeeId == null ? 'Çalışan Ekle' : 'Güncelle',
                    icon: Icons.save,
                    isLoading: _isLoading,
                    onPressed: _saveEmployee,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw 'Kullanıcı girişi gerekli';

      final employeeData = {
        'userId': userId,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'position': _selectedPosition,
        'salary': double.tryParse(_salaryController.text) ?? 0.0,
        'skills': _skillsController.text.trim(),
        'isActive': _isActive,
        'totalAppointments': 0,
        'totalRevenue': 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.employeeId == null) {
        employeeData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('employees').add(employeeData);
      } else {
        await _firestore
            .collection('employees')
            .doc(widget.employeeId)
            .update(employeeData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.employeeId == null
                ? 'Çalışan eklendi'
                : 'Çalışan güncellendi'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _salaryController.dispose();
    _skillsController.dispose();
    super.dispose();
  }
}

// ==================== NOTE FORM ====================

class BeautyNoteForm extends StatefulWidget {
  final String? noteId;
  final Map<String, dynamic>? initialData;

  const BeautyNoteForm({
    super.key,
    this.noteId,
    this.initialData,
  });

  @override
  State<BeautyNoteForm> createState() => _BeautyNoteFormState();
}

class _BeautyNoteFormState extends State<BeautyNoteForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _selectedCategory = 'Genel';
  String _selectedPriority = 'Orta';
  DateTime? _reminderDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    final data = widget.initialData!;
    _titleController.text = data['title'] ?? '';
    _contentController.text = data['content'] ?? '';
    _selectedCategory = data['category'] ?? 'Genel';
    _selectedPriority = data['priority'] ?? 'Orta';
    if (data['reminderDate'] != null) {
      _reminderDate = (data['reminderDate'] as Timestamp).toDate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                    border: Border.all(
                      color: const Color(0xFFF59E0B),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.note,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.noteId == null ? 'Yeni Not' : 'Not Düzenle',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 24),

            ModernTextField(
              controller: _titleController,
              label: 'Başlık',
              hint: 'Not başlığı',
              icon: Icons.title,
              validator: (value) =>
                  value?.isEmpty == true ? 'Başlık gerekli' : null,
            ),

            ModernDropdown<String>(
              value: _selectedCategory,
              label: 'Kategori',
              icon: Icons.category,
              items: const [
                DropdownMenuItem(value: 'Genel', child: Text('Genel')),
                DropdownMenuItem(value: 'Müşteri', child: Text('Müşteri')),
                DropdownMenuItem(value: 'Randevu', child: Text('Randevu')),
                DropdownMenuItem(value: 'Malzeme', child: Text('Malzeme')),
                DropdownMenuItem(value: 'Finansal', child: Text('Finansal')),
                DropdownMenuItem(value: 'Çalışan', child: Text('Çalışan')),
                DropdownMenuItem(
                    value: 'Hatırlatma', child: Text('Hatırlatma')),
              ],
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),

            ModernDropdown<String>(
              value: _selectedPriority,
              label: 'Öncelik',
              icon: Icons.priority_high,
              items: const [
                DropdownMenuItem(value: 'Düşük', child: Text('Düşük')),
                DropdownMenuItem(value: 'Orta', child: Text('Orta')),
                DropdownMenuItem(value: 'Yüksek', child: Text('Yüksek')),
                DropdownMenuItem(value: 'Acil', child: Text('Acil')),
              ],
              onChanged: (value) => setState(() => _selectedPriority = value!),
            ),

            // Hatırlatma Tarihi Seçici
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _reminderDate ??
                        DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _reminderDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm, color: Color(0xFF3366FF)),
                      const SizedBox(width: 12),
                      Text(
                        _reminderDate == null
                            ? 'Hatırlatma Tarihi Seçin (İsteğe Bağlı)'
                            : '${_reminderDate!.day}/${_reminderDate!.month}/${_reminderDate!.year} ${_reminderDate!.hour.toString().padLeft(2, '0')}:${_reminderDate!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 16,
                          color: _reminderDate == null
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF111827),
                        ),
                      ),
                      if (_reminderDate != null) ...[
                        const Spacer(),
                        IconButton(
                          onPressed: () => setState(() => _reminderDate = null),
                          icon: const Icon(Icons.clear, size: 18),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            ModernTextField(
              controller: _contentController,
              label: 'İçerik',
              hint: 'Not içeriği',
              icon: Icons.description,
              maxLines: 5,
              validator: (value) =>
                  value?.isEmpty == true ? 'İçerik gerekli' : null,
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ModernButton(
                    text: 'İptal',
                    isPrimary: false,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ModernButton(
                    text: widget.noteId == null ? 'Not Ekle' : 'Güncelle',
                    icon: Icons.save,
                    isLoading: _isLoading,
                    onPressed: _saveNote,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw 'Kullanıcı girişi gerekli';

      final noteData = {
        'userId': userId,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'reminderDate':
            _reminderDate != null ? Timestamp.fromDate(_reminderDate!) : null,
        'isCompleted': false,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.noteId == null) {
        noteData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('notes').add(noteData);
      } else {
        await _firestore
            .collection('notes')
            .doc(widget.noteId)
            .update(noteData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(widget.noteId == null ? 'Not eklendi' : 'Not güncellendi'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
