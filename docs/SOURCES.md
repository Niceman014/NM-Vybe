# Music sources and usage rights

Terms checked: 2026-10-31.

| Source | Terms / attribution | Offline `canDownload` | Remaining licensing |
| --- | --- | --- | --- |
| Local library | User-selected audio files; remain stored at their original locations. | No source download action; existing local files remain available offline. | User is responsible for having rights to their local files. |
| Jamendo | Jamendo catalog streams include track/artist credit, a link to the Jamendo item, and the track license link. Jamendo's API client ID stays in the backend environment. | **False for every Jamendo track.** NM VYBE does not expose Jamendo downloads or offline copies. | A separate Jamendo commercial-use agreement/authorization for the commercial app and catalog use remains required before distribution. The dashboard's Commercial setting alone is not treated as an offline-use license. |
| Internet Archive | Each item's `licenseurl` (or explicit rights statement when no URL is provided) is read from its item metadata. Credit is shown with a link to the item and, when present, to its license. Internet Archive says item rights are supplied by uploaders, does not guarantee copyright status, and requires users to ensure their use is lawful. | **Per item only:** true for explicit public-domain or CC0 declarations and recognized CC BY / CC BY-SA license URLs. Unknown, NC, ND, and other licenses are stream-only. | Item-specific rights remain the uploader's declaration and must be respected; Internet Archive does not grant a blanket license to its catalog. |

The Internet Archive download allow-list is intentionally conservative. It does not infer permission from a file being publicly playable, and it does not enable downloading based on an unknown or uploader-only statement.

References:

- [Jamendo API Terms of Use](https://devportal.jamendo.com/api_terms_of_use)
- [Jamendo Tracks API license and download fields](https://developer.jamendo.com/v3.0/tracks)
- [Internet Archive Item Search API](https://archive.org/services/docs/api/metadata.html)
- [Internet Archive Item Metadata API](https://archive.org/services/docs/api/md-read.html)
- [Internet Archive rights guidance](https://help.archive.org/help/rights/)
- [Internet Archive Terms of Use](https://archive.org/about/terms.php)
- [Creative Commons license deeds](https://creativecommons.org/share-your-work/cclicenses/)
