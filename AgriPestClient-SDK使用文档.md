# AgriPestClient SDK 使用文档

本文档基于你本地工程中实际接入的 `AgriPestClient 1.0.108` 源码整理，源码位置为：

- `/Users/tommywu/Desktop/TL-PestIdentifyProject/TL-PestIdentify/Pods/AgriPestClient/AgriPestClient`

这不是 SDK 自带 README 的转述，而是按真实代码行为整理出来的可用手册。

## 1. 基本信息

- SDK 名称：`AgriPestClient`
- 当前工程版本：`1.0.108`
- 接入方式：CocoaPods Git Tag
- 统一头文件：`#import <AgriPestClient/AgriPestClient.h>`
- 底层网络：`AFNetworking`
- 模型层：`JSONModel`
- 代码生成方式：OpenAPI Generator 自动生成

本地版本依据：

- `/Users/tommywu/Desktop/TL-PestIdentifyProject/TL-PestIdentify/Podfile`
- `/Users/tommywu/Desktop/TL-PestIdentifyProject/TL-PestIdentify/Podfile.lock`
- `/Users/tommywu/Desktop/TL-PestIdentifyProject/TL-PestIdentify/Pods/Local Podspecs/AgriPestClient.podspec.json`
- `/Users/tommywu/Desktop/TL-PestIdentifyProject/TL-PestIdentify/Pods/AgriPestClient/AgriPestClient/AGConfiguration.h`

## 2. SDK 真实结构

SDK 主要由 4 层组成：

1. `AGDefaultConfiguration`
   负责 host、token、默认 header、SSL、debug 等全局配置。

2. `AGApiClient`
   负责真正发 HTTP 请求、拼 query/path/header、附加鉴权头、反序列化响应。

3. `AGApiService`
   所有业务接口的统一入口，登录、帖子、消息、上传、AI、作物、管理员接口都在这里。

4. `AGObject` 及各类 `Request / Response / Result`
   所有请求模型、业务数据模型、统一返回包装都在这里。

## 3. 正确初始化方式

SDK 自带 README 里的初始化示例已经过时。你本地这版真实可用的方式是 `AGDefaultConfiguration`，不是 README 里写的 `AGConfiguration setDefaultConfiguration:...`。

推荐初始化：

```objc
#import <AgriPestClient/AgriPestClient.h>

AGDefaultConfiguration *config = [AGDefaultConfiguration sharedConfig];
config.host = @"http://115.191.67.35:8080";
config.accessToken = @"你的 access token";

AGApiService *api = [[AGApiService alloc] init];
```

如果还没登录，可以先只配 host：

```objc
AGDefaultConfiguration *config = [AGDefaultConfiguration sharedConfig];
config.host = @"http://115.191.67.35:8080";
```

### 3.1 重要配置项

`AGDefaultConfiguration` 常用字段：

- `host`：服务端根地址
- `accessToken`：JWT access token
- `verifySSL`：是否校验证书
- `sslCaCert`：自定义证书路径
- `debug`：是否开启日志
- `defaultHeaders`：全局默认请求头

### 3.2 Bearer Token 的真实行为

SDK 内部不会帮你做“自动登录”或“自动刷新 token”，它只会在请求时读取：

```objc
[AGDefaultConfiguration sharedConfig].accessToken
```

然后自动拼成：

```text
Authorization: Bearer <token>
```

也就是说：

- 你必须自己保存 token
- 你必须自己在登录成功后写回 `config.accessToken`
- 你必须自己处理 401 和 refreshToken 续期

## 4. 通用调用规范

### 4.1 所有接口的统一返回结构

大多数接口返回的都是这种结构：

```objc
@interface AGResultXxx : AGObject
@property(nonatomic) NSNumber *code;
@property(nonatomic) NSString *message;
@property(nonatomic) id data;
@end
```

你实际判断成功时，不要只看 `error == nil`，还要看：

```objc
output.code.integerValue == 200
```

推荐判断方式：

```objc
[api loginWithLoginRequest:req completionHandler:^(AGResultAuthResponse *output, NSError *error) {
    if (!error && output.code.integerValue == 200) {
        // 业务成功
    } else {
        // 网络错误或业务失败
        NSLog(@"%@", output.message ?: error.localizedDescription);
    }
}];
```

### 4.2 分页结构

分页返回统一是：

