# Pre-Phase 4 stability gate

Date: 2026-10-31. Phase 4 was not started.

The acceptance criteria below are taken from [CHATGPT_INSTRUCTIONS.md](CHATGPT_INSTRUCTIONS.md).
"Pass" means this workstation has direct evidence; a build or widget test is
not reported as a real-phone or physical frame-pacing test.

## Phase 1 — Stabilize

| # | Acceptance check | Result | Evidence / remaining work |
| --- | --- | --- | --- |
| 1 | Windows MP3, FLAC, M4A playback; pause, seek, skip, natural end; no abort/stuck spinner | **Partial** | Windows profile app starts and a prior debug run completed library scan. Actual playback controls and all three codecs were not exercised in this gate. |
| 2 | Riverpod code analyzes without errors | **Pass** | `flutter analyze --no-pub`: no issues found. Riverpod 3 uses the legacy import for StateNotifier APIs. |
| 3 | Remove named unused dependencies; `pub get`, analyze, test, app startup pass | **Pass, app startup partial** | Named removed packages are absent from `pubspec.yaml`; tests/analyzer pass. Windows app built and emitted first frame. A playback-specific startup check remains under item 1. |
| 4 | Correct Android identity; release signing uses private key; signed release APK builds | **Partial** | Debug APK builds. Current ID is `com.nmnext.nmvybe` (not the example `app.nmvybe.player`); do not change it without an upgrade/migration decision. Release validation requires the user's private `android/key.properties` and keystore, so a signed release build was not attempted. |
| 5 | Ignore generated outputs/secrets and keep Git clean after build | **Pass for ignore rules** | Build, `.dart_tool`, nested Gradle caches, `.env`, keystore and local signing properties are ignored. Build outputs and caches were preserved. This document and test changes are intentionally uncommitted until their follow-up commits. |
| 6 | Development-only Windows data fallback is logged and documented | **Pass** | Fallback/warning is documented in README and implemented in settings storage. |
| 7 | Paid wording; no copied-code/inspiration claims | **Partial** | README and package description use proprietary/paid positioning and no inspiration claim. `docs/ARCHITECTURE.md` was corrected for the current media_kit backend. Remaining old architecture references, if any, require a complete wording audit before release. |

## Phase 2 — UI and smoothness

| Acceptance area | Result | Evidence / remaining work |
| --- | --- | --- |
| Unified Material 3 theme, dynamic accent and readable light/dark/pure-black colors | **Pass with spacing cleanup** | Theme factory and spacing/radius constants are used throughout; this gate moved remaining fixed layout gaps in the main screens to spacing tokens. Theme contrast/fallback tests pass. |
| Fixed spacing scale and theme typography | **Partial** | Main layout gaps now use the 4/8/12/16/24/32 tokens. Some fixed dimensions remain intentionally sized for controls/artwork; a full visual audit remains. |
| Every screen has loading, empty, and retryable error states | **Partial** | Library loading skeleton, empty action, and retry error are covered by tests. Empty states exist for playlists and Now Playing; Discover has configured/unconfigured and search states. A loading and retry audit for every individual route is not complete. |
| At least 48 dp targets, large text, screen-reader labels | **Partial** | Theme button defaults set 48 dp; large-text settings UI is tested. TalkBack/Narrator traversal and every icon target are not device-verified. |
| Wide-screen navigation and two-pane player | **Pass** | Windows-width widget smoke test verifies NavigationRail and the desktop player pane. |
| 150–300 ms transitions and reduce-motion support | **Pass** | Theme transitions use 240 ms and reduce-motion tests verify zero-duration transitions; album-art shared Hero tags are used by mini and full players. |
| Android release cold start under 1 second | **Not verified** | No Android phone was attached. Windows profile startup: framework init 34.8 ms, first frame 572.5 ms, first rasterized frame 994.8 ms. These Windows results do not establish Android performance. |
| 5,000 songs scroll at 60 fps with no dropped frames | **Not verified (functional virtualization passes)** | New widget test supplies 5,000 songs and confirms at most 30 SongTile widgets are built in the initial viewport. No 5,000-song profile scroll frame chart or dropped-frame count was collected. |
| Artwork decode sizing/cache; background scan with progress | **Partial** | Image decode requests use display-size cache widths and artwork has a cache service; scan work/progress has tests. Disk-cache behavior and smooth scan under a 5,000-file phone library still need profiling. |
| Selective provider rebuilds | **Partial** | The library/player use selected provider fields in hot paths. A complete rebuild audit with DevTools was not captured in this gate. |
| Per-screen smoke tests; no DevTools jank while scrolling/opening player | **Partial** | Smoke tests now cover empty, loading, retryable error, large-library virtualization, settings, Discover, player, and wide shell. DevTools jank capture on device remains outstanding. |

## Commands and outcomes

- `flutter analyze --no-pub` — passed; `No issues found!`.
- `flutter test --reporter expanded` — passed; all 59 tests passed.
- `flutter run -d windows --profile --trace-startup` — built and launched; startup timing above; trace at `build/start_up_info.json`.
- `flutter build apk --debug` — passed; output at `build/app/outputs/flutter-apk/app-debug.apk`.
- Android device discovery — Windows and Edge only; no physical Android device or emulator available.

Flutter itself initially hung because the installed SDK could not access
`E:\Android Application Development\flutter\bin\cache\lockfile`. The project
`.tmp` folder passed write/delete checks, and no Dart/Flutter analyzer process
was left running. Running checks with permission to access the SDK resolved the
hang; no SDK lock, cache, or project build output was deleted.

## What remains before claiming the Phase 2 performance target

Connect a real Android phone, install the debug APK using the checklist in
[ANDROID_TEST.md](ANDROID_TEST.md), scan a representative 5,000-song library,
then use DevTools Performance in profile mode while scrolling, searching,
loading artwork, and opening Now Playing. Record device/OS, average and worst
frame build/raster times, missed frames, and jank count. No phone-specific
performance claim is made before that capture.
