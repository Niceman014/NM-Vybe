# NM VYBE Phase 2 performance check

Date: 2026-10-30

## Verified on this workstation

- Windows x64 Profile build completed successfully.
- Latest Windows profile trace completed after the rebuild fixes. `timeToFirstFrameMicros` was 75,094 µs (about 75 ms); `timeToFirstFrameRasterizedMicros` was 607,665 µs (about 608 ms). Flutter reported 325 ms from framework initialization to first frame.
- Windows debug build completed successfully.
- Windows release build completed successfully.
- Android debug APK compiled successfully at `build/app/outputs/flutter-apk/app-debug.apk`.
- Android profile APK compiled successfully at `build/app/outputs/flutter-apk/app-profile.apk` (about 104 MB).
- `flutter analyze --no-pub`: no issues found.
- `flutter test --reporter compact`: all 44 tests passed.
- The Library song view uses a lazy `SliverList.builder`, so rows are built as they enter the viewport rather than all at once.

The latest trace is in `build/start_up_info.json`. The Windows profile configuration was missing from the CMake project and is now enabled in `windows/CMakeLists.txt`.

The latest UI optimization also removed whole-library rebuild causes: library sorting now observes only sort preferences, the library observes only the player fields it paints rather than playback position updates, and search updates are debounced. Theme changes use a consistent 240 ms transition and honor system reduced motion. The Android profile APK is ready for a real-device check, but has not been launched from this workstation.

## Not measured

Only Windows and Edge were available as Flutter targets; no Android phone or emulator was connected. This run did not measure Android cold startup, Android frame pacing, a 5,000-song library under interaction, or sustained playback. A first-frame startup trace is not a substitute for a frame-time/jank capture. Therefore this is a successful Windows startup check, not a claim that the 60 fps/no-jank target has been certified on Android or across a large real library.

The Android release build was also attempted. Its release-signing validation stopped it because `android/key.properties` and the private release keystore are not configured. The Android toolchain emitted future-compatibility warnings for the Gradle, Android Gradle Plugin, Kotlin Gradle Plugin, and the local `on_audio_query_android` plugin; these did not prevent the debug APK build.

## Follow-up measurement

Connect the target Android device, populate a representative 5,000-song library, then capture scrolling, search, artwork loading, and playback in Flutter DevTools Performance view on a release-like profile build. Record device/OS, build mode, frame chart, missed frames, and startup timing with that run.
