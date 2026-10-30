# Changelog

Versions follow semver: a patch for a fix, a minor for a new key or type. Each release lists what a consumer notices; docs/DECISIONS.md has the reasoning.

## 0.3.1 (2026-10-30)

No code change. `brand/` holds the family's branding: the note on the s mark and its colours, the SVG layers and rendered icons of the uSuite organization, scommon and sWalk, and `render.swift` to draw any of them.

## 0.3.0 (2026-10-30)

Published as `uSuite/scommon` on GitHub. `PocCase.step` reads a timestamp capture with any lower-case prefix, `<tool>-YYYY-MM-DD-HHMMSS`, so sCapture's `scap-` captures have a step. Consumers take the package from a sibling `../scommon` checkout when there is one, else from `https://github.com/uSuite/scommon.git` from this version.

## 0.2.0 (2026-10-30)

`ConfigArchive`: an app's config files as a zip, exported and imported, with the app's own check of each file before an import changes anything and `.bak` copies of what it replaces. sView and sNotate use it in place of their own `ConfigExport`.

## 0.1.0 (2026-10-27)

Extracted from sView 24ffd9d, used by sView and sNotate. Folder scanning and watching, natural sort, the `poc-` case and file-name parsing, the `key value` config parser and `KeyValueSettings`, the keymap grammar and matcher, and `ConfigPaths`, with the 41 tests that came with them.
