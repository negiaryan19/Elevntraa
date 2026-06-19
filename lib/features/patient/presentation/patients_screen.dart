import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../data/repositories/visit_repository.dart';
import '../../../domain/models/patient.dart';
import '../../../domain/models/visit.dart';

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

  static String _patientKey(PatientProfile p) =>
      '${p.name.trim().toLowerCase()}|${(p.whatsappNumber ?? p.phone ?? '').trim()}';

  Future<void> _load() async {
    final visits = await ref.read(visitRepositoryProvider).recent(limit: 50);
    final patientRepo = ref.read(patientRepositoryProvider);

    final rawEntries = <({VisitRecord visit, PatientProfile? patient})>[];
    for (final v in visits) {
      final p = await patientRepo.byId(v.patientId);
      rawEntries.add((visit: v, patient: p));
    }

    // Group by unique patient (name + phone)
    final grouped =
        <String, List<({VisitRecord visit, PatientProfile? patient})>>{};
    for (final e in rawEntries) {
      final key = e.patient == null
          ? 'unknown|${e.visit.patientId}'
          : _patientKey(e.patient!);
      grouped.putIfAbsent(key, () => []).add(e);
    }

    // Build groups; representative = most recent visit
    final groups =
        grouped.entries.map((e) {
          final sorted = e.value.toList()
            ..sort((a, b) => b.visit.createdAt.compareTo(a.visit.createdAt));
          return _PatientGroup(
            patient: sorted.first.patient,
            latestVisit: sorted.first.visit,
            visitCount: sorted.length,
          );
        }).toList()..sort(
          (a, b) => b.latestVisit.createdAt.compareTo(a.latestVisit.createdAt),
        );

    if (mounted) {
      setState(() {
        _groups = groups;
        _filtered = groups;
        _loading = false;
      });
    }
  }

  void _onSearch(String q) {
    setState(() {
      _query = q;
      final lower = q.toLowerCase();
      _filtered = q.isEmpty
          ? _groups
          : _groups.where((g) {
              final name = (g.patient?.name ?? '').toLowerCase();
              final phone =
                  (g.patient?.whatsappNumber ?? g.patient?.phone ?? '')
                      .toLowerCase();
              return name.contains(lower) || phone.contains(lower);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Stats count unique patients, not consultations
    final today = _groups
        .where((g) => _isToday(g.latestVisit.createdAt))
        .length;
    final thisWeek = _groups
        .where((g) => _isThisWeek(g.latestVisit.createdAt))
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Gradient header
          Container(
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
                      'Patient History',
                      style: AppTypography.headlineLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'View all consultations and records',
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
                            label: 'Total',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: _StatPill(
                            value: '$thisWeek',
                            label: 'This Week',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: _StatPill(value: '$today', label: 'Today'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Search bar (pulled up)
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.radiusXl,
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                  boxShadow: AppColors.cardShadow,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.m,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF9CA3AF),
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: TextField(
                        onChanged: _onSearch,
                        decoration: InputDecoration(
                          hintText: 'Search patients...',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                        ),
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: AppSpacing.radiusSm,
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: _kBlue600,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Patient list — one card per unique patient
          Expanded(
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
                            : () => context.push(
                                AppRoute.patient.build(
                                  params: {'patientId': group.patient!.id},
                                ),
                              ),
                        child: _PatientCard(group: group),
                      );
                    },
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
    final patient = group.patient;
    final visit = group.latestVisit;

    final name = patient?.name ?? 'Unknown Patient';
    final ageSex = [
      if (patient?.age != null) '${patient!.age} years',
      if (patient?.sex != null)
        patient!.sex == Sex.male
            ? 'Male'
            : patient.sex == Sex.female
            ? 'Female'
            : 'Other',
    ].join(' • ');
    final diagnosis = visit.insight?.diagnosis ?? '';
    final dateTime =
        '${_formatDate(visit.createdAt)} · ${visit.createdAt.hour.toString().padLeft(2, '0')}:${visit.createdAt.minute.toString().padLeft(2, '0')}';
    final countLabel =
        '${group.visitCount} ${group.visitCount == 1 ? 'consultation' : 'consultations'}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.radiusXl,
        border: Border.all(color: const Color(0xFFF3F4F6)),
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
                        style: AppTypography.titleSmall,
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
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        countLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: const Color(0xFF0F766E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF9CA3AF),
                      size: 20,
                    ),
                  ],
                ),
                // Age / sex
                if (ageSex.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    ageSex,
                    style: AppTypography.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Last visit date + time
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        dateTime,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
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
                      const Icon(
                        Icons.description_rounded,
                        size: 12,
                        color: _kBlue600,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          diagnosis,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
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

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(dt.year, dt.month, dt.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
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
          const Icon(
            Icons.person_search_rounded,
            size: 48,
            color: Color(0xFFD1D5DB),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            hasQuery ? 'No patients found' : 'No consultations yet',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
