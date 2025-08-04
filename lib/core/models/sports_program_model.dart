import 'package:cloud_firestore/cloud_firestore.dart';

/// Antrenman programı modeli
class SportsProgram {
  final String? id;
  final String userId;
  final String programName; // Program adı
  final String? description; // Açıklama
  final String
      category; // 'kilo_verme', 'kas_gelistirme', 'kardiyovaskuler', 'esneklik'
  final String level; // 'başlangıç', 'orta', 'ileri'
  final int duration; // Program süresi (hafta)
  final int sessionsPerWeek; // Haftalık seans sayısı
  final List<Map<String, dynamic>> dailyWorkouts; // Günlük antrenmanlar
  final Map<String, dynamic>? nutritionPlan; // Beslenme planı
  final List<String>? equipmentNeeded; // Gerekli ekipmanlar
  final List<String>? targetMuscles; // Hedef kas grupları
  final double? estimatedCalories; // Tahmini kalori yakımı
  final String? instructorNotes; // Eğitmen notları
  final bool isTemplate; // Şablon program mı?
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SportsProgram({
    this.id,
    required this.userId,
    required this.programName,
    this.description,
    required this.category,
    required this.level,
    this.duration = 4, // Varsayılan 4 hafta
    this.sessionsPerWeek = 3, // Varsayılan haftada 3 seans
    this.dailyWorkouts = const [],
    this.nutritionPlan,
    this.equipmentNeeded,
    this.targetMuscles,
    this.estimatedCalories,
    this.instructorNotes,
    this.isTemplate = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Firebase'den veri çekme
  factory SportsProgram.fromMap(Map<String, dynamic> map, String id) {
    return SportsProgram(
      id: id,
      userId: map['userId'] ?? '',
      programName: map['programName'] ?? '',
      description: map['description'],
      category: map['category'] ?? '',
      level: map['level'] ?? 'başlangıç',
      duration: map['duration'] ?? 4,
      sessionsPerWeek: map['sessionsPerWeek'] ?? 3,
      dailyWorkouts: map['dailyWorkouts'] != null
          ? List<Map<String, dynamic>>.from(map['dailyWorkouts'])
          : [],
      nutritionPlan: map['nutritionPlan'],
      equipmentNeeded: map['equipmentNeeded'] != null
          ? List<String>.from(map['equipmentNeeded'])
          : null,
      targetMuscles: map['targetMuscles'] != null
          ? List<String>.from(map['targetMuscles'])
          : null,
      estimatedCalories: map['estimatedCalories']?.toDouble(),
      instructorNotes: map['instructorNotes'],
      isTemplate: map['isTemplate'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Firebase'e veri gönderme
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'programName': programName,
      'description': description,
      'category': category,
      'level': level,
      'duration': duration,
      'sessionsPerWeek': sessionsPerWeek,
      'dailyWorkouts': dailyWorkouts,
      'nutritionPlan': nutritionPlan,
      'equipmentNeeded': equipmentNeeded,
      'targetMuscles': targetMuscles,
      'estimatedCalories': estimatedCalories,
      'instructorNotes': instructorNotes,
      'isTemplate': isTemplate,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Copy with method
  SportsProgram copyWith({
    String? id,
    String? userId,
    String? programName,
    String? description,
    String? category,
    String? level,
    int? duration,
    int? sessionsPerWeek,
    List<Map<String, dynamic>>? dailyWorkouts,
    Map<String, dynamic>? nutritionPlan,
    List<String>? equipmentNeeded,
    List<String>? targetMuscles,
    double? estimatedCalories,
    String? instructorNotes,
    bool? isTemplate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SportsProgram(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      programName: programName ?? this.programName,
      description: description ?? this.description,
      category: category ?? this.category,
      level: level ?? this.level,
      duration: duration ?? this.duration,
      sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
      dailyWorkouts: dailyWorkouts ?? this.dailyWorkouts,
      nutritionPlan: nutritionPlan ?? this.nutritionPlan,
      equipmentNeeded: equipmentNeeded ?? this.equipmentNeeded,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      instructorNotes: instructorNotes ?? this.instructorNotes,
      isTemplate: isTemplate ?? this.isTemplate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Kategori emojisi
  String get categoryEmoji {
    switch (category) {
      case 'kilo_verme':
        return '🔥';
      case 'kas_gelistirme':
        return '💪';
      case 'kardiyovaskuler':
        return '❤️';
      case 'esneklik':
        return '🤸';
      default:
        return '🏃';
    }
  }

  // Seviye rengi
  String get levelColor {
    switch (level) {
      case 'başlangıç':
        return '#4CAF50'; // Yeşil
      case 'orta':
        return '#FF9800'; // Turuncu
      case 'ileri':
        return '#F44336'; // Kırmızı
      default:
        return '#2196F3'; // Mavi
    }
  }

  // Toplam seans sayısı
  int get totalSessions => duration * sessionsPerWeek;
}

/// Günlük antrenman detayı modeli
class DailyWorkout {
  final String day; // 'pazartesi', 'salı', vb.
  final String workoutName; // Antrenman adı
  final List<Exercise> exercises; // Egzersizler
  final int restTime; // Setler arası dinlenme (saniye)
  final String? notes; // Notlar

  DailyWorkout({
    required this.day,
    required this.workoutName,
    this.exercises = const [],
    this.restTime = 60,
    this.notes,
  });

  factory DailyWorkout.fromMap(Map<String, dynamic> map) {
    return DailyWorkout(
      day: map['day'] ?? '',
      workoutName: map['workoutName'] ?? '',
      exercises: map['exercises'] != null
          ? (map['exercises'] as List).map((e) => Exercise.fromMap(e)).toList()
          : [],
      restTime: map['restTime'] ?? 60,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'workoutName': workoutName,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'restTime': restTime,
      'notes': notes,
    };
  }
}

/// Egzersiz detayı modeli
class Exercise {
  final String name; // Egzersiz adı
  final String? description; // Açıklama
  final int sets; // Set sayısı
  final int? reps; // Tekrar sayısı
  final int? duration; // Süre (saniye) - kardiyovasküler egzersizler için
  final double? weight; // Ağırlık (kg)
  final String? targetMuscle; // Hedef kas grubu
  final String? equipmentNeeded; // Gerekli ekipman

  Exercise({
    required this.name,
    this.description,
    this.sets = 1,
    this.reps,
    this.duration,
    this.weight,
    this.targetMuscle,
    this.equipmentNeeded,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] ?? '',
      description: map['description'],
      sets: map['sets'] ?? 1,
      reps: map['reps'],
      duration: map['duration'],
      weight: map['weight']?.toDouble(),
      targetMuscle: map['targetMuscle'],
      equipmentNeeded: map['equipmentNeeded'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'sets': sets,
      'reps': reps,
      'duration': duration,
      'weight': weight,
      'targetMuscle': targetMuscle,
      'equipmentNeeded': equipmentNeeded,
    };
  }
}
