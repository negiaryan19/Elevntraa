import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: EmptyState(
            title: 'Welcome to Rxvarta',
            message:
                'Doctor profile + API key setup will live here. Coming in '
                'milestone 3.',
            icon: Icons.medical_services_outlined,
          ),
        ),
      ),
    );
  }
}
