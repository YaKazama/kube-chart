---
updated_at: "2026-11-08T10:35:34Z"
---

# NodeSelectorTerm 共享结构规格

## Purpose

为 Kubernetes `NodeSelectorTerm` 对象提供共享结构渲染入口，把父级传入的 `matchExpressions` 与 `matchFields` 统一归一化为原生 `NodeSelectorRequirement` 结构，并按 API 字段顺序渲染为可嵌入的字段片段。

## ADDED Requirements

### Requirement: 渲染 NodeSelectorTerm 字段片段

系统 MUST 从入参 map 读取 `matchExpressions` 与 `matchFields`，并按 Kubernetes API 字段顺序输出 `matchExpressions` 先于 `matchFields`。

系统 MUST 输出可作为单个 `NodeSelectorTerm` 内容的 YAML 字段片段，返回值可以被调用方解析为 map。

两个字段都无有效内容时，系统 MUST 返回空字符串，MUST NOT 输出空字段或空 map。

系统 MUST 识别 `matchExpressions`、`matchFields` 的同级 `<键名>Alias`；非空别名 MUST 优先于同名规范键，别名缺失或为空时 MUST 回退同名规范键。

入参中除 `matchExpressions`、`matchFields` 及其同级别名以外的字段 MUST 被忽略，MUST NOT 参与输出。

系统 MUST NOT 输出 `status` 或规格未定义的其他字段。

#### Scenario: 两个字段同时提供

- **WHEN** 入参同时提供非空的 `matchExpressions` 与非空的 `matchFields`
- **THEN** 输出先包含 `matchExpressions`、后包含 `matchFields`

#### Scenario: 只提供一个字段

- **WHEN** 入参只提供 `matchExpressions` 与 `matchFields` 中的一个
- **THEN** 输出只包含该字段

#### Scenario: 两个字段都为空

- **WHEN** 两个字段缺失，或归一化后都没有有效条目
- **THEN** 返回空字符串，不输出任何字段

#### Scenario: 别名优先

- **WHEN** 入参同时提供 `matchExpressions` 与取值不同的非空 `matchExpressionsAlias`
- **THEN** 输出使用 `matchExpressionsAlias` 的取值

#### Scenario: 未定义字段被忽略

- **WHEN** 入参除 `matchExpressions`、`matchFields` 外还包含其他键
- **THEN** 输出不包含这些键

### Requirement: 归一化条目形态

`matchExpressions` 与 `matchFields` MUST 接受 string 数组和原生 `NodeSelectorRequirement` map 数组两种输入形态。

同一数组中 MUST 允许 string 条目与 map 条目混用，每个条目 MUST 独立解析。

条目不是 string 或 map 时 MUST 中断渲染。

字段取值不是数组时 MUST 中断渲染。

MUST 移除 `null`、空白字符串与空 map 条目；MUST 对归一化后的条目去重，重复条目只输出一项。

#### Scenario: 混合形态

- **WHEN** 同一数组同时包含 string 条目与 map 条目
- **THEN** 两类条目都按各自形态解析并输出

#### Scenario: 重复条目

- **WHEN** 数组包含两个归一化后完全相同的条目
- **THEN** 输出只包含一项

#### Scenario: 空条目

- **WHEN** 数组包含 `null`、空白字符串或空 map 条目
- **THEN** 输出不包含这些条目

#### Scenario: 条目类型非法

- **WHEN** 数组元素为数字或布尔值
- **THEN** 渲染中断并返回错误

#### Scenario: 字段不是数组

- **WHEN** `matchExpressions` 或 `matchFields` 为 map、字符串或数字
- **THEN** 渲染中断并返回错误

### Requirement: 解析 string 条目

string 条目 MUST 只支持三类形态：

- 第一类：`<key> <operator> <value>`，`<operator>` 仅限 `!=`、`==`、`=`、`>`、`<`，`<value>` MUST 为单个不含空白、逗号与括号的 token。
- 第二类：`<key> in (<value>[, <value>...])` 与 `<key> notin (<value>[, <value>...])`，操作符后 MUST 紧跟圆括号列表。
- 第三类：裸 `<key>` 与 `!<key>`，MUST NOT 携带操作符与值。

