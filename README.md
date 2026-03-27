# 植小保 · TL-PestIdentify

> lgf 和 小wt 的第一个 iOS 小项目

一款基于 AI 的农业病虫害识别 App，帮助用户拍照识别植物病虫害，提供社区交流和 AI 助手功能。

---

## 功能模块

| 模块 | 说明 |
|------|------|
| 登录注册 | 短信验证码登录、密码登录、微信绑定、偏好引导 |
| 首页 | 病虫害资讯卡片流 |
| 拍照识别 | 调用 AI SDK 识别病虫害，查看识别记录 |
| 社区 | 发帖、评论、点赞、收藏 |
| 发布 | 多图选择 + 裁剪发布帖子 |
| AI 助手 | 多轮对话式 AI 助手，支持图片输入 |
| 我的 | 头像更换、昵称编辑、个人资料、设置 |

---

## 技术栈

- **语言**: Objective-C
- **最低系统**: iOS 12.0
- **UI**: 纯代码布局（Masonry），无 Storyboard
- **依赖管理**: CocoaPods

### 主要依赖

| Pod | 用途 |
|-----|------|
| AFNetworking 4.0.1 | HTTP 网络请求 |
| YYModel 1.0.4 | JSON 解析 |
| WCDB.objc (master) | 本地 SQLite 数据库 |
| Masonry 1.1.0 | AutoLayout DSL |
| SDWebImage ~5.0 | 异步图片加载 |
| AgriPestClient v1.0.92 | AI 病虫害识别 SDK |
| LookinServer 1.2.8 | UI 调试（仅 Debug）|

---

## 快速开始

```bash
# 1. 安装依赖
cd TL-PestIdentify && pod install

# 2. 打开工作区（注意不要直接打开 .xcodeproj）
open TL-PestIdentify.xcworkspace
```

然后在 Xcode 中选择目标设备，Command + R 运行。

---

## 后端

- **仓库**: https://github.com/lukecc00/AgroAiServer
- **服务器**: 115.191.67.35（Docker 部署）

---

*植小保 — 让每一位农人都有随身的植保专家*
