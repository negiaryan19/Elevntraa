import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../domain/models/patient.dart';
import '../../../l10n/app_localizations.dart';

const _kBlue600 = Color(0xFF2563EB);
const _kTeal500 = Color(0xFF14B8A6);

/// Search saved patients by name or number. Tapping one opens their report
/// (PatientDetailScreen), from where the doctor can start a new consultation.
class ExistingPatientScreen extends ConsumerStatefulWidget {
  const ExistingPatientScreen({super.key});

  @override
  ConsumerState<ExistingPatientScreen> createState() =>
      _ExistingPatientScreenState();
}

class _ExistingPatientScreenState extends ConsumerState<ExistingPatientScreen> {
  List<PatientProfile> _results = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String q) async {
    setState(() {
      _query = q;
      _loading = true;
    });
    final repo = ref.read(patientRepositoryProvider);
    final res = q.trim().isEmpty ? await repo.recent() : await repo.search(q);
    if (mounted) {
      setState(() {
        _results = res;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
        title: Text(
          AppLocalizations.of(context)!.findPatientTitle,
          style: AppTypography.titleMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: AppSpacing.radiusXl,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  boxShadow: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.cardShadowDark
                      : AppColors.cardShadow,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: TextField(
                        autofocus: true,
                        onChanged: _search,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(
                            context,
                          )!.searchByNameOrNumber,
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          filled: false,
                        ),
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? _EmptyState(hasQuery: _query.trim().isNotEmpty)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      itemCount: _results.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.m),
                      itemBuilder: (context, i) =>
                          _PatientTile(patient: _results[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  const _PatientTile({required this.patient});
  final PatientProfile patient;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final meta = [
      if (patient.age != null) '${patient.age} ${t.years}',
      _sexLabel(t, patient.sex),
      if (patient.whatsappNumber != null) '+91 ${patient.whatsappNumber}',
    ].where((s) => s.isNotEmpty && s != '—').join(' • ');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(
        AppRoute.patient.build(params: {'patientId': patient.id}),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppSpacing.radiusXl,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? AppColors.cardShadowDark
              : AppColors.cardShadow,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kBlue600, _kTeal500],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name,
                    style: AppTypography.titleSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      meta,
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  static String _sexLabel(AppLocalizations t, Sex? sex) {
    switch (sex) {
      case Sex.male:
        return t.male;
      case Sex.female:
        return t.female;
      case Sex.other:
        return t.other;
      case null:
        return '';
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery});
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_search_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            hasQuery
                ? AppLocalizations.of(context)!.noMatchingPatients
                : AppLocalizations.of(context)!.noPatientsYet,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
