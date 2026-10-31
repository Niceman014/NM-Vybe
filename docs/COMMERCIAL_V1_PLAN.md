# NM VYBE commercial v1 plan

## Product direction

NM VYBE v1 is a polished, local-first music player for Android and Windows. It
plays files the user already has, with library scanning, playlists, queue and
background playback. Local playback and local playlists work without an account
or network connection.

The owner selected a proprietary, closed-source license and a one-time purchase.
The permanent app ID is `com.nmnext.nmvybe`. Store accounts, exact pricing,
license text, and rights to all contributions/assets still need to be settled
before publication.

## Recommended distribution and updates

Use the official stores for the paid v1 binaries:

- **Android:** publish a paid Google Play listing. Google Play supports paid
  app pricing by country and manages updates for store-installed copies.
- **Windows:** publish an MSIX package through Microsoft Store. A packaged app
  can check for Store updates with `StoreContext`; the API requires package
  identity. Keep unpackaged developer builds outside the paid release/update
  path.
- **Settings:** keep a “Check for updates” action. It opens the Play listing on
  Android and the Microsoft Store Updates and downloads page on Windows; the
  store displays availability and performs updates for store-installed copies.
  This is a store hand-off, not an in-app version query. Use platform update
  APIs if a future release needs to display availability inside NM VYBE.

The old `version.json` APK URL has been removed. Private paid binaries must not
be advertised through the former public GitHub download path. Treat the JSON
file as version notes only; it is not an update feed.

