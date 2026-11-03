---
change-id: definitions-label-selector-fix
updated_at: "2026-11-03T04:12:24Z"
---

# Definitions LabelSelector Fix

## 目标

- 修正 `definitions.labelSelector` 使用的字符串简写选择器正则，使带前缀的标签键（如 `app.kubernetes.io/name`）能够被识别并归一化。

## 需求

- `base.env` 的 `K8S.SELECTOR` 下 `EQUALITY_FOR_APPS`、`SET_FOR_APPS`、`EXISTS_FOR_APPS` 三处 key 捕获组必须支持可选的单斜杠前缀段。
- 捕获组编号与语义保持不变：`EQUALITY_FOR_APPS` 为 key、操作符、值；`SET_FOR_APPS` 为 key、操作符、值列表；`EXISTS_FOR_APPS` 为否定前缀、key。
- key 匹配范围保持宽松，只补齐斜杠结构，不复刻标签键严格格式校验。
- 已实测 `app.kubernetes.io/name = web`、`app.kubernetes.io/name in (a, b)`、`app.kubernetes.io/name`、`!app.kubernetes.io/name` 在现行正则下全部无法匹配。

## 期望输入格式

- `matchExpressions` 数组项可为字符串简写，例如 `app.kubernetes.io/name = web`、`app.kubernetes.io/name in (a, b)`、`app.kubernetes.io/name`、`!app.kubernetes.io/name`。

## 约束

- 仅修改 `templates/base/_env.tpl` 中 `K8S.SELECTOR` 的上述三条正则常量，不改动 `definitions.labelSelector` 的模板正文与归一化逻辑。
- 严格格式校验只在 `definitions.labelSelectorRequirement` 中执行，本 change 不引入重复校验。
- 多斜杠结构（如 `a/b/c`）与缺段结构（如 `a/`、`/a`）不得被放行。
- 本 change 独立先行落地，不以 `definitions-label-selector-requirement` 的制品或代码为前提。
- 本 change 不新增、不修改 `definitions.labelSelectorRequirement`，也不等待其存在。

## 非目标

- 不改动 `definitions.labelSelector` 的既有分支结构、失败消息与数据清洗职责。
- 不新增或修改 `definitions.labelSelectorRequirement` 模板。
- 不改动 `matchLabels` 相关逻辑。

## 验收

- `app = web`、`app != web`、`app in (a)`、`app notin (a)`、`app`、`!app` 的匹配结果与修改前一致。
- `app.kubernetes.io/name = web`、`app.kubernetes.io/name in (a, b)`、`app.kubernetes.io/name`、`!app.kubernetes.io/name` 改为可匹配。
- `a/b/c`、`a/`、`/a` 在三条正则下均不可匹配。
- 匹配成功后 key 捕获组提取结果不含斜杠丢失或多余字符。
- 验收在三条正则的匹配与捕获层独立完成，不依赖 `definitions.labelSelector` 的完整渲染链路。

## 开放问题

<!-- 暂无。 -->
