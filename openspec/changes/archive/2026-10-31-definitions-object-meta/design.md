# definitions.objectMeta 设计

## 技术目标

- capability：`definitions.objectMeta`
- artifact-type：Helm 命名模板（Kubernetes 原生 API 共享结构）
- target：`templates/api-resources/Definitions/_ObjectMeta.tpl` 中的 `definitions.objectMeta`

## 设计决策

### Decision: 上下文身份与输出顺序

- requirements：`上下文身份与输出边界`
- choice：以 map guard 拒绝非 map 上下文；按 `_pkind`、`_kind` 依次取值并以首个非空值确定有效身份；固定按 `annotations`、`generateName`、`labels`、`name`、`namespace` 输出。
- rationale：规格要求父身份覆盖、退回当前身份且控制字段不进入输出；身份解析直接使用 `base.get` 的既有数据源优先级。

### Decision: annotations 来源隔离

- requirements：`annotations 来源隔离`
- choice：按有效身份选择唯一来源键（默认 `annotations`，三种专用身份分别映射到 `podAnnotations`、`jobAnnotations`、`pvcAnnotations`），经 `base.get` 与 `fromYaml` 恢复后检查 YAML 错误和 string 值；只读取选定的键，不与其他注解键合并。
- rationale：规格锁定身份到来源键的映射及非法值失败边界，来源键切换本身即完成隔离。

### Decision: generateName 与 name 互斥

- requirements：`generateName 与 name 互斥`
- choice：以 `base.get` 解析 `name` 与 `generateName`；仅 `name` 为空且 `generateName` 非空时，经 `base.rfc` 的 `1035` 模式校验后渲染 `generateName` 并省略 `name`。
- rationale：规格要求显式空或缺失 `name` 时启用 `generateName`，`name` 非空时抑制，并传播校验失败。

### Decision: name 模式与嵌套排除

- requirements：`name 资源模式`
- choice：RBAC 四类身份传 `rbac`，`APIService` 传 `apiservice`，其他允许渲染的身份传 `name`；`PodTemplateSpec`、`JobTemplateSpec` 不渲染 `name`。
- rationale：规格锁定身份与校验模式的对应关系，并要求直接调用 `base.name`。

### Decision: labels 与 namespace 委托

- requirements：`labels 委托`、`namespace 委托与资源边界`
- choice：`labels` 固定调用 `base.labels` 并检查返回 map 结构与 string 值；`namespace` 仅在非嵌套、非 PVC、非集群级身份时调用 `base.namespace`；两者均透传 `.` 且不设默认值。
- rationale：规格要求沿用既有缺省契约，并排除指定资源身份。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [context, dot-path, type, mergeMode, required, alias, debug]`；本模板使用前两项。
- output：可由 `fromYaml` 恢复的 YAML 字符串；缺失时为空字符串。
- ownership：`base.get` 负责数据源优先级、取值、合并与序列化；本模板负责路径选择和身份判断。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 原始值, 渲染模板, 允许值列表]`。
- output：`key` 字段片段；空值省略；渲染模板决定序列化格式，类型不符时由渲染模板中断。
- ownership：`base.field` 负责字段格式、空值省略和类型模式；本模板负责传入字段值。

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：map 值。
- output：YAML 字符串；非 map 输入失败。
- ownership：`base.map` 负责 map 类型校验与序列化；本模板负责提供已恢复的 map。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值。
- output：字符串 `"true"` 或 `"false"`。
- ownership：`base.isFromYamlError` 负责识别错误 map；本模板决定是否中断。

### Dependency: `base.rfc`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：字符串，或 `list [value, mode]`；本模板对 `generateName` 传字符串并使用默认 `1035` 模式。
- output：校验通过的字符串；失败时中断。
- ownership：`base.rfc` 负责模式校验；本模板负责生效条件。

### Dependency: `base.labels`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：原始上下文 `.`。
- output：YAML 字符串，调用方经 `fromYaml` 恢复为 map；缺省与合并由既有契约决定。
- ownership：`base.labels` 负责标签缺省与合并；本模板负责恢复、校验并渲染返回 map。

### Dependency: `base.name`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：原始上下文 `.`，或 `list [context, mode]`。
- output：校验通过的名称字符串；失败时中断。
- ownership：`base.name` 负责名称取值、规范化和校验；本模板负责选择模式与省略条件。

### Dependency: `base.namespace`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：原始上下文 `.`。
- output：校验通过的 namespace 字符串，缺省为 `default`。
- ownership：`base.namespace` 负责缺省、规范化和校验；本模板负责资源身份排除。

## 代码边界

### `templates/api-resources/Definitions/_ObjectMeta.tpl`

- access：`write`
- operations：`update` `definitions.objectMeta`
- writable-scopes：`definitions.objectMeta`

## 验证设计

- 最小有效：普通资源身份仅提供 `name`，验证默认 `labels`、`namespace` 与五个字段的顺序。
- 完整有效：`_pkind` 覆盖、三种专用注解、通用注解不进入专用身份输出、显式空 `name` 启用 `generateName`、RBAC 与 `APIService` 模式、PVC 与嵌套模板排除。
- 关键失败：非 map 上下文、注解来源非 map 或非 string、`generateName` 不符合 `1035`、`base.name` 拒绝、`base.namespace` 拒绝。
- 真实依赖：`base.get`、`base.field`、`base.map`、`base.isFromYamlError`、`base.rfc`、`base.name`、`base.namespace` 使用仓库实现。
- Fixture 边界：`base.labels` 非法返回场景使用同名 fixture 替换，仅证明调用方失败分支，不证明 `base.labels` 集成本身。
