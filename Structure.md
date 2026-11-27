# Handoff structure

This tree describes `tarlan_bank_handoff_original.zip`. Every file listed below
is included in the archive; nothing else is. There is no `INSTRUCTIONS.md` in
the handoff by request.

This is the **pre-fix** bundle: the current repository state after rolling back
the custom `AngledGlassPanel` rim work. Scrollable glass here is still the
package `GlassContainer` path in `glass_widget_grid.dart` and `home_screen.dart`,
with `scrollGlassQuality` / `themedGlassSettings` from `glass_settings.dart`.
The removed `angled_glass_panel.dart` and `angled_glass_panel_test.dart` are not
part of this handoff.

```
tarlan_bank_handoff_original/
├── Structure.md
├── analysis_options.yaml
├── pubspec.yaml
├── .md
│   └── CHANGES.md
├── lib
│   ├── main.dart
│   ├── core
│   │   └── router
│   │       ├── app_navigation.dart
│   │       ├── app_router.dart
│   │       ├── auth_intent.dart
│   │       ├── routes.dart
│   │       └── shell_index_provider.dart
│   ├── generated
│   │   ├── app_localizations.dart
│   │   ├── app_localizations_en.dart
│   │   ├── app_localizations_kk.dart
│   │   └── app_localizations_ru.dart
│   ├── l10n
│   │   ├── app_en.arb
│   │   ├── app_kk.arb
│   │   └── app_ru.arb
│   ├── utils
│   │   └── themes
│   │       ├── app_colors.dart
│   │       ├── app_colors_dark.dart
│   │       ├── app_colors_light.dart
│   │       ├── app_theme.dart
│   │       ├── glass_settings.dart
│   │       └── theme_extension.dart
│   └── views
│       ├── main
│       │   ├── home_screen.dart
│       │   ├── main_shell.dart
│       │   └── shell_top_bar.dart
│       └── shared
│           ├── cached_user_avatar.dart
│           ├── currency_rates_card.dart
│           ├── formatters.dart
│           ├── glass_widget_grid.dart
│           ├── mesh_background.dart
│           └── widgets.dart
└── test
    ├── core
    │   └── router
    │       └── shell_chrome_test.dart
    ├── utils
    │   └── themes
    │       ├── color_scheme_test.dart
    │       └── glass_settings_test.dart
    └── views
        ├── main
        │   ├── bottom_nav_variants_test.dart
        │   └── shell_top_bar_test.dart
        └── shared
            ├── glass_surface_test.dart
            ├── glass_widget_grid_test.dart
            └── mesh_background_test.dart
```
