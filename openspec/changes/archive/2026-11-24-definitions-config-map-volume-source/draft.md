---
change-id: definitions-config-map-volume-source
updated_at: "2026-11-23T16:07:39Z"
---

# definitions.configMapVolumeSource

## 目标

- 新增 `definitions.configMapVolumeSource`，接收原生 map 或父级 `definitions.volume` 清洗后的 map，渲染 ConfigMapVolumeSource 字段片段。

## 需求

- 入参为 map；支持原生 map，以及父级清洗后 `items` 为 string array 的 map。
- `name` 必填，按 ConfigMap 官方命名规则处理：必须是 DNS Subdomain（RFC1123 Subdomain，最多 253 字符）。
  - 校验前只 trim，不做小写或其他归一化，避免改变被引用的 ConfigMap 名称。
  - 缺失、空或非法时中断。
- `defaultMode` 可选；接受八进制 `0000`-`0777` 或十进制 `0`-`511`，数值与字符串都合法；最终输出十进制 int。
  - 由公共模板 `base.fileMode` 完成字符串解析与范围门禁：`"0755"` 归一化为十进制 493，`"9"` 归一化为 9。
  - 现有 `base.fileMode` 会拒绝单字符十进制 `"1"`-`"9"`，需要放开到十进制 `0`-`511` 全量。
- `items` 可选；可以是原生 map 数组或 string array，允许两种元素混合。
  - string 元素复用父模板 `K8S.VOLUME.KEY_TO_PATH_ITEM` 捕获 `key`、`path` 与可选 `mode`，归一化为 `{key, path, mode}` map。
  - map 元素原样下传；`mode` 等字段的清洗由 `definitions.keyToPath` 负责，本模板不提前解析。
  - `items` 为空数组、或元素全部为空白字符串时不渲染；元素格式非法或元素不是 map/string 时中断。
- `optional` 可选；空值不渲染，显式 `false` 输出。
- `definitions.keyToPath` 只占位，本 change 不创建；入参为 map，形如 `{key, path, mode}`。
  - `definitions.keyToPath` 输出为空或非 map 时中断。
- `[AI 推断]` 只读取 `defaultMode`、`items`、`name`、`optional`，其他键忽略。

## 期望输入格式

### map 形式

```yaml
name: config-name
defaultMode: 0644
items:
  - key: key
    path: path
    mode: 0644
```

### 父级清洗后的 string array

```yaml
name: config-name
defaultMode: "0644"
items:
  - key path
  - key1 path1 0400
```

- string array 元素使用与父模板 `items` 相同的捕获规则。
- map 元素与 string 元素可以混合出现。
- `items` 为空或全空白时不渲染；元素格式非法或 `defaultMode` 越界时中断。

## 约束

- 不创建 `definitions.keyToPath`；只按已锁定契约调用。
- `defaultMode` 的字符串解析与 int 门禁由 `base.fileMode` 完成，最终输出必须是十进制 int。
- `name` 缺失、空或非法时中断；其他字段非法时中断，空值不渲染。
- `items` string array 的捕获规则复用 `K8S.VOLUME.KEY_TO_PATH_ITEM`，不自定义元素字段顺序。
- 字段按 ConfigMapVolumeSource 顺序输出：`defaultMode`、`items`、`name`、`optional`。
- 扩展 `base.fileMode` 的文件模式归一化属于本 change 范围，不改变其他公共模板行为。

## 非目标

- 不创建 `definitions.keyToPath` 子模板。
- 不实现本 change 之外的 VolumeSource 子模板。
- 不改变父模板 `definitions.volume` 的字段顺序或字符串简写。

## 验收

- 原生 map 输入可渲染 `name`、`defaultMode`、`items`、`optional`。
- 字段按 ConfigMapVolumeSource 顺序输出。
- 父级清洗后的 map 中 `items` 为 string array 时可逐元素解析并交给 `definitions.keyToPath`，map 与 string 元素混合同样支持。
- `defaultMode` 的 `"0000"`、`"0755"`、`"9"`、`493` 可归一化为十进制 int；越界或非法值中断。
- `name` 缺失、空或非法（含大写、超长）时中断。
- `items` 为空或全空白时不渲染；元素格式非法或 `definitions.keyToPath` 输出为空/非 map 时中断。
- `definitions.keyToPath` 的 include 调用存在，但本 change 不创建该子模板。

## 开放问题

- 暂无。
