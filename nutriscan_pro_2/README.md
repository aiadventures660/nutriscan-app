# NutriScan Pro 2.0 — Safe UI Foundation Patch

This is an incremental patch for the existing Flutter application, **not** a replacement application and **not** a completed 16-screen redesign.

## Files
- `lib/config/app_theme.dart`: your original theme, plus non-breaking premium design tokens.
- `lib/widgets/modern_bottom_nav.dart`: your original bottom navigation, retained for compatibility.
- `lib/widgets/premium_components.dart`: new provider-independent, theme-aware section headers, cards, action tiles, and empty states.

## Install
1. Back up your existing project / commit to Git.
2. Copy `premium_components.dart` into your project's `lib/widgets/` directory.
3. Optionally replace `app_theme.dart` after reviewing the small token additions.
4. **Do not replace** your existing `modern_bottom_nav.dart` unless you need to restore the supplied original: the patch copy is unchanged.
5. Import `../widgets/premium_components.dart` from screens and gradually replace old hardcoded cards.
6. Run `flutter analyze`, `flutter test`, and device tests.

## Example
```dart
PremiumActionTile(
  title: 'Scan food',
  subtitle: 'Take a photo or choose from gallery',
  icon: Icons.document_scanner_rounded,
  onTap: () => Navigator.push(context,
    MaterialPageRoute(builder: (_) => const ScanScreen())),
)
```

## Important gaps
The provided uploads do not include all service and widget dependencies, Android/iOS configuration, or assets. This patch has not been compiled because the Flutter SDK is unavailable in this environment. Keep your existing `main.dart`, provider, persistence, and scanner logic unchanged until the complete project is available.

## Security
`api_config.dart` includes an obfuscated embedded API key fallback. Obfuscation does not secure client-side secrets. Rotate the key and migrate Gemini calls to a server-side proxy before production release. Do not include the API configuration in public code archives.
