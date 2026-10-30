# 植小保 · TL-PestIdentify

> lgf 和 小wt 的第一个 iOS 小项目

一款基于 AI 的农业病虫害识别 App，帮助用户拍照识别植物病虫害，提供社区交流和 AI 助手功能。

> 本文维护产品概览、运行操作与验证边界。详细工作区审阅、交接笔记和历史材料不随源码发布；开发与协作流程见 [CONTRIBUTING.md](./CONTRIBUTING.md)。
---

## 功能介绍

### 登录与引导
- 短信验证码登录 / 密码登录
- 微信绑定页面占位（正式登录页无真实微信授权 SDK 接入）
- 新用户偏好设置引导（适老模式、作物类型选择）

### 首页
- 首页当前是 `UITableView`：预警、识别/记录/AI 功能卡、创建作物卡和作物管理卡；不是资讯瀑布流

### 拍照识别
- 相机实时预览、闪光灯切换、拍照 / 相册选图
- 云端主识别：图片压缩并上传 URL 后调用 AgriPestClient `/chat`
- 本地 Core ML 兜底：Vision 三种 crop 策略聚合，云端失败或结果无效时使用
- WCDB 中存在识别记录表和 CRUD API；当前未发现识别页面或记录页面实际写入该表，记录页读取远端 history
- 识别结果详情：病害名、置信度和防治方案；“依据”字段的实际展示未由当前结果 View 确认
- 详情页一键跳转 AI 助手并自动发送病害名

### 社区
- 社区为自定义单/双列瀑布流，包含分页、结构更新、封面加载/预取、详情回刷与确认后发布。布局、数据、图片是独立链路；尚无 postId 去重，Cell 复用未显式取消远图，预取无引用计数，不宣称无错图或已量化性能提升
- 帖子详情页：图文展示、评论、点赞、收藏
- 语音搜索（Apple Speech），不是评论输入
- 发布页负责图片上传与创建帖子；收到业务成功及有效服务端帖子 ID 后，才通过 `onPublished` 更新列表和提示成功。请求中禁用重复发布；上传或业务失败保留当前页面输入。提交后断网/超时会提示先核实“我的发布”，不会自动重复提交；这不是持久草稿功能

### AI 助手
- 支持文字与单图 URL 问诊、原生增量 Markdown、停止与部分回复保留；正式会话按用户本地保存，并附带有预算的历史上下文
- Markdown 展示分离 Turn 有界语法暂存与 BodyView 唯一分块解析；稳定块复用，变化段落生成富文本后计算文字/属性 Render Patch，通过 NSTextStorage 更新已有 UITextView，并按整行实测高度变化合并提交布局。仍会重算变化长段落，不宣称字符级单次解析或已量化提速
- 文字流、Apple Speech 输入和 Dialog 实时通话是不同链路，生命周期和异常处理不能相互替代
- 客户端显式 job 恢复已实现，正式新问诊仍使用旧流，共享后端尚未接入；「重新生成」与「继续接收」不同
- 输入、传输、解析、状态、展示和存储分层实现；正式旧流不自动重发 POST，客户端恢复能力不代表共享后端已部署对应协议

### 定位
- 定位页展示当前城市、推荐城市、城市字母分组列表
- 点击搜索框跳转独立搜索页（`TLWLocationSearchController`）
- 搜索页以约 250ms debounce 调用 MapKit 的 `MKLocalSearch`，结果展示距离和地址；不是本地城市数组的实时过滤
- 点击结果直接选中城市并返回；手动选择的城市名与最近系统定位坐标目前可能不一致，天气仍使用最近系统坐标

### 我的
- 编辑资料页（Figma 1:1 还原，独立毛玻璃卡片设计）
- 头像更换（相册选图 + 圆形裁剪）
- 昵称修改
- 换绑手机号（页面有验证码输入框和发送方法，但输入框隐藏且禁用；确认请求只提交新手机号，不校验验证码）
- 修改密码（当前不展示自动注册原始密码；`generatedPassword` getter 未形成可用链路）
- 我的收藏列表（分页加载 + 下拉刷新）
- 设置页：系统通知权限开关、合规页面（隐私政策 / 用户协议，WebView 内展示）

