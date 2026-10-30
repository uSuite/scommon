# The s-family: naming and app icons

Family-level note for sView, sNotate, sCapture, sWalk and scommon, and for the uSuite organization that publishes them. Proposed 2026-10-25 in the sview repository; moved here with the shared artwork on 2026-10-30.

## What the s means

The lower-case `s` reads as super-fast, and as swift: the apps are fast, and they are built with Apple's Swift toolchain. Both readings are intended and neither is spelled out in the product. The app names are `sView`, `sNotate`, `sCapture` (lower-case s, capital verb), binaries and config directories are `sview`, `snotate`, `scapture`, and nowhere does the UI, the About box or the README expand the s into a word. If someone asks, the answer is "super-fast, and swift"; that keeps the pun and avoids the next point.

Trademark boundary: "Swift" as a language name and the Swift bird logo are Apple's marks, and the orange-gradient bird is instantly recognisable. The family never uses the bird, the Swift wordmark, Apple's orange, or anything that could suggest the apps are Apple products. A lower-case s of our own geometry, in our own colours, is ours.

## The mark

One shared mark, and per member a colour and a small accent. The mark is a lower-case `s` drawn as a path (two joined arcs of equal stroke, round caps), not set from a font, so there is no font licence to think about and the SVG is a few lines of plain text. It is heavy and slightly condensed so it survives at 16 px in Finder lists and 18 pt in the menu bar.

| Member | Background | Accent | Why |
| --- | --- | --- | --- |
| sView | deep blue `#1e5eff` to `#1740b8` | an open viewfinder frame around the s (four thin corner brackets) | the viewport, looking |
| sNotate | amber `#ff9f1a` to `#d97a00` | a filled dot with a white `1` at the s's lower terminal | the step counter, the one annotation that defines the app |
| sCapture | green `#1fbf75` to `#15895a` | a reticle (thin circle with four ticks) in deep green `#0b5c3a`, centred on the s's upper terminal | aiming, the shutter |
| sWalk | violet `#8b5cf6` to `#6d28d9` | a white dot with a violet play triangle, bottom right of the s, ringed in violet like sNotate's dot | playback of a walk |
| scommon | slate `#64748b` to `#475569` | thin `{ }` either side of the s, the weight of sView's brackets | shared code, not an app |
| uSuite (the organization) | graphite `#2b2f36` to `#1b1e23` | three dots in a row under the s, in sView blue, sNotate amber and sCapture green | the family; the Dots of the evidence chain |

The three app hues sit roughly 120 degrees apart so the Dock icons are distinguishable at a glance; sWalk's violet sits between blue and amber on the far side, and scommon and uSuite are neutral because neither is an app in the Dock and the menu bar icon of sCapture reads as part of the set. A lower-saturation variant of each colour is the accent colour inside the app (selection, counters, toasts), so the icon and the UI agree.

If the Dots idea should show, the accent is the place: each app's dot (viewfinder, counter, reticle) is one Dot, and the three together connect into the evidence chain. Nothing more literal than that.

## macOS 26 icon production

macOS 26 renders app icons as layered Liquid Glass inside the system's enclosure shape; the layers come from Icon Composer, which ships with Xcode 26 and writes a single `.icon` file that Xcode consumes directly. The pipeline for the family is therefore plain text first, tool second:

- `brand/s.svg`: the shared s path on a 1024 canvas, one file, hand-editable, the only source of the glyph.
- `brand/<app>-background.svg`, `brand/<app>-accent.svg`: per app, the gradient background and the accent, both on the same 1024 canvas, no raster.
- `brand/<app>.icon`: the Icon Composer document that imports those three SVG layers and carries the per-layer glass settings (specular, translucency, shadow) and the Default, Dark and Mono appearances. It is committed, since it is the thing Xcode reads; the SVGs are committed because they are the thing a human edits.
- `make icon` regenerates the flattened 1024 PNG for the README and the Homebrew cask from the `.icon`, so no marketing image is hand-exported.

The sCapture reticle is the one accent that is not white: a white reticle needed an outline to stand out over the white s, and the outline cut the s apart, so it is deep green.

Rules for the layers: the s and the accent are flat shapes with no baked gradients or shadows (the glass adds depth, and a baked shadow would double it); the background is the only gradient; nothing important sits in the outer 10 percent of the canvas, because the enclosure clips and the glass bevel softens the edge. Dark appearance keeps the s white and darkens the background one step; Mono is left to the system.

Because the floor is macOS 26 there is no legacy `.icns` or multi-size PNG set to maintain; if Xcode wants a fallback asset catalog entry, it generates it from the `.icon`.

## Files in this folder

`s.svg` is the source of the glyph for every member; each app repository keeps a copy in its own `brand/`. The backgrounds and accents of sWalk, scommon and uSuite live here, sView's and sNotate's in their repositories, sCapture's in its repository. `render.swift <background.svg> <accent.svg> <out.png> [--full-bleed] [--size N]` draws one icon in the classic tile, or filling the square with `--full-bleed` for the organization avatar; the apps keep their own `make icon`. Rendered: `usuite-avatar-1024.png` (full bleed, the organization avatar), `scommon-1024.png`, `swalk-1024.png`, and `family-row.png` with the five tiles in the order sView, sNotate, sCapture, sWalk, scommon for the organization's profile page.

## Menu bar icon (sCapture only)

A template image (monochrome, alpha only) at 18 x 18 pt with 2x: the s with the reticle, strokes thickened so they survive at that size. Template images take the menu bar's tint automatically in light, dark and tinted appearances, so one asset is enough. The case id and count are text next to it, set by the system font; the icon never tries to carry information.

## Document and file icons

None in v1. `<case-id>.snotate.json` is a JSON file and shows as one; a custom document icon would need a UTI declaration and a second artwork for little gain. Revisit if the sidecar ever gets its own extension.

## Sources

- [Icon Composer](https://developer.apple.com/icon-composer/)
- [Human Interface Guidelines: App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons/)
