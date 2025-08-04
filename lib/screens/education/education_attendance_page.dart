import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../utils/feedback_utils.dart';

// TODO: Bu sayfaya devamsızlık limiti uyarıları, veli bilgilendirme, rapor çıktısı, otomatik yoklama sistemi eklenecek
class EducationAttendancePage extends StatefulWidget {
  const EducationAttendancePage({super.key});

  @override
  State<EducationAttendancePage> createState() =>
      _EducationAttendancePageState();
}

class _EducationAttendancePageState extends State<EducationAttendancePage> {
  String _selectedClass = 'Tümü';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isSaving = false;
  List<String> _classes = ['Tümü'];
  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  Map<String, String> _attendanceStatus = {}; // studentId -> status

  final List<String> _attendanceOptions = ['var', 'yok', 'geç', 'izinli'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadClasses(),
        _loadStudents(),
      ]);

      await _loadAttendanceForDate();
      _applyFilters();
    } catch (e) {
      if (kDebugMode) debugPrint('Veri yükleme hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadClasses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final classSnapshot = await FirebaseFirestore.instance
          .collection('education_classes')
          .where('userId', isEqualTo: user.uid)
          .get();

      final classes = ['Tümü'];
      for (var doc in classSnapshot.docs) {
        classes.add(doc.data()['name'] ?? doc.id);
      }

      setState(() {
        _classes = classes;
        if (_classes.length > 1 && _selectedClass == 'Tümü') {
          _selectedClass = _classes[1]; // İlk sınıfı seç
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Sınıflar yüklenirken hata: $e');
    }
  }

  Future<void> _loadStudents() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('education_students')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .orderBy('name')
          .get();

      final students = studentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Student(
          id: doc.id,
          name: data['name'] ?? '',
          className: data['className'] ?? '',
          studentNumber: data['studentNumber'] ?? '',
          photoUrl: data['photoUrl'],
        );
      }).toList();

      setState(() {
        _students = students;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Öğrenciler yüklenirken hata: $e');
    }
  }

  Future<void> _loadAttendanceForDate() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final attendanceSnapshot = await FirebaseFirestore.instance
          .collection('education_attendance')
          .where('userId', isEqualTo: user.uid)
          .where('date',
              isEqualTo: Timestamp.fromDate(DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
              )))
          .get();

      final attendanceMap = <String, String>{};
      for (var doc in attendanceSnapshot.docs) {
        final data = doc.data();
        attendanceMap[data['studentId']] = data['status'];
      }

      setState(() {
        _attendanceStatus = attendanceMap;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Devam durumu yüklenirken hata: $e');
    }
  }

  void _applyFilters() {
    List<Student> filtered = _students;

    if (_selectedClass != 'Tümü') {
      filtered = filtered
          .where((student) => student.className == _selectedClass)
          .toList();
    }

    setState(() {
      _filteredStudents = filtered;
    });
  }

  void _updateAttendanceStatus(String studentId, String status) {
    setState(() {
      _attendanceStatus[studentId] = status;
    });
  }

  void _setAllPresent() {
    setState(() {
      for (var student in _filteredStudents) {
        _attendanceStatus[student.id] = 'var';
      }
    });
  }

  void _setAllAbsent() {
    setState(() {
      for (var student in _filteredStudents) {
        _attendanceStatus[student.id] = 'yok';
      }
    });
  }

  Future<void> _saveAttendance() async {
    if (_attendanceStatus.isEmpty) {
      FeedbackUtils.showError(
          context, 'Lütfen en az bir öğrenci için devam durumu seçin');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final batch = FirebaseFirestore.instance.batch();
      final attendanceDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      // Mevcut kayıtları sil
      final existingAttendance = await FirebaseFirestore.instance
          .collection('education_attendance')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: Timestamp.fromDate(attendanceDate))
          .get();

      for (var doc in existingAttendance.docs) {
        batch.delete(doc.reference);
      }

      // Yeni kayıtları ekle
      for (var entry in _attendanceStatus.entries) {
        final studentId = entry.key;
        final status = entry.value;
        final student = _students.firstWhere((s) => s.id == studentId);

        final attendanceRef =
            FirebaseFirestore.instance.collection('education_attendance').doc();

        batch.set(attendanceRef, {
          'userId': user.uid,
          'studentId': studentId,
          'studentName': student.name,
          'studentNumber': student.studentNumber,
          'className': student.className,
          'date': Timestamp.fromDate(attendanceDate),
          'status': status,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();

      FeedbackUtils.showSuccess(context, 'Yoklama başarıyla kaydedildi');
    } catch (e) {
      FeedbackUtils.showError(context, 'Yoklama kaydedilirken hata oluştu: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredStudents.isEmpty)
            _buildEmptyState()
          else
            Expanded(
              child: _buildStudentsList(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.checklist,
              color: Color(0xFF667EEA),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Devam Takibi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Öğrenci devam durumunu takip edin ve yoklama alın',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _setAllPresent,
                icon: const Icon(Icons.check_circle,
                    size: 18, color: Colors.white),
                label: const Text('Hepsini Var',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _setAllAbsent,
                icon: const Icon(Icons.cancel, size: 18, color: Colors.white),
                label: const Text('Hepsini Yok',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAttendance,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save, size: 18, color: Colors.white),
                label: const Text('Yoklamayı Kaydet',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedClass,
              onChanged: (value) {
                setState(() {
                  _selectedClass = value!;
                  _applyFilters();
                });
              },
              decoration: const InputDecoration(
                labelText: 'Sınıf',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.class_),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _classes.map((className) {
                return DropdownMenuItem(
                  value: className,
                  child: Text(className),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                  _loadAttendanceForDate();
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tarih',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  DateFormat('dd.MM.yyyy EEEE', 'tr_TR').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_filteredStudents.length} öğrenci',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.school,
                size: 64,
                color: Color(0xFF667EEA),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Öğrenci bulunamadı',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Seçilen sınıfta aktif öğrenci bulunmuyor',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        final currentStatus = _attendanceStatus[student.id] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: student.photoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.network(
                            student.photoUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultAvatar(student.name),
                          ),
                        )
                      : _buildDefaultAvatar(student.name),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'No: ${student.studentNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            student.className,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Wrap(
                  spacing: 8,
                  children: _attendanceOptions.map((option) {
                    final isSelected = currentStatus == option;
                    return GestureDetector(
                      onTap: () => _updateAttendanceStatus(student.id, option),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getStatusColor(option)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(option),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _getStatusDisplayName(option),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : _getStatusColor(option),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF667EEA).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF667EEA),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'var':
        return Colors.green;
      case 'yok':
        return Colors.red;
      case 'geç':
        return Colors.orange;
      case 'izinli':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'var':
        return 'Var';
      case 'yok':
        return 'Yok';
      case 'geç':
        return 'Geç';
      case 'izinli':
        return 'İzinli';
      default:
        return status;
    }
  }

  String _getDisplayName(String name) {
    if (name.isNotEmpty) {
      return name.length > 12 ? '${name.substring(0, 12)}...' : name;
    }
    return 'Bilinmeyen';
  }
}

// Student Model
class Student {
  final String id;
  final String name;
  final String className;
  final String studentNumber;
  final String? photoUrl;

  Student({
    required this.id,
    required this.name,
    required this.className,
    required this.studentNumber,
    this.photoUrl,
  });
}
