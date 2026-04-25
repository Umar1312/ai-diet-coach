import 'meal.dart';

class PantryItemResponse {
  final String id;
  final String userId;
  final String name;
  final String emoji;
  final String? quantityHint;
  final bool isHighProtein;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;
  final String? servingSize;
  final String createdAt;
  final String updatedAt;

  const PantryItemResponse({
    required this.id,
    required this.userId,
    required this.name,
    required this.emoji,
    this.quantityHint,
    required this.isHighProtein,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    this.servingSize,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PantryItemResponse.fromJson(Map<String, dynamic> json) =>
      PantryItemResponse(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        quantityHint: json['quantity_hint'] as String?,
        isHighProtein: json['is_high_protein'] as bool,
        calories: json['calories'] as int,
        proteinG: json['protein_g'] as int,
        carbsG: json['carbs_g'] as int,
        fatsG: json['fats_g'] as int,
        servingSize: json['serving_size'] as String?,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );
}

class PantryListResponse {
  final List<PantryItemResponse> items;

  const PantryListResponse({required this.items});

  factory PantryListResponse.fromJson(Map<String, dynamic> json) =>
      PantryListResponse(
        items: (json['items'] as List)
            .map((e) => PantryItemResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PantryCreateRequest {
  final String name;
  final String emoji;
  final String? quantityHint;
  final bool isHighProtein;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;
  final String? servingSize;

  const PantryCreateRequest({
    required this.name,
    required this.emoji,
    this.quantityHint,
    this.isHighProtein = false,
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatsG = 0,
    this.servingSize,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'emoji': emoji,
    if (quantityHint != null) 'quantity_hint': quantityHint,
    'is_high_protein': isHighProtein,
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fats_g': fatsG,
    if (servingSize != null) 'serving_size': servingSize,
  };
}

class PantryUpdateRequest {
  final String? name;
  final String? emoji;
  final String? quantityHint;
  final bool? isHighProtein;
  final int? calories;
  final int? proteinG;
  final int? carbsG;
  final int? fatsG;
  final String? servingSize;

  const PantryUpdateRequest({
    this.name,
    this.emoji,
    this.quantityHint,
    this.isHighProtein,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatsG,
    this.servingSize,
  });

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (emoji != null) 'emoji': emoji,
    if (quantityHint != null) 'quantity_hint': quantityHint,
    if (isHighProtein != null) 'is_high_protein': isHighProtein,
    if (calories != null) 'calories': calories,
    if (proteinG != null) 'protein_g': proteinG,
    if (carbsG != null) 'carbs_g': carbsG,
    if (fatsG != null) 'fats_g': fatsG,
    if (servingSize != null) 'serving_size': servingSize,
  };
}

class PantrySuggestionItem extends Meal {
  final String whyItFits;

  const PantrySuggestionItem({
    required super.name,
    required super.emoji,
    super.prepMinutes,
    required super.calories,
    required super.proteinG,
    required super.carbsG,
    required super.fatsG,
    super.cuisine,
    super.servingSize,
    required this.whyItFits,
  });

  factory PantrySuggestionItem.fromJson(Map<String, dynamic> json) =>
      PantrySuggestionItem(
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        prepMinutes: json['prep_minutes'] as int? ?? 0,
        calories: json['calories'] as int,
        proteinG: json['protein_g'] as int,
        carbsG: json['carbs_g'] as int,
        fatsG: json['fats_g'] as int,
        cuisine: json['cuisine'] as String?,
        servingSize: json['serving_size'] as String?,
        whyItFits: json['why_it_fits'] as String,
      );

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'why_it_fits': whyItFits,
  };
}

class PantrySuggestionsResponse {
  final List<PantrySuggestionItem> items;
  final int total;
  final int page;
  final int pageSize;

  const PantrySuggestionsResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PantrySuggestionsResponse.fromJson(Map<String, dynamic> json) =>
      PantrySuggestionsResponse(
        items: (json['items'] as List)
            .map(
              (e) => PantrySuggestionItem.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        pageSize: json['page_size'] as int,
      );
}
