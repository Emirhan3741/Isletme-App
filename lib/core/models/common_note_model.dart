import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'base_model.dart';
import '../constants/app_constants.dart';

// Not Öncelik Seviyeleri
enum NotePriority {
  low('low', 'Düşük', 1),
  medium('medium', 'Orta', 2),
  high('high', 'Yüksek', 3),
  urgent('urgent', 'Acil', 4);

  const NotePriority(this.value, this.displayName, this.level);
  final String value;
  final String displayName;
  final int level;
}

// Not Kategorileri
enum NoteCategory {
  general('general', 'Genel'),
  customer('customer', 'Müşteri'),
  appointment('appointment', 'Randevu'),
  expense('expense', 'Gider'),
  task('task', 'Görev'),
  reminder('reminder', 'Hatırlatıcı'),
  meeting('meeting', 'Toplantı'),
  idea('idea', 'Fikir');

  const NoteCategory(this.value, this.displayName);
  final String value;
  final String displayName;
}

// Not Durumları
enum NoteStatus {
  draft('Taslak'),
  active('Aktif'),
  completed('Tamamlandı'),
  archived('Arşivlendi'),
  cancelled('İptal Edildi');

  const NoteStatus(this.displayName);

  final String displayName;

  // Status rengini döndürür
  Color get color {
    switch (this) {
      case NoteStatus.draft:
        return Colors.orange;
      case NoteStatus.active:
        return Colors.blue;
      case NoteStatus.completed:
        return Colors.green;
      case NoteStatus.archived:
        return Colors.grey;
      case NoteStatus.cancelled:
        return Colors.red;
    }
  }

  static NoteStatus fromString(String value) {
    return NoteStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => NoteStatus.draft,
    );
  }
}

// Not Girişi (Dated Entry)
class NoteEntry {
  final String id;
  final DateTime date;
  final String content;
  final String? attachmentUrl;

  const NoteEntry({
    required this.id,
    required this.date,
    required this.content,
    this.attachmentUrl,
  });

  factory NoteEntry.fromMap(Map<String, dynamic> map) {
    return NoteEntry(
      id: map['id'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      content: map['content'] ?? '',
      attachmentUrl: map['attachmentUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'content': content,
      'attachmentUrl': attachmentUrl,
    };
  }

  NoteEntry copyWith({
    String? id,
    DateTime? date,
    String? content,
    String? attachmentUrl,
  }) {
    return NoteEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }
}

// Ortak Not Modeli
class CommonNoteModel extends BaseModel
    implements StatusModel, CategoryModel, PriorityModel, SectorModel {
  final String title;
  final String content;
  final NoteCategory noteCategory;
  final NotePriority notePriority;
  final NoteStatus noteStatus;
  final List<NoteEntry> entries;
  final DateTime? reminderDate;
  final bool reminderSent;
  final String? linkedEntityId; // Bağlı müşteri, randevu vs. ID'si
  final String? linkedEntityType; // 'customer', 'appointment', 'expense' vs.
  final List<String> tags;
  final String? attachmentUrl;
  @override
  final Map<String, dynamic> sectorSpecificData;

  const CommonNoteModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.updatedAt,
    required this.title,
    required this.content,
    this.noteCategory = NoteCategory.general,
    this.notePriority = NotePriority.medium,
    this.noteStatus = NoteStatus.active,
    this.entries = const [],
    this.reminderDate,
    this.reminderSent = false,
    this.linkedEntityId,
    this.linkedEntityType,
    this.tags = const [],
    this.attachmentUrl,
    this.sectorSpecificData = const {},
  });

