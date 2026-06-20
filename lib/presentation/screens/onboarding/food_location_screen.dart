import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../main.dart';
import '../../widgets/onboarding_progress_bar.dart';
import '../../widgets/primary_button.dart';

class FoodLocationScreen extends StatefulWidget {
  const FoodLocationScreen({super.key});

  @override
  State<FoodLocationScreen> createState() => _FoodLocationScreenState();
}

class _FoodLocationScreenState extends State<FoodLocationScreen> {
  static const _countries = <_CountryOption>[
    _CountryOption('IN', 'India', '🇮🇳'),
    _CountryOption('PK', 'Pakistan', '🇵🇰'),
    _CountryOption('AE', 'United Arab Emirates', '🇦🇪'),
    _CountryOption('US', 'United States', '🇺🇸'),
    _CountryOption('GB', 'United Kingdom', '🇬🇧'),
    _CountryOption('CA', 'Canada', '🇨🇦'),
    _CountryOption('AU', 'Australia', '🇦🇺'),
  ];

  static const _cuisines = <String, List<String>>{
    'IN': [
      'North Indian',
      'South Indian',
      'Mughlai',
      'Hyderabadi',
      'Punjabi',
      'Maharashtrian',
      'Bengali',
      'Gujarati',
    ],
    'PK': ['Pakistani', 'Punjabi', 'Mughlai', 'Sindhi', 'Pashtun'],
    'AE': ['Emirati', 'Middle Eastern', 'Levantine', 'Indian'],
    'US': ['American', 'Mexican', 'Italian', 'Asian'],
    'GB': ['British', 'Indian', 'Mediterranean', 'European'],
    'CA': ['Canadian', 'Indian', 'Asian', 'Mediterranean'],
    'AU': ['Australian', 'Asian', 'Mediterranean', 'Indian'],
  };

  late String _country;
  final Set<String> _selectedCuisines = {};

  @override
  void initState() {
    super.initState();
    final localeCode = PlatformDispatcher.instance.locale.countryCode;
    final supported = _countries.any((country) => country.code == localeCode);
    _country =
        onboardingStore.country ??
        (supported ? localeCode! : _countries.first.code);
    _selectedCuisines.addAll(onboardingStore.preferredCuisines);
  }

  void _continue() {
    HapticFeedback.mediumImpact();
    onboardingStore
      ..setCountry(_country)
      ..setPreferredCuisines(_selectedCuisines.toList());
    context.push('/onboarding/loading');
  }

  @override
  Widget build(BuildContext context) {
    final cuisineOptions = _cuisines[_country] ?? const <String>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const OnboardingProgressBar(step: 9, totalSteps: 10),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'What food feels\nlike home?',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'We’ll prioritize familiar meals, local names, and ingredients you can actually find.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _country,
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
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: _countries
                    .map(
                      (country) => DropdownMenuItem(
                        value: country.code,
                        child: Text(
                          '${country.emoji}  ${country.name}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  HapticFeedback.selectionClick();
                  setState(() {
                    _country = value;
                    _selectedCuisines.clear();
                  });
                },
              ),
              const SizedBox(height: 28),
              const Text(
                'Your favorites',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Optional — pick a few and we’ll tune suggestions around them.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: cuisineOptions.map((cuisine) {
                      final selected = _selectedCuisines.contains(cuisine);
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            selected
                                ? _selectedCuisines.remove(cuisine)
                                : _selectedCuisines.add(cuisine);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
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
                            cuisine,
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
                ),
              ),
              PrimaryButton(text: 'Continue', onPressed: _continue),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryOption {
  final String code;
  final String name;
  final String emoji;

  const _CountryOption(this.code, this.name, this.emoji);
}
