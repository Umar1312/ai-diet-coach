import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:diet_coach_ai/shared/widgets/stepper_slider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/core/constants/app_constants.dart';
import 'package:diet_coach_ai/core/di/providers.dart';
import 'package:diet_coach_ai/core/legal/legal_links.dart';
import 'package:diet_coach_ai/core/router/safe_navigation.dart';
import 'package:diet_coach_ai/main.dart'
    show authStore, dashboardStore, profileStore, subscriptionStore;
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

  String _genderDisplay(String gender) {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      default:
        return gender;
    }
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

  Future<void> _manageSubscription() async {
    HapticFeedback.selectionClick();
    subscriptionStore.clearError();
    await subscriptionStore.manageSubscription();
    if (!mounted) return;
    final message = subscriptionStore.errorMessage.value;
    if (message == null || message.isEmpty) return;
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
          content: Text(message),
        ),
      );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DeleteAccountSheet(),
    );
    if (confirmed != true) return;

    HapticFeedback.mediumImpact();
    final deleted = await profileStore.deleteAccount();
    if (!mounted) return;

    if (!deleted) {
      final message = profileStore.errorMessage.value;
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
            content: Text(
              message.isEmpty ? 'Unable to delete your account.' : message,
            ),
          ),
        );
      return;
    }

    await authStore.finishAccountDeletion();
    dashboardStore.reset();
    profileStore.reset();
    if (mounted) context.go('/login');
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
            final isDeleting = profileStore.isDeleting.value;
            final error = profileStore.errorMessage.value;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _Header()),
                if (isLoading && user == null)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator.adaptive(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textPrimary,
                        ),
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
                      title: 'About you',
                      children: [
                        _ProfileCard(
                          icon: Icons.cake_rounded,
                          title: 'Age',
                          value: '${user.profile.age} years',
                          onTap: () => _showSliderEdit(
                            context,
                            title: 'Age',
                            value: user.profile.age.toDouble(),
                            min: 16,
                            max: 80,
                            unit: 'years',
                            onSave: (value) =>
                                _save(ProfilePatchRequest(age: value.round())),
                          ),
                        ),
                        _ProfileCard(
                          icon: Icons.height_rounded,
                          title: 'Height',
                          value:
                              '${user.profile.heightCm.toStringAsFixed(0)} cm',
                          onTap: () => _showSliderEdit(
                            context,
                            title: 'Height',
                            value: user.profile.heightCm,
                            min: 120,
                            max: 230,
                            unit: 'cm',
                            onSave: (value) => _save(
                              ProfilePatchRequest(
                                heightCm: value.roundToDouble(),
                              ),
                            ),
                          ),
                        ),
                        _ProfileCard(
                          icon: Icons.person_outline_rounded,
                          title: 'Gender',
                          value: _genderDisplay(user.profile.gender),
                          onTap: () => _showDetailedOptionEdit(
                            context,
                            title: 'Gender',
                            current: user.profile.gender,
                            options: const [
                              _OptionDetail('male', 'Male'),
                              _OptionDetail('female', 'Female'),
                            ],
                            onSelected: (value) =>
                                _save(ProfilePatchRequest(gender: value)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _Section(
                      title: 'Goals',
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
                        _ProfileCard(
                          icon: Icons.track_changes_rounded,
                          title: 'Goal',
                          value: _goalDisplay(user.profile.goal),
                          onTap: () => _showDetailedOptionEdit(
                            context,
                            title: 'Goal',
                            current: user.profile.goal,
                            options: const [
                              _OptionDetail(
                                'lose_weight',
                                'Lose Weight',
                                'Build a sustainable calorie deficit.',
                              ),
                              _OptionDetail(
                                'maintain',
                                'Maintain',
                                'Stay consistent at your current weight.',
                              ),
                              _OptionDetail(
                                'gain_muscle',
                                'Gain Muscle',
                                'Fuel training and gradual muscle growth.',
                              ),
                            ],
                            onSelected: (value) =>
                                _save(ProfilePatchRequest(goal: value)),
                          ),
                        ),
                        _ProfileCard(
                          icon: Icons.monitor_weight_rounded,
                          title: 'Current weight',
                          value:
                              '${user.profile.weightKg.toStringAsFixed(1)} kg',
                          onTap: () => _showSliderEdit(
                            context,
                            title: 'Current weight',
                            value: user.profile.weightKg,
                            unit: 'kg',
                            min: 30,
                            max: 200,
                            alternateUnit: 'lb',
                            alternateUnitFactor: 2.20462,
                            onSave: (value) =>
                                _save(ProfilePatchRequest(weightKg: value)),
                          ),
                        ),
                        _ProfileCard(
                          icon: Icons.flag_rounded,
                          title: 'Target weight',
                          value:
                              '${user.profile.targetWeightKg.toStringAsFixed(1)} kg',
                          onTap: () => _showSliderEdit(
                            context,
                            title: 'Target weight',
                            value: user.profile.targetWeightKg,
                            unit: 'kg',
                            min: 30,
                            max: 200,
                            alternateUnit: 'lb',
                            alternateUnitFactor: 2.20462,
                            onSave: (value) => _save(
                              ProfilePatchRequest(targetWeightKg: value),
                            ),
                          ),
                        ),
                        _ProfileCard(
                          icon: Icons.directions_run_rounded,
                          title: 'Activity level',
                          value: _activityDisplay(user.profile.activityLevel),
                          onTap: () => _showDetailedOptionEdit(
                            context,
                            title: 'Activity level',
                            current: user.profile.activityLevel,
                            options: const [
                              _OptionDetail(
                                'sedentary',
                                'Sedentary',
                                'Little to no intentional exercise.',
                              ),
                              _OptionDetail(
                                'light',
                                'Lightly Active',
                                'Light exercise 1–3 days a week.',
                              ),
                              _OptionDetail(
                                'moderate',
                                'Moderately Active',
                                'Exercise 3–5 days a week.',
                              ),
                              _OptionDetail(
                                'active',
                                'Very Active',
                                'Hard exercise 6–7 days a week.',
                              ),
                              _OptionDetail(
                                'very_active',
                                'Extremely Active',
                                'Very hard training or a physical job.',
                              ),
                            ],
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
                          onTap: () => _showFoodPreferencesEdit(context, user),
                        ),
                        _ProfileCard(
                          icon: Icons.ramen_dining_rounded,
                          title: 'Preferred cuisines',
                          value: user.profile.preferredCuisines.isEmpty
                              ? 'Not set'
                              : user.profile.preferredCuisines.join(', '),
                          onTap: () => _showFoodPreferencesEdit(context, user),
                        ),
                      ],
                    ),
                  ),
                  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
                    SliverToBoxAdapter(
                      child: _Section(
                        title: 'Reminders',
                        children: [
                          _ProfileCard(
                            icon: Icons.notifications_active_outlined,
                            title: 'Meal check-ins',
                            value: 'Times and notification settings',
                            onTap: () => context.push('/profile/notifications'),
                          ),
                        ],
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: _Section(
                      title: 'Subscription',
                      children: [
                        _ProfileCard(
                          icon: Icons.workspace_premium_rounded,
                          title: 'NextMeal Pro',
                          value: subscriptionStore.displayStatus,
                          onTap: _manageSubscription,
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _Section(
                      title: 'Legal',
                      children: [
                        _ProfileCard(
                          icon: Icons.description_outlined,
                          title: 'Terms of Use',
                          value: 'How NextMeal works',
                          onTap: LegalLinks.openTermsOfUse,
                        ),
                        _ProfileCard(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          value: 'How we handle your data',
                          onTap: LegalLinks.openPrivacyPolicy,
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
                  SliverToBoxAdapter(
                    child: _DeleteAccountButton(
                      isDeleting: isDeleting,
                      onDelete: _deleteAccount,
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
            onTap: () => context.popOrGo('/home'),
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
                    user.email ?? 'NextMeal',
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

class _DeleteAccountButton extends StatelessWidget {
  final bool isDeleting;
  final VoidCallback onDelete;

  const _DeleteAccountButton({
    required this.isDeleting,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      child: GestureDetector(
        onTap: isDeleting
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onDelete();
              },
        child: Container(
          width: double.infinity,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
          ),
          child: isDeleting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator.adaptive(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
                  ),
                )
              : const Text(
                  'Delete Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
        ),
      ),
    );
  }
}

class _DeleteAccountSheet extends StatelessWidget {
  const _DeleteAccountSheet();

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Delete your account?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'This permanently deletes your profile, meal history, pantry, and uploaded meal photos. This cannot be undone.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Deleting your account does not cancel an active subscription. Cancel it first in your device subscription settings.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Permanently Delete Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.pop(context, false),
            child: const SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  'Keep my account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showSliderEdit(
  BuildContext context, {
  required String title,
  required double value,
  required String unit,
  required double min,
  required double max,
  String? alternateUnit,
  double? alternateUnitFactor,
  required ValueChanged<double> onSave,
}) {
  var selectedValue = value.clamp(min, max);
  var usesAlternateUnit = false;
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (context, setModalState) => _SheetFrame(
        title: title,
        child: Column(
          children: [
            if (alternateUnit != null) ...[
              _UnitPicker(
                primaryUnit: unit,
                alternateUnit: alternateUnit,
                usesAlternateUnit: usesAlternateUnit,
                onChanged: (value) =>
                    setModalState(() => usesAlternateUnit = value),
              ),
              const SizedBox(height: 18),
            ],
            Text(
              (usesAlternateUnit
                      ? selectedValue * alternateUnitFactor!
                      : selectedValue)
                  .toStringAsFixed(unit == 'years' ? 0 : 1),
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              usesAlternateUnit ? alternateUnit! : unit,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.surface,
                thumbColor: AppColors.primary,
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
              ),
              child: StepperSlider(
                semanticLabel:
                    '$title in ${usesAlternateUnit ? alternateUnit : unit}',
                step: unit == 'years' ? 1 : .1,
                value: usesAlternateUnit
                    ? selectedValue * alternateUnitFactor!
                    : selectedValue,
                min: usesAlternateUnit ? min * alternateUnitFactor! : min,
                max: usesAlternateUnit ? max * alternateUnitFactor! : max,
                divisions: usesAlternateUnit
                    ? ((max - min) * alternateUnitFactor!).round()
                    : (max - min).round(),
                onChanged: (newValue) => setModalState(() {
                  selectedValue = usesAlternateUnit
                      ? newValue / alternateUnitFactor!
                      : newValue;
                }),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${usesAlternateUnit ? (min * alternateUnitFactor!).round() : min.round()}',
                  style: const TextStyle(color: AppColors.textTertiary),
                ),
                Text(
                  '${usesAlternateUnit ? (max * alternateUnitFactor!).round() : max.round()}',
                  style: const TextStyle(color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SheetButton(
              label: 'Save',
              onTap: () {
                Navigator.pop(context);
                onSave(selectedValue);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _UnitPicker extends StatelessWidget {
  final String primaryUnit;
  final String alternateUnit;
  final bool usesAlternateUnit;
  final ValueChanged<bool> onChanged;

  const _UnitPicker({
    required this.primaryUnit,
    required this.alternateUnit,
    required this.usesAlternateUnit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UnitPickerOption(
              label: primaryUnit,
              selected: !usesAlternateUnit,
              onTap: () => onChanged(false),
            ),
            _UnitPickerOption(
              label: alternateUnit,
              selected: usesAlternateUnit,
              onTap: () => onChanged(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitPickerOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UnitPickerOption({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.background : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _OptionDetail {
  final String value;
  final String label;
  final String? description;

  const _OptionDetail(this.value, this.label, [this.description]);
}

Future<void> _showDetailedOptionEdit(
  BuildContext context, {
  required String title,
  required String current,
  required List<_OptionDetail> options,
  required ValueChanged<String> onSelected,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _SheetFrame(
      title: title,
      child: Column(
        children: [
          for (final option in options)
            _DetailedSheetOption(
              label: option.label,
              description: option.description,
              selected: option.value == current,
              onTap: () {
                Navigator.pop(context);
                onSelected(option.value);
              },
            ),
        ],
      ),
    ),
  );
}

const _profileCountries = <_ProfileCountryOption>[
  _ProfileCountryOption('IN', 'India', '🇮🇳'),
  _ProfileCountryOption('PK', 'Pakistan', '🇵🇰'),
  _ProfileCountryOption('AE', 'United Arab Emirates', '🇦🇪'),
  _ProfileCountryOption('US', 'United States', '🇺🇸'),
  _ProfileCountryOption('GB', 'United Kingdom', '🇬🇧'),
  _ProfileCountryOption('CA', 'Canada', '🇨🇦'),
  _ProfileCountryOption('AU', 'Australia', '🇦🇺'),
];

const _profileCuisines = <String, List<String>>{
  'IN': [
    'North Indian',
    'South Indian',
    'Mughlai',
    'Hyderabadi',
    'Punjabi',
    'Bengali',
    'Gujarati',
    'Tamil',
    'Kerala',
  ],
  'PK': ['Pakistani', 'Punjabi', 'Mughlai', 'Sindhi', 'Pashtun'],
  'AE': ['Emirati', 'Middle Eastern', 'Levantine', 'Indian'],
  'US': ['American', 'Mexican', 'Italian', 'Asian'],
  'GB': ['British', 'Indian', 'Mediterranean', 'European'],
  'CA': ['Canadian', 'Indian', 'Asian', 'Mediterranean'],
  'AU': ['Australian', 'Asian', 'Mediterranean', 'Indian'],
};

class _ProfileCountryOption {
  final String code;
  final String name;
  final String emoji;

  const _ProfileCountryOption(this.code, this.name, this.emoji);
}

Future<void> _showFoodPreferencesEdit(BuildContext context, User user) {
  final initialCountry = user.profile.country;
  var country = _profileCountries.any((item) => item.code == initialCountry)
      ? initialCountry!
      : _profileCountries.first.code;
  final selected = user.profile.preferredCuisines.toSet();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (context, setModalState) => _FoodPreferencesEditSheet(
        country: country,
        selectedCuisines: selected,
        onCountryChanged: (value) => setModalState(() {
          country = value;
          selected.clear();
        }),
        onCuisineToggled: (value) => setModalState(() {
          selected.contains(value)
              ? selected.remove(value)
              : selected.add(value);
        }),
        onSave: () {
          Navigator.pop(context);
          profileStore.updateProfile(
            ProfilePatchRequest(
              country: country,
              preferredCuisines: selected.toList(),
            ),
          );
        },
      ),
    ),
  );
}

class _FoodPreferencesEditSheet extends StatelessWidget {
  final String country;
  final Set<String> selectedCuisines;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onCuisineToggled;
  final VoidCallback onSave;

  const _FoodPreferencesEditSheet({
    required this.country,
    required this.selectedCuisines,
    required this.onCountryChanged,
    required this.onCuisineToggled,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final cuisines = _profileCuisines[country] ?? const <String>[];
    return Container(
      height: MediaQuery.sizeOf(context).height * .86,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 20, 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Food preferences',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.6,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.surface,
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
              children: [
                const Text(
                  'Country',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: country,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                  items: _profileCountries
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.code,
                          child: Text(
                            '${item.emoji}  ${item.name}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onCountryChanged(value);
                  },
                ),
                const SizedBox(height: 28),
                const Text(
                  'Your favorites',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pick the cuisines you want to see more often.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: cuisines.map((item) {
                    final selected = selectedCuisines.contains(item);
                    return GestureDetector(
                      onTap: () => onCuisineToggled(item),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            color: selected
                                ? AppColors.textOnPrimary
                                : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(28, 14, 28, 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border, width: .5),
              ),
            ),
            child: _SheetButton(label: 'Save', onTap: onSave),
          ),
        ],
      ),
    );
  }
}

Future<void> _showRestrictionsEdit(BuildContext context, User user) {
  final selected = user.profile.dietaryRestrictions.toSet();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (context, setModalState) => _RestrictionsEditSheet(
        selected: selected,
        onToggle: (value) {
          setModalState(() {
            if (selected.contains(value)) {
              selected.remove(value);
            } else {
              selected.add(value);
            }
          });
        },
        onSave: () {
          Navigator.pop(context);
          profileStore.updateProfile(
            ProfilePatchRequest(dietaryRestrictions: selected.toList()),
          );
        },
      ),
    ),
  );
}

class _RestrictionsEditSheet extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onSave;

  const _RestrictionsEditSheet({
    required this.selected,
    required this.onToggle,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 20, 12),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Dietary restrictions',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
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
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(28, 4, 28, 12),
              itemCount: AppConstants.dietaryRestrictions.length,
              itemBuilder: (context, index) {
                final item = AppConstants.dietaryRestrictions[index];
                final value = item['value']!;
                return _SheetOption(
                  label: item['label']!,
                  selected: selected.contains(value),
                  onTap: () => onToggle(value),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 14, 28, 12),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: _SheetButton(label: 'Save', onTap: onSave),
          ),
        ],
      ),
    );
  }
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

class _DetailedSheetOption extends StatelessWidget {
  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  const _DetailedSheetOption({
    required this.label,
    this.description,
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
            width: selected ? 1.2 : .5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
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
