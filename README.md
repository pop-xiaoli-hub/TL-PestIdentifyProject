# 植小保 · TL-PestIdentify

> lgf 和 小wt 的第一个 iOS 小项目

一款基于 AI 的农业病虫害识别 App，帮助用户拍照识别植物病虫害，提供社区交流和 AI 助手功能。

---

## 功能介绍

### 登录与引导
- 短信验证码登录 / 密码登录
- 微信账号绑定
- 新用户偏好设置引导（作物类型选择）

### 首页
- 病虫害资讯卡片流展示
- 支持自定义瀑布流布局

### 拍照识别
- 相机实时预览、闪光灯切换、拍照 / 相册选图
- 调用 AgriPestClient AI SDK（/chat/profile）识别病虫害
- 识别结果写入本地 WCDB 数据库
- 识别记录列表（按日期分组，支持日期筛选）
- 识别结果详情：多候选结果 Tab 切换、病害名 + 置信度 + 防治建议
- 详情页一键跳转 AI 助手并自动发送病害名

### 社区
- 帖子瀑布流列表（自定义 WaterfallLayout）
- 帖子详情页：图文展示、评论、点赞、收藏
- 语音输入评论（TWLSpeechManager）
- 发布帖子：多图选择 + 裁剪

### AI 助手
- 多轮对话式 AI 助手（SSE 流式输出，走 `/api/v1/agent/chat/stream`）
- 自封装 `TLWAIStreamClient`：基于 `NSURLSession` + Data Delegate 逐帧解析 SSE 事件（`meta` / `disease` / `plan_delta` / `plan` / `done` / `error`）
- 支持图片 + 文字混合输入（图片先上传换 URL，再随请求体发送，不走 Base64）
- 消息气泡支持 markdown 渲染：标题加粗、列表转项目符号、**加粗**（iOS 15+，iOS 12-14 自动降级纯文本）
- 增量文本 60ms 节流合并刷新，避免 tableView 抖动
- AI 占位消息"正在思考中..."+ 停止回复（cancel 流 + flush 已累积片段）
- 语音通话模式（SpeechEngineToB SDK）
- 401/403 鉴权失效一次性 refresh + 重建 stream 重试

### 定位
- 定位页展示当前城市、推荐城市、城市字母分组列表
- 点击搜索框跳转独立搜索页（`TLWLocationSearchController`）
- 搜索页自动弹出键盘，实时过滤城市，关键词橙色高亮
- 基于 MKLocalSearch 的本地搜索，结果展示距离和地址
- 点击结果直接选中城市并返回

### 我的
- 编辑资料页（Figma 1:1 还原，独立毛玻璃卡片设计）
- 头像更换（相册选图 + 圆形裁剪）
- 昵称修改
- 换绑手机号（短信验证码校验）
- 修改密码（支持显示自动注册时的原始密码）
- 我的收藏列表（分页加载 + 下拉刷新）
- 设置页：系统通知权限开关、合规页面（隐私政策 / 用户协议，WebView 内展示）

### 登录安全
- 双 Token 机制（accessToken + refreshToken）
- accessToken 过期自动续期，续期失败强制跳回登录页
- 全部 API 接口接入 401/403 自动重试
- SMS 验证码登录自动注册提示

### 通用组件
- 统一 Toast 组件（TLWToast，白色居中 + 半透明遮罩）
- 关键按钮防抖（登录、收藏、提交等）

---

## 导航结构

```
App 启动
└── TLWPasswordLoginController（登录页）
    └── 登录成功
        └── TLWMainTabBarController（主 TabBar）
            ├── Tab 1: TLWHomePageController       首页
            ├── Tab 2: TLWCommunityController       社区
            ├── Tab 3: TLWMessageController         消息
            └── Tab 4: TLWMyController              我的
```

> TabBar 为全自定义胶囊样式（`TLWTabBar`），不使用系统 UITabBar。所有页面均隐藏系统导航栏，使用自定义导航栏 + 右滑返回手势。

---

## 工程结构

