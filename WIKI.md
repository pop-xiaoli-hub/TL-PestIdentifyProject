# 植小保 · 慧眼识虫 — 项目 Wiki

> iOS 病虫害识别 App，国创赛项目。开发者：lgf & 小wt（吴桐）

---

## 一、产品定位

面向农业生产者的 AI 病虫害识别工具。用户拍照上传，AI 自动识别病虫种类并给出防治建议，同时整合天气预警、知识库、社区交流等功能，构成"从识别到解决"的完整服务闭环。

---

## 二、核心功能

| 模块 | 功能概述 |
|------|---------|
| **拍照识别** | 首页一键拍照 / 上传，AI 识别病虫，输出病害名称 + 防治方案 |
| **预警推送** | 系统结合当地实时气象，主动推送当季病虫害预警信息 |
| **知识库** | 按作物分类的病虫害百科，支持检索，记录用户查询历史 |
| **社区** | 农户发帖交流经验，AI 辅助答疑，专家在线服务入口 |
| **消息中心** | 汇聚预警通知、社区互动、专家回复等消息，精准推送 |
| **用户中心** | 个人档案、收藏帖子、一键求助；支持适老化大字模式 |

---

## 三、用户流程

```
启动
 └─ 登录页（手机号 + 验证码 / 微信一键登录）
      └─ 微信绑定页（首次微信登录时）
           └─ 引导页（询问是否开启适老化模式）
                └─ 偏好设置页（选择关注的农作物）
                     └─ 主界面（TabBar 四 Tab）
                          ├─ 首页     ← 预警卡片 + 拍照入口
                          ├─ 社区     ← 占位，待开发
                          ├─ 消息     ← 占位，待开发
                          └─ 我的     ← 占位，待开发
```

---

## 四、当前代码结构

```
TL-PestIdentify/
├── TL-PestIdentify/          # 入口层
│   ├── AppDelegate / SceneDelegate   # 根 VC 设为 TLWLoginController
│   └── TL-TabBar/            # 自定义胶囊 TabBar（解决 iOS 26 Liquid Glass 问题）
│
├── TL_Login/                 # 登录模块（已实现）
│   ├── login/                # TLWLoginController + TLWLoginView
│   ├── wechat/               # TLWWechatBindController + TLWWechatBindView
│   └── guide/                # TLWGuideController/View（适老化引导）
│                             # TLWPreferenceController/View（作物偏好选择）
│
├── TL_HomePage/              # 首页模块（已实现）
│   ├── TLWHomePageController + TLWHomePageView
│   ├── TLWHomeCardCell       # 预警信息卡片
│   ├── TLWHomeCustomCell     # 自定义列表 Cell
│   └── hp_model/TLWWarningModel   # 预警数据模型
│
└── TL_PhotoIdentify/         # 拍照识别模块（框架已建，逻辑待接入）
    ├── TLWIdentifyPageController
    └── TLWIdentifyPageView
```

---

## 五、技术栈

| 项目 | 说明 |
|------|------|
| 语言 | Objective-C |
| 最低支持 | iOS 12.0 |
| UI 方式 | 纯代码 + Masonry 约束，无 Storyboard |
| 网络 | AFNetworking 4.0 |
| 图片加载 | SDWebImage 5.x |
| 数据模型 | YYModel |
| 本地存储 | WCDB（SQLite） |
| UI 调试 | LookinServer（仅 Debug） |
| 依赖管理 | CocoaPods |

---

## 六、开发进度

- [x] 登录 / 微信绑定 / 引导 / 偏好设置页
- [x] 自定义 TabBar（4 Tab 容器）
- [x] 首页预警列表
- [ ] 拍照识别（页面框架已建，AI 接口待接入）
- [ ] 社区模块
- [ ] 消息中心
- [ ] 用户中心

---

## 七、本地运行

```bash
cd TL-PestIdentify
pod install
open TL-PestIdentify.xcworkspace
```

> 注意：必须打开 `.xcworkspace`，不能直接打开 `.xcodeproj`。
