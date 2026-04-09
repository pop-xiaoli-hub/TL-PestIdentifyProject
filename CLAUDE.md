# CLAUDE.md

本文件是这个仓库的长期记忆文档。后续无论是我还是别的 AI/协作助手进入这个项目，都应优先阅读这份文件，而不是每次从头翻完整个工程。

## 一、项目概览

- 项目名称：`植小保 / TL-PestIdentify`
- 项目类型：iOS 农业病虫害识别 App
- 核心能力：病虫害识别、社区交流、消息通知、AI 助手、个人中心
- 开发语言：Objective-C
- 最低系统版本：`iOS 12.0`
- 依赖管理：CocoaPods
- UI 形式：以纯代码布局为主，广泛使用 Masonry
- 架构风格：传统 MVC，按功能模块拆分目录
- 核心后端 SDK：`AgriPestClient`

## 二、项目当前真实状态

这份工程的真实完成度，比旧的 `WIKI.md` 里写的要高。

目前已经有较完整实现的模块：

- 账号密码登录
- 短信验证码登录
- 微信绑定页壳子
- 新手引导与适老化选择流程
- 自定义主 TabBar 容器
- 首页
- 社区流、帖子详情、评论、发帖流程
- 消息页
- 通知页及分类筛选
- 我的页面
- 编辑资料、修改昵称、头像上传裁剪
- 换绑手机号
- 修改密码
- 我的收藏

目前仍然明显处于半成品 / 占位状态的部分：

- 拍照识别接口还没有真正接通
- AI 助手图片上传 / 对话接口还没有真正接通
- 识别记录列表与详情仍然使用 mock 数据
- 设置页下的二级功能大多还是 TODO
- 分享功能还没做
- QQ 登录 / 真正的微信授权登录还没接完

## 三、运行与构建

始终使用 workspace，不要直接打开 `.xcodeproj`。

```bash
cd TL-PestIdentify
pod install
open TL-PestIdentify.xcworkspace
```

命令行构建示例：

```bash
xcodebuild -workspace TL-PestIdentify/TL-PestIdentify.xcworkspace \
  -scheme TL-PestIdentify \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

## 四、依赖说明

依据 `TL-PestIdentify/Podfile` 与 `Podfile.lock`，当前主要依赖如下：

- `LookinServer`：仅 Debug 使用
- `YYModel`
- `AgriPestClient`：git tag 为 `v1.0.106`
- `WCDB.objc`：来自腾讯仓库 `master`
- `Masonry`
- `SDWebImage ~> 5.0`

额外注意：

- `Podfile` 里包含针对 Xcode 26 的兼容修复，主要处理 AFNetworking 相关的 non-modular header 问题
- 这个项目必须使用 `.xcworkspace`

## 五、应用入口与导航结构

应用入口：

- `TL-PestIdentify/TL-PestIdentify/SceneDelegate.m`

当前启动逻辑：

- 根控制器是 `TLWPasswordLoginController`
- 外层包了一层隐藏导航栏的 `UINavigationController`

登录后的路由逻辑主要在：

- `TL-PestIdentify/TL_Login/login/TLWPasswordLoginController.m`

登录成功后流程：

- 先通过 `TLWSDKManager` 保存登录态
- 再拉取用户资料（失败时自动重试 3 次，每次间隔 3 秒，不再直接登出）
- 如果用户已经做过适老化选择，并且已经设置关注作物，则直接进入主 Tab
- 如果已做适老化选择，但还没选关注作物，则进入 `TLWPreferenceController`
- 如果连适老化选择都还没做，则进入 `TLWGuideController`

主容器在：

- `TL-PestIdentify/TL-PestIdentify/TL-TabBar/TLWMainTabBarController.m`

主 Tab 目前为四个：

- 首页：`TLWHomePageController`
- 社区：`TLWCommunityController`
- 消息：`TLWMessageController`
- 我的：`TLWMyController`

关于 TabBar 的重要说明：

- 这是一个完全自定义的胶囊式 TabBar
- 它不是系统 `UITabBar` 的换皮，而是作为普通子视图直接加到页面上
- 这样做的原因，是为了规避 iOS 26 上系统 TabBar 被强行加上 Liquid Glass 效果的问题

## 六、代码层面的通用约定

- 大多数页面都会隐藏系统导航栏，自绘顶部导航区域
- 很多页面会在 `viewWillAppear` 中手动恢复右滑返回手势
- 页面通常拆成 `Controller + View` 两层，旁边再放 Cell、Model 等配套类
- Masonry 是主要布局方式
- 目录是按业务模块组织的，而不是按 MVC 类型全局分组
- 一些控制器已经提前把“对外方法签名”固定好了，即便内部还是 mock 数据，后面接接口时也应尽量保持调用方式不变

## 七、网络层与登录鉴权

全局网络与登录状态管理核心类：

- `TL-PestIdentify/TL_Common/Network/TLWSDKManager.h`
- `TL-PestIdentify/TL_Common/Network/TLWSDKManager.m`

它当前承担的职责包括：

- 配置 `AGDefaultConfiguration`
- 设置后端 host 为 `http://115.191.67.35:8080`
- 将登录态持久化到 `NSUserDefaults`
- 缓存用户资料
- 缓存收藏帖子
- 封装若干常用接口调用
- 统一处理 token 续期与 401 重试

