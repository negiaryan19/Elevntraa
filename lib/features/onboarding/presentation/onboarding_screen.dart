import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/app_localizations.dart';

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
            title: AppLocalizations.of(context)!.welcomeToRxvarta,
            message: AppLocalizations.of(context)!.onboardingMessage,
            icon: Icons.medical_services_outlined,
          ),
        ),
      ),
    );
  }
}
