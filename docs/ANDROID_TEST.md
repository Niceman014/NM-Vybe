# Real Android phone test checklist

This checklist is for a USB-connected Android phone. The checked build is a
debug APK; it is for QA and must not be distributed as a production release.

## 1. Prepare the phone and PC

1. On the phone, enable **Developer options** and **USB debugging**.
2. Connect the phone by USB, unlock it, and accept the debugging prompt.
3. In a project-root PowerShell terminal, run:

   ```powershell
   flutter devices
   adb devices -l
   ```

4. Confirm the phone appears as `device` (not `unauthorized` or `offline`). If
   it is unauthorized, accept the phone prompt and run `adb devices -l` again.
5. If Windows does not list it, install the phone manufacturer's USB driver,
   reconnect, and repeat these checks. Do not proceed until ADB sees the phone.

## 2. Install the debug APK

Build from the project root. This build intentionally has no online backend
URL, so the app must explain that online search is not configured while local
playback remains available.

```powershell
$env:TEMP = Join-Path (Get-Location) '.tmp'
$env:TMP = $env:TEMP
flutter pub get
flutter build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

Open **NM VYBE** from the phone. `-r` upgrades an existing install while
preserving its app data when Android permits it. To reinstall from scratch,
uninstalling clears NM VYBE's private app data; do that only if you intend to
reset the phone's app data.

## 3. Local library and playback

- [ ] First launch reaches the app without a blank screen or startup error.
- [ ] Grant music/audio permission when prompted; deny once and confirm a clear
      recovery path is offered.
- [ ] Scan a library and verify song, artist, album, and artwork information.
- [ ] Play, pause, seek, skip forward/back, shuffle, and repeat.
- [ ] Test one MP3, FLAC, and M4A/AAC file if available; record codec and phone
      model for each result.
- [ ] Lock the screen while playing; check notification and lock-screen
      controls, then pause and resume from the notification.
- [ ] Unplug/reconnect headphones and receive a phone call; check playback
      interruption and recovery.
- [ ] Switch light, dark, and pure-black themes; confirm readable text and no
      visible flash while changing themes.
- [ ] Try large system font/display scaling and verify the main controls remain
      visible and usable.

## 4. Optional online-source test against the local PC backend

Only do this on a trusted private Wi-Fi network. Find the PC's private IPv4
address with `ipconfig`; use that address below instead of the example. Start
the backend with `HOST=0.0.0.0`, `PORT=8787`, and `JAMENDO_CLIENT_ID` provided
only by the ignored `backend/.env`. Allow TCP 8787 through Windows Firewall
only for the Private profile. Never put a Jamendo secret in Flutter build
arguments.

Build a debug APK that points at the PC's LAN address:

```powershell
flutter build apk --debug --dart-define=BACKEND_URL=http://192.168.1.25:8787
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

- [ ] `http://192.168.1.25:8787/health` is reachable from the phone browser.
- [ ] Discover searches Jamendo and shows source/artist credit and item link.
- [ ] Jamendo is stream-only; no Jamendo download action is offered.
- [ ] Internet Archive items show attribution; download is available only when
      the license qualifies, and the saved item plays offline.
- [ ] Stop Wi-Fi during a transfer; verify cancellation/interruption leaves no
      partial or playable corrupt download after restarting the app.

## 5. Capture and report results

Record the date, phone model, Android version, APK build command, sample codecs,
network used, pass/fail for every checked item, and any visible error text.
Collect filtered logs if a failure occurs:

```powershell
adb logcat -c
# Reproduce the problem on the phone, then:
adb logcat -d -s flutter:D AudioService:D AndroidRuntime:E
```

Do not attach logs before checking that they contain no private paths,
identifiers, or user data.
