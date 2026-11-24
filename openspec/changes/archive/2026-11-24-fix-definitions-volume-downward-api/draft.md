---
change-id: fix-definitions-volume-downward-api
updated_at: "2026-11-24T10:53:17Z"
---

# definitions.volume downwardAPI items 格式调整

## 目标

- 调整 downwardAPI 卷简写 items 字符串元素的格式：把可选 `[mode]` 从末尾前移到 `<path>` 之后，field 元素补充可选 `[apiVersion]`。

## 需求

- field 元素格式由 `<path> field <fieldPath> [mode]` 调整为 `<path> [mode] field <fieldPath> [apiVersion]`。
- resource 元素格式由 `<path> resource <resource> [containerName] [divisor] [mode]` 调整为 `<path> [mode] resource <resource> [containerName] [divisor]`。
- 不做旧格式兼容，items 元素按新格式唯一解释；field 末尾第 5 段按 `apiVersion` 捕获。
- 格式不匹配时的报错提示同步使用新格式。
- `mode` 缺失时不写入 `mode` 键；`mode` 的取值校验规则不因位置调整而变化。
- `apiVersion` 缺失时不写入该键，不新增取值校验。

## 期望输入格式

```yaml
items:
  - meta 0400 field metadata.name
  - labels field metadata.labels
  - meta2 field metadata.name v1
  - cpu 0644 resource limits.cpu app 1m
  - cpu2 resource limits.cpu app 1m
```

## 约束

- 只调整 downwardAPI items 的元素格式及关联提示，不改动 configMap/secret 的 `<key> <path> [mode]` 形态。
- 调整既有捕获规则，不新增平行正则。
- 不需要与 `definitions-downward-api-volume-source` 同步，本 change 不修改该 change 的制品。

## 非目标

- 不改变 downwardAPI 简写整体的 `[defaultMode] [items (<item>, ...)]` 结构。
- 不改变 `field`、`resource` 关键字与各必填段语义；除 field 新增 `apiVersion` 外不增加其他段。
- 不涉及 `definitions.downwardAPIVolumeFile` 子模板的创建。

## 验收

- `<path> 0400 field metadata.name` 可匹配，并捕获 path、mode、fieldPath。
- `<path> field metadata.name`（无 mode）仍可匹配，且不产生 mode。
- `<path> 0644 resource limits.cpu app 1m` 可匹配，并捕获 path、mode、resource、containerName、divisor。
- `<path> field metadata.name v1` 匹配后 apiVersion 捕获为 `v1`；缺失时不产生 apiVersion。
- `<path> field metadata.name 0400` 按新格式捕获 `apiVersion="0400"`，不再解释为末尾 mode。
- 旧 resource 带末尾 mode 的输入不再匹配：`<path> resource limits.cpu app 1m 0644`。

## 开放问题

- 暂无。
