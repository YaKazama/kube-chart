# definitions.capabilities 设计

## 技术目标

- capability：`definitions.capabilities`
- artifact-type：Kubernetes 共享结构命名模板
- target：`templates/api-resources/Definitions/_Capabilities.tpl`

## 设计决策

### Decision: 同构字段顺序处理

- requirements：`字段顺序与字段生效`
- choice：按 `list "add" "drop"` 循环，两个字段共用同一处理闭环。
- rationale：字段类型和处理完全同构；循环顺序即官方字段顺序，避免重复代码。

### Decision: 输入解析与类型门禁

- requirements：`输入类型边界`
- choice：`base.get` 取值后使用 `fromYamlArray` 恢复；通过 `base.isFromYamlArrayError` 与 `cannot unmarshal ... into []interface {}` 错误尾判拦截非数组；逐项使用 `kindIs "string"` 拒绝非 string 元素。本模板的类型和名称错误使用 `[definitions.capabilities] <字段>: ...`。
- rationale：`fromYamlArray` 对标量或 map 输入返回单元素错误文本而非可识别错误，需要补充尾判；`base.slice.cleanup` 会接受布尔等标量，必须在清洗前限制元素类型。

### Decision: 拆分、校验与归一

- requirements：`capability 名称校验与归一`、`数组拆分与去重`
- choice：`base.slice.cleanup` 使用新增的 `SPLIT.SPACE_COMMA_SEMICOLON` 常量完成拆分、空项移除与去重；`K8S.CAPABILITY_NAME` 常量由本模板逐项 `mustRegexMatch` 校验，随后 `upper` 并再次 `mustUniq`。不做已知 capability 名称白名单。
- rationale：复用既有清洗能力；`base.slice.cleanup` 的正则校验发生在空项移除之前，首尾或连续分隔符产生的空 token 会误报，因此名称校验放在清洗之后；大写归一发生在清洗去重之后，需要再次去重以消除仅大小写不同的重复项；名称集合过大，只校验字符形态。

### Decision: 空字段与渲染

- requirements：`字段顺序与字段生效`
- choice：归一化结果为空时不调用 `base.field`；非空时以 `base.slice` 渲染。
- rationale：`base.field` 不推断字段生效，调用方必须先完成判空。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`update`
- input：`""`
- output：`fromYaml` 可解析的常量 Map；新增 `SPLIT.SPACE_COMMA_SEMICOLON`（运行时 `\s*[;,\s]+\s*`）与 `K8S.CAPABILITY_NAME`（运行时 `^(?i:cap_)?[A-Za-z][A-Za-z0-9_]*$`）
- ownership：`base.env` 统一维护固定正则；本 change 只追加两个键，不改既有键。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文> <add|drop>`
- output：YAML 字符串；字段缺失或为 null 时为空输出
- ownership：`base.get` 负责取值、别名识别与数据源优先级；本模板只消费字段值。

### Dependency: `base.slice.cleanup`

- availability：`existing`
- source：`templates/base/_collection.tpl`
- operation：`consume`
- input：`list <string array> <拆分正则>`
- output：YAML 列表；拆分后的空项移除并去重；不做名称校验
- ownership：`base.slice.cleanup` 负责拆分、数值化、空项移除与去重；本模板负责元素类型门禁、名称正则校验和大写归一。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 返回值
- output：布尔字符串
- ownership：依赖层识别 Helm 的数组解析错误形态。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list <字段名> <string 列表> "base.slice"`
- output：`key: value` YAML 片段；空列表不输出
- ownership：`base.field` 负责键输出与缩进；字段生效由本模板判断。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`slice`
- output：YAML 列表；非 slice 中断
- ownership：依赖层完成最终类型门禁与序列化。

## 代码边界

### `templates/base/_env.tpl`

- access：`write`
- operations：`add SPLIT.SPACE_COMMA_SEMICOLON`、`add K8S.CAPABILITY_NAME`
- writable-scopes：`SPLIT.SPACE_COMMA_SEMICOLON`、`K8S.CAPABILITY_NAME`

### `templates/api-resources/Definitions/_Capabilities.tpl`

- access：`write`
- operations：`add definitions.capabilities`
- writable-scopes：`definitions.capabilities`

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume base.get`

### `templates/base/_collection.tpl`

- access：`read`
- operations：`consume base.slice.cleanup`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume base.isFromYamlArrayError`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume base.field`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume base.slice`

### `templates/api-resources/Definitions/_SecurityContext.tpl`

- access：`write`
- operations：`update capability comments`
- writable-scopes：`capabilities` 字段的整体契约说明、边界说明与字段处理注释；不修改委托逻辑

## 验证设计

- 最小有效：`add` 仅含 `net_admin`，输出 `NET_ADMIN`。
- 较完整有效：同时提供 `add`、`drop`，覆盖大小写、`CAP_` 前缀、分号/逗号/空格复合字符串、首尾或连续分隔符与重复项，确认字段顺序、拆分和归一化后去重。
- 关键失败：非数组 `add`、非 string 元素、含 `-` 的名称分别中断。
- 集成：通过真实 `definitions.securityContext` 的 `capabilities` 字段调用，确认输出可解析为 SecurityContext 片段。
