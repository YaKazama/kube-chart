# definitions.volume downwardAPI items 格式调整设计

## 技术目标

- capability：`definitions.volume` 的 `downwardAPI` 字符串简写 items 解析
- artifact-type：Helm library Chart 命名模板与 `base.env` 常量
- target：`definitions.volume`

## 设计决策

### Decision: item 段位与捕获组调整

- requirements：`downwardAPI 卷字符串`
- choice：`K8S.VOLUME.DOWNWARD_API_FIELD_ITEM` 的运行时表达式改为 `^\s*([^\s,]+)(?:\s+([^\s,]+))?\s+(?i:field)\s+(\S+)(?:\s+([^\s,]+))?\s*$`，捕获组依次为 path、mode、fieldPath、apiVersion；`K8S.VOLUME.DOWNWARD_API_RESOURCE_ITEM` 改为 `^\s*([^\s,]+)(?:\s+([^\s,]+))?\s+(?i:resource)\s+(\S+)(?:\s+(\S+))?(?:\s+(\S+))?\s*$`，捕获组依次为 path、mode、resource、containerName、divisor。`_Volume.tpl` 仍只把原始 item 字符串加入 `items`。
- rationale：mode 前移后，必填段与可选段由字面量 `field` / `resource` 分隔，Go RE2 无 lookahead 也能唯一匹配；field 末尾可选段直接承载 apiVersion，旧末尾 mode 位置自然转为 apiVersion，无需额外分支。源码在 `_env.tpl` 的 YAML 双引号内按 `\\s`、`\\S` 转义书写，运行时经 `fromYaml` 恢复为上述表达式。

### Decision: 原始 item 字符串下传

- requirements：`downwardAPI 卷字符串`
- choice：`_Volume.tpl` 只对 item 执行 `trim`、形态匹配与 `mustAppend`，`items` 保持原始字符串列表，不解析捕获组、不构造 item map。
- rationale：现有契约由 `definitions.downwardAPIVolumeSource` 消费原始字符串；本 change 不实现该子模板，提前构造映射会越界并重复下游语义。

### Decision: 错误消息同步

- requirements：`downwardAPI 卷字符串`
- choice：`downwardAPI` item 格式不匹配的失败消息改为 `'<path> [mode] field <fieldPath> [apiVersion]' or '<path> [mode] resource <resource> [containerName] [divisor]'`。
- rationale：错误消息必须与规格中的新段位一致，否则无法定位格式差异。

### Decision: 下游子模板 unavailable 与验证 fixture

- requirements：`downwardAPI 卷字符串`
- choice：`definitions.downwardAPIVolumeSource` 标记为 `unavailable`，本 change 不创建。验证在 `/tmp/sd-kube-chart/` 最小 application Chart 中提供同名回显 fixture，原样回显收到的上下文。
- rationale：当前模板清单中没有该 define，规格只锁定原始字符串下传契约；fixture 只证明 `definitions.volume` 自身的匹配、字符串下传与失败行为，不证明真实 `DownwardAPIVolumeSource` 渲染。

## 依赖契约

### Dependency: `base.env`

- availability：existing
- source：`templates/base/_env.tpl`
- operation：update
- input：`""`；经 `fromYaml` 恢复常量 map。
- output：常量 map；`K8S.VOLUME.DOWNWARD_API_FIELD_ITEM` 与 `K8S.VOLUME.DOWNWARD_API_RESOURCE_ITEM` 的运行时表达式与捕获组按 Decision 更新，其余键和 `SPLIT.COMMA` 保持不变。
- ownership：`base.env` 负责集中常量结构、YAML 转义与 map 输出；本层只读取这两个键传给 `mustRegexMatch`。

### Dependency: `definitions.downwardAPIVolumeSource`

- availability：unavailable
- source：无
- operation：consume
- input：`downwardAPI` source 上下文 map，含可选 `defaultMode` 原始 string 与 `items` 原始 item string 列表。
- output：`downwardAPI` source 的 YAML 字段片段；空、`null` 或非 map 由 `definitions.volume` 按 `{}` 处理，非法 YAML 中断。
- ownership：子模板负责把 item 段位映射为 `DownwardAPIVolumeFile`、`fieldRef` 与 `resourceFieldRef`，缺失的可选段不产生对应字段；本 change 只负责简写匹配、原始字符串下传与失败边界。

## 代码边界

### `templates/base/_env.tpl`

- access：write
- operations：更新 `K8S.VOLUME.DOWNWARD_API_FIELD_ITEM` 与 `K8S.VOLUME.DOWNWARD_API_RESOURCE_ITEM` 的表达式及紧邻的捕获顺序注释。
- writable-scopes：`K8S.VOLUME.DOWNWARD_API_FIELD_ITEM`、`K8S.VOLUME.DOWNWARD_API_RESOURCE_ITEM` 及其紧邻注释。

### `templates/api-resources/Definitions/_Volume.tpl`

- access：write
- operations：更新 `downwardAPI` 分支 item 格式不匹配的失败消息。
- writable-scopes：`definitions.volume` 内 `else if eq $source "downwardAPI"` 处理块的 item 失败消息。

## 验证设计

- 最小有效：在 `/tmp/sd-kube-chart/` 新建最小 application Chart，加载 `templates/base/` 与 `templates/api-resources/Definitions/_Volume.tpl`，为 `definitions.downwardAPIVolumeSource` 提供回显上下文的同名 fixture。渲染 `{name: "dw", downwardAPI: "0644 items (meta 0400 field metadata.name)"}`，确认 `defaultMode` 与 `items` 按原始值下传。fixture 只证明 `definitions.volume` 的调用方行为。
- 较完整有效：覆盖省略 mode 的 field、带 apiVersion 的 field、`meta field metadata.name 0400` 的 apiVersion 解释、`cpu resource limits.cpu`、`cpu 0644 resource limits.cpu app 1m`、大小写混合的关键字与多 item 逗号分隔，确认匹配、段位归属与原始字符串下传不变。
- 关键失败：覆盖旧 resource 末尾 mode `cpu resource limits.cpu app 1m 0644`、缺少 fieldPath、缺少 resource、field 多余段、空 `items ()` 与顶层简写不匹配，确认全部中断且 item 消息使用新段位说明。
