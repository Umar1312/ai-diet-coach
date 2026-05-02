import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/main.dart' show pantryStore;
import 'package:diet_coach_ai/features/pantry/stores/pantry_store.dart';
import 'package:diet_coach_ai/shared/models/pantry_models.dart';

class PantryOnboardingScreen extends StatefulWidget {
  const PantryOnboardingScreen({super.key});

  @override
  State<PantryOnboardingScreen> createState() => _PantryOnboardingScreenState();
}

class _PantryOnboardingScreenState extends State<PantryOnboardingScreen> {
  late final PantryStore _store;

  @override
  void initState() {
    super.initState();
    _store = pantryStore;
    _store.loadStarterPack();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Observer(
          builder: (_) {
            return Column(
              children: [
                const _Header(),
                Expanded(
                  child: _store.isLoadingStarter.value
                      ? _buildLoading()
                      : _store.starterError.value.isNotEmpty
                      ? _buildError()
                      : _buildContent(),
                ),
                _buildBottomBar(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _store.starterError.value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _TextButton(label: 'Try Again', onTap: _store.loadStarterPack),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final categories = _store.groupedStarters.value;
    final categoryNames = categories.keys.toList();

    if (categoryNames.isEmpty) {
      return const Center(
        child: Text(
          'No items available',
          style: TextStyle(fontSize: 16, color: AppColors.textTertiary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
      itemCount: categoryNames.length,
      separatorBuilder: (_, _) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final category = categoryNames[index];
        final items = categories[category]!;
        return _CategorySection(
          store: _store,
          category: category,
          items: items,
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Observer(
      builder: (_) {
        final count = _store.selectedCount.value;
        final isAdding = _store.isBulkAdding.value;

        return Container(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PrimaryButton(
                  label: isAdding ? 'Adding...' : 'Add Selected ($count)',
                  onTap: isAdding || count == 0
                      ? null
                      : () async {
                          HapticFeedback.mediumImpact();
                          await _store.addSelectedStarters();
                          if (mounted) {
                            context.pop();
                            _showSuccessSnackBar(count);
                          }
                        },
                  isLoading: isAdding,
                ),
                const SizedBox(height: 12),
                _TextButton(label: 'Skip for now', onTap: () => context.pop()),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(int count) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        backgroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Text(
              '$count items added!',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Set up your kitchen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the staples you usually have at home. We\'ll use them to ground your meal recommendations.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Section ──────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final PantryStore store;
  final String category;
  final List<PantryStarterItem> items;

  const _CategorySection({
    required this.store,
    required this.category,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final isFullySelected = store.isCategoryFullySelected(category);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (isFullySelected) {
                      store.deselectAllInCategory(category);
                    } else {
                      store.selectAllInCategory(category);
                    }
                  },
                  child: Text(
                    isFullySelected ? 'Deselect all' : 'Select all',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items
                  .map((item) => _StarterChip(store: store, item: item))
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

// ── Starter Chip ──────────────────────────────────────────────────────────

class _StarterChip extends StatelessWidget {
  final PantryStore store;
  final PantryStarterItem item;

  const _StarterChip({required this.store, required this.item});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final isSelected = store.selectedStarterNames.contains(item.name);

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            store.toggleStarterItem(item.name);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.textPrimary : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.textPrimary : AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.textOnPrimary
                        : AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.check_rounded,
                    color: AppColors.textOnPrimary,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Buttons ───────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _PrimaryButton({
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.border : AppColors.textPrimary,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textOnPrimary,
                  ),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: onTap == null
                      ? AppColors.textTertiary
                      : AppColors.textOnPrimary,
                  letterSpacing: -0.3,
                ),
              ),
      ),
    );
  }
}

class _TextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