```objc
@interface AGPageResultXxx : AGObject
@property(nonatomic) NSArray *list;
@property(nonatomic) NSNumber *page;
@property(nonatomic) NSNumber *size;
@property(nonatomic) NSNumber *total;
@property(nonatomic) NSNumber *totalPages;
@property(nonatomic) NSNumber *hasNext;
@end
```

注意：

- `page` 从 `0` 开始
- `hasNext` 才是最稳妥的翻页判断

### 4.3 日期字段

模型里的时间字段基本都映射为 `NSDate`，底层通过 ISO8601 做解析。

例如：

- `createdAt`
- `updatedAt`
- `plantingDate`
- `maturityDate`
- `recordDate`

### 4.4 `_id` 的映射规则

很多模型里用的是：

```objc
@property(nonatomic) NSNumber* _id;
```

但它对应的 JSON 字段其实是服务端的：

```json
{ "id": 123 }
```

这是 SDK 在 `.m` 里通过 `JSONKeyMapper` 做的映射，不是后端直接返回 `_id`。

## 5. 接口总览

下面是 `AGApiService` 里真实存在的接口。

### 5.1 认证与用户

| 方法 | HTTP | 路径 | 说明 |
|---|---|---|---|
| `loginWithLoginRequest` | `POST` | `/api/auth/login` | 账号密码登录 |
| `loginBySmsWithSmsLoginRequest` | `POST` | `/api/auth/login-by-sms` | 手机验证码登录，未注册可自动注册 |
| `callRegisterWithRegisterRequest` | `POST` | `/api/auth/register` | 用户注册 |
| `sendSmsCodeWithSendSmsRequest` | `POST` | `/api/auth/send-code` | 发送验证码 |
| `refreshWithRefreshTokenRequest` | `POST` | `/api/auth/refresh` | 刷新 token |
| `getCurrentUserProfileWithCompletionHandler` | `GET` | `/api/users/me` | 获取当前用户资料 |
| `updateProfileWithProfileUpdateRequest` | `PUT` | `/api/users/me` | 更新资料 |
| `changePhoneWithChangePhoneRequest` | `PUT` | `/api/users/me/phone` | 换绑手机号 |
| `updatePasswordWithVarNewPassword` | `PUT` | `/api/users/me/password` | 修改密码 |
| `followUserWithId` | `POST` | `/api/users/{id}/follow` | 关注用户 |
| `unfollowUserWithId` | `DELETE` | `/api/users/{id}/follow` | 取消关注 |

### 5.2 社区帖子

| 方法 | HTTP | 路径 | 说明 |
|---|---|---|---|
| `getPostsWithTag:q:page:size:` | `GET` | `/api/posts` | 普通帖子列表 |
| `getPostDetailWithId` | `GET` | `/api/posts/{id}` | 帖子详情 |
| `createPostWithPostCreateRequest` | `POST` | `/api/posts` | 发帖 |
| `getMyPostsWithPage:size:` | `GET` | `/api/posts/mine` | 我的帖子 |
| `getFavoritedPostsWithPage:size:` | `GET` | `/api/posts/favorites` | 我的收藏 |
| `likePostWithId` | `POST` | `/api/posts/{id}/like` | 点赞 |
| `unlikePostWithId` | `DELETE` | `/api/posts/{id}/like` | 取消点赞 |
| `favoritePostWithId` | `POST` | `/api/posts/{id}/favorite` | 收藏 |
| `unfavoritePostWithId` | `DELETE` | `/api/posts/{id}/favorite` | 取消收藏 |

### 5.3 评论

| 方法 | HTTP | 路径 | 说明 |
|---|---|---|---|
| `getCommentsWithId:page:size:` | `GET` | `/api/posts/{id}/comments` | 获取帖子评论 |
| `addCommentWithId:commentRequest:` | `POST` | `/api/posts/{id}/comments` | 发表评论 |

### 5.4 搜索与标签

| 方法 | HTTP | 路径 | 说明 |
|---|---|---|---|
| `searchPostsWithQ:page:size:` | `GET` | `/api/search/posts` | 搜索帖子 |
| `getSuggestionsWithQ` | `GET` | `/api/search/suggestions` | 搜索联想词 |
| `getTopTagsWithCompletionHandler` | `GET` | `/api/tags` | 热门标签 |

### 5.5 消息通知

