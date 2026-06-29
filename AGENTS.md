# Repository Rules

## Debug and release version synchronization

- `build.yaml` is the release-version source of truth.
- During UI development, run `./update-ui-version.ps1`. Debug builds may display a date-based label such as `UI version: 2026.06.29-c` and use the matching date-based cache suffix.
- Before a release or version commit, run `./update-version.ps1 -Version <X.Y.Z>` from the repository root.
- The script must keep `build.yaml`, `Directory.Build.props`, `Constants.PluginVersion`, the internal UI cache suffix, Jellyfin/Emby page registrations, and visible page version labels synchronized.
- Release pages must display `Version: <X.Y.Z>` and must not retain the debug-only `UI version` label.
- The internal UI asset suffix may remove punctuation (for example, `2.3.1` becomes `v231`) because Jellyfin and Emby page/controller identifiers must remain cache-safe.
- Create and push `v<X.Y.Z>` only after the synchronized version change, tests, and Release builds have succeeded.

## Private documentation

- Keep implementation reports, local developer notes, prompts, and archived samples under `doc/`.
- `doc/` is intentionally ignored as a whole. Never force-add its contents or list private report filenames in `.gitignore`.
- A release report should include the implemented behavior, API changes, tests, build results, release version, commit, tag, and any publication status.

## Host parity

- UI and management API changes must be applied to both Jellyfin and Emby unless a host-specific limitation is documented.
- Jellyfin keeps its Browser JavaScript inline in `browserPage.html`; Emby keeps the equivalent controller in `browserPage.js`.