操作符 token MUST 大小写不敏感，并按以下映射归一化为大小写敏感的规范枚举：`=`、`==`、`in` 为 `In`；`!=`、`notin` 为 `NotIn`；`>` 为 `Gt`；`<` 为 `Lt`。

裸 `<key>` MUST 归一化为 `Exists`，`!<key>` MUST 归一化为 `DoesNotExist`，两者 MUST NOT 携带 `values`。

`gt`、`lt`、`exists`、`doesnotexist` MUST NOT 作为操作符 token；`!` MUST NOT 与操作符组合。

第一类的 `<value>` MUST NOT 被圆括号包裹，也 MUST NOT 再按空白或逗号二次拆分。

第二类 MUST 只按逗号分隔括号内文本，空白 MUST NOT 作为分隔符，空段 MUST 被移除；`(a b)` MUST 得到单元素 `a b`。

第一类与第二类清洗后的 `values` MUST 采用同一套清洗规则，同一取值在两类中 MUST 得到相同结果。

string 条目无法匹配上述任何形态时 MUST 中断渲染，错误信息 MUST 包含所属字段名与条目下标。

#### Scenario: 等值与不等值简写

- **WHEN** 条目为 `c = d`、`c == d` 或 `c != d`
- **THEN** 分别归一化为 `operator` `In`、`In`、`NotIn`，`values` 均为单元素 `d`

#### Scenario: 集合简写

- **WHEN** 条目为 `aa in (xx1, xx2, xx3)` 或 `aa notin (xx1, xx2)`
- **THEN** `operator` 分别为 `In`、`NotIn`，`values` 为括号内按逗号拆分出的元素

#### Scenario: 存在性简写

- **WHEN** 条目为裸 `c` 或 `!c`
- **THEN** `operator` 分别为 `Exists`、`DoesNotExist`，且不产生 `values`

#### Scenario: 比较运算符简写

- **WHEN** 条目为 `c > 7` 或 `c < 9`
- **THEN** `operator` 分别为 `Gt`、`Lt`，`values` 均为单元素

#### Scenario: 操作符大小写不敏感

- **WHEN** 条目为 `c IN (a)` 或 `c NotIn (a)`
- **THEN** `operator` 归一化为 `In`、`NotIn`

#### Scenario: 文本比较运算符不被接受

- **WHEN** 条目为 `c gt 3`、`c lt 5` 或 `c GT 3`
- **THEN** 渲染中断并返回错误

#### Scenario: 集合运算符缺少括号

- **WHEN** 条目为 `c in a` 或 `c notin a, b`
- **THEN** 渲染中断并返回错误

#### Scenario: 第一类值不接受括号

- **WHEN** 条目为 `c > (7)` 或 `c = (7)`
- **THEN** 渲染中断并返回错误

#### Scenario: 括号内空白不拆分

- **WHEN** 条目为 `c in (a b)`
- **THEN** `values` 为单元素 `a b`

#### Scenario: 无法解析的条目

- **WHEN** 条目为 `c != d e`、`c > 1 2`、`c exists d`、`!c != d`、`!c > 1` 或 `c !=`
- **THEN** 渲染中断并返回错误

### Requirement: 校验 key

`matchExpressions` 与 `matchFields` 的 `key` MUST 按 Kubernetes 标签键语法校验，MUST NOT 按字段路径语法放行。

`key` MUST 为非空 string，MUST 由至多一个 `/` 分隔为可选的 DNS 前缀段与名称段；名称段与前缀段 MUST 符合 Kubernetes 标签键的字符与长度约束，前缀段长度 MUST NOT 超过 253 个字符。

`key` 缺失、为 `null`、为空字符串或不符合上述语法时 MUST 中断渲染，错误信息 MUST 包含所属字段名与条目下标。

#### Scenario: 合法 key

- **WHEN** `key` 为 `c` 或 `app.kubernetes.io/name`
- **THEN** 正常渲染

#### Scenario: key 缺失或为空

- **WHEN** map 条目不含 `key`，或 `key` 为空字符串
- **THEN** 渲染中断并返回错误

#### Scenario: key 语法非法

- **WHEN** `key` 含两个及以上 `/`，名称段以 `-` 开头，或前缀段含大写字母
- **THEN** 渲染中断并返回错误

#### Scenario: 字段路径写法

- **WHEN** `key` 为不符合标签键语法的字段路径写法
- **THEN** 渲染中断并返回错误