### 登录安全
- 双 Token 与身份采用单条 Keychain 记录保存，具备并发 refresh 排队及按用户数据库切换；单记录原子保存不等于全系统跨存储事务
- 单记录保存失败不发布新会话；旧凭据迁移、并发刷新及调用者重试仍有边界，不能将局部接口的一次重试扩大为全站账号隔离保障
- 当前不具备完整第三方登录/运营商一键认证；不能将某个接口的鉴权重试描述成全站自动覆盖

### 通用组件
- 统一 Toast 组件（TLWToast，白色居中 + 半透明遮罩）
- 部分关键按钮在请求期间禁用或由业务状态防重；当前没有统一的全站防抖组件

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

> TabBar 由自定义 `UIViewController` 容器手动管理四个 `UINavigationController`；`TLWTabBar` 作为子视图嵌入，虽是 `UITabBar` 子类，但不使用 `UITabBarController` 的系统 Tab 管理逻辑。所有页面均隐藏系统导航栏，使用自定义导航栏 + 右滑返回手势。

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

- **语言**: Objective-C（少量 `.mm` 用于 WCDB/C++）
- **最低系统**: iOS 15.0（以当前 Podfile、target 和 post_install 为准）
- **UI**: 纯代码布局（Masonry）；实际页面由代码构造，SceneDelegate 显式设置 root
- **架构**: MVC；AI 助手由 Controller 编排，Session/Store/Persistence 管会话，Turn 管一轮生命周期，StreamClient/Parser 管传输，FramePacer/IncrementalMarkdown/原生块视图管展示
- **依赖管理**: CocoaPods

### 依赖列表（以当前 Podfile / Podfile.lock 为准）

| Pod | 版本/来源 | 用途 |
|-----|------|------|
| AFNetworking | 3.2.1（AgriPestClient 间接依赖） | HTTP 网络请求 |
| YYModel | 1.0.4 | JSON 解析映射 |
| WCDB.objc | 2.1.16，git master 锁定 commit | 本地 SQLite 数据库 |
| Masonry | Podfile 未固定小版本 | AutoLayout DSL |
| SDWebImage | 5.21.7（`~> 5.0`） | 异步图片加载缓存 |
| AgriPestClient | git tag `v1.0.110` | 后端 OpenAPI 生成 SDK |
| SpeechEngineToB | `0.0.14.2-bugfix` | AI 通话/Dialog 语音 |
| LookinServer | Debug only | UI 层级调试 |

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

### 后台不可用时：本地 SSE 流式验收

仅 Debug 显式启用，不修改 SDK 全局后端地址。客户端仍走真实 `NSURLSession → SSE parser → turn → 增量刷新 → 聊天页面`，不是直接向气泡塞文字。

测试服务不会随 Xcode 的 Run 自动启动。先在仓库根目录单独运行（Python 3.9+，无第三方依赖；本机防火墙已允许 `/usr/bin/python3` 入站）：

```bash
/usr/bin/python3 -u scripts/ai_sse_server.py --host 0.0.0.0 --port 8765 --scenario normal --speed slow
```

`0.0.0.0:8765` 用于允许可信局域网内的真机访问；只在可信网络运行，不把端口暴露到公网。服务不记录提问、请求头或凭据；若误收到 Authorization/Cookie 会拒绝请求，绝不回显值。

Xcode 选择共享 Scheme **`TL-PestIdentify-LocalSSE`**（不是普通 `TL-PestIdentify`），目标选真机后直接 Run。该 Scheme 已固定：

| 名称 | 值 |
| --- | --- |
| `TLW_AI_STREAM_TEST_URL` | `http://192.168.1.61:8765/api/v1/agent/chat/stream` |

这是当前 Mac Wi-Fi 地址。换网络后用 `ipconfig getifaddr en0` 核对，并在该 Scheme 的 Run 环境变量里更新；**真机不能用 `127.0.0.1` 指代 Mac**。普通 Scheme 与 Release 不带这个变量，仍走真实后台。

