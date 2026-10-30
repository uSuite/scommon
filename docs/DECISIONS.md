# scommon: decisions

Single source of truth for choices that shape the code. Newest at the bottom. Supersede, never rewrite.

## 2026-10-27 scommon is a package, extracted from sView's SCommon target

Why: three siblings (sView, sNotate, sCapture) share the same 15 files; sView split them into an `SCommon` target on 2026-10-26 and sNotate copied that target whole, byte-identical as checked on 2026-10-27. The rule of three is met and a copy that must stay identical is a package. Origin: sview `develop` 24ffd9d; the files are copied, the history stays in sview. Rules out: a git submodule, a vendored copy, a published registry package.

## 2026-10-27 Consumers depend by local path, unpinned

Why: one person edits all repositories on one machine; a version pin would be ceremony with no second party to protect. `Package.swift` says `.package(path: "../scommon")` and XcodeGen's `packages:` the same path. Tags mark change sets for the changelog and for the day a second machine appears. Rules out: version requirements in consumers' manifests.

## 2026-10-27 Foundation and CoreGraphics only

Why: every consumer tests its core headless, and the shared code must stay the most testable part. Anything that needs AppKit, SwiftUI or ImageIO is the consumer's. Rules out: image decoding, views, menus, and any file this package would open on a consumer's behalf.

## 2026-10-27 The import rule names what the code already imports (supersedes "Foundation and CoreGraphics only")

Why: the code extracted from sView imports Foundation, Dispatch, CoreServices (FSEvents for `FSEventWatcher`) and UniformTypeIdentifiers (image types in `FolderScanner`), and none of them CoreGraphics. All four are headless and testable, which is what the earlier entry meant to protect. Allowed: Foundation, Dispatch, CoreServices, UniformTypeIdentifiers and CoreGraphics. Rules out, as before: AppKit, SwiftUI, ImageIO and anything that draws or decodes.

## 2026-10-30 ConfigArchive: an app's settings as a zip, out and back in

Why: sView and sNotate each carried a `ConfigExport`, the same code with another folder name, and the Settings windows both apps gained on 2026-10-30 needed import too, which would have been a second shared copy. `ConfigArchive(app:fileNames:)` writes the files that exist into one `<app>/` folder of a zip (with `ditto`, no resource forks, extended attributes or quarantine), never state.json; `inspect` reads a zip back, its `<app>/` folder or the files at its root, in `fileNames` order, refusing one with none of them or a file that is not UTF-8, and hands each file to the app's own check so the app can show the problems it would report on disk before anything changes; `apply` writes them, keeping each replaced file as `<name>.bak` (an older backup is replaced). The default destination keeps the old rule: `<app>-config-<date>.zip` on the Desktop, never overwriting. Process and file work only, so it stays inside the import rule. Rules out: merging an imported file into the current one, importing state.json, an app-specific check here.

## 2026-10-30 Consumers use the sibling checkout, else the GitHub URL (supersedes "Consumers depend by local path, unpinned")

Why: the s-family goes public under the uSuite organization on GitHub, and someone who clones one app has no `../scommon`. A consumer's `Package.swift` picks `.package(path: "../scommon")` when that folder holds a `Package.swift`, and `.package(url: "https://github.com/uSuite/scommon.git", from: "<minor>")` otherwise, so the one-machine workflow is unchanged and an outside clone builds. A consumer raises its minimum when it needs a newer change set; tags are now what outside builds resolve, so a change set is never retagged. Rules out: a manifest that only works next to a sibling, `swift package edit` (xcodebuild does not honour it).

## 2026-10-30 Timestamp captures take any lower-case prefix

Why: the timestamp pattern was written for the one prefix of the capture scripts used before sCapture, so sCapture's own `scap-` captures had no step. `<tool>-YYYY-MM-DD-HHMMSS` with `<tool>` lower-case letters keeps both and anything later. Rules out: a configurable prefix list.

## 2026-10-30 Published as uSuite/scommon; the session log stays local

Why: the public repository starts from one commit of the released tree; the history before it stays in the private archive copy. docs/STATUS.md is a working log of sessions on one machine, so it moves to docs/local/, which is ignored. Rules out: publishing the private history, tracking the session log.

## 2026-10-30 The family's branding lives in brand/ here

Why: sView's `docs/04-branding.md` said the family note moves to `scommon/brand/` once scommon exists, and the uSuite organization, scommon and sWalk now have marks of their own. `brand/README.md` is that note with rows for sWalk (violet, play dot), scommon (slate, braces) and the organization (graphite, three dots in the app colours), and the one non-white accent, sCapture's deep green reticle. `brand/render.swift` draws any member's icon from its SVG layers; it uses AppKit, so it is a script beside the package, never part of `Sources`. Rules out: a second copy of the family note in an app repository (sView keeps a pointer).
