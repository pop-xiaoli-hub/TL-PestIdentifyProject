# Contributing Guide

本仓库采用 `main + feature` 的轻量协作模型。以下规范用于降低合并冲突、提升代码可追溯性。

接手先读 [README](README.md)，再核对相关源码与测试。工作区整理笔记不随源码上传，不作为公开协作的必需依赖。

## 1. 分支策略

- `main`：可发布分支，只接收通过 Review 的变更。
- `feature/*`：功能开发。
- `fix/*`：线上问题修复。
- `refactor/*`：重构（无业务行为变更）。
- `release/*`：发版准备（版本号、文档、回归修复）。

建议命名格式：

- `feature/community-search`
- `fix/post-detail-like-crash`
- `refactor/message-module-structure`

## 2. 提交流程

1. 从最新 `main` 切分支：
   `git checkout main && git pull && git checkout -b feature/xxx`
2. 本地完成开发并自测通过。
3. 使用清晰 commit message（推荐 Conventional Commits）。
4. 推送分支并发起 PR 到 `main`。
5. 通过 CI + Code Review 后再合并。

以上是人工协作流程，不构成 Agent 自动 commit/push 授权。不得改写历史、夹带用户改动或全量暂存；提交、推送分别需要当前请求授权。

## 3. Commit 规范

推荐格式：

`<type>: <summary>`

可用 `type`：

- `feat`: 新功能
- `fix`: 缺陷修复
- `refactor`: 重构
- `docs`: 文档
- `chore`: 构建/脚本/配置
- `test`: 测试相关

示例：

- `feat: add message list pagination`
- `fix: avoid post detail like state rollback mismatch`

## 4. Pull Request 要求

- PR 尽量小而明确，避免超大“混合改动”。
- 标题清楚描述目标和范围。
- 必须填写变更说明、验证方式、风险点。
- 涉及 UI 的变更，附截图或录屏。
- 涉及接口行为的变更，附关键请求/响应说明。
- 行为变更同步公开 README 中受影响的功能、运行操作与验收边界；本地审阅和交接材料按需维护，不要求上传。
- 分开提交构建、隔离组件、本地真实流、真机、生产证据；44/44 Catalyst 隔离回归不等于 Keychain/WCDB 真机验收。
- 重连变更必须保持显式协议选择。正式旧流不能自动重 POST；job 协议重启后未知创建只能查询，不能静默第二次创建。检查业务 canonical、seq/cursor 和关联提问的事务一致性；UI pending 不是恢复游标。
- 鉴权测试不得删除真实用户状态；发布 POST 结果未知不自动重试；日志和文档不得包含真实凭据或用户内容。

## 5. 合并策略

- `main` 禁止直接 push，必须通过 PR。
- 优先使用 “Squash and Merge” 保持主线简洁（或团队统一使用 Merge Commit，但需一致）。
- 合并前确保：
  - CI 通过
  - 至少 1 个 Reviewer 通过
  - 无阻塞性冲突

## 6. 版本与标签（简版）

- 版本号使用 SemVer：`MAJOR.MINOR.PATCH`（如 `1.2.0`）。
- 每次发版后创建 Git Tag：`v1.2.0`。
- 详细流程见 [docs/发版流程.md](docs/发版流程.md)。

## 7. 分支清理

- PR 合并后删除远端功能分支。
- 每周清理已合并分支，保持仓库整洁。

