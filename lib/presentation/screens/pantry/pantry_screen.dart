import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/main.dart' show dashboardStore;
import 'package:diet_coach_ai/shared/models/home_models.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  @override
  void initState() {
    super.initState();
    dashboardStore.loadPantry();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Observer(
          builder: (_) {
            final items = dashboardStore.pantry;
            final isLoading = dashboardStore.isLoadingPantry.value;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _Header()),
                const SliverToBoxAdapter(child: _PantryHint()),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (isLoading)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (items.isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Your pantry is empty',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.15,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _PantryTile(item: items[i]),
                        childCount: items.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your pantry',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Recommendations stay grounded in what you actually have',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textTertiary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PantryHint extends StatelessWidget {
  const _PantryHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "I'll only suggest meals from this list until it runs thin.",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.1,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PantryTile extends StatelessWidget {
  final PantryItem item;
  const _PantryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 28)),
              const Spacer(),
              if (item.isHighProtein)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.proteinLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'HIGH PROTEIN',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.protein,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          if (item.quantityHint != null) ...[
            const SizedBox(height: 3),
            Text(
              item.quantityHint!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