| 方法 | HTTP | 路径 | 说明 |
|---|---|---|---|
| `getMyMessagesWithPage:size:` | `GET` | `/api/messages` | 消息分组列表 |
| `getAlertMessagesWithPage:size:` | `GET` | `/api/messages/alerts` | 首页预警消息 |
| `getUnreadCountWithCompletionHandler` | `GET` | `/api/messages/unread-count` | 未读数 |
| `markAsReadWithId` | `PUT` | `/api/messages/{id}/read` | 单条已读 |
| `markAllAsReadWithCompletionHandler` | `PUT` | `/api/messages/read-all` | 全部已读 |

### 5.6 我的作物

| 方法 | HTTP | 路径 | 说明 |
|---|---|---|---|
| `getMyCropsWithCompletionHandler` | `GET` | `/api/my-crops` | 我的作物列表 |
| `createCropWithMyCropCreateRequest` | `POST` | `/api/my-crops` | 新建作物 |
| `getCropDetailWithId` | `GET` | `/api/my-crops/{id}` | 作物详情 |
| `updateCropWithId:myCropUpdateRequest:` | `PUT` | `/api/my-crops/{id}` | 更新作物 |
| `deleteCropWithId` | `DELETE` | `/api/my-crops/{id}` | 删除作物 |
| `addTagWithId:tagOperationRequest:` | `POST` | `/api/my-crops/{id}/tags` | 添加打卡标签 |
| `removeTagWithId:tagOperationRequest:` | `DELETE` | `/api/my-crops/{id}/tags` | 删除/取消标签 |

### 5.7 AI 诊断

| 方法 | HTTP | 路径 | 说明 |
|---|---|---|---|
| `chatWithChatRequest` | `POST` | `/api/v1/agent/chat` | 普通 AI 诊断 |
| `chatProfileWithChatRequest` | `POST` | `/api/v1/agent/chat/profile` | 带性能剖析的 AI 诊断 |
| `chatStreamWithChatRequest` | `POST` | `/api/v1/agent/chat/stream` | 流式接口 |
| `getHistoryWithCompletionHandler` | `GET` | `/api/v1/agent/history` | AI 历史记录 |

### 5.8 文件上传

| 方法 | HTTP | 路径 | 说明 |
|---|---|---|---|
| `uploadFileWithFile:prefix:` | `POST` | `/api/files/upload` | 单文件上传 |
| `uploadFilesWithFiles:prefix:` | `POST` | `/api/files/upload/batch` | 多文件上传 |
| `startMultipartUploadWithMultipartUploadInitRequest` | `POST` | `/api/files/multipart/init` | 初始化分片上传 |
| `completeMultipartUploadWithMultipartUploadCompleteRequest` | `POST` | `/api/files/multipart/complete` | 合并分片 |

### 5.9 管理员接口

| 方法 | HTTP | 路径 | 说明 |
|---|---|---|---|
| `getAllPostsWithTag:q:page:size:` | `GET` | `/api/admin/community/posts` | 管理员查看全部帖子 |
| `updatePostWithId:postCreateRequest:` | `PUT` | `/api/admin/community/posts/{id}` | 管理员修改帖子 |
| `deletePostWithId` | `DELETE` | `/api/admin/community/posts/{id}` | 管理员删帖 |
| `getAllCommentsWithPage:size:` | `GET` | `/api/admin/community/comments` | 管理员查看评论 |
| `updateCommentWithId:commentRequest:` | `PUT` | `/api/admin/community/comments/{id}` | 管理员改评论 |
| `deleteCommentWithId` | `DELETE` | `/api/admin/community/comments/{id}` | 管理员删评论 |
| `publishMessageWithAdminMessageCreateRequest` | `POST` | `/api/admin/messages` | 发布系统/预警消息 |
| `getMessageHistoryWithPage:size:` | `GET` | `/api/admin/messages/history` | 消息发布历史 |
| `resendMessageWithId` | `POST` | `/api/admin/messages/{id}/resend` | 重发消息 |
| `getUsersWithPage:size:` | `GET` | `/api/admin/users` | 用户列表 |
| `getUserByIdWithId` | `GET` | `/api/admin/users/{id}` | 用户详情 |
| `createUserWithAdminUserUpdateDto` | `POST` | `/api/admin/users` | 创建用户 |
| `updateUserWithId:adminUserUpdateDto:` | `PUT` | `/api/admin/users/{id}` | 更新用户 |
| `deleteUserWithId` | `DELETE` | `/api/admin/users/{id}` | 删除用户 |

