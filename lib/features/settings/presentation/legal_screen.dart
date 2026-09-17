import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// The two legal documents shipped with the app (roadmap item 28).
enum LegalDoc { terms, privacy }

/// Renders a bundled Markdown document from `assets/legal/` so Terms and the
/// Privacy Policy are readable offline and inside the app, rather than being
/// a tile that does nothing.
///
/// The renderer is deliberately tiny (headings, bullets, paragraphs and
/// `**bold**`) — enough for these documents and no extra dependency.
class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key, required this.doc});

  final LegalDoc doc;

  static Future<void> open(BuildContext context, LegalDoc doc) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => LegalScreen(doc: doc)));
  }

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  Future<_LegalContent>? _content;
  String? _loadedForLocale;

  String get _baseName => switch (widget.doc) {
    LegalDoc.terms => 'terms',
    LegalDoc.privacy => 'privacy',
  };

  String? get _onlineUrl => switch (widget.doc) {
    LegalDoc.terms => AppConfig.termsUrl,
    LegalDoc.privacy => AppConfig.privacyUrl,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = Localizations.localeOf(context).languageCode;
    if (_loadedForLocale == code && _content != null) return;
    _loadedForLocale = code;
    _content = _load(code);
  }

  /// Prefers a translated document and falls back to English; the English
  /// copy always exists, so a missing translation is not an error.
  Future<_LegalContent> _load(String localeCode) async {
    for (final candidate in {
      'assets/legal/${_baseName}_$localeCode.md',
      'assets/legal/${_baseName}_en.md',
    }) {
      try {
        return _LegalContent.parse(await rootBundle.loadString(candidate));
      } catch (_) {
        continue;
      }
    }
    throw StateError('No bundled copy of $_baseName');
  }

  Future<void> _openOnline(String url) async {
    final t = AppLocalizations.of(context)!;
    var ok = false;
    try {
      ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.helpCouldNotOpen)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final title = switch (widget.doc) {
      LegalDoc.terms => t.legalTerms,
      LegalDoc.privacy => t.legalPrivacyPolicy,
    };
    final onlineUrl = _onlineUrl;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<_LegalContent>(
        future: _content,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Text(
                  t.legalLoadFailed,
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final content = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              if (content.lastUpdated != null)
                Text(
                  t.legalLastUpdated(content.lastUpdated!),
                  style: AppTypography.labelSmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: AppSpacing.s),
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: AppSpacing.radiusMd,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Text(
                        t.legalReviewNotice,
                        style: AppTypography.bodySmall.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...content.blocks.map((b) => _BlockView(block: b)),
              if (onlineUrl != null) ...[
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () => _openOnline(onlineUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(t.legalViewOnline),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Minimal Markdown ────────────────────────────────────────────────────────

enum _BlockKind { title, heading, paragraph, bullet }

class _Block {
  const _Block(this.kind, this.text);
  final _BlockKind kind;
  final String text;
}

class _LegalContent {
  const _LegalContent({required this.blocks, this.lastUpdated});

  final List<_Block> blocks;
  final String? lastUpdated;

  /// Splits the document into blocks. A leading `Last updated: …` line is
  /// lifted out so it can be shown as a caption.
  static _LegalContent parse(String source) {
    final lines = source.replaceAll('\r\n', '\n').split('\n');
    String? lastUpdated;
    final blocks = <_Block>[];
    final paragraph = StringBuffer();

    void flush() {
      final text = paragraph.toString().trim();
      if (text.isNotEmpty) blocks.add(_Block(_BlockKind.paragraph, text));
      paragraph.clear();
    }

    for (final raw in lines) {
      final line = raw.trimRight();
      final trimmed = line.trim();
      if (lastUpdated == null &&
          blocks.isEmpty &&
          paragraph.isEmpty &&
          trimmed.toLowerCase().startsWith('last updated:')) {
        lastUpdated = trimmed.substring('last updated:'.length).trim();
        continue;
      }
      if (trimmed.isEmpty) {
        flush();
        continue;
      }
      if (trimmed.startsWith('## ')) {
        flush();
        blocks.add(_Block(_BlockKind.heading, trimmed.substring(3).trim()));
        continue;
      }
      if (trimmed.startsWith('# ')) {
        flush();
        blocks.add(_Block(_BlockKind.title, trimmed.substring(2).trim()));
        continue;
      }
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        flush();
        blocks.add(_Block(_BlockKind.bullet, trimmed.substring(2).trim()));
        continue;
      }
      if (paragraph.isNotEmpty) paragraph.write(' ');
      paragraph.write(trimmed);
    }
    flush();
    return _LegalContent(blocks: blocks, lastUpdated: lastUpdated);
  }
}

class _BlockView extends StatelessWidget {
  const _BlockView({required this.block});
  final _Block block;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = AppTypography.bodyMedium.copyWith(
      color: scheme.onSurface,
      height: 1.5,
    );

    switch (block.kind) {
      case _BlockKind.title:
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.m),
          child: Text(
            block.text,
            style: AppTypography.headlineMedium.copyWith(
              color: scheme.onSurface,
            ),
          ),
        );
      case _BlockKind.heading:
        return Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.s,
          ),
          child: Text(
            block.text,
            style: AppTypography.titleMedium.copyWith(color: scheme.onSurface),
          ),
        );
      case _BlockKind.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.m),
          child: Text.rich(_inline(block.text, body), style: body),
        );
      case _BlockKind.bullet:
        return Padding(
          padding: const EdgeInsets.only(
            bottom: AppSpacing.s,
            left: AppSpacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text.rich(_inline(block.text, body), style: body),
              ),
            ],
          ),
        );
    }
  }

  /// Turns `**bold**` runs into spans; everything else is plain text.
  static TextSpan _inline(String text, TextStyle base) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    var index = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: base.copyWith(fontWeight: FontWeight.w700),
        ),
      );
      index = match.end;
    }
    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index)));
    }
    return TextSpan(children: spans);
  }
}