### Requirement: 校验 operator 与 values 的适用关系

归一化后的 `operator` MUST 是 `DoesNotExist`、`Exists`、`Gt`、`In`、`Lt`、`NotIn` 之一，且 MUST 大小写敏感。

原生 map 条目的 `operator` 输入 MUST 大小写不敏感地识别上述六个取值；超出该枚举时 MUST 中断渲染。

`operator` 为 `In` 或 `NotIn` 时，`values` MUST 非空。

`operator` 为 `Exists` 或 `DoesNotExist` 时，`values` MUST 为空；提供非空 `values` 时 MUST 中断渲染。

`operator` 为 `Gt` 或 `Lt` 时，`values` MUST 恰好包含一个元素，该元素 MUST 为整数；非整数或元素数量不为 1 时 MUST 中断渲染。

`Gt`、`Lt` 的整数取值 MUST 规范化：`07` MUST 输出为 `7`，`-07` 输出为 `-7`，`+3` 输出为 `3`，`0000`、`-0`、`+0` 输出为 `0`，显式 `0` MUST 合法。

`In`、`NotIn` 的 `values` 元素 MUST 与其他运算符一样经过同一套清洗规则，数字字符串 MUST 按清洗结果输出。

`values` 元素 MUST NOT 校验字符集，与 Kubernetes 标签值一致只校验 `key`。

#### Scenario: In 缺少 values

- **WHEN** `operator` 为 `In` 且清洗后 `values` 为空
- **THEN** 渲染中断并返回错误

#### Scenario: Exists 携带 values

- **WHEN** `operator` 为 `Exists` 且提供非空 `values`
- **THEN** 渲染中断并返回错误

#### Scenario: 比较运算符元素数量非法

- **WHEN** 原生 map 条目的 `operator` 为 `Gt` 且 `values` 有两个元素
- **THEN** 渲染中断并返回错误

#### Scenario: 比较运算符取值非整数

- **WHEN** 条目为 `c > abc`、`c < 3.5`，或原生 map 条目的 `Gt` 值非整数
- **THEN** 渲染中断并返回错误

#### Scenario: 比较运算符取值带前导零

- **WHEN** 条目为 `c > 07`、`c > -07` 或 `c > +3`
- **THEN** `values` 分别为 `7`、`-7`、`3`

#### Scenario: 数值在两类路径上一致

- **WHEN** 条目分别为 `c = 07` 与 `c in (07)`
- **THEN** 两者 `values` 均为单元素 `7`

#### Scenario: 非标签字符集的值

- **WHEN** `values` 元素包含标签值字符集以外的字符
- **THEN** 正常渲染，不中断

### Requirement: 委托 definitions.nodeSelectorRequirement

系统 MUST 把每个归一化后的条目作为上下文委托 `definitions.nodeSelectorRequirement`，并以该模板返回的 map 作为数组元素。

传给子模板的上下文 MUST 始终包含 `key`(string) 与 `operator`(string)；仅在存在有效 `values` 时包含 `values`(string array)，无有效值时 MUST NOT 包含 `values` 键。

系统 MUST NOT 在子模板内重复进行 `values` 的拆分、去空、去重或约束校验。

子模板返回内容无法解析为 YAML map 时 MUST 中断渲染。

#### Scenario: 子模板收到清洗后的上下文

- **WHEN** 条目为 `aa in (xx1, xx2, 123333)`
- **THEN** 子模板收到的上下文为 `key` `aa`、`operator` `In`、`values` 为 `xx1`、`xx2`、`123333` 三个 string

#### Scenario: 无 values 的上下文

- **WHEN** 条目为裸 `c`、`!c`，或 map 条目的 `operator` 为 `Exists`、`DoesNotExist`
- **THEN** 子模板收到的上下文不包含 `values` 键

#### Scenario: 子模板返回非法 YAML

- **WHEN** `definitions.nodeSelectorRequirement` 的返回值无法解析为 map
- **THEN** 渲染中断并返回错误

## 非目标

- 不创建或修改 `definitions.nodeSelectorRequirement`。
- 不校验 `values` 元素的字符集与长度。
- 不处理数值清洗的整数溢出，相关风险记录在 change 内 `TODO.md`。
- 不负责父级 `NodeSelectorTerms` 数组的取值、顺序与去重。
- 不输出 `status` 或其他规格未定义字段。