当前本地存储的关键字段：

- `TLW_access_token`
- `TLW_refresh_token`
- `TLW_user_id`
- `TLW_username`
- `TLW_generated_password`

当前鉴权机制：

- 使用双 token：`accessToken + refreshToken`
- 各业务页面发现接口返回 `401` 时，通常会调用 `handleUnauthorizedWithRetry:`
- `TLWSDKManager` 内部用 `isRefreshing` 和一个重试 block 队列，避免并发多个 401 时重复刷新 token
- 如果 refresh 失败，会清空本地登录态并跳回登录页

后续开发建议：

- 新增需要鉴权的接口时，尽量沿用现有 `401 -> handleUnauthorizedWithRetry:` 的处理方式
- 不要在页面里各自重新发明一套 token 续期逻辑

## 八、全局通知

当前项目内比较重要的通知有：

- `TLWProfileDidUpdateNotification`
- `TLWAvatarDidUpdateNotification`

这些通知主要用于在首页、我的、编辑资料页之间同步用户资料和头像变化。

## 九、模块结构与现状

### 1. 登录与引导

目录：

- `TL-PestIdentify/TL_Login`

关键文件：

- `login/TLWPasswordLoginController.m`
- `login/TLWSmsLoginController.m`
- `wechat/TLWWechatBindController.m`
- `guide/TLWGuideController.m`
- `guide/TLWPreferenceController.m`

现状说明：

- 账号密码登录是真实接接口的
- 短信登录也已经接通，并带有自动注册提示逻辑
- 适老化选择会写入 `NSUserDefaults`
- 微信/QQ 登录目前还只是占位或半接入状态

### 2. 首页

目录：

- `TL-PestIdentify/TL_HomePage`

关键文件：

- `TLWHomePageController.m`

当前行为：

- 会读取缓存用户信息，展示头像和昵称
- 第 0 行是可展开的预警/提示卡片
- 第 1 行是功能入口卡片，跳拍照识别、识别记录和 AI 助手
- 后面的自定义内容区目前更偏静态展示

当前数据状态：

- 首页预警内容目前还是硬编码 / mock 风格的数据

### 3. 拍照识别

目录：

- `TL-PestIdentify/TL_PhotoIdentify`

关键文件：

- `TLWIdentifyPageController.m`

已经完成的部分：

- 相机权限申请
- 相机预览
- 闪光灯切换
- 拍照
- 从相册选图
- 跳转识别记录页

还没完成的部分：

- 真正的识别接口调用
- 识别结果页与真实后端返回的打通

当前状态判断：

- `tl_identifyFromAI` 现在只会显示 loading，并在代码里留了 `POST /api/identify` 的 TODO

### 4. 识别记录

目录：

- `TL-PestIdentify/TL_Record`
- `TL-PestIdentify/TL_RecordDetail`

关键文件：

- `TLWRecordController.m`

当前状态：

- 页面结构和跳转都已经有了
- 数据目前是按日期分组的本地 mock 数据
- 筛选按钮还是 TODO
- “记录详情跳 AI 助手并预填病害名” 还是 TODO

### 5. 社区

目录：

- `TL-PestIdentify/TL_Community`
- `TL-PestIdentify/TL_Publish`

关键文件：

- `TLWCommunityController.m`
- `TLWPostDetailController.m`
- `TLWPublishController.m`
- `TLWCommunityWaterfallLayout.m`

已经完成的部分：

- 帖子流分页拉取
- 瀑布流布局
- 帖子详情
- 评论列表与发表评论
- 发布入口
- 语音输入弹层
- 本地刚发布内容与远端列表合并显示的处理

需要特别注意的实现细节：

- 社区流会递归拉取多页帖子
- 在刷新过程中，会尽量保留本地刚发布但还未完全同步的帖子
- Cell 高度目前使用的是人工设定的图片比例，不是真实远端图片宽高比

还没彻底收尾的地方：

- 发布页草稿回显相关逻辑还有 TODO

### 6. 消息与通知

目录：

- `TL-PestIdentify/TL_Message`
- `TL-PestIdentify/TL_Notification`

关键文件：

- `TLWMessageController.m`
- `TLWNotificationController.m`

已经完成的部分：

- 消息总览页
- 系统消息 / 通知 / 评论互动分类组织
- 未读状态展示
- 标记已读
- 通知页 tab 筛选
- 从评论互动跳帖子详情

补充说明：

