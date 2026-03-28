# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"植小保" (TL-PestIdentify) — an iOS pest identification app built with Objective-C. Project by lgf and 小wt (xiaoli pop). The app targets iOS 12.0+.

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

## Architecture

Classic MVC with Objective-C. No Storyboard for custom screens — all UI is programmatic via Masonry constraints.

**App entry point:** `SceneDelegate` sets `TLWPasswordLoginController` (wrapped in `UINavigationController`) as `rootViewController`. Login success navigates to the main TabBar.

**UI conventions:**
- All custom screens hide the system nav bar and draw their own nav bar
- Pages with custom nav bars must implement right-swipe-back gesture
- Background style: use `bgGradient` image asset as `UIImageView` background (not `layer.contents`)
- Mock data in ViewControllers for UI preview when backend APIs are not ready

## Module Structure

```
TL-PestIdentify/
├── TL-PestIdentify/          # Core: AppDelegate, SceneDelegate, TabBar
│   └── TL-TabBar/            # TLWTabBar, TLWTabBarItemView
├── TL_Login/                 # Login & onboarding
│   ├── login/                # SMS login, password login
│   ├── wechat/               # WeChat bind
│   └── guide/                # Guide, preference selection, crop
├── TL_HomePage/              # Home feed, card cells
├── TL_PhotoIdentify/         # Photo pest identification
├── TL_Community/             # Community: post list, detail, comments
│   └── cp_icon/              # Community icons
├── TL_Publish/               # Publish post (photo picker, crop)
├── TL_My/                    # Profile page
│   ├── Avatar/               # TLWPhotoPickerController, TLWAvatarCropController
│   ├── EditProfile/          # TLWEditProfileController/View
│   ├── EditNickname/         # TLWEditNicknameController/View
│   └── Setting/              # TLWSettingViewController/View
├── TL_Record/                # Identification records list
├── TL_RecordDetail/          # Record detail page
├── TL_AiAssisstant/          # AI chat assistant
├── TL_Message/               # Messages/notifications
├── TL_Notification/          # Notification module
└── TL_Common/                # Shared utilities
    ├── Network/              # TLWSDKManager (API calls)
    ├── TLWImagePickerManager # Photo picker manager
    ├── TLWPhotoCell          # Shared photo cell
    ├── TLWCameraManager      # Camera access
    └── TWLSpeechManager      # Speech input
```

## Dependencies (CocoaPods)

| Pod | Version | Purpose |
|-----|---------|---------|
| AFNetworking | 4.0.1 | HTTP networking |
| YYModel | 1.0.4 | JSON model mapping |
| WCDB.objc | master (git) | Local SQLite database |
| Masonry | 1.1.0 | Autolayout DSL |
| SDWebImage | ~5.0 | Async image loading |
| AgriPestClient | v1.0.92 (git tag) | AI pest identification SDK |
| LookinServer | 1.2.8 | UI inspector (Debug only) |

> WCDB.objc 使用 git master 源：`https://github.com/Tencent/wcdb.git`

## Backend

- **后端代码仓库**: https://github.com/lukecc00/AgroAiServer (master 分支)
- **服务端 IP**: 115.191.67.35
- **部署方式**: Docker
- **查看后端更新**: `gh api 'repos/lukecc00/AgroAiServer/commits?sha=master&per_page=20' --jq '.[] | "\(.commit.author.date) | \(.commit.author.name) | \(.commit.message)"'`
