# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"植小保" (TL-PestIdentify) — an iOS pest identification app built with Objective-C. This is an early-stage project by lgf and 小wt (xiaoli pop). The app targets iOS 12.0+.

## Build & Run

This project uses CocoaPods. Always open the workspace, not the `.xcodeproj`:

```bash
# Install/update pods (run from TL-PestIdentify/)
cd TL-PestIdentify && pod install

# Open the workspace in Xcode
open TL-PestIdentify/TL-PestIdentify.xcworkspace
```

Build and run from Xcode, or via `xcodebuild`:
```bash
xcodebuild -workspace TL-PestIdentify/TL-PestIdentify.xcworkspace \
           -scheme TL-PestIdentify \
           -destination 'platform=iOS Simulator,name=iPhone 16' \
           build
```

Run tests:
```bash
xcodebuild test -workspace TL-PestIdentify/TL-PestIdentify.xcworkspace \
                -scheme TL-PestIdentify \
                -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Architecture

The app uses a classic MVC pattern with Objective-C, no Storyboard for custom screens (programmatic UI via Masonry).

**App entry point:** `SceneDelegate` sets `TWLLoginViewController` as `rootViewController` directly — bypassing `Main.storyboard`'s initial `ViewController`.

**Module structure:**
- `TL-PestIdentify/TL-PestIdentify/` — Core app files (AppDelegate, SceneDelegate, ViewController)
- `TL-PestIdentify/TLWLogin/` — Login module (currently the only feature module)
  - `TWLLoginViewController` — manages login logic and wires up button actions
  - `TWLLoginView` — builds the entire login UI programmatically using Masonry constraints

**Login screen design pattern:** The View (`TWLLoginView`) exposes read-only `UITextField` and `UIButton` properties. The ViewController subscribes to button actions via `addTarget:action:forControlEvents:`. Business logic (API calls) is marked with `// TODO:` stubs.

**Asset usage in TWLLoginView:** Most UI is built natively (CAGradientLayer background, Masonry constraints). Only specific PNG slices from the Figma design are used as `UIImageView` backgrounds:
- `Group 1927.png` — app logo
- `Frame 3.png` — phone number field background (includes the "send code" green capsule button visual)
- `Group 1864.png` — login button (resizable)
- `Vector-4.png` — terms checkbox circle
- `Group 1906.png` — bottom social login icons (QQ, phone, label)
- `Group 1908.png` — WeChat icon overlay

All PNG assets live in `TL-PestIdentify/TLWLogin/病虫害App/`.

## Dependencies (CocoaPods)

| Pod | Version | Purpose |
|-----|---------|---------|
| AFNetworking | 4.0.1 | HTTP networking |
| YYModel | 1.0.4 | JSON model mapping |
| WCDB.objc | 2.1.15 | Local SQLite database |
| Masonry | 1.1.0 | Autolayout DSL |
| SDWebImage | ~5.0 | Async image loading |
| LookinServer | 1.2.8 | UI inspector (Debug only) |

## Backend

- **后端代码仓库**: https://github.com/lukecc00/AgroAiServer (master 分支)
- **服务端 IP**: 115.191.67.35
- **部署方式**: Docker
- **查看后端更新**: `gh api 'repos/lukecc00/AgroAiServer/commits?sha=master&per_page=20' --jq '.[] | "\(.commit.author.date) | \(.commit.author.name) | \(.commit.message)"'`

## Current Branch State

- Branch `feature-login`: Login module (`TLWLogin/`) is newly added and not yet integrated into the Xcode project file. The `TWLLoginViewController` and `TWLLoginView` files exist on disk but need to be added to the `.xcodeproj` to compile.
- `ViewController` (from the original Storyboard template) is unused — the root VC is now `TWLLoginViewController`.