  factory CommonNoteModel.fromMap(Map<String, dynamic> map) {
    final baseFields = BaseModel.getBaseFields(map);
    return CommonNoteModel(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      noteCategory: NoteCategory.values.firstWhere(
        (category) => category.value == (map['noteCategory'] ?? 'general'),
        orElse: () => NoteCategory.general,
      ),
      notePriority: NotePriority.values.firstWhere(
        (priority) => priority.value == (map['notePriority'] ?? 'medium'),
        orElse: () => NotePriority.medium,
      ),
      noteStatus: NoteStatus.values.firstWhere(
        (status) => status.name == (map['noteStatus'] ?? 'active'),
        orElse: () => NoteStatus.active,
      ),
      entries: (map['entries'] as List<dynamic>?)
              ?.map((entry) => NoteEntry.fromMap(entry as Map<String, dynamic>))
              .toList() ??
          [],
      reminderDate: (map['reminderDate'] as Timestamp?)?.toDate(),
      reminderSent: map['reminderSent'] ?? false,
      linkedEntityId: map['linkedEntityId'],
      linkedEntityType: map['linkedEntityType'],
      tags: List<String>.from(map['tags'] ?? []),
      attachmentUrl: map['attachmentUrl'],
      sectorSpecificData:
          Map<String, dynamic>.from(map['sectorSpecificData'] ?? {}),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'title': title,
      'content': content,
      'noteCategory': noteCategory.value,
      'notePriority': notePriority.value,
      'noteStatus': noteStatus.name,
      'entries': entries.map((entry) => entry.toMap()).toList(),
      'reminderDate':
          reminderDate != null ? Timestamp.fromDate(reminderDate!) : null,
      'reminderSent': reminderSent,
      'linkedEntityId': linkedEntityId,
      'linkedEntityType': linkedEntityType,
      'tags': tags,
      'attachmentUrl': attachmentUrl,
      'sectorSpecificData': sectorSpecificData,
    });
    return map;
  }

  // StatusModel implementation
  @override
  String get status => noteStatus.name;

  @override
  bool get isActive => noteStatus == NoteStatus.active;

  // CategoryModel implementation
  @override
  String get category => noteCategory.value;

  @override
  String get categoryDisplayName => noteCategory.displayName;

  // PriorityModel implementation
  @override
  String get priority => notePriority.value;

  @override
  int get priorityLevel => notePriority.level;

  // SectorModel implementation
  @override
  String get sector => sectorSpecificData['sector'] ?? '';

  // Utility methods
  bool get hasReminder => reminderDate != null;

  bool get isReminderDue {
    if (!hasReminder || reminderSent) return false;
    return DateTime.now().isAfter(reminderDate!);
  }

  bool get isCompleted => noteStatus == NoteStatus.completed;

  bool get isArchived => noteStatus == NoteStatus.archived;

  bool get hasEntries => entries.isNotEmpty;

  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;

  bool get hasLinkedEntity =>
      linkedEntityId != null && linkedEntityId!.isNotEmpty;

  int get totalEntries => entries.length;

  DateTime? get lastEntryDate {
    if (entries.isEmpty) return null;
    return entries.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  // Add new entry
  CommonNoteModel addEntry(NoteEntry entry) {
    final newEntries = List<NoteEntry>.from(entries)..add(entry);
    return copyWith(
      entries: newEntries,
      updatedAt: DateTime.now(),
    );
  }

  // Remove entry
  CommonNoteModel removeEntry(String entryId) {
    final newEntries = entries.where((entry) => entry.id != entryId).toList();
    return copyWith(
      entries: newEntries,
      updatedAt: DateTime.now(),
    );
  }

  // Update entry
  CommonNoteModel updateEntry(String entryId, NoteEntry updatedEntry) {
    final newEntries = entries.map((entry) {
      return entry.id == entryId ? updatedEntry : entry;
    }).toList();
    return copyWith(
      entries: newEntries,
      updatedAt: DateTime.now(),
    );
  }

  // Add tag
  CommonNoteModel addTag(String tag) {
    if (tags.contains(tag)) return this;
    final newTags = List<String>.from(tags)..add(tag);
    return copyWith(tags: newTags);
  }

  // Remove tag
  CommonNoteModel removeTag(String tag) {
    final newTags = tags.where((t) => t != tag).toList();
    return copyWith(tags: newTags);
  }

  // Mark as completed
  CommonNoteModel markAsCompleted() {
    return copyWith(
      noteStatus: NoteStatus.completed,
      updatedAt: DateTime.now(),
    );
  }

  // Archive note
  CommonNoteModel archive() {
    return copyWith(
      noteStatus: NoteStatus.archived,
      updatedAt: DateTime.now(),
    );
  }

  // Restore note
  CommonNoteModel restore() {
    return copyWith(
      noteStatus: NoteStatus.active,
      updatedAt: DateTime.now(),
    );
  }

  CommonNoteModel copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    String? content,
    NoteCategory? noteCategory,
    NotePriority? notePriority,
    NoteStatus? noteStatus,
    List<NoteEntry>? entries,
    DateTime? reminderDate,
    bool? reminderSent,
    String? linkedEntityId,
    String? linkedEntityType,
    List<String>? tags,
    String? attachmentUrl,
    Map<String, dynamic>? sectorSpecificData,
  }) {
    return CommonNoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      content: content ?? this.content,
      noteCategory: noteCategory ?? this.noteCategory,
      notePriority: notePriority ?? this.notePriority,
      noteStatus: noteStatus ?? this.noteStatus,
      entries: entries ?? this.entries,
      reminderDate: reminderDate ?? this.reminderDate,
      reminderSent: reminderSent ?? this.reminderSent,
      linkedEntityId: linkedEntityId ?? this.linkedEntityId,
      linkedEntityType: linkedEntityType ?? this.linkedEntityType,
      tags: tags ?? this.tags,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      sectorSpecificData: sectorSpecificData ?? this.sectorSpecificData,
    );
  }

  // Sektörel özelleştirmeler
  String? get clientId => sectorSpecificData['clientId'];
  String? get projectId => sectorSpecificData['projectId'];
  String? get treatmentType => sectorSpecificData['treatmentType'];
  Map<String, dynamic> get customFields =>
      sectorSpecificData['customFields'] ?? {};

  // Sektörel validasyon
  bool get isValidForSector {
    switch (sector) {
      case 'beauty':
        return title.isNotEmpty;
      case 'psychology':
        return title.isNotEmpty &&
            (linkedEntityId != null || content.isNotEmpty);
      case 'diet':
        return title.isNotEmpty;
      default:
        return title.isNotEmpty;
    }
  }

  // Durum rengi
  Color get statusColor {
    if (isReminderDue) return AppConstants.warningColor;
    return noteStatus.color;
  }

  @override
  String toString() =>
      'CommonNoteModel(id: $id, title: $title, status: ${noteStatus.displayName}, priority: ${notePriority.displayName})';
}
