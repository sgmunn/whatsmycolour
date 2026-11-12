<img src="assets/icon.svg" width="64" height="64" alt="">

# What's My Colour

A small native macOS color picker. Requires macOS 14 or newer.

## Run

```sh
./scripts/build-app.sh
open "dist/What's My Colour.app"
```

Click **Pick color** (⌘⇧P) to open the system magnifying eyedropper. Move over the desktop or any app, then click a pixel to select it. Press **⌘C** to copy its uppercase `#RRGGBB` value. Escape cancels picking and keeps the previous color. Hex values are converted to sRGB.

The picker uses macOS's system color sampler. Cmd+C copies the selected color while this app is active; select the pixel before copying.

## Develop

```sh
swift run
swift test
```

Build output is a locally signed app in `dist/`; drag it to Applications if desired.
