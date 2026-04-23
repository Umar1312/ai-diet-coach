import 'macro_model.dart';

class MealModel {
  final String id;
  final String name;
  final DateTime timestamp;
  final String? imageUrl;
  final MacroModel macros;
  final String? notes;

  MealModel({
    required this.id,
    required this.name,
    required this.timestamp,
    this.imageUrl,
    required this.macros,
    this.notes,
  });

  MealModel copyWith({
    String? id,
    String? name,
    DateTime? timestamp,
    String? imageUrl,
    MacroModel? macros,
    String? notes,
  }) {
    return MealModel(
      id: id ?? this.id,
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      macros: macros ?? this.macros,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'imageUrl': imageUrl,
      'macros': macros.toJson(),
      'notes': notes,
    };
  }

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      imageUrl: json['imageUrl'],
      macros: MacroModel.fromJson(json['macros'] ?? {}),
      notes: json['notes'],
    );
  }
}
