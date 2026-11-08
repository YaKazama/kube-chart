# NodeSelectorTerm 共享结构任务

## 实施

- [x] T1 `templates/base/_env.tpl`：在 `writable-scopes` 内 `add` `K8S.SELECTOR.NODE_TERM_FOR_APPS` 与 `K8S.SELECTOR.NODE_TERM_VALUES_FOR_APPS` 两个键及其紧邻中文注释：前者为大小写不敏感的条目结构正则，含 `!`、`key`、运算符、values 原文四个捕获组；后者限定 values 原文只能是括号列表或单个不带空白、逗号与括号的 token；对应 `Decision: 新增解析正则常量`。
- [x] T2 `templates/api-resources/Definitions/_NodeSelectorTerm.tpl`：新建文件，在 `writable-scopes` 内 `add` 紧邻 `define` 之前的中文整体契约注释与 `define "definitions.nodeSelectorTerm"` 骨架，并实现两个字段的读取与数组归一化：按固定字段顺序 `base.get` 取值、空输出跳过、`fromYamlArray`、`base.isFromYamlArrayError` 保护、非数组中断；对应 `Decision: 目标文件与命名模板归属`、`Decision: 字段读取与数组解析`。
- [x] T3 `templates/api-resources/Definitions/_NodeSelectorTerm.tpl`：在 `writable-scopes` 内实现 string 条目归一化：`mustRegexMatch` 与四组提取、`!` 与运算符互斥即中断、六种运算符映射、裸 key 与 `!` 前缀映射 `Exists`/`DoesNotExist`、`NODE_TERM_VALUES_FOR_APPS` 形态校验、按运算符 token 类别判定括号一致性、括号内值与单值统一走 `base.slice.cleanup` 搭配 `SPLIT.COMMA` 清洗与 `toStrings` 回写，并补齐条目级中文注释；对应 `Decision: string 条目归一化`。
- [x] T4 `templates/api-resources/Definitions/_NodeSelectorTerm.tpl`：在 `writable-scopes` 内实现原生 map 条目归一化：`base.get` 取 `key`、`operator`、`values`，`key` 标量还原与 `SYS.YAML_QUOTED` 剥离，`operator` 六枚举映射，`values` 的 `fromYamlArray`、`base.isFromYamlArrayError`、`mustWithout` 与 `base.slice.cleanup` 清洗，并补齐条目级中文注释；对应 `Decision: 原生 map 条目归一化`。
- [x] T5 `templates/api-resources/Definitions/_NodeSelectorTerm.tpl`：在 `writable-scopes` 内实现校验闭环：`splitList "/"` 段数判断、`mustRegexMatch` 搭配 `KEY_NAME_FOR_APPS` 与 `KEY_PREFIX_FOR_APPS`、前缀 253 长度上限，以及按 `operator` 分派的 `values` 约束校验（`In`/`NotIn` 非空、`Exists`/`DoesNotExist` 无值、`Gt`/`Lt` 单值且匹配 `TYPES.INT`），并补齐校验级中文注释；对应 `Decision: key 语法校验`、`Decision: values 约束校验`。
- [x] T6 `templates/api-resources/Definitions/_NodeSelectorTerm.tpl`：在 `writable-scopes` 内实现收集与输出闭环：跳过 `null`、空白字符串与空 map 条目、构造上下文 dict、`mustUniq` 去重、逐条 `include "definitions.nodeSelectorRequirement"`、`fromYaml` 与 `base.isFromYamlError` 保护、按字段顺序用 `base.field` 搭配 `base.slice` 输出、两字段皆空时返回空字符串；对应 `Decision: 去重、委托与输出`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（`definitions.nodeSelectorRequirement` 为同名回显 fixture）：只提供 `matchExpressions: ["c != d"]`，验证输出只含 `matchExpressions`，fixture 收到 `key` `c`、`operator` `NotIn`、`values` 单元素 `d`，且不出现 `matchFields`。
- [x] V2 `/tmp/` 最小 application Chart（fixture）：提供 `matchExpressions: ["c", "!c", "aa in (xx1, xx2, xx3)", "c > 07"]` 与 map 形态的 `matchFields`，验证输出字段顺序为 `matchExpressions` 在前、六个 `operator` 映射正确、`values` 均为 string、`07` 归一化为 `7`、`Exists` 与 `DoesNotExist` 的上下文不含 `values` 键；另验证 `matchExpressionsAlias` 覆盖与空别名回退。
- [x] V3 `/tmp/` 最小 application Chart（fixture）：分别提供重复 string 条目、重复 map 条目、`null`、空白字符串与空 map 条目，验证输出条目唯一且不含空条目；再验证两字段均为空时返回空字符串。
- [x] V4 `/tmp/` 最小 application Chart（fixture）：`matchExpressions` 为 map 或字符串、条目为数字或布尔、条目为 `c != d e`、`c > 1 2`、`c in a`、`c > (7)`、`c != (d, e)`、`c gt 3`、`c lt 5`、`c exists d`、`!c != d`、`c !=`、`c in(a)`、`-abc`、`a=b`，以及 `key` 为空、`key` 含两个 `/`、`key` 前缀含大写、`operator` 非枚举，逐一验证渲染中断且错误信息含 `[definitions.nodeSelectorTerm]` 与字段路径。
- [x] V5 `/tmp/` 最小 application Chart（fixture）：`In` 无值、`Exists` 带值、`Gt` 带两个值、`Gt` 取值 `abc` 与 `3.5`，逐一验证渲染中断；再验证 `c in (@@)` 等非标签字符集的值不中断；另用返回非 YAML 的 fixture 验证子模板返回值保护。
- [x] V6 静态检查：`templates/base/_env.tpl` 与 `templates/api-resources/Definitions/_NodeSelectorTerm.tpl` 无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
