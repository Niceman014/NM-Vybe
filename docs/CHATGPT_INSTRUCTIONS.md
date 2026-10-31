# NM VYBE — Instructions for ChatGPT

Oct 30, 2026 · @Omar

## Product brief

NM VYBE is a paid ($5.99, one-time) local-first music player for Android and Windows first, with macOS, iOS and Linux later. Paste this whole document into ChatGPT, or save it as `docs/CHATGPT_INSTRUCTIONS.md` in the project and tell ChatGPT to read it before every task.

- **Promise:** your music, your vibe. No ads, no subscription, no tracking.
- **Core value:** a very smooth player, a great local library, an equalizer, synced lyrics, and colors that follow the album art.
- **Optional extras:** Google sign-in to back up and sync playlists, and online sources that are legally allowed.
- **Quality bar:** it must feel faster and calmer than free alternatives. Smoothness is the product, so every change is judged on whether it keeps the app fast and stable.
- **Stack:** Flutter, Riverpod, `just_audio` with `audio_service`, sembast for storage. A Node.js backend and a Next.js site come later.

## Hard rules

If a task would break one of these, stop and ask the owner first.

1. **Licensing.** Never copy code from other apps, especially GPL ones. No credit or "inspired by" lines are needed, because nothing is copied. Learning ideas is fine; write our own code. Every new dependency must have a license that allows closed-source commercial use (MIT, BSD, Apache, MPL). Ask before adding one.
2. **Music sources.** No YouTube scraping, no proxy lists, no unofficial extractors. Only use sources whose terms allow what we do with them (see Phase 3).
3. **Secrets.** No API keys, tokens or passwords in the app or in Git. Keys live in the Node backend or in environment files that are gitignored.
4. **Quality gates.** After every task, `flutter analyze` prints no issues and `flutter test` passes. Never mark a task done on a build that doesn't run.
5. **Small steps.** One task at a time, one commit per task, with a clear message. Do not rewrite unrelated files.
6. **Don't break the user's data.** Any database change needs a migration and a test. Never delete the user's music files.
7. **No fake results.** If something could not be tested (for example on a real Android phone), say so plainly instead of claiming it works.

## Current state and known problems

The app has about 16,000 lines of Dart with a clean `core/`, `features/` and `shared/` split. These problems were found in review and are fixed in Phase 1.

| Problem | Where | Effect |
| --- | --- | --- |
| Play crashes with `abort() has been called`; spinner never ends | Windows Debug build | Playback unusable on Windows |
| Two Windows audio backends in `pubspec.yaml`; the media kit one is never initialized | `just_audio_windows` and `just_audio_media_kit` | Likely cause of the crash |
| Lockfile has Riverpod 3.4.3 but code uses `StateNotifier` from the main import | `lib/**/controllers/*.dart` | Probably does not compile |
| Unused dependencies: `drift`, `drift_flutter`, `on_audio_query_pluse`, `cached_network_image`, `go_router` | `pubspec.yaml` | Bigger app, confusing code |
| `palette_generator` is discontinued | `palette_controller.dart` | Future breakage |
| `applicationId` is `com.example.nm_vybe`; release signed with the debug key | `android/app/build.gradle.kts` | Play Store will reject it |
| Updater security was incomplete | `features/updates/`, private backend manifest, and SemVer parser | Fixed in Phase 4a; installer hosting and license checks remain Phase 4c work |
| Text says "free" | `pubspec.yaml`, `docs/ARCHITECTURE.md`, `README.md` | Conflicts with the paid plan |
| Project folder is 1.23 GB | `build/`, `.dart_tool/`, Gradle caches, temp folders | Slow to zip, copy and back up |

## Target file structure

Keep the Flutter app at the project root for now so existing tools and paths keep working. `backend/` and `website/` are added later as separate folders or repositories, so Flutter builds and zips stay small. `NEW` marks files to create, `MOVE` marks files to relocate, and everything else stays where it is.