### 5.10 其他

| 方法 | HTTP | 路径 | 说明 |
|---|---|---|---|
| `healthWithCompletionHandler` | `GET` | `/api/health` | 健康检查 |

## 6. 常用请求模型

### 6.1 登录注册

`AGLoginRequest`

- `usernameOrPhone`
- `password`

`AGSmsLoginRequest`

- `phone`
- `code`

`AGRegisterRequest`

- `username`
- `phone`
- `password`

`AGRefreshTokenRequest`

- `refreshToken`

`AGSendSmsRequest`

- `phone`

### 6.2 用户资料

`AGProfileUpdateRequest`

- `fullName`
- `avatarUrl`
- `bio`
- `location`
- `followedCrops`

`AGChangePhoneRequest`

- `varNewPhone`

注意：这版 SDK 的换绑手机号请求模型里只有 `varNewPhone`，没有验证码字段。

### 6.3 发帖评论

`AGPostCreateRequest`

- `title`
- `content`
- `images`
- `tags`

`AGCommentRequest`

- `content`

### 6.4 我的作物

`AGMyCropCreateRequest` / `AGMyCropUpdateRequest`

- `plantName`
- `imageUrl`
- `status`
- `plantingDate`
- `maturityDate`
- `pestCount`

`AGTagOperationRequest`

- `recordDate`
- `tagType`
- `content`
- `status`

`tagType` 可见枚举语义：

- `WATERING`
- `FERTILIZING`
- `MEDICATION`
- `NOTE`

### 6.5 AI 诊断

`AGChatRequest`

- `text`
- `imageUrl`
- `useSingleModel`
- `extraInfo`

说明：

- `imageUrl` 可以传图片 URL
- 也可以直接传 Base64 字符串
- `chatProfile` 会返回性能剖析信息

### 6.6 上传

`AGMultipartUploadInitRequest`

- `fileHash`
- `filename`
- `partCount`
- `contentType`

`AGMultipartUploadCompleteRequest`

- `uploadId`
- `filename`
- `partCount`
- `contentType`
- `prefix`

## 7. 常用响应模型

### 7.1 登录返回

`AGAuthResponse`

- `token`
- `refreshToken`
- `expiresIn`
- `userId`
- `username`
- `fullName`
- `generatedPassword`

注意：

- 短信登录自动注册时，可能会返回 `generatedPassword`

### 7.2 用户资料

`AGUserProfileDto`

- `_id`
- `username`
- `phone`
- `fullName`
- `avatarUrl`
- `bio`
- `location`
- `followedCrops`
- `favoriteCount`
- `historyRecognitionCount`

### 7.3 帖子

`AGPostResponseDto`

- `_id`
- `title`
- `content`
- `images`
- `tags`
- `authorId`
- `authorName`
- `authorUsername`
- `authorAvatar`
- `likeCount`
- `favoriteCount`
- `commentCount`
- `isLiked`
- `isFavorited`
- `createdAt`
- `updatedAt`

### 7.4 评论

`AGCommentResponseDto`

- `_id`
- `postId`
- `content`
- `authorId`
- `authorName`
- `authorUsername`
- `authorAvatar`
- `createdAt`

### 7.5 消息

`AGMessageResponseDto`

- `_id`
- `type`
- `title`
- `content`
- `senderId`
- `senderName`
- `senderUsername`
- `senderAvatar`
- `postId`
- `isRead`
- `createdAt`

`AGMessageGroupResponseDto`

- `systemMessages`
- `systemUnreadCount`
- `alertMessages`
- `alertUnreadCount`
- `commentMessages`
- `commentUnreadCount`

### 7.6 作物

`AGMyCropResponseDto`

- `_id`
- `plantName`
- `imageUrl`
- `status`
- `plantingDate`
- `maturityDate`
- `pestCount`
- `records`
- `createdAt`

`records` 的 value 是 `AGCultivationRecordDto` 数组，字段包括：

- `_id`
- `recordDate`
- `tagType`
- `content`
- `status`

### 7.7 搜索

`AGSearchResultResponse`

- `matches`
- `recommendations`
- `suggestions`

### 7.8 AI 诊断

`AGChatProfileResponse`

- `answer`
- `profile`

`AGProfile` 里是服务端性能剖析数据，例如：

- `requestId`
- `clientIp`
- `requestBytes`
- `hasImage`
- `imageUrlType`
- `visionMs`
- `agentMs`
- `saveHistoryMs`
- `totalMs`

