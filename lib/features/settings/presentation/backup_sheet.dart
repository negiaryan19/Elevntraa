import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../data/backup_service.dart';

/// Settings > Backup & sync (roadmap item 24).
///
/// Shows what a backup contains, when the last one happened, and runs the
/// upload / restore with live stage text. Everything the doctor sees is
/// localized; failures show the [Failure] message, never a raw exception.
class BackupSheet extends ConsumerStatefulWidget {
  const BackupSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => const BackupSheet(),
    );
  }

  @override
  ConsumerState<BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends ConsumerState<BackupSheet> {
  DateTime? _lastBackupAt;
  BackupEntry? _latestRemote;
  bool _loading = true;
  bool _busy = false;
  String? _stage;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final service = ref.read(backupServiceProvider);
    final last = await service.lastBackupAt();
    BackupEntry? latest;
    try {
      final remote = await service.listRemote();
      latest = remote.isEmpty ? null : remote.first;
    } catch (_) {
      // Offline or not signed in: the sheet still shows the local timestamp
      // and explains why the buttons are disabled.
      latest = null;
    }
    if (!mounted) return;
    setState(() {
      _lastBackupAt = last;
      _latestRemote = latest;
      _loading = false;
    });
  }

  String _stageLabel(AppLocalizations t, String stage) => switch (stage) {
    BackupStage.collecting => t.backupStageCollecting,
    BackupStage.zipping => t.backupStageZipping,
    BackupStage.uploading => t.backupStageUploading,
    BackupStage.downloading => t.backupStageDownloading,
    BackupStage.restoring => t.backupStageRestoring,
    _ => stage,
  };

  Future<void> _backupNow() async {
    final t = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
      _stage = BackupStage.collecting;
    });
    try {
      await ref
          .read(backupServiceProvider)
          .backupNow(
            onProgress: (stage) {
              if (mounted) setState(() => _stage = stage);
            },
          );
      if (!mounted) return;
      setState(() => _success = t.backupDone);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = t.backupFailed(e is Failure ? e.message : '$e'));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _stage = null;
        });
      }
    }
  }

  Future<void> _restoreLatest() async {
    final t = AppLocalizations.of(context)!;
    final entry = _latestRemote;
    if (entry == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.backupRestoreConfirmTitle),
        content: Text(
          t.backupRestoreConfirmBody(_formatDateTime(context, entry.createdAt)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.backupRestoreConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
      _success = null;
      _stage = BackupStage.downloading;
    });
    try {
      await ref
          .read(backupServiceProvider)
          .restore(
            entry,
            onProgress: (stage) {
              if (mounted) setState(() => _stage = stage);
            },
          );
      if (!mounted) return;
      setState(() => _success = '${t.backupRestored}\n${t.backupRestartHint}');
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = t.backupRestoreFailed(e is Failure ? e.message : '$e'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _stage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final offline =
        ref.watch(connectivityStatusProvider) == ConnectivityStatus.offline;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
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
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                t.backupTitle,
                style: AppTypography.headlineMedium.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                t.backupIntro,
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              _InfoRow(
                icon: Icons.check_circle_outline,
                text: t.backupIncludes,
              ),
              const SizedBox(height: AppSpacing.xs),
              _InfoRow(
                icon: Icons.remove_circle_outline,
                text: t.backupExcludes,
              ),
              const SizedBox(height: AppSpacing.md),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: AppSpacing.radiusMd,
                ),
                child: _loading
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _lastBackupAt == null
                                ? t.backupNever
                                : t.backupLastAt(
                                    _formatDateTime(context, _lastBackupAt!),
                                  ),
                            style: AppTypography.titleSmall.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            _latestRemote == null
                                ? t.backupNoRemote
                                : t.backupLatestRemote(
                                    _formatDateTime(
                                      context,
                                      _latestRemote!.createdAt,
                                    ),
                                    _formatSize(_latestRemote!.sizeBytes),
                                  ),
                            style: AppTypography.bodySmall.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
              ),

              if (offline) ...[
                const SizedBox(height: AppSpacing.m),
                _Banner(
                  text: t.backupNeedsInternet,
                  color: scheme.tertiaryContainer,
                  textColor: scheme.onTertiaryContainer,
                  icon: Icons.wifi_off_rounded,
                ),
              ],
              if (_stage != null) ...[
                const SizedBox(height: AppSpacing.m),
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Text(
                        _stageLabel(t, _stage!),
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              if (_success != null) ...[
                const SizedBox(height: AppSpacing.m),
                _Banner(
                  text: _success!,
                  color: scheme.secondaryContainer,
                  textColor: scheme.onSecondaryContainer,
                  icon: Icons.check_circle_rounded,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.m),
                _Banner(
                  text: _error!,
                  color: scheme.errorContainer,
                  textColor: scheme.onErrorContainer,
                  icon: Icons.error_outline_rounded,
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_busy || offline) ? null : _backupNow,
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: Text(t.backupNow),
                ),
              ),
              if (_latestRemote != null) ...[
                const SizedBox(height: AppSpacing.s),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: (_busy || offline) ? null : _restoreLatest,
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: Text(t.backupRestoreLatest),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDateTime(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final date = MaterialLocalizations.of(context).formatMediumDate(local);
  final time = TimeOfDay.fromDateTime(local).format(context);
  return '$date, $time';
}

String _formatSize(int bytes) {
  if (bytes <= 0) return '—';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    required this.color,
    required this.textColor,
    required this.icon,
  });

  final String text;
  final Color color;
  final Color textColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppSpacing.radiusMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
