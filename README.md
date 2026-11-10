# Trading Decision Journal

Trading Decision Journal is a Flutter Android app for discretionary traders. It brings trade notes, risk planning, decision quality, and performance review into one journal so traders can examine both the outcome of a trade and the process behind it.

## The problem

A trade result alone does not explain whether the entry, risk, and execution followed a plan. The app helps traders record those decisions while they are still clear, size a planned position, and review patterns across past trades.

## Features

- **Trade journal:** Record market, strategy, symbol, direction, entry, stop loss, exit, risk, fees, notes, and chart images. Browse trade history and filter it by time period.
- **1R Calculator:** Estimate position size from account balance or a fixed risk amount, entry, stop loss, and symbol specifications. Apply the calculated symbol, prices, risk, and suggested volume to a new trade.
- **Broker profiles and symbol search:** Use the built-in symbol specifications or save custom broker profiles. Search the current profile's symbols with case-insensitive partial matches.
- **Decision quality checklist:** Review market context, entry zone, execution, risk, and emotional discipline. The checklist classifies trades as A, A-, or B for later review.
- **Performance analytics:** Review net and average R, win rate, trade grades, an equity curve, calendar history, and filtered views in the dashboard and Analyst screen.
- **Image and PDF reports:** Build a report from journal data, preview an image report, and share PNG or PDF exports.
- **English and Vietnamese:** Switch the app language in settings; both languages are supported in the Flutter UI.

## Technology and structure

The app uses Flutter and Dart with Material 3. The main code is organized by responsibility:

| Area | Implementation |
| --- | --- |
| App UI | Screens and flows in `lib/ui/`, with navigation through `AppShell` |
| Trade model | Trade fields, R result, and checklist grading in `lib/models/trade.dart` |
| State and storage | `provider` and `ChangeNotifier` for app settings and trades; JSON trade records and settings in `shared_preferences` |
| Chart images | `image_picker` for selection and `path_provider` for copies in the app's documents directory |
| Analytics and exports | Chart and calendar widgets in the UI; report data, PNG rendering, PDF generation, and sharing in `lib/reports/` |
| Localization | English/Vietnamese strings in `lib/l10n/strings.dart`, selected through `AppSettings` |

The 1R Calculator keeps built-in symbol specifications in the calculator screen and stores custom broker profiles locally. Currency conversion uses saved exchange rates or built-in estimates when fresh rates are unavailable.

## Run locally

1. Install a Flutter SDK compatible with the Dart constraint in `pubspec.yaml` (`^3.11.0`) and set up an Android emulator or device.
2. From the repository root, run:

   ```bash
   flutter doctor
   flutter pub get
   flutter run
   ```

The Android Gradle configuration references an ignored local signing properties file. Release signing materials are not part of this repository; a clean-clone debug build without that file has not been verified.

## Testing and limitations

Run the current automated checks from the repository root:

```bash
flutter test
flutter analyze
```

The automated tests currently focus on symbol search, broker switching, calculator results, and the calculator-to-Add-Trade flow. Other screens and device features have limited automated coverage. `flutter analyze` currently reports existing lint warnings and informational notices.

Trade records and chart images are stored on the device; this repository does not implement account-based cloud sync. Position sizing depends on symbol specifications and currency rates, so broker-specific contract details should be checked before relying on an estimate. Image picking, sharing, PDF rendering, and keyboard layout should also be checked on an Android device when those flows change.

## Development approach

Git history documents incremental calculator and trade-entry work, including a merged pull request for symbol search. Changes should remain scoped, receive a code review, and run relevant regression tests before merging. AI tools can assist with implementation and review, while the source code, test results, and final product decisions remain subject to human verification.
