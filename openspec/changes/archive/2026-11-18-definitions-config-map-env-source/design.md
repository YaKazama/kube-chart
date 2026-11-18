# definitions.configMapEnvSource 设计

## 技术目标

- capability：`definitions.configMapEnvSource`
- artifact-type：Helm 命名模板
- target：`templates/api-resources/Definitions/_ConfigMapEnvSource.tpl`

## 设计决策

### Decision: name 归一与校验

- requirements：`name 归一与校验`
- choice：通过 `base.get` 取 `name`，交由 `base.string.normalize` 解码，再 `trim` 并判空；非空名称使用 `base.rfc` 的 `1123sub` 模式校验，最后通过 `base.field` 以带引号标量输出。
- rationale：规格要求先移除首尾空白再执行 RFC1123 Subdomain 与 253 字符校验；`base.rfc` 已提供该模式，现有选择器模板也采用此调用边界。

### Decision: optional 省略与布尔归一

- requirements：`optional 渲染与省略`
- choice：通过 `base.get` 取 `optional`，使用 `base.env` 的 `SYS.YAML_QUOTED` 剥离一层 YAML 引号后 `trim`；结果为空时不调用 `base.field`，非空结果交给 `base.field` 并以 `base.bool` 渲染。
- rationale：规格要求空值省略、显式 `false` 保留且非法值中断；`base.field` 不推断字段是否生效，调用方必须先完成省略判断。

### Decision: 字段片段顺序

- requirements：`ConfigMapEnvSource 片段`
- choice：在 `definitions.configMapEnvSource` 内先输出 `name`，再输出 `optional`，不输出父键或数组包装。
- rationale：规格固定字段顺序为 `name`、`optional`，且只允许字段片段输出。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：空字符串 `""`。
- output：可解析为常量 map 的 YAML 字符串；本模板只读取 `SYS.YAML_QUOTED`。
- ownership：`base.env` 提供静态正则常量，本模板负责在提取 `optional` 时应用该常量。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文 map> <"name"|"optional">`。
- output：YAML 字符串；缺失、`null` 或空值返回空输出。
- ownership：`base.get` 负责取值与序列化，本模板负责字段存在性、归一和失败边界。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 返回的 YAML 标量文本。
- output：解码后的字符串；空输入返回空字符串，非字符串或非法 YAML 标量中断渲染。
- ownership：`base.string.normalize` 负责 YAML 标量解码与字符串类型门禁，本模板负责 `trim`、判空和名称规则校验。

### Dependency: `base.rfc`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：`list [<name>, "1123sub"]`。
- output：校验通过的名称字符串；空值、正则不匹配或超过 253 字符时中断渲染。
- ownership：`base.rfc` 负责 RFC1123 Subdomain 与长度校验，本模板负责在调用前完成 `trim` 和必填判断。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [<key>, <value>, <"quote"|"base.bool">]`。
- output：非空值渲染为 YAML 键值对，空渲染结果不输出字段。
- ownership：`base.field` 负责键值对格式与引号输出，本模板负责字段顺序和仅在字段生效时调用。

### Dependency: `base.bool`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：原生布尔值或字符串 `"true"`、`"false"`。
- output：布尔字符串；其他值中断渲染。
- ownership：`base.bool` 负责布尔类型门禁，本模板负责先排除应省略的空值。

## 代码边界

### `templates/api-resources/Definitions/_ConfigMapEnvSource.tpl`

- access：`write`
- operations：`add` `definitions.configMapEnvSource`
- writable-scopes：`define "definitions.configMapEnvSource"` 及其契约注释

### `templates/base/_env.tpl`

- access：`read`
- operations：`consume` `SYS.YAML_QUOTED`

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume` `base.get`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` `base.string.normalize`

### `templates/base/_k8s.tpl`

- access：`read`
- operations：`consume` `base.rfc`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.bool`

## 验证设计

- 最小有效场景：在 `/tmp/` 最小 application Chart 中加载当前 Chart 的真实 `base.*` 能力，调用 `definitions.configMapEnvSource` 仅传 `name`，确认输出仅有 `name`。
- 较完整有效场景：传入带首尾空白的 `name`，并分别传入 `optional: false` 与 `optional: "true"`，确认名称已 `trim`、字段顺序为 `name`、`optional` 且布尔值正确。
- 关键失败场景：缺少 `name`、空白 `name`、非法 RFC1123 Subdomain、非字符串 `name`、非法 `optional` 值均中断渲染。
- 省略边界场景：`optional` 为 `null`、空字符串或仅空白字符串时不输出该字段。
