import 'dashboard_state.dart';

class HistoryResponse {
  final List<DayHistoryEntry> days;

  const HistoryResponse({required this.days});

  factory HistoryResponse.fromJson(Map<String, dynamic> json) =>
      HistoryResponse(
        days: (json['days'] as List)
            .map((e) => DayHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DayHistoryEntry {
  final String dayId;
  final MacroTargets consumed;
  final MacroTargets targets;
  final int mealCount;
  final String aiSummary;

  const DayHistoryEntry({
    required this.dayId,
    required this.consumed,
    required this.targets,
    required this.mealCount,
    required this.aiSummary,
  });

  factory DayHistoryEntry.fromJson(Map<String, dynamic> json) =>
      DayHistoryEntry(
        dayId: json['day_id'] as String,
        consumed: MacroTargets.fromJson(
          json['consumed'] as Map<String, dynamic>,
        ),
        targets: MacroTargets.fromJson(json['targets'] as Map<String, dynamic>),
        mealCount: json['meal_count'] as int,
        aiSummary: json['ai_summary'] as String,
      );
}
