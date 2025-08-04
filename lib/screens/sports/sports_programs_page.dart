import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/sports_program_model.dart';

class SportsProgramsPage extends StatefulWidget {
  const SportsProgramsPage({super.key});

  @override
  State<SportsProgramsPage> createState() => _SportsProgramsPageState();
}

class _SportsProgramsPageState extends State<SportsProgramsPage> {
  String _searchQuery = '';
  String _selectedFilter = 'Tümü';
  List<SportsProgram> _programs = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadPrograms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  List<SportsProgram> get _filteredPrograms {
    return _programs.where((program) {
      final matchesSearch = program.programName
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      final matchesFilter =
          _selectedFilter == 'Tümü' || program.category == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _loadPrograms() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.sportsProgramsCollection)
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _programs = snapshot.docs
            .map((doc) => SportsProgram.fromMap(doc.data(), doc.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Programlar yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
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
                      hintText: 'Program ara...',
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
                ElevatedButton.icon(
                  onPressed: () => _showAddProgramDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Program'),
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
                : _programs.isEmpty
                    ? _buildEmptyState()
                    : _buildProgramsList(),
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
              Icons.fitness_center,
              size: 64,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz program yok',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'İlk antrenman programınızı oluşturun',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddProgramDialog(),
            icon: const Icon(Icons.add),
            label: const Text('İlk Programı Oluştur'),
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

  Widget _buildProgramsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _programs.length,
      itemBuilder: (context, index) {
        final program = _programs[index];
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getProgramColor(program.category)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getProgramIcon(program.category),
                      color: _getProgramColor(program.category),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.programName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getProgramColor(program.category),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getProgramTypeText(program.category),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (program.description != null &&
                            program.description!.isNotEmpty) ...[
                          Text(
                            program.description!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${program.duration} hafta',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.repeat,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${program.sessionsPerWeek} gün/hafta',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.trending_up,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getDifficultyText(program.level),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        if (program.dailyWorkouts.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Egzersizler (${program.dailyWorkouts.length})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children:
                                program.dailyWorkouts.take(4).map((exercise) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  exercise.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (program.dailyWorkouts.length > 4)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '+${program.dailyWorkouts.length - 4} egzersiz daha...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getProgramColor(String type) {
    switch (type) {
      case 'strength':
        return const Color(0xFFEF4444);
      case 'cardio':
        return const Color(0xFF06B6D4);
      case 'flexibility':
        return const Color(0xFF8B5CF6);
      case 'hiit':
        return const Color(0xFFF59E0B);
      case 'beginner':
        return const Color(0xFF10B981);
      case 'advanced':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getProgramIcon(String type) {
    switch (type) {
      case 'strength':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.directions_run;
      case 'flexibility':
        return Icons.self_improvement;
      case 'hiit':
        return Icons.flash_on;
      case 'beginner':
        return Icons.star_border;
      case 'advanced':
        return Icons.star;
      default:
        return Icons.sports_gymnastics;
    }
  }

  String _getProgramTypeText(String type) {
    switch (type) {
      case 'strength':
        return 'Güç';
      case 'cardio':
        return 'Kardio';
      case 'flexibility':
        return 'Esneklik';
      case 'hiit':
        return 'HIIT';
      case 'beginner':
        return 'Başlangıç';
      case 'advanced':
        return 'İleri';
      default:
        return type;
    }
  }

  String _getDifficultyText(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return 'Başlangıç';
      case 'intermediate':
        return 'Orta';
      case 'advanced':
        return 'İleri';
      default:
        return difficulty;
    }
  }

  void _showAddProgramDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: const _AddProgramForm(),
        ),
      ),
    );
  }
}

class _AddProgramForm extends StatefulWidget {
  const _AddProgramForm();

  @override
  State<_AddProgramForm> createState() => _AddProgramFormState();
}

class _AddProgramFormState extends State<_AddProgramForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _exerciseController = TextEditingController();

  String _selectedType = 'strength';
  String _selectedDifficulty = 'beginner';
  int _duration = 4;
  int _daysPerWeek = 3;
  final List<String> _exercises = [];
  bool _isLoading = false;

  final List<Map<String, String>> _programTypes = [
    {'value': 'strength', 'label': 'Güç Antrenmanı'},
    {'value': 'cardio', 'label': 'Kardiyovasküler'},
    {'value': 'flexibility', 'label': 'Esneklik'},
    {'value': 'hiit', 'label': 'HIIT'},
    {'value': 'beginner', 'label': 'Başlangıç Programı'},
    {'value': 'advanced', 'label': 'İleri Seviye'},
  ];

  final List<Map<String, String>> _difficulties = [
    {'value': 'beginner', 'label': 'Başlangıç'},
    {'value': 'intermediate', 'label': 'Orta'},
    {'value': 'advanced', 'label': 'İleri'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _exerciseController.dispose();
    super.dispose();
  }

  Future<void> _saveProgram() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final programData = {
        'userId': user.uid,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'difficulty': _selectedDifficulty,
        'duration': _duration,
        'daysPerWeek': _daysPerWeek,
        'exercises': _exercises,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'isActive': true,
      };

      await FirebaseFirestore.instance
          .collection(AppConstants.sportsProgramsCollection)
          .add(programData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Program başarıyla oluşturuldu'),
            backgroundColor: Color(0xFF10B981),
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

  void _addExercise() {
    if (_exerciseController.text.trim().isNotEmpty) {
      setState(() {
        _exercises.add(_exerciseController.text.trim());
        _exerciseController.clear();
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Color(0xFFFF6B35),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Yeni Program Oluştur',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form Fields
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Program Adı',
                hintText: 'Örn: 4 Haftalık Güç Antrenmanı',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Program adı gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                hintText: 'Program hakkında detaylı bilgi...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Program Tipi ve Zorluk
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Program Tipi',
                      border: OutlineInputBorder(),
                    ),
                    items: _programTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['value'],
                        child: Text(type['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDifficulty,
                    decoration: const InputDecoration(
                      labelText: 'Zorluk Seviyesi',
                      border: OutlineInputBorder(),
                    ),
                    items: _difficulties.map((difficulty) {
                      return DropdownMenuItem<String>(
                        value: difficulty['value'],
                        child: Text(difficulty['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDifficulty = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Süre ve Gün Sayısı
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _duration,
                    decoration: const InputDecoration(
                      labelText: 'Süre (hafta)',
                      border: OutlineInputBorder(),
                    ),
                    items: [2, 4, 6, 8, 12, 16].map((duration) {
                      return DropdownMenuItem<int>(
                        value: duration,
                        child: Text('$duration hafta'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _duration = value!);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _daysPerWeek,
                    decoration: const InputDecoration(
                      labelText: 'Gün/Hafta',
                      border: OutlineInputBorder(),
                    ),
                    items: [2, 3, 4, 5, 6, 7].map((days) {
                      return DropdownMenuItem<int>(
                        value: days,
                        child: Text('$days gün'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _daysPerWeek = value!);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Egzersizler
            const Text(
              'Egzersizler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _exerciseController,
                    decoration: const InputDecoration(
                      hintText: 'Egzersiz adı ekle...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addExercise(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_exercises.isNotEmpty) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _exercises.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _exercises[index],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeExercise(index),
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.red,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProgram,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
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
                      : const Text('Oluştur'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
