<img src="assets/icon.svg" width="64" height="64" alt="">

# What's My Colour

A small native macOS color picker. Requires macOS 14 or newer.

## Run

```sh
./scripts/build-app.sh
open "dist/What's My Colour.app"
```

Click **Start live** (⌘⇧P), then move the pointer over the desktop or any app. The main window stays on top and updates its swatch and hex value continuously. A crosshair marks the sample location, with a pixel magnifier and hex label beside the pointer. The overlay lets clicks pass through and disappears when sampling is frozen. Keep this app active and press **⌘C** to copy the current uppercase `#RRGGBB` value. Press **⌘⇧P** again to freeze or resume the color. Hex values are converted to sRGB.

Live sampling requires macOS **Screen Recording** permission. Enable What's My Colour in **System Settings → Privacy & Security → Screen Recording** (called **Screen & System Audio Recording** on some macOS versions). Relaunch the app if macOS requests it, then click Start live again. Screen pixels are processed locally and never saved or transmitted.

Keyboard shortcuts work while What's My Colour is active. Moving the pointer over another app does not change keyboard focus; clicking that app does.

## Develop

```sh
swift run
swift test
```

Build output is a locally signed app in `dist/`; drag it to Applications if desired.