```text
nm_vybe/                               # Flutter project root (D:\Flutter Projects\nm_vybe)
├── android/  ios/  windows/  macos/  linux/  web/   # platform folders (generated)
├── assets/
│   ├── icons/                          # app icon, source SVG/PNG
│   ├── images/                         # placeholder album art (remove the folder entry if empty)
│   └── licenses/                       # NEW: third-party license texts for the About page
├── docs/
│   ├── ARCHITECTURE.md                 # update: paid product, Riverpod version, new layers
│   ├── CHATGPT_INSTRUCTIONS.md         # NEW: this document
│   ├── DECISIONS.md                    # NEW: one line per decision (why sembast, why media_kit)
│   └── SOURCES.md                      # NEW: each music source, its terms, canDownload value, date checked
├── lib/
│   ├── main.dart                       # boot only: init storage, audio handler, ProviderScope
│   ├── app.dart                        # MaterialApp, theme, router
│   │
│   ├── core/                           # no UI, no feature logic
│   │   ├── constants/                  # app_constants.dart, theme_constants.dart
│   │   ├── theme/                      # app_theme.dart, color_schemes.dart (NEW), text_styles.dart (NEW)
│   │   ├── platform/                   # platform_info.dart (MOVE from utils), per-OS media controls (NEW)
│   │   ├── storage/                    # db_service.dart (MOVE from services), settings_service.dart (MOVE)
│   │   ├── audio/                      # audio_handler.dart (MOVE), audio_session_setup.dart (NEW)
│   │   ├── network/                    # http_client.dart (NEW): timeouts, HTTPS only, no token logging
│   │   └── utils/                      # formatters.dart, logger.dart, semver.dart (NEW)
│   │
│   ├── data/                           # where data comes from
│   │   ├── models/                     # Song, Playlist, Album, Artist, DownloadRecord (NEW)
│   │   ├── repositories/               # library_repository.dart, in_memory_library_repository.dart (MOVE from core/data)
│   │   │                               # music_repository.dart (NEW): merges all sources
│   │   │                               # download_repository.dart (NEW)
│   │   └── sources/                    # NEW
│   │       ├── music_source.dart       # interface: search, getStreamUrl, canDownload, attributionFor
│   │       ├── local_files_source.dart # wraps scanner_service.dart
│   │       ├── internet_archive_source.dart
│   │       ├── audius_source.dart      # stream only
│   │       └── radio_source.dart       # stream only
│   │
│   ├── features/                       # one folder per feature: controllers, views, widgets
│   │   ├── library/
│   │   │   ├── controllers/            # scan_controller.dart
│   │   │   ├── services/               # scanner_service.dart, artwork_service.dart (MOVE from core/services)
│   │   │   ├── tags/                   # tag_reader.dart split into id3.dart, flac.dart, mp4.dart, tag_reader.dart (MOVE + split)
│   │   │   ├── views/                  # library_page.dart split into tabs: songs, albums, artists
│   │   │   └── widgets/
│   │   ├── player/                     # now playing, mini player, queue, lyrics, equalizer sheet
│   │   │   ├── controllers/            # player_controller.dart, palette_controller.dart
│   │   │   ├── services/               # lyrics_service.dart (MOVE from core/services)
│   │   │   ├── views/
│   │   │   └── widgets/                # mini_player.dart (MOVE from shared/widgets)
│   │   ├── playlists/
│   │   ├── search/                     # NEW: local plus online search UI
│   │   ├── downloads/                  # NEW: download queue, storage settings, offline library
│   │   ├── settings/                   # settings_page.dart split into sections; equalizer_controller.dart
│   │   ├── auth/                       # NEW (Phase 4): Google sign-in, guest mode, delete account
│   │   ├── purchase/                   # NEW (Phase 4): paywall, entitlement provider
│   │   ├── sync/                       # NEW (Phase 4): playlist backup to Firestore
│   │   └── updates/                    # MOVE update_service.dart and update_info_model.dart here; per-platform strategies
│   │
│   └── shared/
│       ├── providers/                  # app_providers.dart (MOVE from core/providers); split per feature as it grows
│       └── widgets/                    # app_shell, album_art, song_tile, empty_state, error_state, skeletons
│
├── test/                               # mirrors lib/: unit, widget, and integration tests
│   ├── core/  data/  features/
│   └── fixtures/                       # tiny mp3, flac and m4a files with known tags
├── integration_test/                   # NEW: play a file, scan a folder, download recovery
├── tool/                               # helper scripts (icons, demo library)
├── .github/workflows/                  # NEW: analyze + test on every push; signed builds on tags
├── .gitignore                          # build/, .dart_tool/, android/.gradle/, *.jks, key.properties, .env, *.log, *.dill
├── analysis_options.yaml
├── pubspec.yaml  pubspec.lock
└── README.md

docs/UPDATES.md                         # update flow and private manifest format

backend/                                # NEW (Phase 4), separate folder or repo: Node.js + TypeScript
├── src/
│   ├── routes/                         # purchases, entitlements, updates, source proxy
│   ├── services/                       # play_billing.ts, app_store.ts, firestore.ts
│   └── index.ts
├── test/
├── .env.example                        # names only, never real values
└── package.json

website/                                # NEW (later), separate folder or repo: Next.js
├── app/                                # landing, pricing, downloads, privacy, terms, support
└── package.json
```

