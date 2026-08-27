import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Default is English — the only fully-reviewed language. Every other
/// supported language is machine-translated and marked Beta in the picker.
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

/// Updates the live app locale (provider state + [Intl.defaultLocale], so
/// NumberFormat/DateFormat calls with no explicit locale follow it too).
/// Callers are responsible for persisting the choice via SettingsRepository.
void applyAppLocale(WidgetRef ref, Locale locale) {
  Intl.defaultLocale = locale.toString();
  ref.read(localeProvider.notifier).state = locale;
}

const supportedAppLocales = [
  Locale('en'),
  Locale('ne'),
  Locale('bo'),
  Locale('fr'),
  Locale('es'),
  Locale('hi'),
  Locale('zh'),
];

Locale localeFromKey(String? key) =>
    key == null || key.isEmpty ? const Locale('en') : Locale(key);

String localeToKey(Locale locale) => locale.languageCode;

/// Wraps a `flutter_localizations` delegate (Material/Widgets/Cupertino) to
/// fall back to English instead of crashing for locales it can't actually
/// serve. Two distinct failure modes observed with Tibetan (`bo`):
/// - `GlobalWidgetsLocalizations` reports `isSupported == false` for `bo` —
///   handled by falling back whenever `isSupported` is false.
/// - `GlobalMaterialLocalizations` reports `isSupported == true` for `bo`
///   (it's in Flutter's supported-language list) but its `load()` builds
///   `DateFormat` instances internally, and Dart's `intl` package has no
///   locale data for `bo` at all — `DateFormat.y('bo')` throws
///   `ArgumentError: Invalid locale "bo"`, uncaught. Handled by wrapping
///   `load()` in try/catch, not just trusting `isSupported`.
/// Net effect: picking an unsupported/broken locale keeps our own
/// `AppLocalizations` (app UI strings) on that locale, while framework
/// widgets (date pickers, default dialog buttons, etc.) silently fall back
/// to English instead of crashing the whole app.
///
/// Deliberately NOT an `async` method: `flutter_localizations`' delegates
/// return a `SynchronousFuture` and — critically — the observed `bo` crash
/// is a plain synchronous throw during `load()`, not an async error. An
/// `async`/`await` wrapper here would still catch that, but it also forces
/// this Future to resolve on a later microtask even when the primary
/// resolves synchronously, which breaks `Localizations`' synchronous
/// fast-path (`_LocalizationsState.load`'s `if (typeToResources != null)`
/// check) for every locale, not just `bo`. That fast-path is what makes a
/// locale change take effect in the same frame instead of one frame late —
/// worth preserving. A plain (non-async) try/catch around the synchronous
/// call catches the same exception without paying that cost. (`.catchError`
/// is avoided too: `SynchronousFuture.catchError` returns a Future that
/// never completes, since a `SynchronousFuture` is documented to never
/// error — silently swallowing a real fallback need.)
class FallbackLocalizationsDelegate<T> extends LocalizationsDelegate<T> {
  final LocalizationsDelegate<T> _primary;

  const FallbackLocalizationsDelegate(this._primary);

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) {
    if (_primary.isSupported(locale)) {
      try {
        return _primary.load(locale);
      } catch (_) {
        // Fall through to English below.
      }
    }
    return _primary.load(const Locale('en'));
  }

  @override
  bool shouldReload(FallbackLocalizationsDelegate<T> old) => false;
}