重新运行 Debug App，会直接打开标题带「本地测试」的 AI 助手，不依赖正式登录/启动资料接口；返回会退出测试页到登录导航根页，重新运行可再进入。输入任意非空文字发送。预置六轮本地历史，最后一条可直接预览列表、长代码和表格；每次回答固定，开头即包含 Markdown/emoji 样本，随后有 24 个阅读锚点和长链接。代码、表格是真实原生横向容器，不是管道字符排版。正常完整回复只出现一次 `TLW_STREAM_END_2026`；手动提前完成、错误和 EOF 不要求出现尾标。

在运行服务的同一个终端输入命令并回车：

| 命令 | 行为 |
| --- | --- |
| `pause` / `resume` | 暂停/继续正文；暂停期间每 0.5 秒发注释心跳，不等于模拟网络空闲超时 |
| `done` | 立即用**已发送正文**形成最终快照，再发送完成事件 |
| `error` | 保留已发正文，再发送本地模拟错误 |
| `disconnect` | 不发 `done`，直接关闭连接，验证未完成 EOF |
| `scenario normal` / `split` / `error` / `eof` / `hold` | 切换**后续请求**剧本；输入时保留 `scenario` 前缀，例如 `scenario split` |
| `speed slow` / `normal` / `fast` | 切换**后续请求**速度，例如 `speed fast` |
| `status` / `quit` | 查看活动流数量 / 关闭服务 |

暂停和终态命令作用于当前所有活动流，不会预先影响下一轮。`split` 使用 CRLF/LF、多事件批量写入，并把 UTF-8 字节切成小块；TCP/URLSession 可以重新合并这些块，一次服务端写入不等于一次接收回调。`error`/`eof` 在部分正文后结束；`hold` 在第 50 个增量后自动暂停，适合手动触发收尾。App 点击停止会取消真实连接，不会自动重发。

验收时用 `slow` 或 `hold`，不要只看快速完整回复：

1. 生成时点击正文收起键盘；输入框、按钮和已有文字选区不被背景收键盘手势拦截。
2. 普通长正文由外层列表纵向滚动，不再出现 240pt 正文视口或固定 300pt 生成行。
3. 灰色识别卡内部先消费纵向位移，到顶/底再接力外层；从卡外拖动不改卡内位置。
4. 代码/宽表格/图片条左右滑动，纵向起手则交给外层；停在历史时新增内容不强行追底。距底超过 24pt 时，输入区上方居中显示回底部箭头；点击后按最后一行的测得高度回到底部，而不是停在估算行高。
5. 拖动期间输入 `done`，检查完成收尾不突然解除限高或重建已闭合块，并保留阅读锚点。
6. 完成后长按选区、复制 emoji/代码、点击链接，检查文本、换行和手势仲裁。
7. 停止后立即发送下一轮、离页后重进，检查旧流不续写、测试消息不恢复。
8. 在内容区右划不退出；从左边缘返回并中途取消，回复仍继续。真正返回后旧流不得继续写入。
9. 真断网/超时或 `disconnect` 后保留部分回复；点「重新生成」产生新任务，旧的部分回复不被覆盖。`pause` 持续发心跳，不能用来证明 8 秒网络静默提示。

隔离边界：本地请求不发送真实 Token/Cookie/共享凭据，不附带定位，不调用正式鉴权刷新、profile 对比或图片上传。选中图片仅用于内存预览，不写正式图片归档；测试回答另附 4 张可横滑图片和可内滚识别卡。生成中已增量渲染 Markdown，完成后开放正文选择。测试会话只在内存。其他业务接口不受这个开关影响。非法/空测试地址直接报错，不回退线上。取消环境变量并重新运行即可恢复正式模式；Release 无法启用该覆盖。

服务回归：`python3 -m unittest discover -s scripts -p 'test_*.py' -v`。本地服务与网络解析验证不代替真机手势、生产鉴权、代理缓冲及上游模型联调。