### 7.9 上传

`AGMultipartUploadInitResponse`

- `uploadId`
- `uploadedParts`
- `uploadUrls`

## 8. 常见调用示例

### 8.1 账号密码登录

```objc
AGDefaultConfiguration *config = [AGDefaultConfiguration sharedConfig];
config.host = @"http://115.191.67.35:8080";

AGLoginRequest *req = [[AGLoginRequest alloc] init];
req.usernameOrPhone = @"13800000000";
req.password = @"123456";

AGApiService *api = [[AGApiService alloc] init];
[api loginWithLoginRequest:req completionHandler:^(AGResultAuthResponse *output, NSError *error) {
    if (!error && output.code.integerValue == 200) {
        AGAuthResponse *auth = output.data;
        config.accessToken = auth.token;
        NSLog(@"登录成功，userId=%@", auth.userId);
    } else {
        NSLog(@"登录失败：%@", output.message ?: error.localizedDescription);
    }
}];
```

### 8.2 短信登录

```objc
AGSmsLoginRequest *req = [[AGSmsLoginRequest alloc] init];
req.phone = @"13800000000";
req.code = @"123456";

[api loginBySmsWithSmsLoginRequest:req completionHandler:^(AGResultAuthResponse *output, NSError *error) {
    if (!error && output.code.integerValue == 200) {
        [AGDefaultConfiguration sharedConfig].accessToken = output.data.token;
    }
}];
```

### 8.3 获取当前用户资料

```objc
[api getCurrentUserProfileWithCompletionHandler:^(AGResultUserProfileDto *output, NSError *error) {
    if (!error && output.code.integerValue == 200) {
        AGUserProfileDto *profile = output.data;
        NSLog(@"%@", profile.fullName);
    }
}];
```

### 8.4 上传多图后发帖

```objc
[api uploadFilesWithFiles:fileURLs prefix:@"community/" completionHandler:^(AGResultListString *uploadOutput, NSError *uploadError) {
    if (uploadError || uploadOutput.code.integerValue != 200) return;

    AGPostCreateRequest *req = [[AGPostCreateRequest alloc] init];
    req.title = @"标题";
    req.content = @"正文";
    req.images = uploadOutput.data;
    req.tags = @[@"水稻", @"病害"];

    [api createPostWithPostCreateRequest:req completionHandler:^(AGResultPostResponseDto *postOutput, NSError *postError) {
        if (!postError && postOutput.code.integerValue == 200) {
            NSLog(@"发帖成功");
        }
    }];
}];
```

### 8.5 收藏与取消收藏

```objc
[api favoritePostWithId:@(postId) completionHandler:^(AGResultVoid *output, NSError *error) {
    if (!error && output.code.integerValue == 200) {
        NSLog(@"收藏成功");
    }
}];

[api unfavoritePostWithId:@(postId) completionHandler:^(AGResultVoid *output, NSError *error) {
    if (!error && output.code.integerValue == 200) {
        NSLog(@"取消收藏成功");
    }
}];
```

### 8.6 AI 诊断

```objc
AGChatRequest *req = [[AGChatRequest alloc] init];
req.text = @"叶片发黄并且有斑点";
req.imageUrl = @"https://example.com/demo.jpg";
req.useSingleModel = @(NO);

[api chatWithChatRequest:req completionHandler:^(AGResultString *output, NSError *error) {
    if (!error && output.code.integerValue == 200) {
        NSLog(@"%@", output.data);
    }
}];
```

## 9. 业务错误码

源码里已经提供了 `AGServiceCode` 枚举，可直接用于判断常见业务失败。

常用的有：

- `AGServiceCodeSuccess = 200`
- `AGServiceCodeInvalidUsernameOrPassword = 4005`
- `AGServiceCodeInvalidOrExpiredSmsCode = 4008`
- `AGServiceCodeInvalidTokenOrTokenExpired = 4006`
- `AGServiceCodePostNotFound = 4101`
- `AGServiceCodePostAlreadyLiked = 4103`
- `AGServiceCodePostAlreadyFavorited = 4104`
- `AGServiceCodeCropNotFound = 4201`
- `AGServiceCodeAiServiceIsCurrentlyUnavailable = 4302`
- `AGServiceCodeFileUploadFailed = 4401`
- `AGServiceCodeSearchQueryIsTooShort = 4601`