**Dependency rules ChatGPT must follow**

1. Direction is `features` → `data` → `core`. `core` never imports from `features` or `data`.
2. A feature never imports another feature's `views` or `widgets`. Shared UI goes in `shared/widgets`, shared state in `shared/providers`.
3. Screens talk to repositories only. Repositories talk to sources and the database. Nothing in `views` calls `http` or reads files directly.
4. Platform-specific code lives behind an interface in `core/platform/`, with one implementation per OS.
5. Files stay under about 500 lines. Split by responsibility, not by arbitrary line count.
6. Each moved file gets its imports fixed in the same commit, and `flutter analyze` plus `flutter test` must pass before the next move.

**Order for the restructure.** Do it after Phase 1 (the app must compile and play first), and move one folder per commit: storage, then audio, then data, then the features.

## System design

Three diagrams show how the app is used, what data it keeps and how the main flows run. ChatGPT keeps the code consistent with them and updates the diagrams when a design changes.

### Use case diagram

&#91;embedded content: use case diagram · 1 actor, 10 use cases, 4 outside services\]

The listener reaches all ten use cases. Outside services only support sign-in, payment, online sources and updates, and the paid unlock is highlighted.

### ER diagram

&#91;embedded content: ER diagram · 8 tables, 7 relationships\]

Playlist items link playlists to songs, an album groups songs and belongs to one artist, and a download record exists only for saved songs. The sembast document store keeps these as collections with the same fields.

### Sequence diagram: purchase and unlock

&#91;embedded content: sequence diagram · purchase and unlock, 9 messages\]

The app never grants itself the unlock: the server verifies the purchase with the store and writes the entitlement, and the app only reads it.

### Sequence diagram: stream and download a track

&#91;embedded content: sequence diagram · stream and download a track, 14 messages\]

Streaming works for every enabled source. Saving an offline copy happens only for sources whose terms allow it, and the file is written as `.part` and renamed after the check.

## Phase 1: Stabilize

Do these tasks in order. Each has a check that must pass before moving on.

1. **Fix Windows playback.**
   - Remove `just_audio_windows`. Keep `just_audio_media_kit` and `media_kit_libs_windows_audio`.
   - Call `JustAudioMediaKit.ensureInitialized()` in `main()` for desktop, before the audio handler is created.
   - Wrap file loading in error handling so a bad file shows a message and skips to the next track instead of aborting.
   - Check: on Windows, play an mp3, a flac and an m4a; pause, seek, skip and let a track end without a crash or a stuck spinner.
2. **Fix the Riverpod mismatch.**
   - Pin `flutter_riverpod: ^2.6.1` (matches `docs/ARCHITECTURE.md`), or import `package:flutter_riverpod/legacy.dart` where `StateNotifier` is used.
   - Check: `flutter analyze` has no errors in `lib/`.
3. **Clean dependencies.**
   - Remove unused packages (confirm each with a search first): `drift`, `drift_flutter`, `on_audio_query_pluse`, `cached_network_image`, `go_router`, and `just_audio_windows`.
   - Replace `palette_generator` with a small color-extraction helper built on `material_color_utilities`, or keep it only if it still builds.
   - Check: `flutter pub get`, `flutter analyze` and `flutter test` all pass; the app still starts.
