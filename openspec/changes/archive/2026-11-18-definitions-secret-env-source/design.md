# definitions.secretEnvSource设计

## 技术目标

- capability：`definitions.secretEnvSource`
- artifact-type：Helm 命名模板
- target：`templates/api-resources/Definitions/_SecretEnvSource.tpl`

## 设计决策

### Decision: 独立 SecretEnvSource 片段模板

- requirements：`SecretEnvSource 字段片段`
- choice：在目标文件新增唯一命名模板 `definitions.secretEnvSource`，只渲染 `name`、`optional` 字段片段。
- rationale：draft 明确要求独立模板及字段片段边界，现有 `definitions.configMapEnvSource` 仅作为同构行为参考。

### Decision: 名称归一、校验与引用输出复用基础能力

- requirements：`名称归一与校验`
- choice：经 `base.get` 取值，由 `base.string.normalize` 解码为字符串，使用 `trim` 判空，再由 `base.rfc` 的 `1123sub` 校验，最后通过 `base.field` 以带引号标量输出 `name`。
- rationale：完整沿用 `definitions.configMapEnvSource` 的名称边界，并复用已存在的公共取值、解码、校验与字段渲染能力。

### Decision: optional 空值省略与布尔校验

- requirements：`optional 归一与省略`
- choice：经 `base.get` 取值并 `trim`，空结果省略；非空时剥离可选 YAML 外层引号，交由 `base.bool` 校验，再由 `base.field` 输出 `optional`。
- rationale：该路径保留原生布尔与合法字符串布尔值、保留显式 `false`，并统一拒绝其他表示。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：任意占位字符串，不读取其内容。
- output：可由 `fromYaml` 解析的常量 map；本 change 只读取 `SYS.YAML_QUOTED`。
- ownership：依赖层维护静态 YAML 引号正则；目标模板只消费该常量剥离 `optional` 外层引号。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：list `[上下文 map, "name" 或 "optional"]`。
- output：可解析的 YAML 标量文本；缺失、显式 `null` 和空字符串返回空结果。
- ownership：依赖层只负责安全取值；目标模板负责 trim、必填判断、类型约束和字段语义。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 输出且未经预先 trim、`fromYaml` 或拼接的 YAML 标量文本。
- output：解码后的字符串；空输入返回空字符串，非字符串或非法 YAML 标量中断渲染。
- ownership：依赖层只负责字符串解码；目标模板负责 trim、判空及后续名称校验。

### Dependency: `base.rfc`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：list `[trim 后的名称, "1123sub"]`。
- output：校验通过的字符串；不符合 RFC1123 Subdomain 或超过 253 个字符时中断渲染。
- ownership：依赖层负责名称正则与长度校验；目标模板负责传入归一后的名称。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：list `[字段名, 原始值, 渲染模板]`；本 change 使用 `name`、`quote` 与 `optional`、`base.bool`。
- output：`key: value` YAML 字段片段；渲染结果为空时不输出。
- ownership：依赖层负责单个字段的序列化与引号处理；目标模板负责字段选择、顺序和调用时机。

### Dependency: `base.bool`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：原生布尔值或字符串 `"true"`、`"false"`。
- output：`true` 或 `false`；其他类型或字符串中断渲染。
- ownership：依赖层负责布尔类型校验与文本返回；目标模板负责保留显式 `false` 并组装字段。

## 代码边界

### `templates/api-resources/Definitions/_SecretEnvSource.tpl`

- access：`write`
- operations：`add definitions.secretEnvSource`
- writable-scopes：`definitions.secretEnvSource` 命名模板的完整定义及其模板注释

### `templates/base/_env.tpl`

- access：`read`
- operations：`consume "base.env"`

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume "base.get"`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume "base.string.normalize"`

### `templates/base/_k8s.tpl`

- access：`read`
- operations：`consume "base.rfc"`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume "base.field"`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume "base.bool"`

## 验证设计

以下场景均使用 `/tmp/` 最小 application Chart 依赖当前 library Chart；真实依赖为已存在的 `base.*` 命名模板，不使用替身。

- 最小有效：仅传入 `name`，验证只输出带引号名称且不出现 `optional`。
- 较完整有效：传入带首尾空白的 `name`，以及原生 `false`、字符串 `"true"` 的 `optional`，验证名称归一、布尔输出及字段顺序。
- 关键失败：分别传入缺失或空白的 `name`、非字符串 `name`、非法或超长 `name`，以及非法 `optional`，验证渲染中断。
- 省略边界：分别传入缺失、显式 `null`、空字符串和仅空白字符串的 `optional`，验证字段被省略。
