import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/meal_model.dart';
import '../../../data/models/macro_model.dart';
import '../../widgets/primary_button.dart';

class LogMealSheet extends StatefulWidget {
  final Function(MealModel) onMealLogged;

  const LogMealSheet({super.key, required this.onMealLogged});

  @override
  State<LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends State<LogMealSheet> {
  int _selectedTab = 0;
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();

  final List<Map<String, dynamic>> _options = [
    {'icon': Icons.camera_alt, 'label': 'Camera'},
    {'icon': Icons.mic, 'label': 'Voice'},
    {'icon': Icons.edit, 'label': 'Text'},
    {'icon': Icons.menu_book, 'label': 'Menu'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _logMeal() {
    if (_nameController.text.isNotEmpty &&
        _caloriesController.text.isNotEmpty) {
      final meal = MealModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        timestamp: DateTime.now(),
        macros: MacroModel(
          calories: double.tryParse(_caloriesController.text) ?? 0,
          carbs: 0,
          protein: 0,
          fats: 0,
        ),
      );
      widget.onMealLogged(meal);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = _selectedTab == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedTab = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        option['icon'],
                        size: 20,
                        color: isSelected
                            ? AppColors.textOnPrimary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        option['label'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AppColors.textOnPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          // Content based on selected tab
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0: // Camera
        return _CameraTab();
      case 1: // Voice
        return _VoiceTab();
      case 2: // Text
        return _TextTab(
          nameController: _nameController,
          caloriesController: _caloriesController,
          onLogMeal: _logMeal,
        );
      case 3: // Menu
        return _MenuTab();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _CameraTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Take a photo of your meal',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(text: 'Open Camera', onPressed: () {}),
      ],
    );
  }
}

class _VoiceTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, size: 64, color: AppColors.textTertiary),
                  SizedBox(height: 16),
                  Text(
                    'Tap to speak what you ate',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'e.g., "I had three eggs and an avocado"',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.mic,
            color: AppColors.textOnPrimary,
            size: 40,
          ),
        ),
      ],
    );
  }
}

class _TextTab extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController caloriesController;
  final VoidCallback onLogMeal;

  const _TextTab({
    required this.nameController,
    required this.caloriesController,
    required this.onLogMeal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meal Name',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'e.g., Grilled Chicken Salad',
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Calories',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: caloriesController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'e.g., 450',
            suffixText: 'cal',
          ),
        ),
        const Spacer(),
        PrimaryButton(text: 'Log Meal', onPressed: onLogMeal),
      ],
    );
  }
}

class _MenuTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Scan a restaurant menu',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Get AI recommendations based on your macros',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(text: 'Scan Menu', onPressed: () {}),
      ],
    );
  }
}
