import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/sports_member_model.dart';

class SportsMembersPage extends StatefulWidget {
  const SportsMembersPage({super.key});

  @override
  State<SportsMembersPage> createState() => _SportsMembersPageState();
}

class _SportsMembersPageState extends State<SportsMembersPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tümü';
  bool _isLoading = true;
  List<SportsMember> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.sportsMembersCollection)
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _members = snapshot.docs
            .map((doc) => SportsMember.fromMap(doc.data(), doc.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Üyeler yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  List<SportsMember> get _filteredMembers {
    var filtered = _members.where((member) {
      final matchesSearch = _searchQuery.isEmpty ||
          member.tamAd.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          member.telefon.contains(_searchQuery) ||
          member.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _selectedFilter == 'tümü' ||
          (_selectedFilter == 'aktif' && member.durum == 'aktif') ||
          (_selectedFilter == 'vip' && member.isVip) ||
          (_selectedFilter == member.durum);

      return matchesSearch && matchesFilter;
    }).toList();

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Arama ve Filtre Barı
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Row(
              children: [
                // Arama Kutusu
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Üye ara...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Filtre Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'tümü', child: Text('Tümü')),
                      DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                      DropdownMenuItem(value: 'pasif', child: Text('Pasif')),
                      DropdownMenuItem(
                          value: 'donduruldu', child: Text('Donduruldu')),
                      DropdownMenuItem(value: 'vip', child: Text('VIP')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Yeni Üye Butonu
                ElevatedButton.icon(
                  onPressed: () => _showAddMemberDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Üye'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // İçerik
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF6B35),
                    ),
                  )
                : _filteredMembers.isEmpty
                    ? _buildEmptyState()
                    : _buildMembersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.group_add,
              size: 64,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz üye yok',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'İlk üyenizi ekleyerek başlayın',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddMemberDialog(),
            icon: const Icon(Icons.add),
            label: const Text('İlk Üyeyi Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredMembers.length,
      itemBuilder: (context, index) {
        final member = _filteredMembers[index];
        return _buildMemberCard(member);
      },
    );
  }

  Widget _buildMemberCard(SportsMember member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Üst Kısım - Ad ve Durum
          Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    member.ad[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Ad Soyad ve Durum
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member.tamAd,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        if (member.isVip) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'VIP',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: member.durum == 'aktif'
                                ? Colors.green
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          member.durum.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: member.durum == 'aktif'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Aksiyonlar
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditMemberDialog(member);
                      break;
                    case 'delete':
                      _showDeleteConfirmation(member);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        const SizedBox(width: 8),
                        Text('Düzenle'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('Sil', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Alt Kısım - Detaylar
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.phone,
                  'Telefon',
                  member.telefon,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.email,
                  'E-posta',
                  member.email,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.card_membership,
                  'Üyelik',
                  member.uyelikTipi,
                ),
              ),
              if (member.yas != null)
                Expanded(
                  child: _buildInfoItem(
                    Icons.cake,
                    'Yaş',
                    '${member.yas} yaş',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: const Color(0xFF6B7280),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => _MemberFormDialog(
        onSave: (member) => _saveMember(member),
      ),
    );
  }

  void _showEditMemberDialog(SportsMember member) {
    showDialog(
      context: context,
      builder: (context) => _MemberFormDialog(
        member: member,
        onSave: (updatedMember) => _updateMember(updatedMember),
      ),
    );
  }

  Future<void> _saveMember(SportsMember member) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.sportsMembersCollection)
          .add(member.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Üye başarıyla eklendi'),
          backgroundColor: Colors.green,
        ),
      );

      _loadMembers();
    } catch (e) {
      if (kDebugMode) debugPrint('Üye kaydetme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateMember(SportsMember member) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.sportsMembersCollection)
          .doc(member.id)
          .update(member.copyWith(updatedAt: DateTime.now()).toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Üye başarıyla güncellendi'),
          backgroundColor: Colors.green,
        ),
      );

      _loadMembers();
    } catch (e) {
      if (kDebugMode) debugPrint('Üye güncelleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(SportsMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Üyeyi Sil'),
        content: Text(
            '${member.tamAd} adlı üyeyi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMember(member);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMember(SportsMember member) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.sportsMembersCollection)
          .doc(member.id)
          .update({'isActive': false});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Üye başarıyla silindi'),
          backgroundColor: Colors.green,
        ),
      );

      _loadMembers();
    } catch (e) {
      if (kDebugMode) debugPrint('Üye silme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _MemberFormDialog extends StatefulWidget {
  final SportsMember? member;
  final Function(SportsMember) onSave;

  const _MemberFormDialog({
    this.member,
    required this.onSave,
  });

  @override
  State<_MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<_MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  final _telefonController = TextEditingController();
  final _emailController = TextEditingController();
  final _notController = TextEditingController();

  String _cinsiyet = 'Erkek';
  String _uyelikTipi = 'aylık';
  String _durum = 'aktif';
  bool _isVip = false;
  DateTime? _dogumTarihi;
  DateTime _uyelikBaslangici = DateTime.now();
  DateTime? _uyelikBitisi;

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      _adController.text = widget.member!.ad;
      _soyadController.text = widget.member!.soyad;
      _telefonController.text = widget.member!.telefon;
      _emailController.text = widget.member!.email;
      _notController.text = widget.member!.not ?? '';
      _cinsiyet = widget.member!.cinsiyet;
      _uyelikTipi = widget.member!.uyelikTipi;
      _durum = widget.member!.durum;
      _isVip = widget.member!.isVip;
      _dogumTarihi = widget.member!.dogumTarihi;
      _uyelikBaslangici = widget.member!.uyelikBaslangici;
      _uyelikBitisi = widget.member!.uyelikBitisi;
    }
  }

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _notController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.member == null ? 'Yeni Üye Ekle' : 'Üye Düzenle',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),

                // Ad Soyad
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _adController,
                        decoration: const InputDecoration(
                          labelText: 'Ad',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ad gereklidir';
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
                          labelText: 'Soyad',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Soyad gereklidir';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Telefon Email
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _telefonController,
                        decoration: const InputDecoration(
                          labelText: 'Telefon',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Telefon gereklidir';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'E-posta gereklidir';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dropdown'lar
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _cinsiyet,
                        decoration: const InputDecoration(
                          labelText: 'Cinsiyet',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Erkek', child: Text('Erkek')),
                          DropdownMenuItem(
                              value: 'Kadın', child: Text('Kadın')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _cinsiyet = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _uyelikTipi,
                        decoration: const InputDecoration(
                          labelText: 'Üyelik Tipi',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'aylık', child: Text('Aylık')),
                          DropdownMenuItem(
                              value: 'yıllık', child: Text('Yıllık')),
                          DropdownMenuItem(
                              value: 'paket', child: Text('Paket')),
                          DropdownMenuItem(
                              value: 'günlük', child: Text('Günlük')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _uyelikTipi = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // VIP Checkbox
                CheckboxListTile(
                  title: const Text('VIP Üye'),
                  value: _isVip,
                  onChanged: (value) {
                    setState(() {
                      _isVip = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Not
                TextFormField(
                  controller: _notController,
                  decoration: const InputDecoration(
                    labelText: 'Notlar',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Butonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _saveMember,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(widget.member == null ? 'Ekle' : 'Güncelle'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveMember() {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final member = SportsMember(
        id: widget.member?.id,
        userId: user.uid,
        ad: _adController.text,
        soyad: _soyadController.text,
        telefon: _telefonController.text,
        email: _emailController.text,
        dogumTarihi: _dogumTarihi,
        cinsiyet: _cinsiyet,
        uyelikTipi: _uyelikTipi,
        uyelikBaslangici: _uyelikBaslangici,
        uyelikBitisi: _uyelikBitisi,
        durum: _durum,
        isVip: _isVip,
        not: _notController.text.isEmpty ? null : _notController.text,
        createdAt: widget.member?.createdAt ?? DateTime.now(),
      );

      widget.onSave(member);
      Navigator.pop(context);
    }
  }
}
