import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../features/consultation/presentation/intake_choice_screen.dart';
import '../features/consultation/presentation/intake_screen.dart';
import '../features/consultation/presentation/recording_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/patient/presentation/existing_patient_screen.dart';
import '../features/patient/presentation/patient_detail_screen.dart';
import '../features/patient/presentation/patients_screen.dart';
import '../features/prescription/presentation/pdf_preview_screen.dart';
import '../features/prescription/presentation/review_sign_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../l10n/app_localizations.dart';

/// Named route table. Keep paths centralized so feature code uses
/// [AppRoute.foo.path] / `context.go(AppRoute.foo.path)` and we don't have
/// raw strings sprinkled around.
enum AppRoute {
  onboarding('/onboarding'),
  home('/'),
  patients('/patients'),
  settings('/settings'),
  intake('/intake'),
  intakeForm('/intake/form'),
  intakeExisting('/intake/existing'),
  recording('/recording/:visitId'),
  review('/review/:visitId'),
  pdf('/pdf/:visitId'),
  patient('/patient/:patientId');

  const AppRoute(this.path);
  final String path;

  String build({Map<String, String> params = const {}}) {
    var result = path;
    params.forEach((k, v) => result = result.replaceAll(':$k', v));
    return result;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.home.path,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoute.onboarding.path,
        name: AppRoute.onboarding.name,
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            _MainShell(location: state.uri.toString(), child: child),
        routes: [
          GoRoute(
            path: AppRoute.home.path,
            name: AppRoute.home.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _TabBackHandler(isHome: true, child: HomeScreen()),
            ),
          ),
          GoRoute(
            path: AppRoute.patients.path,
            name: AppRoute.patients.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _TabBackHandler(isHome: false, child: PatientsScreen()),
            ),
          ),
          GoRoute(
            path: AppRoute.settings.path,
            name: AppRoute.settings.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _TabBackHandler(isHome: false, child: SettingsScreen()),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.intake.path,
        name: AppRoute.intake.name,
        builder: (context, state) => const IntakeChoiceScreen(),
      ),
      GoRoute(
        path: AppRoute.intakeForm.path,
        name: AppRoute.intakeForm.name,
        builder: (context, state) =>
            IntakeScreen(patientId: state.uri.queryParameters['patientId']),
      ),
      GoRoute(
        path: AppRoute.intakeExisting.path,
        name: AppRoute.intakeExisting.name,
        builder: (context, state) => const ExistingPatientScreen(),
      ),
      GoRoute(
        path: AppRoute.recording.path,
        name: AppRoute.recording.name,
        builder: (context, state) => RecordingScreen(
          visitId: state.pathParameters['visitId']!,
          append: state.uri.queryParameters['append'] == 'true',
          fromReview: state.uri.queryParameters['fromReview'] == 'true',
        ),
      ),
      GoRoute(
        path: AppRoute.review.path,
        name: AppRoute.review.name,
        builder: (context, state) =>
            ReviewSignScreen(visitId: state.pathParameters['visitId']!),
      ),
      GoRoute(
        path: AppRoute.pdf.path,
        name: AppRoute.pdf.name,
        builder: (context, state) =>
            PdfPreviewScreen(visitId: state.pathParameters['visitId']!),
      ),
      GoRoute(
        path: AppRoute.patient.path,
        name: AppRoute.patient.name,
        builder: (context, state) =>
            PatientDetailScreen(patientId: state.pathParameters['patientId']!),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.notFound)),
      body: Center(
        child: Text('${AppLocalizations.of(context)!.notFound}: ${state.uri}'),
      ),
    ),
  );
});

/// Shell that hosts the bottom-nav tabs.
///
/// The [PopScope] lives here at the ROOT navigator level (not inside the
/// shell's nested navigator) so it intercepts back presses even after a modal
/// opened with `useRootNavigator: true` has been dismissed — which previously
/// caused the tab's nested-navigator PopScope to be bypassed, exiting the app.
///
/// canPop: true  → Home tab: let the root navigator pop the shell (exits app).
/// canPop: false → other tabs: block pop and navigate to Home instead.
class _MainShell extends StatelessWidget {
  const _MainShell({required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isHome = location == AppRoute.home.path;
    return PopScope(
      canPop: isHome,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // Home tab already handled by the system
        context.go(AppRoute.home.path);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: child,
        bottomNavigationBar: _BottomNavBar(location: location),
      ),
    );
  }
}

/// Handles back presses inside the nested navigator (normal tab navigation).
///
/// The root-level [_MainShell] PopScope catches back presses that arrive at
/// the ROOT navigator — specifically, the press that follows dismissing a
/// `useRootNavigator: true` modal (Bug 1 scenario). For all other back presses
/// Flutter routes through the NESTED navigator first, hitting this handler.
class _TabBackHandler extends StatelessWidget {
  const _TabBackHandler({required this.isHome, required this.child});
  final bool isHome;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: isHome,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(AppRoute.home.path);
      },
      child: child,
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    final isHome = location == '/' || location == '';
    final isPatients = location.startsWith('/patients');
    final isSettings = location.startsWith('/settings');

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.s,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: AppLocalizations.of(context)!.navHome,
                route: AppRoute.home.path,
                isActive: isHome,
              ),
              _NavItem(
                icon: Icons.people_rounded,
                label: AppLocalizations.of(context)!.navPatients,
                route: AppRoute.patients.path,
                isActive: isPatients,
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: AppLocalizations.of(context)!.navSettings,
                route: AppRoute.settings.path,
                isActive: isSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: () => context.go(route),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.s,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (isActive)
                  Container(
                    width: 44,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: AppSpacing.radiusMd,
                    ),
                  ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: AppTypography.labelSmall.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
