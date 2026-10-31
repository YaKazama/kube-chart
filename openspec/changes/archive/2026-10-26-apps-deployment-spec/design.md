# Apps DeploymentSpec 模板设计

## 技术目标

- capability：`apps.deploymentSpec`
- artifact-type：Helm 命名模板（library Chart）
- target：`templates/api-resources/Apps/_DeploymentSpec.tpl` 中的 `apps.deploymentSpec`

## 设计决策

### Decision: 标量字段闭环

- requirements：`integer 字段默认值与范围约束`、`paused 默认值`
- choice：按 Kubernetes API 字段顺序逐字段完成取值、默认值、运行时类型检查、integer 边界判断和 `base.field` 渲染；integer 接受原生整数或可由 `base.int` 校验的整数字符串，显式负数作为抑制信号且不回退默认值；paused 只接受原生 boolean，再由 `base.bool` 渲染。
- rationale：保持零值可观察、类型稳定和字段处理闭环，并满足 Helm 模板工程规则。

### Decision: Selector 清洗与标签合并

- requirements：`selector 必填与标签合并`
- choice：selector 缺失或 nil 时失败，显式空 map 保持有效；仅复制 `matchLabels` 和 `matchExpressions`，恢复 `base.labels` 的 map 输出，以 selector 标签为左值执行隔离合并，再把清洗结果传给 `definitions.labelSelector`。
- rationale：调用层拥有字段筛选和来源优先级，子模板只拥有 LabelSelector 内部结构。

### Decision: Strategy 多类型归一化

- requirements：`strategy 多类型归一化`
- choice：先区分有效 map 与 string；map 只复制 `type`、`rollingUpdate`，显式空 map 保持有效；string 使用 `SYS.YAML_QUOTED` 去除 YAML 外层引号，再以 `APPS.DEPLOYMENT.STRATEGY` 全量匹配并将捕获组归一化为 map，之后统一委托 `definitions.deploymentStrategy`。
- rationale：多类型只在调用层存在，依赖模板始终接收 map；正则由 `base.env` 集中管理。

### Decision: PodTemplateSpec 委托

- requirements：`template 必填透传`
- choice：把原始上下文只读传给 `core.podTemplateSpec`，对返回字符串执行非空、YAML 错误和 map 类型保护后渲染 `template`。
- rationale：PodTemplateSpec 的内部字段归属 core 能力，当前层只负责必填返回边界。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：空 string `""`
- output：可由 `fromYaml` 恢复的非空 YAML map；`SYS.YAML_QUOTED` 和 `APPS.DEPLOYMENT.STRATEGY` 必须为非空 string
- ownership：提供集中常量；当前模板负责解析、类型保护和字段失败消息。`APPS.DEPLOYMENT.STRATEGY` 的运行时值为 `^(Recreate|RollingUpdate)(?:\s+(.*))?$`，`${1}` 为 `type`，`${2}` 为可空 string `rollingUpdate`

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <当前上下文> <字段点分路径> [强制类型] [合并模式] [必填]`
- output：YAML string；缺失可选路径为空输出，必填或非法参数立即失败
- ownership：提供多层数据源取值；当前模板负责默认值、字段类型和业务边界

### Dependency: `base.labels`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：当前上下文 map
- output：可由 `fromYaml` 恢复的非空标签 map YAML
- ownership：生成基础标签；当前模板负责与 `selector.matchLabels` 左优隔离合并

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list <字段名> <已归一化值> [渲染模板] [允许值]`
- output：字段 YAML string；参数或渲染类型非法时失败
- ownership：只负责字段序列化；当前模板负责字段生效条件、默认值和错误上下文

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：map
- output：map YAML string；非 map 输入失败
- ownership：序列化已验证 map，不负责业务结构校验

### Dependency: `base.int`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：原生整数或整数字符串
- output：校验后的 integer YAML 标量；非法输入失败
- ownership：提供 integer 类型校验与渲染；当前模板负责默认值、负数抑制和上限

### Dependency: `base.bool`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：当前模板已确认的原生 boolean
- output：boolean YAML 标量；非法输入失败
- ownership：提供 boolean 渲染；当前模板负责拒绝非原生 boolean 输入

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：任意 `fromYaml` 返回值
- output：string boolean，仅错误 map 返回 `"true"`
- ownership：识别 Helm YAML 错误形态；当前模板负责真实类型和空值检查

### Dependency: `definitions.labelSelector`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：仅含 `matchLabels`、`matchExpressions` 的清洗 selector map
- output：非空 LabelSelector YAML map；空值、无效 YAML 或非 map 由当前模板失败
- ownership：依赖负责 LabelSelector 内部字段；当前模板负责必填、清洗和标签合并

### Dependency: `definitions.deploymentStrategy`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：仅含 `type`、`rollingUpdate` 的 map，允许显式空 map；string 分支的 `rollingUpdate` 保持 string
- output：DeploymentStrategy YAML map；空值、无效 YAML 或非 map 由当前模板失败
- ownership：依赖负责 DeploymentStrategy 内部字段；当前模板负责多类型识别与归一化

### Dependency: `core.podTemplateSpec`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：原始调用上下文 `.`，只读
- output：非空 PodTemplateSpec YAML map；空值、无效 YAML 或非 map 由当前模板失败
- ownership：依赖负责 PodTemplateSpec 内部字段；当前模板只负责必填委托和返回边界

## 代码边界

### `templates/api-resources/Apps/_DeploymentSpec.tpl`

- access：`write`
- operations：新增 `define "apps.deploymentSpec"` 及其紧邻中文契约注释
- writable-scopes：`apps.deploymentSpec`

### `templates/base/_env.tpl`

- access：`read`
- operations：消费 `base.env` 中的 `SYS.YAML_QUOTED`、`APPS.DEPLOYMENT.STRATEGY`

### `templates/base/_get.tpl`

- access：`read`
- operations：消费 `base.get`

### `templates/base/_k8s.tpl`

- access：`read`
- operations：消费 `base.labels`

### `templates/base/_field.tpl`

- access：`read`
- operations：消费 `base.field`

### `templates/base/_types.tpl`

- access：`read`
- operations：消费 `base.map`、`base.int`、`base.bool`

### `templates/base/_convert.tpl`

- access：`read`
- operations：消费 `base.isFromYamlError`

## 验证设计

- 在 `/tmp/` 最小 application Chart 中加载 write boundary 和现存 base read boundary；只为 3 个 unavailable 子模板提供满足上述最小输入/输出契约的同名 fixture。
- 最小有效场景覆盖建议默认值、必填 selector/template 和省略 strategy。
- 较完整有效场景覆盖整数字符串、显式零值、上限值、负数抑制、显式空 selector、selector 标签左优合并、matchExpressions、strategy map、string 和显式空 map。
- 关键失败场景覆盖标量类型错误、integer 超限、selector 缺失/nil/类型错误、strategy string 不匹配或类型错误，以及 3 个子模板的空值、YAML 错误或非 map 返回。
- 轻量静态检查只覆盖 write boundary 的空白、冲突标记和文件末尾换行；不声明真实子模板集成或完整 Chart 发布通过。
