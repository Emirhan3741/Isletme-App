import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/user_profile_model.dart';

class ClinicProfilePage extends StatefulWidget {
  const ClinicProfilePage({super.key});

  @override
  State<ClinicProfilePage> createState() => _ClinicProfilePageState();
}

class _ClinicProfilePageState extends State<ClinicProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  UserProfile? _userProfile;

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _aboutController = TextEditingController();

  String? _selectedSpecialization;
  String? _selectedTitle;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _clinicNameController.dispose();
    _addressController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.userProfilesCollection)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        _userProfile =
            UserProfile.fromMap(doc.docs.first.data(), doc.docs.first.id);
        _populateForm();
      } else {
        // Create new profile
        _userProfile = UserProfile(
          id: '',
          userId: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _populateForm();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Profil yükleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil yüklenirken hata oluştu')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateForm() {
    if (_userProfile != null) {
      _nameController.text = _userProfile!.name;
      _emailController.text = _userProfile!.email;
      _phoneController.text = _userProfile!.phone ?? '';
      _clinicNameController.text = _userProfile!.clinicName ?? '';
      _addressController.text = _userProfile!.address ?? '';
      _aboutController.text = _userProfile!.about ?? '';
      _selectedSpecialization = _userProfile!.specialization;
      _selectedTitle = _userProfile!.title;
      _profileImageUrl = _userProfile!.profileImageUrl;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final updatedProfile = UserProfile(
        id: _userProfile?.id ?? '',
        userId: user.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        specialization: _selectedSpecialization,
        title: _selectedTitle,
        clinicName: _clinicNameController.text.trim().isEmpty
            ? null
            : _clinicNameController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        about: _aboutController.text.trim().isEmpty
            ? null
            : _aboutController.text.trim(),
        profileImageUrl: _profileImageUrl,
        createdAt: _userProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_userProfile?.id.isEmpty ?? true) {
        // Create new profile
        await FirebaseFirestore.instance
            .collection(AppConstants.userProfilesCollection)
            .add(updatedProfile.toMap());
      } else {
        // Update existing profile
        await FirebaseFirestore.instance
            .collection(AppConstants.userProfilesCollection)
            .doc(_userProfile!.id)
            .update(updatedProfile.toMap());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil başarıyla güncellendi')),
      );

      _loadUserProfile(); // Reload profile
    } catch (e) {
      if (kDebugMode) debugPrint('Profil kaydetme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil kaydedilirken hata oluştu')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Firebase Storage'a yükle
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${FirebaseAuth.instance.currentUser!.uid}.jpg');

        await storageRef.putData(file.bytes!);
        final imageUrl = await storageRef.getDownloadURL();

        setState(() {
          _profileImageUrl = imageUrl;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Resim yükleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resim yüklenirken hata oluştu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Hesabım',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              _buildProfileImageSection(),

              const SizedBox(height: AppConstants.paddingXLarge),

              // Personal Information
              _buildSectionCard(
                'Kişisel Bilgiler',
                Icons.person,
                [
                  Row(
                    children: [
                      if (_selectedTitle != null) ...[
                        Expanded(
                          flex: 1,
                          child: _buildDropdownField(
                            'Unvan',
                            _selectedTitle,
                            SpecializationOptions.titles,
                            (value) => setState(() => _selectedTitle = value),
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingMedium),
                      ],
                      Expanded(
                        flex: 3,
                        child: _buildTextField(
                          'Ad Soyad',
                          _nameController,
                          Icons.person,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Ad soyad gereklidir';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildTextField(
                    'E-posta',
                    _emailController,
                    Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'E-posta gereklidir';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value!)) {
                        return 'Geçerli bir e-posta adresi girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildTextField(
                    'Telefon',
                    _phoneController,
                    Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Professional Information
              _buildSectionCard(
                'Meslek Bilgileri',
                Icons.work,
                [
                  _buildDropdownField(
                    'Unvan',
                    _selectedTitle,
                    SpecializationOptions.titles,
                    (value) => setState(() => _selectedTitle = value),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildDropdownField(
                    'Branş',
                    _selectedSpecialization,
                    SpecializationOptions.specializations,
                    (value) => setState(() => _selectedSpecialization = value),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Clinic Information
              _buildSectionCard(
                'Klinik Bilgileri',
                Icons.local_hospital,
                [
                  _buildTextField(
                    'Klinik/Hastane Adı',
                    _clinicNameController,
                    Icons.local_hospital,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildTextField(
                    'Adres',
                    _addressController,
                    Icons.location_on,
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // About Section
              _buildSectionCard(
                'Hakkımda',
                Icons.info,
                [
                  _buildTextField(
                    'Hakkımda',
                    _aboutController,
                    Icons.info,
                    maxLines: 4,
                    hint: 'Kendiniz hakkında kısa bilgi...',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              image: _profileImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_profileImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _profileImageUrl == null
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey.shade400,
                  )
                : null,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          OutlinedButton.icon(
            onPressed: _pickProfileImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Fotoğraf Değiştir'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppConstants.primaryColor, size: 20),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
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
          const SizedBox(height: AppConstants.paddingLarge),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: BorderSide(color: AppConstants.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: BorderSide(color: AppConstants.primaryColor),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: BorderSide(color: AppConstants.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: BorderSide(color: AppConstants.primaryColor),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
          .toList(),
    );
  }
}
