enum NoteColor {
  blue,
  green,
  red,
  orange,
  purple,
  pink,
  yellow,
  gray,
  turquoise,
  lime,
}

extension NoteColorExtension on NoteColor {
  String get displayName {
    switch (this) {
      case NoteColor.blue:
        return 'Blue';
      case NoteColor.green:
        return 'Green';
      case NoteColor.red:
        return 'Red';
      case NoteColor.orange:
        return 'Orange';
      case NoteColor.purple:
        return 'Purple';
      case NoteColor.pink:
        return 'Pink';
      case NoteColor.yellow:
        return 'Yellow';
      case NoteColor.gray:
        return 'Gray';
      case NoteColor.turquoise:
        return 'Turquoise';
      case NoteColor.lime:
        return 'Lime';
    }
  }

  static NoteColor fromString(String value) {
    return NoteColor.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NoteColor.blue,
    );
  }
}
