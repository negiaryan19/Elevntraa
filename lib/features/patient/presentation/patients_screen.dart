import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/reveal.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../data/repositories/visit_repository.dart';
import '../../../domain/models/patient.dart';
import '../../../domain/models/visit.dart';
import '../../../l10n/app_localizations.dart';

const _kBlue600 = Color(0xFF2563EB);
const _kTeal500 = Color(0xFF14B8A6);

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  List<_PatientGroup> _groups = [];
  List<_PatientGroup> _filtered = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<_PatientGroup> groups;
    try {
      // Every patient in the clinic, not just those inside the most recent
      // N visits: a truncated window made older patients vanish from the
      // list and from search once the doctor had seen enough people.
      final entries = await ref
          .read(visitRepositoryProvider)
          .latestPerPatient();
      final patients = await ref
          .read(patientRepositoryProvider)
          .byIds(entries.map((e) => e.latestVisit.patientId));
      groups = [
        for (final e in entries)
          _PatientGroup(
            patient: patients[e.latestVisit.patientId],
            latestVisit: e.latestVisit,
            visitCount: e.visitCount,
          ),
      ];
    } catch (e) {
      // A database error must not leave the tab spinning forever.
      debugPrint('[patients] load failed: $e');
      groups = const [];
    }

    if (mounted) {
      setState(() {
        _groups = groups;
        _filtered = _applyQuery(groups, _query);
        _loading = false;
      });
    }
  }

  static List<_PatientGroup> _applyQuery(
    List<_PatientGroup> groups,
    String query,
  ) {
    if (query.isEmpty) return groups;
    final lower = query.toLowerCase();
    return groups.where((g) {
      final name = (g.patient?.name ?? '').toLowerCase();
      final phone = (g.patient?.whatsappNumber ?? g.patient?.phone ?? '')
          .toLowerCase();
      return name.contains(lower) || phone.contains(lower);
    }).toList();
  }

  void _onSearch(String q) {
    setState(() {
      _query = q;
      _filtered = _applyQuery(_groups, q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    // Stats count unique patients, not consultations
    final today = _groups
        .where((g) => _isToday(g.latestVisit.createdAt))
        .length;
    final thisWeek = _groups
        .where((g) => _isThisWeek(g.latestVisit.createdAt))
        .length;

    return Scaffold(
      // theme-driven background
      body: Column(
        children: [
          // Gradient header
          Reveal(
            delayMs: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_kBlue600, _kTeal500],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.adaptive(context, AppSpacing.lg),
                    AppSpacing.lg,
                    AppSpacing.adaptive(context, AppSpacing.xl + AppSpacing.s),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.patientHistory,
                        style: AppTypography.headlineLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        t.viewAllConsultations,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: _StatPill(
                              value: '${_groups.length}',
                              label: t.statTotal,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: _StatPill(
                              value: '$thisWeek',
                              label: t.statThisWeek,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: _StatPill(
                              value: '$today',
                              label: t.statToday,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Search bar (pulled up)
          Reveal(
            delayMs: 90,
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: AppSpacing.radiusXl,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    boxShadow: AppColors.cardShadow,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.m,
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
                          onChanged: _onSearch,
                          decoration: InputDecoration(
                            hintText: t.searchPatientsHint,
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
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: AppSpacing.radiusSm,
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Patient list — one card per unique patient
          Expanded(
            child: Reveal(
              delayMs: 180,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                  ? _EmptyState(hasQuery: _query.isNotEmpty)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.m),
                      itemBuilder: (context, i) {
                        final group = _filtered[i];
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: group.patient == null
                              ? null
                              : () async {
                                  await context.push(
                                    AppRoute.patient.build(
                                      params: {'patientId': group.patient!.id},
                                    ),
                                  );
                                  // The list is loaded once, so a name or
                                  // number edited on the patient's page (or
                                  // a new visit started from it) would stay
                                  // stale here until the tab was rebuilt.
                                  if (mounted) await _load();
                                },
                          child: _PatientCard(group: group),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  static bool _isThisWeek(DateTime dt) {
    final now = DateTime.now();
    return now.difference(dt).inDays < 7;
  }
}

// ── Data ─────────────────────────────────────────────────────────────────────

class _PatientGroup {
  const _PatientGroup({
    required this.patient,
    required this.latestVisit,
    required this.visitCount,
  });
  final PatientProfile? patient;
  final VisitRecord latestVisit;
  final int visitCount;
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: AppSpacing.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.group});
  final _PatientGroup group;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final patient = group.patient;
    final visit = group.latestVisit;

    final name = patient?.name ?? t.unknownPatient;
    final ageSex = [
      if (patient?.age != null) '${patient!.age} ${t.years}',
      if (patient?.sex != null)
        patient!.sex == Sex.male
            ? t.male
            : patient.sex == Sex.female
            ? t.female
            : t.other,
    ].join(' • ');
    final diagnosis = visit.insight?.diagnosis ?? '';
    final dateTime =
        '${_formatDate(t, visit.createdAt)} · ${visit.createdAt.hour.toString().padLeft(2, '0')}:${visit.createdAt.minute.toString().padLeft(2, '0')}';
    final countLabel =
        '${group.visitCount} ${group.visitCount == 1 ? t.consultationOne : t.consultationMany}';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppSpacing.radiusXl,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: AppColors.cardShadow,
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
                // Name row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTypography.titleSmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // Consultation count chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        countLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
                // Age / sex
                if (ageSex.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    ageSex,
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Last visit date + time
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        dateTime,
                        style: AppTypography.labelSmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Latest diagnosis
                if (diagnosis.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.description_rounded,
                        size: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          diagnosis,
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(AppLocalizations t, DateTime dt) {
    final now = DateTime.now();
    final diff = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(dt.year, dt.month, dt.day)).inDays;
    if (diff == 0) return t.statToday;
    if (diff == 1) return t.yesterday;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
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
                ? AppLocalizations.of(context)!.noPatientsFound
                : AppLocalizations.of(context)!.noConsultationsYet,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
