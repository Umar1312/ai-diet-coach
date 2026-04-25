class PantryItemResponse {
  final String id;
  final String userId;
  final String name;
  final String emoji;
  final String? quantityHint;
  final bool isHighProtein;
  final String createdAt;
  final String updatedAt;

  const PantryItemResponse({
    required this.id,
    required this.userId,
    required this.name,
    required this.emoji,
    this.quantityHint,
    required this.isHighProtein,
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

  const PantryCreateRequest({
    required this.name,
    required this.emoji,
    this.quantityHint,
    this.isHighProtein = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'emoji': emoji,
    if (quantityHint != null) 'quantity_hint': quantityHint,
    'is_high_protein': isHighProtein,
  };
}

class PantryUpdateRequest {
  final String? name;
  final String? emoji;
  final String? quantityHint;
  final bool? isHighProtein;

  const PantryUpdateRequest({
    this.name,
    this.emoji,
    this.quantityHint,
    this.isHighProtein,
  });

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (emoji != null) 'emoji': emoji,
    if (quantityHint != null) 'quantity_hint': quantityHint,
    if (isHighProtein != null) 'is_high_protein': isHighProtein,
  };
}
