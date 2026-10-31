# NM VYBE

**Your music. Your vibe.**

NM VYBE is a local-first music player for Android and Windows. It scans and
plays music already available on your device, organizes it into a searchable
library, and keeps playlists and playback preferences locally. Optional online
discovery uses Jamendo and the Internet Archive through clearly attributed
source listings.

> **Project status:** Android is the primary target and Windows is in beta.
> Public store releases are not available yet. Online Jamendo use in a
> commercial release still requires the applicable commercial authorization.

## Highlights

- **Local music library** — Android MediaStore scanning and Windows folder
  scanning, with searchable titles, artists, albums, and playlists.
- **Metadata and artwork** — reads common tags and embedded or folder artwork.
- **Full player controls** — queue, shuffle, repeat, playback speed, sleep
  timer, and background playback controls on Android.
- **Playlists and favourites** — manage collections locally on your device.
- **Lyrics** — display local `.lrc` files with synced highlighting.
- **Online discovery** — search and stream Jamendo tracks through the backend;
  Jamendo is always stream-only. Internet Archive items are downloadable only
  when their item metadata identifies a supported copying license.
- **Adaptive interface** — Material 3, light and dark themes, dynamic colour,
  and layouts for phone and desktop sizes.

### Audio formats

MP3, M4A/AAC, FLAC, WAV, OGG, Opus, AIFF, and WMA (best effort, depending on
the platform decoder).

### Platform support

| Platform | Status | Notes |
| --- | --- | --- |
| Android | Primary target | Local library scanning, background playback, and media controls |
| Windows | Beta | Local folder scanning and desktop playback |
| Web, Linux, macOS | Not release-supported | May require platform-specific work |

## Quick start

### Requirements

- Flutter 3.47 or later (with its bundled Dart SDK)
- Android SDK for Android builds
- Visual Studio with Desktop development with C++ for Windows builds
- Node.js 20 or later for the optional online music backend

### Get the app running

```powershell
git clone https://github.com/Niceman014/NM-Vybe.git
cd NM-Vybe
flutter pub get
flutter run -d windows
```

For Android, connect a device with USB debugging enabled or start an emulator,
then run:

```powershell
flutter run -d <device-id>
```

Use `flutter devices` to see available device IDs. In VS Code, open the project
folder and run those commands in its integrated terminal. For Windows, the
included helper also prepares writable, project-local temporary folders:

```powershell
.\tool\run_windows.ps1
```

The VS Code task **NM VYBE: Run Windows** invokes the same helper. To connect
the Windows app to a locally running backend, pass its URL:

```powershell
.\tool\run_windows.ps1 -BackendUrl http://127.0.0.1:8787
```

## Online music backend

The app reads `BACKEND_URL` from a Dart compile-time define. If it is omitted,
online search is disabled with an explanatory message; local music playback
continues to work.

### Run locally

Create `backend/.env` from `backend/.env.example` and set the Jamendo client ID
as `JAMENDO_CLIENT_ID`. Keep `.env` private and never pass the client ID or a
client secret to Flutter. Start the service in a terminal:

```powershell
cd backend
npm run start:local
```

In another terminal, connect the app. Use `127.0.0.1` on Windows, `10.0.2.2`
from an Android emulator, or the PC's private LAN address from a physical
phone on the same network:

```powershell
# Windows
flutter run -d windows --dart-define=BACKEND_URL=http://127.0.0.1:8787

# Android emulator
flutter run -d <device-id> --dart-define=BACKEND_URL=http://10.0.2.2:8787

# Physical Android phone (replace with the PC's private IPv4 address)
flutter run -d <device-id> --dart-define=BACKEND_URL=http://192.168.1.25:8787
```

For a phone connection, set `HOST=0.0.0.0` in the local backend environment
and allow port `8787` through Windows Firewall only on a trusted private
network. Debug builds accept HTTP only for loopback and local/private addresses.
Release builds require HTTPS.

### Deploy the backend

The root `render.yaml` defines a Render web service. Configure
`JAMENDO_CLIENT_ID` as a private host environment variable, deploy the backend,
then build the app with its HTTPS address:

```powershell
flutter build apk --release --dart-define=BACKEND_URL=https://your-api-host
flutter build windows --release --dart-define=BACKEND_URL=https://your-api-host
```

Review the provider's current hosting charges and Jamendo's commercial terms
before deployment or commercial distribution. The Jamendo client ID must stay
on the backend. Do not commit `.env`, signing credentials, or private keys.

## Offline downloads and source rights

Jamendo tracks are stream-only in NM VYBE. Internet Archive tracks become
downloadable only for rights metadata that explicitly identifies public
domain, CC0, CC BY, or CC BY-SA. Other and unclear licenses remain stream-only.
Downloads are stored locally with source and license information. Because
Internet Archive rights are supplied by uploaders, users must review each
item's rights and comply with its terms. See [docs/SOURCES.md](docs/SOURCES.md)
for source terms, attribution, and the last review date.

## Build

```powershell
# Android APK
flutter build apk --release

# Windows desktop
flutter build windows --release
```

For a signed Android release, create a private upload keystore and configure
`android/key.properties` using [android/key.properties.example](android/key.properties.example).
The actual properties file and keystore are ignored by Git and must remain
private. Windows packaging and code signing are not yet configured as a
published installer.

## Verification

Run the app and checks locally:

```powershell
flutter pub get
flutter analyze
flutter test

cd backend
npm test
```

The backend test suite uses temporary loopback HTTP servers. Local firewall or
endpoint-security rules may need to allow the test process to bind to
`127.0.0.1`.

## Project layout

```text
lib/                  Flutter app, feature screens, state, services, sources
backend/              Jamendo API proxy, health endpoint, and Node tests
docs/                 Architecture and music-source terms
android/, windows/    Native platform runners and configuration
test/                 Flutter unit and widget tests
tool/                 Development helpers and demo-library generator
third_party/          Local Android plugin patch (see its package license)
```

The app uses Riverpod for state, `just_audio` with `media_kit` on Windows,
`audio_service` for background controls, and Sembast for local persistence.
See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for more detail.

## Roadmap

- [x] Local library scanning, metadata, artwork, and playlists
- [x] Queue controls, sleep timer, playback speed, and Android media controls
- [x] Jamendo stream-only discovery through a backend
- [x] Internet Archive discovery with license-aware offline downloads
- [ ] Physical-device verification of local-backend discovery and downloads
- [ ] Jamendo commercial authorization for commercial distribution
- [ ] Published Android and Windows packages

## Contributing and licensing

NM VYBE is currently a proprietary project and is not accepting public code
contributions. Third-party libraries and assets remain subject to their own
licenses; review the in-app third-party notices and source documentation before
redistribution. A complete dependency and asset rights audit is still required
before commercial sale.

NM VYBE does not host or distribute a general music catalog. It plays local
files and presents links to third-party music sources; users are responsible
for respecting the rights and terms associated with their files and each
online item.
