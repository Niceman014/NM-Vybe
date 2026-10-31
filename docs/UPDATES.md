# Secure update flows

Phase 4a adds platform-specific update handling. A Windows installer download is
not live yet: the manifest uses a placeholder until Phase 4c adds license
checks and hosting. No APK or installer URL is published in this repository.

## Windows update manifest

The backend serves:

```text
GET /v1/updates/latest?platform=windows&channel=stable
```

The manifest is read from a private JSON file. Set the backend environment
variable `UPDATE_MANIFEST_FILE` to its path. If unset, the backend looks for
`backend/private/updates.json`. That path is ignored by Git. Keep actual release
metadata private, and do not put credentials in the app or response logs.

Manifest shape:

```json
{
  "releases": {
    "windows": {
      "stable": {
        "version": "1.2.0+14",
        "minSupportedVersion": "1.0.0+1",
        "releaseNotes": "Security and stability improvements.",
        "sha256": "<64 hexadecimal characters>",
        "sizeBytes": 12345678,
        "downloadUrl": "PHASE_4C_DOWNLOAD_URL_PENDING"
      }
    }
  }
}
```

`version` and `minSupportedVersion` use SemVer. `sizeBytes` is the exact
installer size. `sha256` is the lowercase or uppercase SHA-256 digest. The
placeholder is returned as `downloadUrl` with `downloadConfigured: false` until
Phase 4c has implemented the license check and the owner has hosted the signed
installer. A real URL must use HTTPS. The endpoint accepts the Windows platform
and `stable` or `beta` channels; Android APK metadata is rejected.

The Windows app reads `BACKEND_URL`, compares the installed version, and shows
release notes when an update is available. Before opening the installer it
downloads to a `.part` file, checks the declared size and SHA-256, then renames
and launches it. It never launches on a hash or size mismatch. Release builds
require HTTPS for both the backend and installer; debug builds may use HTTP only
for a local/private backend. Interrupted `.part` files are removed on the next
startup.

## Platform behavior

- **Android:** distributions come only from Google Play. The app uses Play's
  in-app update API, then falls back to the app's Play listing if the API is
  unavailable (for example, a locally sideloaded build). It never self-installs
  an APK.
- **Windows:** the app queries the backend manifest, downloads the direct
  installer over HTTPS, verifies the exact size and SHA-256, then launches it.
  A version below `minSupportedVersion` shows a non-dismissable update screen;
  already-downloaded and local music can still be played offline.
- **iOS and macOS:** open the App Store search page. Apple manages installation
  and updates.
- **Linux:** open the repository's release page. NM VYBE does not launch a
  Linux installer itself.

The optional automatic check runs at most once per day and is skipped when the
device reports no network connection. A manual check remains available in
Settings.

## Owner actions before release

1. **Android:** build and sign the app bundle, publish it to a Google Play
   internal testing track, and verify updates using a Play-installed test build.
   In-app updates are not testable from a normal sideloaded APK.
2. **Windows:** build the installer from the release source and sign it with
   the product's trusted code-signing certificate. Test install, upgrade,
   rollback/recovery, and the minimum-supported-version gate on a Windows test
   machine.
3. After Phase 4c adds license checks, host the signed installer at a stable
   HTTPS URL. Record its exact byte size and SHA-256.
4. Create the private manifest file outside Git, fill in the release metadata,
   replace `PHASE_4C_DOWNLOAD_URL_PENDING` with the hosted HTTPS URL, and set
   `UPDATE_MANIFEST_FILE` in the backend environment. Restart the backend and
   verify the endpoint reports `downloadConfigured: true` without logging the
   URL or any token.
5. Increase the app version and minimum supported version only when the release
   policy requires it. Keep the stable and beta manifests separate.

## Phase 4a test limits

Automated tests cover SemVer ordering, backend validation/rate limiting/cache,
platform strategy selection, HTTPS policy, interrupted-file cleanup, exact-size
checks, hash rejection, and launch-after-verification ordering. Google Play's
in-app flow requires a Play-distributed build and a configured test track. The
Windows installer cannot be downloaded or launched until Phase 4c supplies
license checks and the owner hosts a signed installer. Real Android Play and
Windows upgrade testing remain owner-run checks.