```
TL-PestIdentify/
├── TL-PestIdentify/              # 核心壳：AppDelegate、SceneDelegate、TabBar
│   └── TL-TabBar/                # TLWMainTabBarController、TLWTabBar
├── TL_Login/                     # 登录模块
│   ├── login/                    # 短信登录、密码登录
│   ├── wechat/                   # 微信绑定
│   └── guide/                    # 引导页、偏好选择、头像裁剪
├── TL_HomePage/                  # 首页
│   ├── Models/                   # 首页模型
│   └── Resources/Images/         # 首页图片资源
├── TL_PhotoIdentify/             # 拍照识别页
│   └── Resources/Images/         # 识别页图片资源
├── TL_Community/                 # 社区
│   └── Resources/Images/         # 社区图片资源
├── TL_Publish/                   # 发布帖子
├── TL_My/                        # 我的
│   ├── Avatar/                   # 相册选图、头像裁剪
│   ├── EditProfile/              # 编辑资料（Figma 还原）
│   ├── EditNickname/             # 修改昵称
│   ├── ChangePhone/              # 换绑手机号
│   ├── ChangePassword/           # 修改密码
│   ├── Favorite/                 # 我的收藏
│   └── Setting/                  # 设置
├── TL_Record/                    # 识别记录列表
│   └── TL_RecordDetail/          # 识别记录详情
├── TL_AIAssistant/               # AI 助手
├── TL_Message/                   # 消息
│   ├── Controllers/
│   ├── Views/
│   ├── Models/
│   └── Components/
├── TL_Notification/              # 通知
│   ├── Controllers/
│   ├── Views/
│   ├── Models/
│   └── Components/
└── TL_Common/                    # 公共工具
    ├── UI/                       # Toast、PhotoCell 等通用 UI
    ├── Media/                    # 相机、相册、语音
    ├── Network/                  # TLWSDKManager（统一 API 封装）
    └── TLWWCDB/                  # 本地数据库
```

---

## 技术栈

- **语言**: Objective-C
- **最低系统**: iOS 12.0
- **UI**: 纯代码布局（Masonry），无 Storyboard
- **架构**: MVC
- **依赖管理**: CocoaPods

### 依赖列表

| Pod | 版本 | 用途 |
|-----|------|------|
| AFNetworking | 4.0.1 | HTTP 网络请求 |
| YYModel | 1.0.4 | JSON 解析映射 |
| WCDB.objc | master (git) | 本地 SQLite 数据库 |
| Masonry | 1.1.0 | AutoLayout DSL |
| SDWebImage | ~5.0 | 异步图片加载缓存 |
| AgriPestClient | v1.0.109 | AI 病虫害识别 SDK |
| LookinServer | 1.2.8 | UI 层级调试（仅 Debug）|

---

## 快速开始

```bash
# 1. 克隆仓库
git clone https://github.com/pop-xiaoli-hub/TL-PestIdentifyProject.git
cd TL-PestIdentifyProject

# 2. 安装 CocoaPods 依赖（在 TL-PestIdentify 目录下）
cd TL-PestIdentify && pod install

# 3. 打开工作区（必须用 .xcworkspace，不要直接开 .xcodeproj）
open TL-PestIdentify.xcworkspace
```

在 Xcode 中选择目标设备或模拟器，`Command + R` 运行。

---

## 后端

| 项目 | 地址 |
|------|------|
| 后端仓库 | https://github.com/lukecc00/AgroAiServer |
| 服务器 IP | 115.191.67.35 |
| 部署方式 | Docker |

```bash
# 查看后端最新提交
gh api 'repos/lukecc00/AgroAiServer/commits?sha=master&per_page=20' \
  --jq '.[] | "\(.commit.author.date) | \(.commit.author.name) | \(.commit.message)"'
```

---

## TODO

### 待完成功能
- [ ] **发布草稿回显** — 将 draftObject 内容回显到发布页（作物名称、文本、图片）
- [ ] **个人主页背景图** — 背景图选择 + 上传
- [ ] **分享功能** — 我的页面分享按钮

### 待接入第三方 SDK
- [ ] **微信登录** — 微信 SDK 授权后跳转引导页（当前直接跳过）
- [ ] **QQ 登录** — 接入 QQ SDK

### 设置页待实现
- [ ] 关于我们
- [ ] 我要反馈
- [ ] 系统权限管理

---

*植小保 — 让每一位农人都有随身的植保专家*
