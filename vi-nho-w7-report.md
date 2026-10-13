# MINI-PROJECT SHORT TECHNICAL REPORT

**Course:** Cross-Platform Mobile App Development (VKU)  
**Mini-Project Title:** Mini-Project 3 — Ví Nhỏ: Receipt OCR & Expense Tracker  
**Team / Student Name:** Nguyen Ba Nghia  
**Submission Date:** 13/10/2026

---

## 1. GENERAL INFORMATION & DELIVERABLE LINKS

- **Team Member:** Nguyen Ba Nghia — Student ID: 23IT.B137 — Role: Individual Developer / Flutter UI, OCR & SQLite Integration — Contribution: 100%.
- **🔗 Live Demo / APK:** [Download app-release.apk](https://github.com/Kalte-Luft/vi-nho/releases/download/v1.0.0/app-release.apk)
- **💻 GitHub Repository:** [Kalte-Luft/vi-nho](https://github.com/Kalte-Luft/vi-nho)

**Project scope:** An Android application that converts receipt photos into reviewed expense records, stores data locally, and visualizes spending. Small extensions include a monthly budget and expense search/category filters.

## 2. FEATURE IMPLEMENTATION CHECKLIST

| Required feature | Status | Implementation |
|---|:---:|---|
| On-device OCR & heuristics | ✅ | `image_picker` camera/gallery, ML Kit Latin recognition, Dart Regex extraction of merchant, date and total. Review screen supports manual correction. |
| Custom Canvas visualization | ✅ | Animated category donut and seven-day bar chart using `CustomPainter`, `TextPainter` and `TweenAnimationBuilder`. |
| State management & database | ✅ | Riverpod 2.6.1, sqflite CRUD/settings and receipt photos copied into persistent app storage. |
| UI/UX | ✅ | Vietnamese Material 3 interface, light/dark themes, responsive layouts, loading/error states and image zoom. |
| Extensions | ✅ | Monthly budget, remaining/overspent amount, accent-insensitive search and month/category filters. |

## 3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE

**Data flow:** Camera/gallery → ML Kit → Regex parser → review/manual correction → SQLite → expense list and Canvas charts.

| Path | Responsibility |
|---|---|
| `lib/models/` | Expense model, categories and VND formatting. |
| `lib/services/` | Image selection, OCR and receipt heuristics. |
| `lib/data/` | SQLite access, settings and photo storage. |
| `lib/state/` | Riverpod ownership of application state. |
| `lib/ui/` | Overview, history, review form, themes and custom charts. |
| `test/` | Parser, database/file persistence and widget tests. |

Amounts are stored as integer VND. The parser prioritizes final-total labels and excludes subtotal, cash tendered and change. Missing fields remain editable instead of being silently guessed. Text controllers are disposed, recognizers are closed in `finally`, and async UI updates check `mounted`.

## 4. EMPIRICAL EVIDENCE & SCREENSHOTS

| Check | Result |
|---|---|
| `flutter analyze` | Passed, no issues. |
| `flutter test` | 8 tests passed: parser edge cases, SQLite CRUD/settings, persistent photos/database and UI interactions. |
| Signed release APK | Built successfully; APK Signature Scheme v2 verified; installed on `25053RT47C`, Android 16 / API 36. |
| Native OCR sample | Correct merchant **HIGHLANDS COFFEE**, total **69,000 VND**, date **13/10/2026**. |
| Restart persistence | Expense, photo and selected theme remained after force-stop/cold start. |
| Device visualization | Donut and weekly bar charts rendered on the installed release build. |

**Screenshots:** [Overview](docs/device-screenshots/08-final-overview.png), [OCR review](docs/device-screenshots/03-ocr-review.png), [weekly chart](docs/device-screenshots/10-final-weekly.png).

**Validation limits:** Physical-device OCR used the bundled sample image. Real camera capture, gallery selection and airplane-mode behavior have not yet been manually verified. OCR accuracy varies with image quality and receipt layout; the user must confirm the extracted fields.

## 5. TECHNICAL CHALLENGES & RESOLUTIONS

1. **Selecting the correct receipt total:** The largest number may be cash tendered or a phone number. Label-based heuristics prioritize the final amount due, reject invalid dates and route uncertain results to manual review.
2. **Android release compatibility:** Interrupted NDK downloads and Java 25/Gradle incompatibility blocked builds. A complete NDK and local JDK 21 resolved the toolchain issues. Exact R8 rules handle unused optional OCR-script references while the app explicitly initializes only the Latin recognizer.
