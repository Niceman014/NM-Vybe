# NM VYBE Phase 2 performance check

Date: 2026-10-31

## Verified on this workstation

- Windows x64 Profile build completed successfully.
- Fresh Windows x64 profile startup trace: `timeToFirstFrameMicros` was 572,526 µs (573 ms); `timeToFirstFrameRasterizedMicros` was 994,786 µs (995 ms); framework initialization was 34,781 µs (35 ms). Captured by `flutter run -d windows --profile --trace-startup`; trace saved at `build/start_up_info.json`.
- Windows debug build completed successfully.
- Windows release build completed successfully.
- Android debug APK compiled successfully at `build/app/outputs/flutter-apk/app-debug.apk`.
- Android profile APK compiled successfully at `build/app/outputs/flutter-apk/app-profile.apk` (about 104 MB).
- `flutter analyze --no-pub`: no issues found.
- `flutter test --reporter expanded`: all 59 tests passed, including loading/error-state checks and a 5,000-song lazy-list widget check.
- The Library song view uses a lazy `SliverList.builder`, so rows are built as they enter the viewport rather than all at once.

The latest trace is in `build/start_up_info.json`. The Windows profile configuration was missing from the CMake project and is now enabled in `windows/CMakeLists.txt`.

The latest UI optimization also removed whole-library rebuild causes: library sorting now observes only sort preferences, the library observes only the player fields it paints rather than playback position updates, and search updates are debounced. Theme changes use a consistent 240 ms transition and honor system reduced motion. The 5,000-song widget test verifies that the lazy list constructs only rows around the viewport; it does not measure frame pacing or scrolling in profile mode.

## Not measured

Only Windows and Edge were available as Flutter targets; no Android phone or emulator was connected. This run did not measure Android cold startup, Android frame pacing, a 5,000-song library under interaction in profile mode, or sustained playback. A Windows startup trace and a widget virtualization test are not substitutes for a frame-time/jank capture on a 5,000-song library. Therefore 60 fps/no-jank is not certified.

The Android release build was also attempted. Its release-signing validation stopped it because `android/key.properties` and the private release keystore are not configured. The Android toolchain emitted future-compatibility warnings for the Gradle, Android Gradle Plugin, Kotlin Gradle Plugin, and the local `on_audio_query_android` plugin; these did not prevent the debug APK build.

## Follow-up measurement

Connect the target Android device, populate a representative 5,000-song library, then capture scrolling, search, artwork loading, and playback in Flutter DevTools Performance view on a release-like profile build. Record device/OS, build mode, frame chart, missed frames, and startup timing with that run. See [ANDROID_TEST.md](ANDROID_TEST.md) for the phone checklist.
