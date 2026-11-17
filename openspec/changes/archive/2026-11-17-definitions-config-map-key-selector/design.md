# definitions.configMapKeySelector 设计

## 技术目标

- capability：`definitions.configMapKeySelector`
- artifact-type：Kubernetes 原生 API 同域共享结构模板（`ConfigMapKeySelector`）
- target：`templates/api-resources/Definitions/_ConfigMapKeySelector.tpl`

## 设计决策

### Decision: 单文件承载并按官方字段顺序渲染

- requirements：`字段渲染顺序与类型`
- choice：新建 `templates/api-resources/Definitions/_ConfigMapKeySelector.tpl`，只包含 `definitions.configMapKeySelector` 一个 define，按 `key` → `name` → `optional` 顺序处理。
- rationale：共享结构文件围绕与文件名对应的主模板组织；三个字段各自独立，无拆分收益；官方字段表顺序为 `key`、`name`、`optional`。

### Decision: key 与 name 用自控空值校验替代 base.get 必填参数

- requirements：`必填字段校验`
- choice：`key` 与 `name` 均以 `base.get` 取值（不启用必填参数），经 `base.string.normalize` 解码并 `trim` 后自行判空；为空时以 `[definitions.configMapKeySelector] <字段>: required field is missing or empty` 中断。
- rationale：`base.get` 的必填参数失败消息使用 `[base.get]` 前缀，无法满足失败消息统一为 `[模板名] 字段路径: 错误原因`；取值仍由 `base.get` 负责，判空与消息归本层。

### Decision: name 复用 base.rfc 的 1123sub 模式

- requirements：`name 按 RFC1123 Subdomain 校验`、`RFC 校验能力新增 Subdomain 模式`
- choice：`name` 判空后直接 `include "base.rfc" (list $name "1123sub")`，长度与字符规则均由该能力收口；本模板不做长度判断，也不直接调用正则。
- rationale：项目规则要求复用依赖层已有能力，不得内联已提供的校验逻辑；`base.rfc` 已统一封装正则、长度上限与失败消息，为本模板重写一份会形成同一规则的重复实现。

### Decision: 为 base.rfc 追加 1123sub 分支与常量

- requirements：`RFC 校验能力新增 Subdomain 模式`
- choice：在 `templates/base/_k8s.tpl` 的 `base.rfc` 中，于既有三个 `else if` 分支后追加 `1123sub`：正则取 `$const.RFC.RFC1123_SUBDOMAIN`，`modeLabel` 为 `RFC1123 Subdomain`，`maxLen` 为 `253`；同时更新其契约注释中的模式清单与示例。
- rationale：`base.rfc` 已把「正则 + 长度 + 失败消息」三件事统一在一个模式分支里，追加分支即可复用全部机制；常量需新增，因为现有 `RFC1035`、`RFC1123` 均为 Label 规则，不含点；追加 `else if` 不改动既有分支，旧模式行为与消息保持原样。

### Decision: optional 用 base.get 原始输出的引号形态区分原生布尔与字符串

- requirements：`optional 只接受原生布尔值`
- choice：`optional` 以 `base.get` 取值并 `trim`；非空时，若 `SYS.YAML_QUOTED` 命中（说明原值是字符串）或值不是 `true`/`false`，则以 `[definitions.configMapKeySelector] optional: must be boolean` 中断；否则交给 `base.bool` 并以 `base.bool` 渲染。
- rationale：`base.get` 返回 YAML 文本，原生布尔序列化为裸 `true`/`false`，字符串 `"true"` 会被序列化为带引号形态，用既有 `SYS.YAML_QUOTED` 即可区分，无需绕过取值层直接读原生值；`base.bool` 负责最终布尔语义与输出，`false` 也能正常输出。

### Decision: 父级 configMapKeyRef 必需段数改为 2

