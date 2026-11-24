import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/locale/app_locale.dart';
import 'package:tarlan_bank/core/theme/theme_settings.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LANGUAGE SELECTOR
// ─────────────────────────────────────────────────────────────────────────────

class AppLocaleItem {
  final String code;
  final String label;
  final String? flag;

  const AppLocaleItem(this.code, this.label, {this.flag});
}

class AppLanguageSelector {
  static Future<String?> show(
    BuildContext context, {
    required String current,
    required List<AppLocaleItem> locales,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final l = AppLocalizations.of(ctx);
        final cs = Theme.of(ctx).colorScheme;
        final tt = Theme.of(ctx).textTheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.language,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...locales.map(
                (loc) => ListTile(
                  leading: loc.flag != null
                      ? Text(loc.flag!, style: const TextStyle(fontSize: 24))
                      : null,
                  title: Text(loc.label),
                  trailing: current == loc.code
                      ? Icon(Icons.check_rounded, color: cs.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, loc.code),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP CONTROLS  (language + theme)
// ─────────────────────────────────────────────────────────────────────────────

class TopControls extends ConsumerWidget {
  const TopControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PillButton(
          icon: locale.languageCode == 'system' ? Icons.language_rounded : null,
          label: locale.languageCode == 'system'
              ? null
              : locale.languageCode.toUpperCase(),
          onTap: () => showLanguageSheet(context, ref),
        ),
        const SizedBox(width: 6),
        PillButton(
          icon: mode == ThemeMode.dark
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
          onTap: () => ref
              .read(themeModeProvider.notifier)
              .set(mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
        ),
      ],
    );
  }
}

class PillButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const PillButton({super.key, this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 20, minWidth: 48),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: label != null
              ? Center(
                  child: Text(
                    label!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                )
              : Center(child: Icon(icon, size: 18, color: cs.onSurface)),
        ),
      ),
    );
  }
}

Future<String?> showLanguageSheet(BuildContext context, WidgetRef ref) async {
  final lang = await AppLanguageSelector.show(
    context,
    current: ref.watch(localeProvider).languageCode,
    locales: [
      ...AppLocalizations.supportedLocales.map(
        (loc) =>
            AppLocaleItem(loc.languageCode, loc.displayName, flag: loc.flag),
      ),
      AppLocaleItem('system', AppLocalizations.of(context).langSys, flag: '🌐'),
    ],
  );
  if (lang != null) {
    await ref.read(localeProvider.notifier).setLocale(lang);
  }
  return lang;
}