同一服务也提供本地 `stream-job.v1` fixture。验证客户端同任务恢复时，在 Debug Run 环境中显式将 `TLW_AI_STREAM_TEST_URL` 的路径改为 `/api/v1/agent/jobs`，主机与端口沿用当前可信局域网服务地址；不要改 SDK 生产地址或 Release 开关。启动输出 `JOB_PROTOCOL` 给出端点；`scenario reconnect / duplicate / gap / expired / lost-ack / retry-exhausted` 选择后续 job 的故障剧本，`status` 区分活动订阅与创建任务数。普通 `/chat/stream` 不具备这些 job 语义；Debug 测试会话仍仅在内存，不能用这条路径证明崩溃后正式 WCDB 恢复。
鉴权/资料单测通过 `TLWAuthStatePreservingTestCase` 在内存保存并于正常 tearDown 恢复原有 Defaults、Keychain、SDK 运行时 Token 与共享用户上下文，不记录凭据；2026-10-25 已将新增的 `auth_session` 记录纳入保护。旧版状态恢复回归曾在真机通过，不代表新版单记录迁移已通过真机验收；此前被旧用例删除的凭据无法追回，正式模式仍可能需要重新登录。

验证应分别记录构建、组件测试、本地真实 HTTP/SSE、真机和生产后端结果。仓库提供 `TL-PestIdentify-UnitTests` 与本地 fixture；本地固定回复不证明生产模型、真实上传/鉴权或完整恢复协议可用，历史通过结果也不替代当前版本复验。



---

## 后端

| 项目 | 说明 |
|------|------|
| 后端仓库 | https://github.com/lukecc00/AgroAiServer |
| 后端地址 | 由受控环境配置提供；本仓库文档不记录具体服务器地址 |
| 部署方式 | Docker |

```bash
# 查看后端最新提交
gh api 'repos/lukecc00/AgroAiServer/commits?sha=master&per_page=20' \
  --jq '.[] | "\(.commit.author.date) | \(.commit.author.name) | \(.commit.message)"'
```

---

## 当前状态与待办

### 已明确实现
- [x] 云端主识别 + 本地 Core ML 兜底
- [x] AI 助手 SSE 领域事件解析、客户端注释心跳、增量输出、停止回复、图片 URL 输入
- [x] 社区分页、下拉刷新、超时保护、自定义双列瀑布流、封面预取、真实图片比例、按帖高度缓存
- [x] WCDB 收藏、我的发布按用户隔离；识别记录表和 CRUD 已实现，但当前未发现识别业务页面写入该表
- [x] AI 会话按用户持久化、上下文预算与连接代际隔离；Debug 本地 SSE 测试使用独立内存会话
- [x] 显式 job 协议的客户端恢复、事务检查点及本地 fixture；正式旧流和共享后端尚未切换
### 待改进或未完成
- [ ] **识别页流式化** — 当前主识别路径仍是一次性 `/chat`，可复用 `TLWAIStreamClient` 先展示病害再流式输出方案
- [ ] **SSE 端到端验收** — 既有组件、fixture 和 iPhone 定向单测不等于整套产品验收；当前复杂手势、长文/低电量性能、最后修补后的完整传输场景，以及共享后端 job 联调仍待验证
- [ ] **社区差分数据源** — 当前分页追加使用 batch insert，Diffable Data Source/稳定 ID 合并仍未引入
- [ ] **发布异常场景验收** — 成功提示和列表回调已等待服务端确认；失败保留页面输入、结果未知先核实，仍需真实后端场景验证，不自动重复提交
- [ ] **发布草稿回显** — `tl_applyDraftIfNeeded` 仍为空
- [ ] **发布页图片预览/删除**
- [ ] **个人主页背景图与分享功能** — 分享按钮当前为占位
- [ ] **微信登录 / QQ 登录** — 第三方授权 SDK 尚未接入
- [ ] **推送闭环** — 系统授权与注册调用存在；当前未发现 device token 上报或收到/点击推送的完整处理链路

### 实现与验收边界

AI 助手的状态、协议和展示实现位于 `TL-PestIdentify/TL_AIAssistant/`，回归用例位于 `TL-PestIdentify/TL-PestIdentifyTests/`。社区和登录分别位于 `TL_Community/` 与 `TL_Common/Network/`。以当前源码和可复现运行结果为准，不将规划、客户端协议或本地 fixture 描述成已上线能力。

---

*植小保 — 让每一位农人都有随身的植保专家*