- requirements：`父级必需段数修正`
- choice：把 `templates/api-resources/Definitions/_EnvVarSource.tpl` 配置表中 `configMapKeyRef` 的 `required` 从 `1` 改为 `2`。
- rationale：本能力要求 `key` 与 `name` 同时非空，单段字符串必然产生缺 `key` 的上下文；在组装前拒绝比依赖子模板报错更符合「尽早报错」，且改动只涉及该配置项的一个数值。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, 点分路径]`；本能力使用 `key`、`name`、`optional` 三条单层路径，不传强制类型与必填参数。
- output：YAML 字符串；路径缺失时为空输出。
- ownership：取值与别名识别由 `base.get` 负责；必填判空、类型判定与失败消息由本能力负责。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 的原始输出，不得预先 trim。
- output：解码后的 string；空输入返回空字符串；非 string 标量中断。
- ownership：YAML 标量还原与类型失败由该模板负责；本能力只消费结果并判空。

### Dependency: `base.bool`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：原生 bool，或字面量字符串 `"true"` / `"false"`。
- output：布尔字符串；其他输入中断。
- ownership：布尔语义与输出由该模板负责；输入是否为原生布尔由本能力前置判定。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 值, 渲染模板]`；`key`、`name` 使用 `quote`，`optional` 使用 `base.bool`。
- output：单字段 YAML 片段，空值不输出。
- ownership：渲染格式与引号由该模板负责；字段生效判断由本能力负责。

### Dependency: `base.rfc`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`update`
- input：`list [字符串, 模式]`；本能力传入 `list $name "1123sub"`。
- output：校验通过的字符串；不符合模式时中断，失败消息使用 `[base.rfc]` 前缀。
- ownership：正则选择、长度上限、空字符串拦截与失败消息由 `base.rfc` 负责；本 change 只追加 `1123sub` 模式，不改动既有 `1035`、`1123`、`rbac` 分支。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`update`
- input：占位空字符串，经 `fromYaml` 恢复常量 Map。
- output：常量 Map；本 change 新增 `RFC.RFC1123_SUBDOMAIN`，`base.rfc` 读取它，本能力自身只读取 `SYS.YAML_QUOTED`。
- ownership：常量定义与结构有效性由该模板负责；本 change 只新增 `RFC.RFC1123_SUBDOMAIN` 一个键，不改动其他键。

## 代码边界

### `templates/api-resources/Definitions/_ConfigMapKeySelector.tpl`

- access：`write`
- operations：add `definitions.configMapKeySelector`
- writable-scopes：整个新建文件

### `templates/base/_env.tpl`

- access：`write`
- operations：add `RFC.RFC1123_SUBDOMAIN`
- writable-scopes：`RFC` 映射下新增的 `RFC1123_SUBDOMAIN` 单行键

### `templates/base/_k8s.tpl`

- access：`write`
- operations：update `base.rfc` 增加 `1123sub` 模式分支，并同步其契约注释中的模式清单与示例
- writable-scopes：`base.rfc` 内部 mode 分支链末尾新增的 `else if eq $mode "1123sub"` 块，以及该 define 紧邻上方的整体契约注释中模式清单与示例对应的行

### `templates/api-resources/Definitions/_EnvVarSource.tpl`

- access：`write`
- operations：update `configMapKeyRef` 配置项的 `required` 值 `1` → `2`
- writable-scopes：`$sources` 列表中 `configMapKeyRef` 条目的 `required` 数值

## 验证设计

- 最小有效：真实 `templates/base/` 与 `_ConfigMapKeySelector.tpl` 加载到 `/tmp/` 最小 application Chart，输入 `key` 与 `name`，断言两个字段均以双引号输出。
- 较完整有效：三字段齐全时按 `key`、`name`、`optional` 顺序输出；`optional: false` 仍输出；含额外键时只输出三个官方字段。
- 关键失败：`key` 缺失、`name` 缺失、`name` 为空白、`name` 含下划线、`name` 超过 253 字符、`name` 段首尾为连字符、`optional` 为字符串 `"true"`、`optional` 为数字，均中断；`key`、`name` 的失败消息含对应字段名，`name` 规则违规的失败消息含实际取值。
- 忽略边界：只提供必需字段时不输出 `optional`；额外键不产生输出。
- 正则常量：验证必须加载真实 `templates/base/_env.tpl`，不得用同名 fixture 替代被新增的常量。
- 共享能力回归：加载真实 `templates/base/_k8s.tpl`，对 `1035`、`1123`、`rbac` 三个既有模式分别用合法与非法取值各验一次，确认结果与失败消息未受新增分支影响。
- 父级回归：加载真实 `_EnvVarSource.tpl`，`configMapKeyRef` 为 `cfg` 时不组装该字段且输出为空，为 `cfg LOG_LEVEL` 时组装并委托本能力。