- 消息页仍然是“静态骨架 + 动态服务端数据”混合结构
- 通知页的完成度比旧文档描述得更高

### 7. AI 助手

目录：

- `TL-PestIdentify/TL_AIAssistant`

关键文件：

- `TLWAIAssistantController.m`
- `TLWAICallController.h` / `TLWAICallController.m`
- `Views/TLWAIAssistantView.h` / `.m`
- `Views/TLWAIAssistantComposerView.h` / `.m`
- `Views/Cells/TLWAIAssistantMessageCell.m`

已经完成的部分：

- 多轮对话（已接入 AgriPestClient chatProfile SDK）
- 文字 + 单图混合输入（图片压缩后 Base64 编码）
- AI 占位消息"正在思考中..."+ 实时回显
- Plus 面板（相机 / 相册 / AI 通话三入口，与键盘和语音面板互斥）
- 停止按钮：AI 回复过程中可手动中断
- AI 加载态交互（隐藏 mic，plus 左移，显示 stop）
- 语音面板与长按语音输入交互
- 多图预览
- 401 token 过期自动续期重试
- AI 通话页面（TLWAICallController，壳子）

还没完成的部分：

- AI 通话页面的真实语音通话功能接入

### 8. 我的 / 个人中心

目录：

- `TL-PestIdentify/TL_My`

关键文件：

- `TLWMyController.m`
- `EditProfile/TLWEditProfileController.m`
- `EditNickname/TLWEditNicknameController.m`
- `ChangePhone/TLWChangePhoneController.m`
- `ChangePassword/TLWChangePasswordController.m`
- `Favorite/TLWMyFavoriteController.m`
- `Setting/TLWSettingViewController.m`

已经完成的部分：

- 基于缓存资料渲染用户信息
- 头像乐观更新、上传、再同步资料
- 修改昵称
- 换绑手机号
- 修改密码
- 收藏列表
- 退出登录

还缺的部分：

- 分享按钮逻辑
- 设置页里关于我们、反馈、权限、协议、隐私等页面仍是 TODO

## 十、公共工具层

目录：

- `TL-PestIdentify/TL_Common`

关键公共类：

- `TLWSDKManager`：网络、登录态、缓存
- `TLWImagePickerManager`：统一相机 / 相册图片选择
- `TLWCameraManager`：相机能力封装
- `TLWToast`：全局 Toast
- `TWLSpeechManager`：语音识别封装
- `TLWPhotoCell`：通用图片 Cell

## 十一、当前最值得优先关注的 TODO

当前代码里最值得优先推进的空缺点：

- `TLWIdentifyPageController.m`：接通真实识别接口
- `TLWAICallController.m`：AI 通话页面接入真实语音通话功能
- `TLWRecordDetailController.m`：支持跳 AI 助手并预填当前病害名
- `TLWPublishController.m`：发布草稿回显
- `TLWSettingViewController.m`：设置页二级页面
- `TLWMyController.m`：分享逻辑
- `TLWSmsLoginController.m` / `TLWWechatBindController.m`：QQ / 微信 SDK 集成

## 十二、后续进入项目时的推荐阅读顺序

如果只是想快速进入状态，推荐按这个顺序读：

1. `README.md`
2. `TL-PestIdentify/TL_Common/Network/TLWSDKManager.h`
3. `TL-PestIdentify/TL_Common/Network/TLWSDKManager.m`
4. `TL-PestIdentify/TL-PestIdentify/SceneDelegate.m`
5. `TL-PestIdentify/TL-PestIdentify/TL-TabBar/TLWMainTabBarController.m`
6. 当前要修改的目标功能控制器

## 十三、协作与修改建议

- 优先在现有控制器和现有 View 结构上改，不要轻易额外引入新架构层
- 需要鉴权的新接口，尽量接入 `TLWSDKManager` 的既有模式
- 旧文档只能当参考，代码才是最终事实来源
- 当前工作区本身就是 dirty 的，特别是消息、通知、网络相关文件已经有本地改动，修改前要先留意
- 仓库根目录下的 `fork_sdk/` 与 `fork_test/` 不是主 App target 的核心业务目录，更多是辅助或实验性质内容

## 十四、后端参考

- 后端仓库：[AgroAiServer](https://github.com/lukecc00/AgroAiServer)
- 当前客户端里写死的服务地址：`http://115.191.67.35:8080`
- 文档中记录的部署方式：Docker

## 十五、一句话总结

这已经不是一个纯演示级别的小壳工程了，而是一个中等规模的 Objective-C iOS 项目：

- 有自定义主壳和导航结构
- 有集中式登录鉴权与网络层
- 有多个已经接近可用的业务模块
- 也有几条还停留在 mock / TODO 阶段的主链路

以后再进入这个仓库，优先从 `TLWSDKManager` 和目标业务控制器入手，不要再完全依赖旧的 `WIKI.md`。
