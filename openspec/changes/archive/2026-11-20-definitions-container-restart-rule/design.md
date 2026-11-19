# definitions.containerRestartRule 设计

## 技术目标

- capability：`definitions.containerRestartRule`
- artifact-type：Helm 命名模板（Kubernetes 共享结构层，`api-resources/Definitions`）
- target：`templates/api-resources/Definitions/_ContainerRestartRule.tpl` 中的 `definitions.containerRestartRule`

## 设计决策

### Decision: 上下文类型分派

- requirements：`重启规则字段片段渲染`、`string 简写解析`
- choice：以 `kindOf .` 分派：`string` 使用 `K8S.CONTAINER_RESTART_RULE` 完整匹配后按捕获位取值；`map` 使用 `base.get` 逐字段取值；其他类型 `fail`。
- rationale：string 与 map 必须先归一为同一组 `action`、`exitCodes`，再共用字段校验与渲染流程。

### Decision: action 归一化

- requirements：`重启规则字段片段渲染`
- choice：string 分支由正则保证 action 为 `restart`，直接输出 `Restart`；map 分支经 `base.get` 与 `base.string.normalize` 取值，空值或 `lower` 后不是 `restart` 时 `fail`，通过后输出 `Restart`。
- rationale：`action` 由本模板拥有且不向下传递，两种上下文都必须归一为唯一合法输出。

### Decision: operator 原样下传

- requirements：`string 简写解析`
- choice：正则以 `([^\s,()]+)` 捕获 operator，直接使用捕获值构造子模板上下文，不做枚举比较、大小写转换或内容校验。
- rationale：operator 的枚举与内容合法性属于子模板职责；本模板只负责从简写中定位并原样传递该 token。

### Decision: exitCodes 构造与委托

- requirements：`重启规则字段片段渲染`、`string 简写解析`
- choice：string 分支构造 `dict "operator" <捕获值> "values" <整数列表>`；map 分支以 `base.get` 取 `exitCodes` 后 `fromYaml` 恢复，不做结构调整。两种上下文都以恢复后的 map 调用子模板并 `fromYaml` 回收结果；解析失败或结果为空时 `fail`，非空时以 `base.field` 和 `exitCodes` 父键输出。
- rationale：父层必须保证必填 `exitCodes` 生效，不能以省略字段掩盖子模板空结果。

### Decision: values 整数归一

- requirements：`string 简写解析`
- choice：括号内原文以 `SPLIT.COMMA` 拆分，逐项要求 `TYPES.INT` 完整匹配后转为 `int` 追加；整体为空时 `fail`。
- rationale：`values` 为 integer array，显式 `0` 必须保留；字符串直接下传会破坏 API 类型。

### Decision: map 未知键忽略

- requirements：`重启规则字段片段渲染`
- choice：map 分支只通过 `base.get` 读取 `action` 与 `exitCodes`，不遍历或输出其他键。
- rationale：未知键不属于 ContainerRestartRule 输出契约，也不应影响本模板判定。

### Decision: 父模板开放 string 元素

- requirements：`Container 字段片段渲染`
- choice：只在 `_Container.tpl` 的 `restartPolicyRules` 调用中追加 `"allowString" true`，与 `ports`、`resizePolicy` 保持一致；`definitions.container.array` 自身不改动。
- rationale：string 元素必须先通过父层元素类型门禁才能到达本模板，改动只作用于当前字段调用点。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`update`
- input：空字符串占位，`include` 后 `fromYaml` 恢复常量 Map。
- output：`K8S.CONTAINER_RESTART_RULE` 的运行时表达式更新为 `^((?i:restart))[\s,]+([^\s,()]+)[\s,]+\(([^()]+)\)$`，捕获顺序为 action、operator 与括号内 values 原文。
- ownership：`base.env` 只提供常量；匹配、捕获位提取与失败判断由 `definitions.containerRestartRule` 负责。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文> "action"` 与 `list <上下文> "exitCodes"`，不传占位参数。
- output：可 `fromYaml` 解析的 YAML 字符串；缺失时为空输出。
- ownership：`base.get` 负责数据源优先级与 `*Alias` 识别；本模板负责空值判定与失败。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list "action" "Restart" "quote"` 与 `list "exitCodes" <恢复后的 map> "base.map"`。
- output：单字段 YAML 片段；值渲染为空时不输出。
- ownership：`base.field` 只负责单键渲染与目标类型门禁；字段缺失、生效与失败判断在本模板。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 返回的 YAML 标量文本。
- output：解码后的 string；非 string 标量中断。
- ownership：`base.string.normalize` 只负责标量解码与类型门禁。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值。
- output：布尔字符串，`true` 表示解析失败。
- ownership：只识别 Helm 的解析错误形态。

