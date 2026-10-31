# Windows manual test checklist

Automation verifies library scrolling and fixture playback. Use this short
checklist for Windows behaviors that need real keyboard, window and audio
device interaction.

## Start the app

From a PowerShell terminal in the project folder:

```powershell
Set-Location 'D:\Flutter Projects\nm_vybe'
flutter run -d windows
```

## Media keys and system integration

- [ ] Start a local track, then use the keyboard's play/pause media key.
- [ ] Use previous and next media keys; verify track title and artwork update.
- [ ] Repeat with the app minimized and while another app has focus.
- [ ] If using a headset with media buttons, verify its controls too.

## Window sizing and layout

- [ ] Resize the window from wide to narrow and back while on Library.
- [ ] Repeat on Discover, Playlists, Settings and Now Playing.
- [ ] Confirm text, transport controls and navigation remain visible and usable.
- [ ] Minimize and restore the app; confirm the current track and position persist.

## Long-running playback

- [ ] Play a local track for at least 30 minutes, including a track change.
- [ ] Confirm playback continues while the app is minimized and the UI position
      remains in sync when restored.
- [ ] Test pause/resume, seek, repeat and shuffle during the session.
- [ ] Change the Windows default output device during playback; confirm audio
      recovers or record the exact error and recovery steps.
- [ ] Leave the app idle after playback and confirm CPU use settles.

## Record a failure

Record the Windows version, audio output device, file format, steps, and exact
error text. Re-run from the terminal to capture logs. Do not include private
file paths or personal library metadata in shared logs.
