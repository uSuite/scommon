# scommon

The shared Swift package of the s-family (sView, sNotate, sCapture, later sWalk): folder scanning and watching, natural sort, the `poc-` case and file-name parsing, the `key value` config parser and `KeyValueSettings`, the keymap grammar and matcher, `ConfigPaths` for `~/.config/<app>/`, `ConfigArchive`, and for the App Sandbox `Sandbox`, `Bookmarks` and `FolderAccess`. Swift 6.2, Foundation, Dispatch, CoreServices, UniformTypeIdentifiers and CoreGraphics only, macOS 26, strict concurrency, no third-party packages. Extracted from sView (develop 24ffd9d) on 2026-10-27. Published as `uSuite/scommon` on GitHub; consumers use a sibling `../scommon` checkout when there is one, else the GitHub URL from a minimum version (docs/DECISIONS.md).

## Commands

- `make test`   swift test (the only tests of this code; a consumer's `swift test` does not run them)
- `make build`  swift build
- `make lint`   compile every source file alone
- `make clean`
- `make version`

## Rules

- Shared code changes here first, test first; a change set gets a tag (patch for a fix, minor for a new key or type) once every consumer's smoke passes against it.
- Never edit these files through a consumer's checkout; never copy them into a consumer.
- No AppKit, no SwiftUI, no ImageIO here: a type that needs them belongs to the consumer.
- One logical change per commit; the message says why. Default git identity, no trailers.
- Multi-line calls: one argument per line. No banner comment lines.
- Plain text, no em-dash character, no horizontal rules in markdown, one paragraph per line.
- Update docs/local/STATUS.md (untracked, the session log) at the end of every session; docs/DECISIONS.md is the source of truth.
