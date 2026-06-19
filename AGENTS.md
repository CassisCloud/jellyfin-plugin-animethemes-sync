# Codex Notes

## Release Process

- GitHub Releases are created from version tags, but Jellyfin plugin update text and catalog metadata do not change for users until the `gh-pages` `manifest.json` is updated.
- After publishing a release, verify or update the generated `manifest.json` on `gh-pages` so Jellyfin can see the new version and changelog.
- Keep release notes concise and consistent with prior releases: use `## Changes` with short bullet points.
- Avoid including validation commands, implementation internals, or non-plugin details in release notes.
- Remember that Jellyfin's plugin page does not render release-note line breaks reliably, so write changelog bullets that still read acceptably when flattened.
