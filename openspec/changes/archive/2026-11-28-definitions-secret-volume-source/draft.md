---
change-id: definitions-secret-volume-source
updated_at: "2026-11-28T10:57:30Z"
---

# definitions.secretVolumeSource

## 目标

- 新增 `definitions.secretVolumeSource`，按 Kubernetes `SecretVolumeSource` 官方定义渲染该字段片段。

## 期望输入格式

- 上下文为原生 map 或由父模板清洗后的 map。
- 键与官方字段一致：`defaultMode`、`items`、`optional`、`secretName`。
- `items` 支持原生 KeyToPath array 或 string array。

## 需求

- 字段按官方 `SecretVolumeSource` 定义：`defaultMode`（integer, 可选）、`items`（KeyToPath array 或 string array, 可选）、`optional`（boolean, 可选）、`secretName`（string, 必填）。
- 渲染顺序按官方定义字段顺序：`defaultMode`、`items`、`optional`、`secretName`。
- `secretName` 必填；其他字段可选。
- `items` 通过子模板 `definitions.keyToPath` 渲染；本 change 只占位调用，不创建该子模板。
- `items` 为 string array 时，元素格式为 `<key> <path> [mode]`，与 `definitions.volume` 的 `secret` 简写一致；向下传递前清洗为包含 `key`、`path` 及可选 `mode` 的 KeyToPath map。
- `items` 混合 string 与 map 时，string 元素先清洗为 KeyToPath map，再与其他条目一并渲染。
- `secretName` 必填并按 RFC1123 Subdomain 校验。
- 收集的 items 渲染数据需要去重、去空。
- 可选字段为空时不渲染对应字段；必填字段不能为空。
- 非法输入时中断并报错。

## 约束

- `definitions.keyToPath` 仅作为占位调用，不创建、不修改。
- 优先采用简洁直白语法。

## 非目标

- 不创建 `definitions.keyToPath`（仓库中已存在 `templates/api-resources/Definitions/_KeyToPath.tpl`）。
- 不调整 `SecretVolumeSource` 之外的其他 definition 模板。

## 验收

- 合法输入按 `defaultMode`、`items`、`optional`、`secretName` 的官方顺序渲染。
- `secretName` 缺失、为空或不是合法 RFC1123 Subdomain 时中断渲染。
- `items` 为 KeyToPath array 时逐项委托 `definitions.keyToPath`，结果去重去空。
- `items` 为 string array 或混合数组时，string 元素按 `<key> <path> [mode]` 清洗为 KeyToPath map 后再渲染。
- 可选字段为空时对应字段不出现。
- 非法输入时渲染中断并报错。