Official references: [Google Play app pricing](https://support.google.com/googleplay/android-developer/answer/6334373?hl=en-en),
[Android app update behavior](https://developer.android.com/google/play/app-updates),
[Microsoft Store package updates](https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/package-updates-from-store).

## Sign-in and playlist backup

Google sign-in is for optional cross-device backup, not a prerequisite for
playing local files. The user should explicitly tap a Google sign-in button and
grant consent; the app should not assume it can silently choose the phone's
default account.

Google sign-in and cloud playlist backup are requested release features, not
implemented yet. They require a backend, account recovery, account deletion,
account-scoped access controls, service monitoring, and ongoing storage
funding. Avoid promising cloud playlists “for life” until retention and
service-continuity costs are funded and documented. Provide playlist export so
users can keep a portable copy. The one-time app license and the availability
of a hosted backup service must be described separately.

### Purchase and account decisions

- Sell the Android and Windows applications as separate one-time store
  purchases. Each store owns checkout, receipts, refunds, and the device's
  installation license. Do not add an app password, subscription, or a second
  in-app paywall for the same v1 product.
- A store purchase unlocks the app on the purchasing store account. It does not
  automatically transfer between Google Play and Microsoft Store accounts.
  Explain this before checkout; choose and publish country-specific prices in
  each store console.
- Local playback and playlists remain usable without a NM VYBE account. Google
  sign-in is a single, explicit button for the optional cloud-backup service.
  A user can select among accounts in Google's consent UI; never read or assume
  the phone's default Google account without consent.
- Verify Google identity on a trusted backend. Do not treat a user ID, email,
  ID token supplied by the client, or locally stored flag as authorization.
  Scope each backup record to the verified provider subject and enforce that
  same owner in database rules/server checks. Keep OAuth secrets and signing
  credentials out of the app bundle and repository.
- Back up playlist metadata (playlist names, order, and stable track
  identifiers), not users' audio files. Android/Windows file paths are
  device-specific and must not be presented as portable audio. Provide
  export/import and a clear last-sync/error state.
- “For life” is not a supportable cloud-retention guarantee for a one-time
  purchase without a funded service commitment. Describe backup as available
  while the service operates, document retention/deletion and account recovery,
  and give users a portable export. Decide storage, monitoring, support, and
  shutdown/restore policy before implementing cloud backup.

If an iOS release later uses Google as its primary login, plan to offer Sign in
with Apple where Apple's login-services rule applies. iOS is not part of v1.

## Current release blockers

| Area | Current evidence | Required before release |
| --- | --- | --- |
| App identity | Owner selected `com.nmnext.nmvybe`; Android namespace/application ID and iOS app/test bundle IDs now use it | Keep this identity unchanged for all future releases |
| Android signing | Release build loads `android/key.properties`; a release task now fails unless all values and the keystore file are configured | Create and back up the upload keystore securely, copy `android/key.properties.example`, and configure CI secrets before a release build |
| Flutter analysis | Riverpod is pinned to the documented 2.6.1 API; `flutter analyze` now reports no issues | Run tests and Android/Windows release builds before store submission |
| Updates | The public APK download URL was removed; Settings opens Google Play's app listing or Microsoft's Updates and downloads page | Test with store-installed builds; listings and Windows package identity are still pending. The current action hands off to the store and does not query availability inside the app |
| Purchase | Product decision is separate one-time paid store listings for Android and Windows; no client-side entitlement or payment SDK is implemented | Create store listings, set prices/refund disclosures, and validate owned-license/install behavior with store accounts |
| Google account | Not implemented; local playback does not require sign-in | Select and configure trusted OAuth/backend/database services, verify tokens server-side, enforce user-scoped backup access, and publish privacy/account-deletion flows before enabling the button |
| Product copy | README and Settings now describe a planned one-time commercial release, local guest use, and unpublished store listings | Keep release claims synchronized with working store purchases, sign-in, and update features |
| License | Owner selected proprietary/closed-source; no root license document is present; Settings includes Flutter's third-party license page | Audit authorship, contributions, dependencies, and assets; prepare reviewed proprietary terms before sale |
| Dependencies | Removed unused packages and the uninitialized media-kit backend; `on_audio_query_android` is locally patched under BSD-3-Clause for namespace, Flutter compileSdk, and Java/Kotlin target compatibility; `file_picker` is pinned to 10.3.10 for Flutter compileSdk compatibility and Android parser fixes | Keep one active desktop playback backend; review upstream releases and remove the local patch when upstream includes these Android build fixes |
| Windows media codecs | Removed the unused `media_kit_libs_windows_audio` package from the v1 dependency set; the app uses the declared Windows-native `just_audio_windows` backend | Revisit media-kit only if another platform needs it, with exact binary licenses and notices verified first |

### Preliminary dependency license review

The locally resolved `on_audio_query` package includes a BSD-style 3-clause
license and `just_audio_windows` includes MIT terms. Include required
third-party notices with distributed binaries. These checks cover selected
direct dependencies only, not the full transitive dependency or asset
inventory.

Local signing files and passwords are now ignored by `.gitignore`. A repository
search found no matching credential files or tracked copies at the time of this
review; repeat the secret scan before release.

## Release sequence

1. Audit authorship and asset rights; prepare reviewed proprietary license terms and third-party notices.
2. Stabilize dependencies and source, then run `flutter analyze`, unit/widget
   tests, and release builds on a functioning Flutter toolchain.
3. Configure Android upload signing and Windows MSIX identity/signing. Keep
   secrets in the release environment, not source control.
4. Publish through Google Play and Microsoft Store; verify the Settings store
   hand-off on store-installed packages and handle developer builds explicitly.
   Add platform update APIs only if an in-app availability result is required.
5. Set store prices, privacy disclosures, support contact, store listings, and
   refund/support policies before publishing.
6. Implement Google sign-in and playlist cloud backup after choosing the
   backend and defining retention, export, account deletion, and operating costs.
7. Plan iOS, macOS, and Linux as separate platform releases with their own
   playback, purchase, signing, and update validation.

## Validation snapshot (2026-10-29)

- `flutter analyze`: passed with no issues.
- `flutter test`: passed (28 tests).
- `flutter build apk --debug`: passed. The installed SDK is Flutter 3.50.0
  beta; repeat release validation on the stable channel before publishing.
- `flutter build windows --release`: passed and produced an unpackaged Windows
  bundle. Store packaging, package identity, and signing are still pending.
- Windows app-data metadata now uses the NM VYBE identity, and startup copies
  existing files from the previous `com.example/nm_vybe` folder when needed.
  `tool/run_windows.ps1` redirects debug data and temp files into ignored
  workspace folders for restricted environments.
- Windows Debug could not be relaunched during this check because its existing
  executable was locked (`LNK1168`). Close the running debug app before using
  the helper to validate the startup path interactively.
- Android Play release signing is not configured because the private keystore
  and `android/key.properties` are not present. Do not publish a debug build.
- No physical-device playback, permission, background-audio, or store-install
  tests have been run in this workspace.
