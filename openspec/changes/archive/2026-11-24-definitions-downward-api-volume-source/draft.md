---
change-id: definitions-downward-api-volume-source
updated_at: "2026-11-24T13:41:11Z"
---

# definitions.downwardAPIVolumeSource

## 目标

- 新增 `definitions.downwardAPIVolumeSource` 模板，归一化 `defaultMode` 与 `items` 容器结构，并把每个 item 原样委托给子模板 `definitions.downwardAPIVolumeFile`；item 段位解析与 path 归一化由子模板负责。

## 需求

- 上下文兼容原生 map 和父模板清洗后的 map。
- 原生 map 的 `items` 以官方 DownwardAPIVolumeFile 对象数组为主；类型层面也接受 string 元素并允许与 map 混合，但这只是意外兼容，不作为推荐写法。
- 父模板清洗后的 `items` 为 string array，元素形态以父模板内容为准：`<path> [mode] field <fieldPath> [apiVersion]` 或 `<path> [mode] resource <resource> [containerName] [divisor]`；段位解析由 `definitions.downwardAPIVolumeFile` 负责。
- resource item 由子模板按空格分段，段位固定：
  - 第 1 段 `path`，必填。
  - 第 2 段 `mode`，可选。
  - 第 3 段字面量 `resource`，必填且不区分大小写。
  - 第 4 段 `<resource>`，必填。
  - 第 5 段 `containerName`，可选。
  - 第 6 段 `divisor`，可选。
- field item 由子模板按空格分段，段位固定：
  - 第 1 段 `path`，必填。
  - 第 2 段 `mode`，可选。
  - 第 3 段字面量 `field`，必填且不区分大小写。
  - 第 4 段 `fieldPath`，必填。
  - 第 5 段 `apiVersion`，可选。
- field item 第 5 段按 `apiVersion` 解释，不兼容旧段位把 `mode` 放在末尾的写法；resource item 出现第 6 段之后的多余段时中断。
- `defaultMode` 由公共模板统一处理，最终只接受 int 类型。
- 传给 `definitions.downwardAPIVolumeFile` 的上下文：string item MUST 以 `dict "item" <原始字符串>` 包装，map item MUST 原样传递；item 段位解析、`path`/`fieldRef`/`resourceFieldRef`/`mode` 构造与 path 归一化由子模板负责。
- `definitions.downwardAPIVolumeSource` 不解析、不校验 string item 段位，也不构造 item map；`fieldRef`、`resourceFieldRef` 的内部字段及两者互斥关系由子模板处理。
- `path` 为相对路径；由子模板复用 `base.path` 的 rel 归一化并拒绝 `..` 与前导 `../`，与 `definitions.keyToPath` 一致。
- `items` 为空数组或元素全为空白 string 时省略；空白 string MUST 跳过，非空白 string 与 map MUST 原样传递。
- `definitions.downwardAPIVolumeFile` 输出为空时该元素不渲染；输出非 map（含非法 YAML）时中断。
- 子模板 `definitions.downwardAPIVolumeFile` 仅作占位，本 change 不创建。

## 期望输入格式

### 原生 map

```yaml
defaultMode: 0644
items:
  - path: labels
    fieldRef:
      apiVersion: v1
      fieldPath: metadata.labels
  - path: cpu
    resourceFieldRef:
      containerName: app
      resource: limits.cpu
```

### 父级清洗后的 map

```yaml
defaultMode: "0644"
items:
  - meta 0400 field metadata.name
  - meta2 field metadata.name v1
  - cpu resource limits.cpu app 1m
  - cpu2 0644 resource limits.cpu app 1m
```

- string 元素由子模板复用父模板 `K8S.VOLUME.DOWNWARD_API_FIELD_ITEM` 与 `K8S.VOLUME.DOWNWARD_API_RESOURCE_ITEM` 的捕获规则，段位与“需求”一致。
- `cpu resource limits.cpu app 2`：第 5 段 `containerName=app`，第 6 段 `divisor=2`，无 `mode`。
- `cpu 0644 resource limits.cpu app 2`：第 2 段 `mode=0644`。
- `meta2 field metadata.name v1`：第 5 段 `apiVersion=v1`。
- 原生 map 中的 string 元素与 map 元素可以混合，元素类型不统一时不视为错误。

## 约束

- 仅使用 Helm 内置函数、Go Template、Sprig 与 Helm 特有函数。
- 子模板 `definitions.downwardAPIVolumeFile` 只占位，本 change 不创建。
- `defaultMode` 的字符串解析与 int 门禁由公共模板完成。
- `path` 的归一化与 `..` 拒绝由子模板复用公共路径能力，本模板不重复实现。
- 子模板解析 string item 时复用共享常量 `K8S.VOLUME.DOWNWARD_API_FIELD_ITEM` 与 `K8S.VOLUME.DOWNWARD_API_RESOURCE_ITEM`；需要调整时同步修改这些常量，不新增平行正则。
- string 形态的必填位由子模板捕获规则保证非空；map 形态原样传递，不补做必填校验。

## 非目标

- 不实现 `definitions.downwardAPIVolumeFile` 的清洗与渲染。
- 不扩展其他卷源类型。
- 本模板不解析 string item 段位，不校验 `fieldRef`、`resourceFieldRef` 的内部字段，也不判定两者互斥。
- 不在本模板归一化 `path`。
- 不把原生 map 接受 string item 的意外兼容固化为推荐输入格式。

## 验收

- 原生 map 与父模板清洗后的 map 均可渲染 `defaultMode` 与 `items`；string item MUST 以 `{item: <原始字符串>}` 传给子模板，map item MUST 原样传递。
- 空白 string 跳过；`items` 为空、缺失或全空白时不渲染。
- 本模板不因 string item 段位内容而中断；段位合法性由子模板负责。
- `defaultMode` 最终以 int 类型输出。
- `definitions.downwardAPIVolumeFile` 输出为空时跳过该元素，输出非 map 时中断。
- `definitions.downwardAPIVolumeFile` 的 include 调用存在，但本 change 不创建该子模板。

## 开放问题

- 暂无。
