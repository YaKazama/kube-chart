# `definitions.persistentVolumeClaimTemplate` 设计

## 技术目标

- capability：`definitions.persistentVolumeClaimTemplate`
- artifact-type：Helm 命名模板
- target：`templates/api-resources/Definitions/_PersistentVolumeClaimTemplate.tpl`

## 设计决策

### Decision: 上下文与字段取值

- requirements：`PersistentVolumeClaimTemplate 字段片段渲染`、`输入失败边界`
- choice：入口拒绝非 map 上下文；`metadata`、`spec` 统一以 `base.get` 取值，`fromYaml` 恢复，`base.isFromYamlError` 拦截解析错误。
- rationale：工程规则要求多层字段统一使用 `base.get`；既有 Definitions 模板使用同一恢复与错误保护模式。

### Decision: metadata 委托

- requirements：`PersistentVolumeClaimTemplate 字段片段渲染`
- choice：`metadata` 缺失或恢复后为空时不调用子模板并省略字段；非空时以该 map 原样调用 `definitions.objectMeta`，不设置 `_kind` 或 `_pkind`。
- rationale：用户确认直接调用已实现的 `definitions.objectMeta`；该模板无身份字段时按默认分支渲染。

### Decision: spec 委托与必填

- requirements：`PersistentVolumeClaimTemplate 字段片段渲染`、`输入失败边界`
- choice：`spec` 缺失或恢复后为空时立即失败；非空时调用 `core.persistentVolumeClaimSpec`，子模板返回空内容或非法 YAML 时失败。
- rationale：用户确认 `spec` 必填且不能为空，`core.persistentVolumeClaimSpec` 只占位、不创建。

### Decision: 输出形态

- requirements：`PersistentVolumeClaimTemplate 字段片段渲染`
- choice：`metadata` 与 `spec` 均恢复为 map 后经 `base.field` + `base.map` 渲染；不输出父键、`---`、`status` 或控制字段。
- rationale：`definitions.ephemeralVolumeSource` 以 map 片段消费本模板输出，并由调用方 `base.field` 包装 `volumeClaimTemplate` 父键。

### Decision: 失败消息

- requirements：`输入失败边界`
- choice：本层失败消息统一为 `[definitions.persistentVolumeClaimTemplate] <字段路径>: <原因>`；子模板自身失败按其原消息向上传播。
- rationale：工程规则要求统一失败消息格式。

## 依赖契约

### Dependency: `base.get`

- availability：existing
- source：`templates/base/_get.tpl`
- operation：consume
- input：`list <上下文> <字段路径>`，只读取 `metadata` 与 `spec`。
- output：YAML 字符串；路径缺失时为空输出。
- ownership：`base.get` 负责多数据源优先级、别名与序列化；本层负责 YAML 恢复、错误保护和字段生效判断。

### Dependency: `base.isFromYamlError`

- availability：existing
- source：`templates/base/_convert.tpl`
- operation：consume
- input：`fromYaml` 返回值。
- output：`"true"` 或 `"false"` 布尔字符串。
- ownership：`base.isFromYamlError` 只识别 Helm 解析错误形态；本层决定失败消息与后续分支。

### Dependency: `base.field`

- availability：existing
- source：`templates/base/_field.tpl`
- operation：consume
- input：`list "metadata" <map> "base.map"` 与 `list "spec" <map> "base.map"`。
- output：字段 YAML 片段；渲染结果为空时不输出。
- ownership：`base.field` 只渲染已归一化字段；本层负责字段生效与空值判断。

### Dependency: `base.map`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：已恢复的 map。
- output：YAML map 文本；非 map 时失败。
- ownership：`base.map` 执行最终类型门禁；本层不重复同类类型检查。

### Dependency: `definitions.objectMeta`

- availability：existing
- source：`templates/api-resources/Definitions/_ObjectMeta.tpl`
- operation：consume
- input：`metadata` 恢复后的 map，不附加 `_kind`、`_pkind`。
- output：可嵌入 `metadata` 下的字段片段；无有效输出时为空；非法入参中断。
- ownership：`definitions.objectMeta` 决定 `metadata` 的字段范围、默认值与校验；本层只决定是否调用与是否省略字段。

### Dependency: `core.persistentVolumeClaimSpec`

- availability：unavailable
- source：无
- operation：consume
- input：`spec` 恢复后的非空 map。
- output：可嵌入 `spec` 下的字段片段；调用契约固定，当前无实现。
- ownership：`spec` 的字段级渲染与校验全部归该子模板；本 change 只保留调用占位，不创建占位 `define`。

## 代码边界

### `templates/api-resources/Definitions/_PersistentVolumeClaimTemplate.tpl`

- access：write
- operations：add `definitions.persistentVolumeClaimTemplate`
- writable-scopes：该 define 的契约注释与正文

### `templates/api-resources/Definitions/_ObjectMeta.tpl`

- access：read
- operations：consume `definitions.objectMeta`

### `templates/api-resources/Definitions/_EphemeralVolumeSource.tpl`

- access：read
- operations：consume `definitions.persistentVolumeClaimTemplate` 调用契约

### `templates/base/_get.tpl`

- access：read
- operations：consume `base.get`

### `templates/base/_convert.tpl`

- access：read
- operations：consume `base.isFromYamlError`

### `templates/base/_field.tpl`

- access：read
- operations：consume `base.field`

### `templates/base/_types.tpl`

- access：read
- operations：consume `base.map`

## 验证设计

- 在 `/tmp/sd-kube-chart/` 新建最小 application Chart，加载真实的 `_PersistentVolumeClaimTemplate.tpl`、`_ObjectMeta.tpl` 与 `base` 模板，并为 `core.persistentVolumeClaimSpec` 提供同名最小 fixture；fixture 结果只证明本模板调用与分支行为，不证明真实依赖集成。
- 最小有效：`metadata` 提供 `name` 与 `labels`、`spec` 提供非空 map，渲染出 `metadata` 与 `spec`，且无 `---`、父键或控制字段。
- 较完整有效：`metadata` 含 `annotations` 与 `labels`、`spec` 含典型字段，输出与两个子模板对同一 map 的输出一致。
- 空值有效：缺失 `metadata`、`metadata: {}`、`metadata: null` 时只输出 `spec`。
- 关键失败：缺失 `spec`、`spec: {}`、`spec: null`、`metadata` 为 list、非 map 上下文、fixture 返回空内容或非法 YAML，均应中断并包含预期前缀。
