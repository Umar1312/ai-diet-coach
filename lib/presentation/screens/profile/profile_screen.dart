import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/core/constants/app_constants.dart';
import 'package:diet_coach_ai/core/di/providers.dart';
import 'package:diet_coach_ai/main.dart' show authStore, profileStore;
import 'package:diet_coach_ai/shared/models/user_setup_request.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    profileStore.loadProfile();
  }

  String _goalDisplay(String goal) {
    switch (goal) {
      case 'lose_weight':
        return 'Lose Weight';
      case 'maintain':
        return 'Maintain';
      case 'gain_muscle':
        return 'Gain Muscle';
      default:
        return goal;
    }
  }

  String _activityDisplay(String level) {
    const map = {
      'sedentary': 'Sedentary',
      'light': 'Lightly Active',
      'moderate': 'Moderately Active',
      'active': 'Very Active',
      'very_active': 'Extremely Active',
    };
    return map[level] ?? 'Moderately Active';
  }

  Future<void> _save(ProfilePatchRequest request) async {
    final ok = await profileStore.updateProfile(request);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            backgroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success),
                SizedBox(width: 12),
                Text(
                  'Updated',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Observer(
          builder: (_) {
            final user = profileStore.user.value;
            final isLoading = profileStore.isLoading.value;
            final error = profileStore.errorMessage.value;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _Header()),
                if (isLoading && user == null)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )
                else if (error.isNotEmpty && user == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ProfileError(message: error),
                  )
                else if (user != null) ...[
                  SliverToBoxAdapter(child: _Summary(user: user)),
                  SliverToBoxAdapter(
                    child: _Section(
                      title: 'Targets',
                      children: [
                        _ProfileCard(
                          icon: Icons.local_fire_department_rounded,
                          title: 'Calories',
                          value: '${user.targets.calories} cal',
                        ),
                        _ProfileCard(
                          icon: Icons.fitness_center_rounded,
                          title: 'Protein',
                          value: '${user.targets.proteinG}g',
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _Section(
                      title: 'Goal settings',
                      children: [
                        _ProfileCard(
                          icon: Icons.track_changes_rounded,
                          title: 'Goal',
                          value: _goalDisplay(user.profile.goal),
                          onTap: () => _showOptionEdit(
                            context,
                            title: 'Goal',
                            current: user.profile.goal,
                            options: const {
                              'lose_weight': 'Lose Weight',
                              'maintain': 'Maintain',
                              'gain_muscle': 'Gain Muscle',
                            },
                            onSelected: (value) =>
                                _save(ProfilePatchRequest(goal: value)),
                          ),
                        ),
                        _ProfileCard(
                          icon: Icons.monitor_weight_rounded,
                          title: 'Current weight',
                          value:
                              '${user.profile.weightKg.toStringAsFixed(1)} kg',
                          onTap: () => _showNumberEdit(
                            context,
                            title: 'Current weight',
                            value: user.profile.weightKg,
                            unit: 'kg',
                            min: 20,
                            max: 300,
                            onSave: (value) =>
                                _save(ProfilePatchRequest(weightKg: value)),
                          ),
                        ),
                        _ProfileCard(
                          icon: Icons.flag_rounded,
                          title: 'Target weight',
                          value:
                              '${user.profile.targetWeightKg.toStringAsFixed(1)} kg',
                          onTap: () => _showNumberEdit(
                            context,
                            title: 'Target weight',
                            value: user.profile.targetWeightKg,
                            unit: 'kg',
                            min: 20,
                            max: 300,
                            onSave: (value) => _save(
                              ProfilePatchRequest(targetWeightKg: value),
                            ),
                          ),
                        ),
                        _ProfileCard(
                          icon: Icons.directions_run_rounded,
                          title: 'Activity level',
                          value: _activityDisplay(user.profile.activityLevel),
                          onTap: () => _showOptionEdit(
                            context,
                            title: 'Activity level',
                            current: user.profile.activityLevel,
                            options: const {
                              'sedentary': 'Sedentary',
                              'light': 'Lightly Active',
                              'moderate': 'Moderately Active',
                              'active': 'Very Active',
                              'very_active': 'Extremely Active',
                            },
                            onSelected: (value) => _save(
                              ProfilePatchRequest(activityLevel: value),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _Section(
                      title: 'Food preferences',
                      children: [
                        _ProfileCard(
                          icon: Icons.restaurant_rounded,
                          title: 'Dietary restrictions',
                          value: user.profile.dietaryRestrictions.isEmpty
                              ? 'None'
                              : user.profile.dietaryRestrictions.join(', '),
                          onTap: () => _showRestrictionsEdit(context, user),
                        ),
                        _ProfileCard(
                          icon: Icons.public_rounded,
                          title: 'Country',
                          value: user.profile.country?.isNotEmpty == true
                              ? user.profile.country!
                              : 'Not set',
                          onTap: () => _showTextEdit(
                            context,
                            title: 'Country code',
                            value: user.profile.country ?? '',
                            hint: 'US, PK, IN',
                            onSave: (value) =>
                                _save(ProfilePatchRequest(country: value)),
                          ),
                        ),
                        _ProfileCard(
                          icon: Icons.ramen_dining_rounded,
                          title: 'Preferred cuisines',
                          value: user.profile.preferredCuisines.isEmpty
                              ? 'Not set'
                              : user.profile.preferredCuisines.join(', '),
                          onTap: () => _showTextEdit(
                            context,
                            title: 'Preferred cuisines',
                            value: user.profile.preferredCuisines.join(', '),
                            hint: 'Pakistani, Mexican',
                            onSave: (value) => _save(
                              ProfilePatchRequest(
                                preferredCuisines: value
                                    .split(',')
                                    .map((item) => item.trim())
                                    .where((item) => item.isNotEmpty)
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (error.isNotEmpty)
                    SliverToBoxAdapter(child: _InlineError(message: error)),
                  SliverToBoxAdapter(
                    child: _SignOutButton(
                      onSignOut: () async {
                        await authStore.signOut();
                        profileStore.reset();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
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
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Profile',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -1.0,
                height: 1.1,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final User user;

  const _Summary({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.email ?? 'AI Diet Buddy',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.profile.age} yrs, ${user.profile.heightCm.toStringAsFixed(0)} cm',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          for (final child in children) ...[child, const SizedBox(height: 10)],
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 18, 28, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  final String message;

  const _ProfileError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 42),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              profileStore.loadProfile(force: true);
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  final Future<void> Function() onSignOut;

  const _SignOutButton({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onSignOut();
        },
        child: Container(
          width: double.infinity,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Text(
            'Sign Out',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showOptionEdit(
  BuildContext context, {
  required String title,
  required String current,
  required Map<String, String> options,
  required ValueChanged<String> onSelected,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _SheetFrame(
      title: title,
      child: Column(
        children: [
          for (final entry in options.entries)
            _SheetOption(
              label: entry.value,
              selected: entry.key == current,
              onTap: () {
                Navigator.pop(context);
                onSelected(entry.key);
              },
            ),
        ],
      ),
    ),
  );
}

Future<void> _showNumberEdit(
  BuildContext context, {
  required String title,
  required double value,
  required String unit,
  required double min,
  required double max,
  required ValueChanged<double> onSave,
}) {
  final controller = TextEditingController(text: value.toStringAsFixed(1));
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SheetFrame(
      title: title,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                hintText: unit,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 18),
            _SheetButton(
              label: 'Save',
              onTap: () {
                final parsed = double.tryParse(controller.text.trim());
                if (parsed == null || parsed < min || parsed > max) return;
                Navigator.pop(context);
                onSave(parsed);
              },
            ),
          ],
        ),
      ),
    ),
  ).whenComplete(controller.dispose);
}

Future<void> _showTextEdit(
  BuildContext context, {
  required String title,
  required String value,
  required String hint,
  required ValueChanged<String> onSave,
}) {
  final controller = TextEditingController(text: value);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SheetFrame(
      title: title,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 18),
            _SheetButton(
              label: 'Save',
              onTap: () {
                Navigator.pop(context);
                onSave(controller.text.trim());
              },
            ),
          ],
        ),
      ),
    ),
  ).whenComplete(controller.dispose);
}

Future<void> _showRestrictionsEdit(BuildContext context, User user) {
  final selected = user.profile.dietaryRestrictions.toSet();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (context, setModalState) => _SheetFrame(
        title: 'Dietary restrictions',
        child: Column(
          children: [
            for (final item in AppConstants.dietaryRestrictions)
              _SheetOption(
                label: item['label']!,
                selected: selected.contains(item['value']),
                onTap: () {
                  setModalState(() {
                    final value = item['value']!;
                    if (selected.contains(value)) {
                      selected.remove(value);
                    } else {
                      selected.add(value);
                    }
                  });
                },
              ),
            const SizedBox(height: 12),
            _SheetButton(
              label: 'Save',
              onTap: () {
                Navigator.pop(context);
                profileStore.updateProfile(
                  ProfilePatchRequest(dietaryRestrictions: selected.toList()),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _SheetFrame extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetFrame({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SheetOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.textPrimary : AppColors.border,
            width: selected ? 1.2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SheetButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textOnPrimary,
          ),
        ),
      ),
    );
  }
}
