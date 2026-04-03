# Release SOP (iOS)

本文档定义 TL-PestIdentify 的版本发布流程，目标是让版本号、代码、Tag、发布说明一一对应。

## 1. 版本号规则

采用 SemVer：

- `MAJOR`：不兼容变更
- `MINOR`：向后兼容的新功能
- `PATCH`：向后兼容的修复

示例：`1.4.2`

## 2. iOS 版本字段映射

- `MARKETING_VERSION` -> 对外版本号（例如 `1.4.2`）
- `CURRENT_PROJECT_VERSION` -> 构建号（例如 `132`）

建议：

- 每次发版至少递增 `CURRENT_PROJECT_VERSION`
- 仅在功能或修复集合完成时提升 `MARKETING_VERSION`

## 3. 发版流程

1. 从最新 `main` 创建发布分支
2. 更新版本号
3. 回归验证
4. 提 PR 合并回 `main`
5. 在 `main` 上打 Tag 并创建 GitHub Release

## 4. 操作命令示例

### 4.1 创建发布分支

```bash
git checkout main
git pull origin main
git checkout -b release/1.4.2
```

### 4.2 更新版本号（可选 agvtool）

```bash
cd TL-PestIdentify
xcrun agvtool new-marketing-version 1.4.2
xcrun agvtool next-version -all
```

### 4.3 提交并推送

```bash
git add -A
git commit -m "chore(release): bump version to 1.4.2"
git push origin release/1.4.2
```

### 4.4 合并后打 Tag

```bash
git checkout main
git pull origin main
git tag -a v1.4.2 -m "Release v1.4.2"
git push origin main
git push origin v1.4.2
```

## 5. Release Notes 模板

发布说明建议包含：

- 新功能（Features）
- 修复项（Fixes）
- 破坏性变更（Breaking Changes）
- 升级说明（Migration Notes）

## 6. Hotfix 流程（线上紧急修复）

1. 从 `main` 拉 `fix/*` 分支
2. 修复并走 PR + CI
3. 合并后提升 `PATCH`，例如 `1.4.2 -> 1.4.3`
4. 打 `v1.4.3` Tag