4. **App identity and signing.**
   - Set `applicationId` and `namespace` to `app.nmvybe.player` (or the ID the owner chooses) and set the app label to `NM VYBE`.
   - Add a release signing config that reads `android/key.properties`; never commit the keystore or the file.
   - Check: `flutter build apk --release` works with a local test keystore.
5. **Repository hygiene.**
   - Add to `.gitignore`: `build/`, `.dart_tool/`, `android/.gradle/`, `*.jks`, `key.properties`, `google-services.json`, `.env`, `*.log`, `*.dill`, `.nm_vybe_data/`, and the project-local temp folder.
   - Remove logs, `check_build.dill` and `android/local.properties` from the repo.
   - Check: `git status` is clean after a build.
6. **Windows data folder fallback.**
   - Keep the fallback to `.nm_vybe_data` only for development, and log a clear warning. The real fix is the Windows Temp and AppData permission; document it in the README.
7. **Wording.** Replace "free" with the paid positioning, and delete any "inspired by" or credit lines, in `pubspec.yaml`, `README.md` and `docs/ARCHITECTURE.md`.

## Phase 2: UI and smoothness

The goal is a calm, fast interface that feels native. Make these changes consistently across every screen.

**Design rules**

- One Material 3 theme in `app_theme.dart`. All colors, text styles, radii and spacing come from theme constants. No hard-coded colors or sizes inside widgets.
- A fixed spacing scale (4, 8, 12, 16, 24, 32) and a small set of text styles. Align everything to the scale.
- Dynamic color from the current album art, with a safe fallback when artwork is missing. Text must stay readable (check contrast) in light, dark and pure-black themes.
- Every screen has a loading skeleton, an empty state with one clear action, and an error state with a retry button.
- Tap targets are at least 48 dp. Everything works with large system fonts and TalkBack or Narrator labels on the main controls.
- On wide screens (Windows), use a side navigation and a two-pane layout instead of a stretched phone UI.

**Motion**

- Short, consistent transitions (150-300 ms). The mini player expands into Now Playing with a shared-element animation.
- Respect the system "reduce motion" setting.

