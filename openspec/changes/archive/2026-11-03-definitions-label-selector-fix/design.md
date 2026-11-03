# Definitions LabelSelector Fix 设计

## 技术目标

- capability：`definitions.labelSelector`
- artifact-type：常量正则
- target：`templates/base/_env.tpl` 的 `K8S.SELECTOR.EQUALITY_FOR_APPS`、`K8S.SELECTOR.SET_FOR_APPS`、`K8S.SELECTOR.EXISTS_FOR_APPS`

## 设计决策

### Decision: key 捕获组采用可选斜杠段

- requirements：`matchExpressions 字符串简写归一化`
- choice：三条正则的 key 捕获组统一改为 `([A-Za-z0-9._-]+(?:/[A-Za-z0-9._-]+)?)`，斜杠段整体为可选非捕获分组。
- rationale：字符类 `[A-Za-z0-9._/-]+` 会放行 `a/b/c`、`a/`、`/a`，与本 change「多斜杠与缺段不得放行」的约束冲突；可选分组把斜杠数量精确限定为 0 或 1，且两段均要求至少一个字符。

### Decision: 捕获组编号与语义保持不变

- requirements：`matchExpressions 字符串简写归一化`
- choice：`EQUALITY_FOR_APPS` 保持 `${1}`=key、`${2}`=操作符、`${3}`=值；`SET_FOR_APPS` 保持 `${1}`=key、`${2}`=操作符、`${3}`=值列表；`EXISTS_FOR_APPS` 保持 `${1}`=否定前缀、`${2}`=key。
- rationale：可选斜杠段必须写作非捕获分组 `(?:...)`，否则会新增捕获组并整体右移既有编号，导致 `mustRegexReplaceAll` 提取错位；`definitions.labelSelector` 的模板正文因此无需任何改动。

### Decision: 仅补斜杠结构，不放宽字段格式语义

- requirements：`matchExpressions 字符串简写归一化`
- choice：`<前缀>` 与 `<名称>` 复用同一字符集 `[A-Za-z0-9._-]`，不引入名称段长度、前缀 DNS 子域合法性、大小写限制。
- rationale：本 change 只修复结构性缺口；严格格式校验的归属已由本 change 非目标锁定为 `definitions.labelSelectorRequirement`。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`update`
- input：任意占位值；不读取其内容。
- output：可由 `fromYaml` 解析的常量 Map，`K8S.SELECTOR` 下三条正则为字符串常量。
- ownership：本层负责正则内容；`base.env` 仅声明静态常量，不执行校验。

### Dependency: `definitions.labelSelector`

- availability：`existing`
- source：`templates/api-resources/Definitions/_LabelSelector.tpl`
- operation：`consume`
- input：上下文 map，可含 `matchExpressions`、`matchLabels` 及内置别名。
- output：可嵌入 `selector` 下的 LabelSelector YAML 字段片段；非法入参中断渲染。
- ownership：`definitions.labelSelector` 负责归一化与委托；本 change 只提供其常量依赖，不修改其分支结构、失败消息与清洗职责。

### Dependency: `definitions.labelSelectorRequirement`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`dict "key" <string> "operator" <string>`，`In`/`NotIn` 时附 `values` 为 string array。
- output：非空 map；空、无效 YAML 或非 map 由调用方失败。
- ownership：该模板当前不存在且明确不在本 change 实现；本 change 的验证只覆盖正则匹配与捕获层，不覆盖完整渲染链路。

## 代码边界

### `templates/base/_env.tpl`

- access：`write`
- operations：`update` `K8S.SELECTOR.EQUALITY_FOR_APPS`、`K8S.SELECTOR.SET_FOR_APPS`、`K8S.SELECTOR.EXISTS_FOR_APPS` 三条常量值。
- writable-scopes：上述三个常量键的字符串值。

### `templates/api-resources/Definitions/_LabelSelector.tpl`

- access：`read`
- operations：`consume` `include "base.env"` 与三处 `mustRegexMatch`、`mustRegexReplaceAll` 调用。

## 验证设计

- 最小有效：加载真实 `_env.tpl`，用 `helm template` 对 `app = web`、`app != web`、`app in (a)`、`app notin (a)`、`app`、`!app` 断言匹配结果与修改前一致。
- 带前缀有效：同一 fixture 对 `app.kubernetes.io/name = web`、`app.kubernetes.io/name in (a, b)`、`app.kubernetes.io/name`、`!app.kubernetes.io/name` 断言三条正则匹配成功。
- 捕获提取：`mustRegexReplaceAll` 后取 `${1}`、`${2}`、`${3}`，断言 `app.kubernetes.io/name` 完整无截断、操作符与值正确。
- 关键失败：`a/b/c`、`a/`、`/a` 在三条正则下均不匹配。
- fixture 边界：`definitions.labelSelectorRequirement` 不可用，故验证不进入 `definitions.labelSelector` 的完整渲染链路；如需覆盖该链路，须在 `/tmp/` 提供同名 fixture，且只证明调用方行为。
