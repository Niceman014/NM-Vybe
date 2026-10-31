package com.nmnext.nmvybe

import com.ryanheise.audioservice.AudioServiceFragmentActivity

/**
 * Hosts the Flutter UI in the Flutter engine owned by audio_service.
 *
 * Extending [AudioServiceFragmentActivity] (instead of FlutterActivity) makes
 * the activity reuse the cached engine that `AudioService.init` created, so
 * background playback and the media notification keep running when the
 * activity is destroyed, and a notification tap re-attaches to the same
 * engine instead of starting a second one.
 */
class MainActivity : AudioServiceFragmentActivity()