**Performance targets (measure, don't guess)**

- Cold start to first interactive frame in under 1 second on a mid-range Android phone in release mode.
- A 5,000-song library scrolls at 60 fps with no dropped frames, using lazy builders and `const` widgets.
- Artwork is decoded at display size and cached on disk, with no full-size images in lists.
- Library scanning runs in the background, shows progress, and never blocks the UI thread.
- Use `ref.watch(provider.select(...))` so widgets rebuild only for the data they use.
- Profile with Flutter DevTools in profile mode before and after each change, and report the numbers.

**Code cleanliness**

- Split files over about 500 lines: `tag_reader.dart`, `settings_page.dart` and `library_page.dart` first.
- Check: a UI smoke test per main screen, and no jank warnings in DevTools while scrolling the library and opening Now Playing.

## Phase 3: Music sources and offline downloads

Build the source layer first, with local files as the only source, then add online sources one at a time. A source gets its `canDownload` flag set to true only after the owner confirms its terms allow offline copies.

**Architecture**

- `MusicSource` interface with `search(query, page)`, `getStreamUrl(trackId)`, `canDownload` and `attributionFor(track)`.
- `MusicRepository` merges results from all enabled sources. The UI never talks to a source directly.
- Track IDs are prefixed by source (`local:`, `audius:`, `ia:`) so they never collide.
- All API calls to third parties go through the Node backend when a key is involved. No keys in the app.

**Source status (verify terms again before building each one)**

| Source | Stream | Offline download | Notes |
| --- | --- | --- | --- |
| Local files | Yes | Not needed | Core feature |
| Internet Archive | Yes | Only items whose license allows it (public domain, CC0, some CC) | Read the license field of each item |
| Audius | Yes | No. Terms say streaming only | Confirm API terms and key rules |
| Jamendo | Needs a commercial license from Jamendo for a paid app | No. API terms forbid offline access | Ask Jamendo for a quote before building |
| Internet radio streams | Yes | No | Use only public stream URLs |
| YouTube or Piped | Do not build | Do not build | Store and legal risk |

**Offline download pipeline (only for `canDownload` sources)**

1. Ask the source for the best audio file it offers and keep the original bytes. Do not re-encode, so quality is the source's maximum.
2. Download to `<id>.part` in the app's private folder, with progress and cancel.
3. Verify the size (and hash if the source gives one), then rename to the final file.
4. Insert a database row: source, track ID, local path, codec, bitrate, size, license, date.
5. The player uses `localPath` when it exists, and streams otherwise.
6. Settings: storage limit, "delete downloads", download on Wi-Fi only, and a list showing size per track.
7. Retry with backoff, resume if the server supports it, and delete corrupt `.part` files on startup.

**Streaming cache.** For stream-only sources keep only a small playback buffer, cleared on exit. Do not save full copies.

**Check:** a test that downloads a public-domain Internet Archive file, kills the app mid-download, and confirms no corrupt file is left and the next launch recovers.

## Phase 4: Sign-in, purchase and updates

Do this only after Phases 1 to 3 are done and tested on a real Android phone and on Windows.

**Google sign-in**

- Use Firebase Auth with `google_sign_in`: one Google button, no email or password forms. Guest mode works before login, and playlists sync after login.
- Store data under `users/{uid}/...` in Firestore, with security rules that let a user read and write only their own documents.
- Add "Delete my account and data" in settings (required by both stores).
- Windows needs an OAuth browser flow. Test it early, because it differs from mobile.

**One-time purchase ($5.99)**

- Android and iOS: Google Play Billing and Apple In-App Purchase. Desktop direct sales: a merchant-of-record service (Paddle or Lemon Squeezy).
- The Node backend verifies every purchase with the store, then writes the entitlement to Firestore under the user's UID. The app can only read it.
- Free tier or trial so people can test before paying; the paywall must never lock the user's own files.
- Add Play Integrity checks on Android so the backend can reject modified apps.

**Secure updater (one strategy per platform)**

- Android is distributed only through Google Play and uses Play in-app updates; never self-install APKs.
- Windows direct downloads come from a private backend manifest; verify the installer SHA-256 before launching it. Release requests and installer downloads use HTTPS.
- The private manifest is stored outside the repository. No public `version.json`, APK URL, or installer URL belongs in source control. Its download URL remains a documented placeholder until Phase 4c adds license checks and hosting.
- iOS, macOS and Linux open their store or release page; they do not self-install binaries.
- Parse versions with a proper semver parser so `1.0.0-beta` never crashes.
- Never host paid builds on a public repository.
- Check: unit tests for version comparison, hash mismatch rejection and each platform branch.

**Hardening**

- Release builds use `--obfuscate --split-debug-info`, HTTPS only (turn cleartext traffic off), and no logging of tokens or personal data.
- Publish a privacy policy and terms before any store submission.

## Phase 5: Release, and how to report

**Release checklist**

- [ ] Android release APK/AAB is signed with the real keystore and installs on a real phone.
- [ ] Windows installer is built and code-signed (or the SmartScreen warning is documented).
- [ ] Playback works with the screen off, with headphones unplugged, and during a phone call.
- [ ] Media keys, lock-screen controls and the notification work on Android; media keys work on Windows.
- [ ] Library scan tested with 10, 1,000 and 10,000 songs.
- [ ] Privacy policy, terms and support email are live on the website.
- [ ] Store listing text, screenshots and the app icon are ready.
- [ ] A closed beta of at least 10 testers has run for two weeks with no crash in the last week.
- [ ] Purchase flow tested with test accounts, including refund and restore on a new device.

**How ChatGPT reports after each task**

1. What changed, listed as file paths.
2. The exact commands run and their results (`flutter analyze`, `flutter test`, build).
3. What was tested on a real device and what was not.
4. New problems found and what you recommend next.
5. The commit message.

Never say "done" without the command results. If a step fails twice, stop, explain the cause in plain words, and ask the owner before trying a different approach.

**First message to give ChatGPT**

> Read this document fully. Start with Phase 1, task 1 only. Show me the plan in five lines, then do it, run the checks, and report in the format above. Do not start task 2 until I say so.
