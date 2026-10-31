# Vendored third-party patches

## `on_audio_query_android`

This is the BSD-3-Clause Android implementation from `on_audio_query_android`
1.1.0, copied from its published package and kept locally so NM VYBE can apply
the Android build compatibility fixes needed by the current Flutter/AGP toolchain.
The original license and upstream attribution are in the package's `LICENSE`
and `pubspec.yaml`.

Local changes are limited to the Android Gradle configuration: declare the
existing manifest namespace, use Flutter's configured compile SDK instead of
the upstream hard-coded API 33, and align Java/Kotlin targets to 17. The Dart
and Kotlin plugin implementation is unchanged. Review upstream releases before
updating this copy; remove the override once an upstream version contains these
build fixes.