建议业务层统一写一个错误翻译器，而不是到处直接弹 `output.message`。

## 10. 在你当前项目中的推荐用法

你当前工程已经做了一层更适合业务使用的封装：

- `/Users/tommywu/Desktop/TL-PestIdentifyProject/TL-PestIdentify/TL_Common/Network/TLWSDKManager.h`
- `/Users/tommywu/Desktop/TL-PestIdentifyProject/TL-PestIdentify/TL_Common/Network/TLWSDKManager.m`

推荐原则：

### 10.1 登录态相关

直接通过 `TLWSDKManager` 管 token、refreshToken 和当前用户缓存，不要在各个页面里各自保存。

### 10.2 帖子与评论

项目里已经封装了：

- 获取帖子列表
- 获取评论列表
- 发评论
- 获取收藏列表

这些优先走 `TLWSDKManager`，只有缺的接口再直接调 `AGApiService`。

### 10.3 上传图片

项目里已经把 `UIImage -> 临时文件 -> SDK uploadFilesWithFiles:` 这一套封好了，直接复用 `uploadImages:prefix:completion:` 更省事。

### 10.4 401 处理

SDK 不会自动刷新 token，但你项目里 `TLWSDKManager` 已经实现了：

- refreshToken 续期
- 并发 401 排队
- 刷新失败回登录页

所以新加鉴权接口时，建议统一跟项目现有模式走，不要单页自己写一套。

## 11. 已知注意事项

这些是根据源码读出来的真实注意点。

### 11.1 SDK README 初始化示例不可靠

以本地 `1.0.108` 源码为准，使用：

- `AGDefaultConfiguration sharedConfig`
- `config.host = ...`
- `config.accessToken = ...`

### 11.2 换绑手机号接口当前没有验证码字段

`AGChangePhoneRequest` 只有：

- `varNewPhone`

没有短信验证码字段。这意味着如果前端页面想让用户输入验证码，必须先确认后端接口是否另有约束，否则页面语义会和接口能力不一致。

### 11.3 `chatStream` 目前只是有 SSE 模型，但 SDK 没提供完整流式事件消费封装

`chatStreamWithChatRequest` 返回的是 `AGSseEmitter`，但从当前 Objective-C SDK 代码看，没有额外的事件监听器、逐 token 回调封装。也就是说：

- 接口声明存在
- 但客户端侧“真流式消费能力”并不完整

如果要做稳定流式聊天，可能还需要额外的 SSE 客户端实现。

### 11.4 管理员接口和普通用户接口是分开的

例如帖子和评论：

- 普通用户走 `/api/posts`
- 管理员走 `/api/admin/community/posts`

不要混用。

### 11.5 收藏、点赞、关注都有成对接口

每组都分正向和取消两个接口：

- `like / unlike`
- `favorite / unfavorite`
- `follow / unfollow`

前端不能只写一半，否则状态会漂。

### 11.6 上传接口要求传 `NSURL`

上传时传的是本地文件 URL，不是 `UIImage`。如果你手里是图片对象，需要先落临时文件。

## 12. 建议的项目级封装习惯

如果后面还会继续扩展，建议按下面的分层维护：

1. `AGApiService`
   只当“底层 SDK”

2. `TLWSDKManager`
   负责登录态、401、缓存、公共调用模式

3. 业务模块 Controller / ViewModel
   只关心页面逻辑，不直接操作 token 和复杂拼装

这样后面升级 `1.0.109`、`1.0.110` 时会更稳。

## 13. 结论

这个 SDK 目前已经覆盖了你项目绝大多数真实业务场景：

- 认证登录
- 用户资料
- 社区帖子与评论
- 收藏点赞关注
- 消息通知
- 我的作物
- AI 诊断
- 文件上传
- 管理员后台能力

它的核心使用原则其实很简单：

1. 用 `AGDefaultConfiguration` 配 host 和 token
2. 用 `AGApiService` 调业务接口
3. 始终检查 `error` 和 `output.code == 200`
4. 文件上传传 `NSURL`
5. 鉴权续期自己处理，或者统一交给你项目里的 `TLWSDKManager`

如果后面你要，我还可以继续做两件更实用的事：

1. 再补一份“按你当前 App 页面对应到 SDK 方法”的对照文档
2. 直接给你生成一份 `SDK-接口速查表.md`，只保留方法名、参数、返回值和注意事项，方便你开发时秒查
