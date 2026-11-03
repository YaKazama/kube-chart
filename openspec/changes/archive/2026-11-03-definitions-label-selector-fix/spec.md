---
updated_at: "2026-11-03T04:16:50Z"
---

# Definitions LabelSelector Fix 规格

## MODIFIED Requirements

### Requirement: matchExpressions 字符串简写归一化

系统 MUST 接受可选的 `matchExpressions` array；非 array 输入 MUST 失败。`matchExpressions` 为 `null` 时 MUST 按缺失处理并省略该字段。元素允许 string 或 map。string 元素 MUST 按以下完整匹配规则解析：

- 等值/不等值：`<key><空白><操作符><空白><value>`，操作符为 `=`、`==` 或 `!=`；`=` 和 `==` 归一化为 `In`，`!=` 归一化为 `NotIn`，values 为单值列表。
- 集合：`<key><空白><操作符><空白>(<values>)`，操作符为 `in` 或 `notin` 且大小写不敏感；`in` 归一化为 `In`，`notin` 归一化为 `NotIn`。
- 存在性：`<key>` 归一化为 `Exists`；`!<key>` 归一化为 `DoesNotExist`，该形态不输出 values。

`<key>` MUST 由可选的 `<前缀>/` 段与必填的 `<名称>` 段组成。`<前缀>` 与 `<名称>` 均只允许字母、数字、`.`、`_`、`-`。前缀段 MUST 至多出现一次；`<前缀>` 与 `<名称>` MUST 非空。等值 value 只允许字母、数字、`.`、`_`、`-`；集合 values 允许逗号分隔和两侧空白。

`<key>` 中出现多个斜杠（如 `a/b/c`）、斜杠前为空（如 `/a`）或斜杠后为空（如 `a/`）时 MUST 视为不匹配。

不符合上述任一规则的 string 元素 MUST 失败并中断渲染；`in` 和 `notin` 的列表经清洗后为空时 MUST 同样失败并中断渲染。`In` 和 `NotIn` values MUST 经 `base.slice.cleanup` 清洗后输出为非空 string array；`Exists` 和 `DoesNotExist` MUST 不输出 values 字段。

清洗会把纯数字字符串转换为 int、去重并移除空字符串；输出前 MUST 逐项 `toString`，因此纯数字值以规范化十进制字符串输出，前导零和显式 `+` 不保留。

#### Scenario: 等值

- **WHEN** 字符串为 `environment = production`
- **THEN** 输出 `key: environment`、`operator: In`、`values: [production]`

#### Scenario: 不等值

- **WHEN** 字符串为 `tier != frontend`
- **THEN** 输出 `key: tier`、`operator: NotIn`、`values: [frontend]`

#### Scenario: 集合

- **WHEN** 字符串为 `environment in (production, qa)`
- **THEN** 输出 `key: environment`、`operator: In`、`values: [production, qa]`

#### Scenario: 存在性

- **WHEN** 字符串为 `partition` 或 `!partition1`
- **THEN** 分别输出 `operator: Exists` 和 `operator: DoesNotExist`，且不包含 `values`

#### Scenario: 带前缀键的等值

- **WHEN** 字符串为 `app.kubernetes.io/name = web`
- **THEN** 输出 `key: app.kubernetes.io/name`、`operator: In`、`values: [web]`

#### Scenario: 带前缀键的集合

- **WHEN** 字符串为 `app.kubernetes.io/name in (web, api)`
- **THEN** 输出 `key: app.kubernetes.io/name`、`operator: In`、`values: [web, api]`

#### Scenario: 带前缀键的存在性

- **WHEN** 字符串为 `app.kubernetes.io/name` 或 `!app.kubernetes.io/name`
- **THEN** 分别输出 `key: app.kubernetes.io/name`、`operator: Exists` 和 `operator: DoesNotExist`，且不包含 `values`

#### Scenario: 非法简写中断

- **WHEN** 字符串不匹配等值、集合和存在性任一规则
- **THEN** 失败并中断渲染

#### Scenario: 多斜杠中断

- **WHEN** 字符串的 key 含多个斜杠，如 `a/b/c = web`、`a/b/c in (x)` 或 `a/b/c`
- **THEN** 三种形态均不匹配，失败并中断渲染

#### Scenario: 斜杠缺段中断

- **WHEN** 字符串的 key 在斜杠前或斜杠后为空，如 `/a = web`、`a/ = web`
- **THEN** 不匹配，失败并中断渲染

#### Scenario: 集合为空中断

- **WHEN** 字符串为 `environment in ()`
- **THEN** 失败并中断渲染

## 非目标

- 不改变 `matchExpressions` 原生 map 元素的字段规则与 `values` 规则。
- 不改变 `matchLabels` 的必填性与渲染方式。
- 不引入标签键的严格格式校验（名称段长度、前缀 DNS 子域合法性、大小写限制）；该职责由 `definitions.labelSelectorRequirement` 承担。
