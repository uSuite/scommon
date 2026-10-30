# scommon

<img src="brand/scommon-1024.png" alt="scommon icon" width="128">

The shared package of the s-family: what sView, sNotate and sCapture all need and none of them should own. A plain SwiftPM library with no dependencies, published at `https://github.com/uSuite/scommon`; an app adds `.package(url: "https://github.com/uSuite/scommon.git", from: "0.3.0")`, and the s-family apps use a sibling `../scommon` checkout instead when there is one.

## Part of sSuite

sSuite is a small family of macOS tools that turn work done on screen into step-by-step evidence and guides, one job per tool, published under the [uSuite](https://github.com/uSuite) organization. The organization page explains why the family exists.

| Tool | Job |
| --- | --- |
| [sCapture](https://github.com/uSuite/scapture) | captures a window at a fixed size and scale into the active case folder (shell proof of concept today, Swift app next) |
| [sView](https://github.com/uSuite/sview) | views images and walks case folders from the keyboard |
| [sNotate](https://github.com/uSuite/snotate) | annotates a case folder as one story and exports one image per step |
| sWalk | planned: renders a notated case as an animated step-by-step clip |
| **scommon** (this one) | the Swift package the tools share: folders, sorting, config and keymap |

scommon has no app of its own. A change here is tested here first, tagged, and then picked up by each tool by raising its minimum version.

## What is in it

| Module part | What |
| --- | --- |
| FolderScanner, FolderModel, FolderTree, ImageItem, Sorter | list and order the images of a folder and its siblings; natural sort, hidden and AppleDouble files skipped |
| DirectoryWatcher, FSEventWatcher | see files appear, change and vanish |
| PocCase | `poc-<product>-<area>-<action>` folders, `<case-id>-<nn>` and `<tool>-YYYY-MM-DD-HHMMSS` capture names |
| KeyValueParser, KeyValueSettings, LineIssue, ConfigPaths | the `key value` text files in `~/.config/<app>/` and the problems they report |
| Key, Keymap, KeyMatcher | the key grammar shared by every app, generic over the app's command type |

`PocCase` is one opinionated convention for case folders of step-by-step evidence captures (`poc-demo-vm-stop/poc-demo-vm-stop-01.png`, or `scap-2026-10-25-143012.png` from sCapture); code that does not use that layout can ignore it.

The family's icons, their rules and the uSuite organization avatar are in `brand/` (see `brand/README.md`).

Build and test with `make test`; Swift 6.2 and macOS 26. MIT licence.
