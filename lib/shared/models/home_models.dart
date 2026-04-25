import 'package:flutter/material.dart';
import 'pantry_models.dart';

/// Overall "where am I today" vibe shown in the status header.
enum DayStatus { onTrack, slightlyOver, needProtein, roomForDinner, goalHit }

extension DayStatusParsing on DayStatus {
  static DayStatus fromString(String value) {
    switch (value) {
      case 'on_track':
        return DayStatus.onTrack;
      case 'slightly_over':
        return DayStatus.slightlyOver;
      case 'need_protein':
        return DayStatus.needProtein;
      case 'room_for_dinner':
        return DayStatus.roomForDinner;
      case 'goal_hit':
        return DayStatus.goalHit;
      default:
        return DayStatus.onTrack;
    }
  }
}

extension DayStatusX on DayStatus {
  String get label {
    switch (this) {
      case DayStatus.onTrack:
        return 'On track';
      case DayStatus.slightlyOver:
        return 'Slightly over';
      case DayStatus.needProtein:
        return 'Need protein';
      case DayStatus.roomForDinner:
        return 'Room for dinner';
      case DayStatus.goalHit:
        return 'Goal hit';
    }
  }

  /// Short dot + label color hint.
  Color get tint {
    switch (this) {
      case DayStatus.onTrack:
        return const Color(0xFF64993A);
      case DayStatus.slightlyOver:
        return const Color(0xFFDE6969);
      case DayStatus.needProtein:
        return const Color(0xFF6998DE);
      case DayStatus.roomForDinner:
        return const Color(0xFFDE9A69);
      case DayStatus.goalHit:
        return const Color(0xFF000000);
    }
  }
}

/// The hero recommendation shown on the home screen.
class NextMealRecommendation {
  final String name;
  final String whyItFits;
  final int prepMinutes;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;
  final String emoji;

  const NextMealRecommendation({
    required this.name,
    required this.whyItFits,
    required this.prepMinutes,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    required this.emoji,
  });

  factory NextMealRecommendation.fromJson(Map<String, dynamic> json) =>
      NextMealRecommendation(
        name: json['name'] as String,
        whyItFits: json['why_it_fits'] as String,
        prepMinutes: json['prep_minutes'] as int,
        calories: json['calories'] as int,
        proteinG: json['protein_g'] as int,
        carbsG: json['carbs_g'] as int,
        fatsG: json['fats_g'] as int,
        emoji: json['emoji'] as String,
      );
}

/// One slot in the flex plan strip (lunch / snack / dinner / late).
class FlexPlanSlot {
  final String label;
  final String hint;
  final IconData icon;
  final bool isOpen;
  final bool isOptional;
  final bool isDone;

  const FlexPlanSlot({
    required this.label,
    required this.hint,
    required this.icon,
    this.isOpen = true,
    this.isOptional = false,
    this.isDone = false,
  });

  factory FlexPlanSlot.fromJson(Map<String, dynamic> json) => FlexPlanSlot(
    label: json['label'] as String,
    hint: json['hint'] as String,
    icon: _iconFromKey(json['icon_key'] as String),
    isOpen: json['is_open'] as bool,
    isOptional: json['is_optional'] as bool,
    isDone: json['is_done'] as bool? ?? false,
  );

  static IconData _iconFromKey(String key) {
    switch (key) {
      case 'lunch':
        return Icons.lunch_dining_rounded;
      case 'snack':
        return Icons.cookie_rounded;
      case 'dinner':
        return Icons.dinner_dining_rounded;
      case 'late':
        return Icons.nightlight_round;
      default:
        return Icons.restaurant;
    }
  }
}

/// A pantry item the user already has at home.
class PantryItem {
  final String name;
  final String emoji;
  final String? quantityHint; // "400g left", "expires in 2d"
  final bool isHighProtein;

  const PantryItem({
    required this.name,
    required this.emoji,
    this.quantityHint,
    this.isHighProtein = false,
  });

  factory PantryItem.fromResponse(PantryItemResponse response) => PantryItem(
    name: response.name,
    emoji: response.emoji,
    quantityHint: response.quantityHint,
    isHighProtein: response.isHighProtein,
  );
}

/// Quick action chip under the hero card.
class QuickAction {
  final String label;
  final IconData icon;
  final Color color;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// State shown in the recalibration card.
enum RecalibrationMode {
  balanced, // on track
  lighterDinner, // overate earlier
  needProtein, // undereating protein
  dayAdjusted, // day changed, plan rebalanced
}

extension RecalibrationModeParsing on RecalibrationMode {
  static RecalibrationMode fromString(String value) {
    switch (value) {
      case 'balanced':
        return RecalibrationMode.balanced;
      case 'lighter_dinner':
        return RecalibrationMode.lighterDinner;
      case 'need_protein':
        return RecalibrationMode.needProtein;
      case 'day_adjusted':
        return RecalibrationMode.dayAdjusted;
      default:
        return RecalibrationMode.balanced;
    }
  }
}

class RecalibrationStatus {
  final RecalibrationMode mode;
  final String title;
  final String detail;

  const RecalibrationStatus({
    required this.mode,
    required this.title,
    required this.detail,
  });

  factory RecalibrationStatus.fromJson(Map<String, dynamic> json) =>
      RecalibrationStatus(
        mode: RecalibrationModeParsing.fromString(json['mode'] as String),
        title: json['title'] as String,
        detail: json['detail'] as String,
      );
}
