import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../domain/models/visit.dart';
import '../../../l10n/app_localizations.dart';
import '../../consultation/data/pending_consultations.dart';

/// Pending consultations with the patient each belongs to.
final _pendingWithNamesProvider =
    FutureProvider<List<({VisitRecord visit, String name})>>((ref) async {
      final visits = await ref.watch(pendingVisitsProvider.future);
      if (visits.isEmpty) return const [];
      final patients = await ref
          .watch(patientRepositoryProvider)
          .byIds(visits.map((v) => v.patientId));
      return [
        for (final v in visits)
          (visit: v, name: patients[v.patientId]?.name ?? ''),
      ];
    });

/// Consultations recorded without internet, on Home where the doctor will see
/// them: waiting, being processed, ready to review, or failed (roadmap items
/// 13, 14). Takes no space when there are none.
///
/// Watching [pendingConsultationsProvider] here also keeps the queue alive
/// for as long as the doctor is in the app.
class PendingConsultationsCard extends ConsumerWidget {
  const PendingConsultationsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final processingId = ref
        .watch(pendingConsultationsProvider)
        .processingVisitId;
    final items = ref.watch(_pendingWithNamesProvider).value ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();

    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('pending_consultations_card'),
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.pendingTitle,
            style: AppTypography.titleSmall.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.s),
          for (final item in items)
            _PendingRow(
              visit: item.visit,
              name: item.name.isEmpty ? t.patientFallback : item.name,
              processing: item.visit.id == processingId,
            ),
        ],
      ),
    );
  }
}

class _PendingRow extends ConsumerWidget {
  const _PendingRow({
    required this.visit,
    required this.name,
    required this.processing,
  });

  final VisitRecord visit;
  final String name;
  final bool processing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final queue = ref.read(pendingConsultationsProvider.notifier);
    final state = visit.pendingState;

    final (IconData icon, Color color, String status) = switch (state) {
      PendingState.ready => (
        Icons.check_circle_rounded,
        scheme.primary,
        t.pendingReady,
      ),
      PendingState.failed => (
        Icons.error_outline_rounded,
        scheme.error,
        t.pendingFailed,
      ),
      _ when processing => (
        Icons.sync_rounded,
        scheme.primary,
        t.pendingProcessing,
      ),
      _ => (Icons.cloud_off_rounded, scheme.onSurfaceVariant, t.pendingQueued),
    };

    // Why it failed, in the doctor's language. An unknown stored code (from a
    // newer build) falls back to the generic sentence.
    final reason = state == PendingState.failed
        ? failureCodeText(
            t,
            FailureCode.values
                    .where((c) => c.name == visit.pendingError)
                    .firstOrNull ??
                FailureCode.unknown,
          )
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: Key('pending_row_${visit.id}'),
            borderRadius: AppSpacing.radiusMd,
            // Only a processed consultation opens: it becomes an ordinary
            // visit the moment the doctor goes to review it.
            onTap: state != PendingState.ready
                ? null
                : () async {
                    await queue.clear(visit.id);
                    if (context.mounted) {
                      context.push(
                        AppRoute.review.build(params: {'visitId': visit.id}),
                      );
                    }
                  },
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        reason == null ? status : '$status · $reason',
                        style: AppTypography.bodySmall.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
                if (state == PendingState.ready)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
          if (state == PendingState.failed)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: Key('pending_dismiss_${visit.id}'),
                  onPressed: () => queue.clear(visit.id),
                  child: Text(t.pendingDismiss),
                ),
                // A recording with nothing in it has nothing more to give
                // the second time; the recording screen makes the same call.
                if (visit.pendingError != FailureCode.invalidAudio.name)
                  TextButton(
                    key: Key('pending_retry_${visit.id}'),
                    onPressed: () => queue.retry(visit.id),
                    child: Text(t.profileRetry),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
