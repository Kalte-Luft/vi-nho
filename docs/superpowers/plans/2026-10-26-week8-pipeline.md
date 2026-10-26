# Week 8 pipeline implementation plan

**Goal:** Upgrade Ví Nhỏ on the existing repository, preserve stored receipts, install a signed update and publish v1.1.0 with a 2–4 page PDF.
**Architecture:** Keep Flutter, ML Kit Latin, sqflite and Riverpod 2. Use immutable AppState with NotifierProvider. Split core/models/services/state/widgets/screens. Persist optional OCR bounding boxes alongside the existing receipt record with a non-destructive SQLite migration.
**Spec:** User-provided Week 8 pipeline and grading-checklist screenshots, 26/10/2026.

## Constraints and decisions
- Keep existing styling and mini-project scope; no server/authentication/new chart package.
- New OCR receipts require explicit review confirmation before database writes.
- Show OCR text bounds on the photo, including an enlarged view; keep old receipts without OCR metadata readable.
- On successful save, show the receipt month's animated report. Never show save success before SQLite completes.
- Preserve application ID, signing key and existing user data.
- User explicitly requests one final verification phase after all implementation. Do not run incremental tests or TDD cycles. Only rerun a failed check if repair is necessary.
- User will record the real-receipt demo video; do not create or claim a substitute video.

## Tasks
- [x] Refactor folders and migrate to immutable NotifierProvider state; preserve async error propagation.
- [x] Add OCR evidence models/service, SQLite v2 migration and photo-bounds review widget with confirmation.
- [x] Update parser/state/database/widget coverage without running it during implementation.
- [x] Update README/checklist, report source (architecture diagram, regex table, screenshots, limitations), release version.
- [x] Final phase: analyze + test once, signed release build, signature check, install preserving data, one device walkthrough for OCR/review/chart/persistence and light/dark screenshots.
- [ ] Generate and visually verify the final PDF with actual results, commit/push and upload APK + PDF to GitHub Release. Verify public links.

## Review focus
Missing or corrupt OCR metadata on old data; no writes before confirmation/cancel; persistence failure propagation; migration preserves photos/settings; notifier disposal during async work.

## Final verification notes
- Analyze clean. 14 tests passed initially; the review test needed a ListView-specific scroll and unfocus, then passed individually. No application code changes were required by testing.
- Signed release installed on Android 16; native sample OCR, confirmation, chart update and cold-start persistence verified. Device had no previous installation; migration proven by SQLite test.
- Video remains user-owned and unrecorded.