### Dependency: `definitions.containerRestartRuleOnExitCodes`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：string 上下文为 `{operator, values}`；map 上下文为 `exitCodes` 原值。
- output：可 `fromYaml` 解析为非空 map 的 `ContainerRestartRuleOnExitCodes` 字段片段；空内容或非法 YAML 由本模板中断。
- ownership：子模板内部结构、operator 枚举与 values 数量上限由后续 change 实现；本模板只负责清洗 string 上下文、调用委托并以 `exitCodes` 为父键输出。

### Dependency: `definitions.container.array`

- availability：`existing`
- source：`templates/api-resources/Definitions/_Container.tpl`
- operation：`consume`
- input：`dict "key" "restartPolicyRules" "define" "definitions.containerRestartRule" "raw" <原始值> "allowString" true`。
- output：单字段 YAML 片段；无有效内容时不输出。
- ownership：`definitions.container.array` 负责数组解析、元素类型门禁与结果回收；本模板不重复这些判断。

## 代码边界

### `templates/base/_env.tpl`

- access：`write`
- operations：`update` `K8S.CONTAINER_RESTART_RULE` 及其紧邻注释
- writable-scopes：`K8S` 下 `CONTAINER_RESTART_RULE` 键及其紧邻注释

### `templates/api-resources/Definitions/_ContainerRestartRule.tpl`

- access：`write`
- operations：`add` `definitions.containerRestartRule`
- writable-scopes：整个文件

### `templates/api-resources/Definitions/_Container.tpl`

- access：`write`
- operations：`update` `restartPolicyRules` 字段闭环的 `include` 调用；`update` 该字段在整体契约注释与字段注释中的输入类型描述
- writable-scopes：`restartPolicyRules` 的整体契约注释行、字段注释行与 `include` 调用行

## 验证设计

- 真实依赖：`base.env`、`base.get`、`base.field`、`base.string.normalize`、`base.isFromYamlError`、`definitions.container.array` 全部加载真实实现。
- fixture：`/tmp/` 最小 Chart 中的同名 `definitions.containerRestartRuleOnExitCodes` 支持两种模式：回显收到的上下文，或返回空内容；只用于验证调用方行为，不作为真实子模板集成通过的证据。
- 最小有效：map 上下文 `{action: restart, exitCodes: {operator: in, values: [1]}}` 输出 `action: "Restart"` 与 `exitCodes`，且 `action` 在前。
- 较完整有效：string `restart Once (0, 1, 2)` 输出 `action: "Restart"`，fixture 收到 `{operator: Once, values: [0, 1, 2]}`，证明 operator 内容不限制且原样下传；`RESTART NotIn (7)` 同样输出 `action: "Restart"`。
- 关键失败：`action: stop`、缺少 `action`、缺少 `exitCodes`、`restart in ()`、`restart notin 1, 2`、`restart in (a, 1)`、空 string，以及 fixture 返回空内容。
- `definitions.container` 层：`restartPolicyRules: ["restart in (1, 2)"]` 时 string 元素被接受并交给 `definitions.containerRestartRule`；`restartPolicyRules: [1]` 中断。
