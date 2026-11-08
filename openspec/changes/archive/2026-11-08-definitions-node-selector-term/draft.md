---
change-id: definitions-node-selector-term
updated_at: "2026-11-08T11:29:30Z"
---

# definitions.nodeSelectorTerm

## 目标

- 新增模板 `definitions.nodeSelectorTerm`，把 `matchExpressions`、`matchFields` 统一清洗为原生 `NodeSelectorRequirement` 结构并渲染。

## 需求

- 入参示例：

  ```yaml
  matchExpressions:
    - c != d
  matchFields:
    - aa in (xx1, xx2, 123333)
  ```

- `matchExpressions` 与 `matchFields` 都支持 string array 和原生 `NodeSelectorRequirement` array 两种输入形态。
- string 条目与原生 map 条目允许出现在同一数组中，每个元素独立解析，互不干扰。
- 两个字段共用同一个子模板 `definitions.nodeSelectorRequirement`；本 change 只为该子模板占位，不创建其模板内容。
- 传给子模板的上下文是清洗后的 map，始终包含 `key`(string)、`operator`(string)，仅在存在有效值时才包含 `values`(string array)；无有效值时上下文中不存在 `values` 键。
- `values` 的拆分、去空、去重和约束校验全部在本 change 内完成，子模板不做 `values` 相关的清洗或校验。
- 清洗后的条目去重、去空后再传给子模板；去重交由 Helm 模板函数处理，不额外定义字段全等的判等规则。
- 输入为空时不渲染。
- `operator` 清洗后大小写敏感，枚举为 `DoesNotExist`、`Exists`、`Gt`、`In`、`Lt`、`NotIn`。
- string 条目分为三类，三类合起来覆盖全部六个 `operator`：
  - 第一类（符号运算符 + 单值）：`<key> <op> <value>`，`<op>` 仅接受 `!=`、`==`、`=`、`>`、`<`，值必须是单个不含空白、逗号与括号的 token。
  - 第二类（集合运算符 + 括号多值）：`<key> in (<value>[, <value>...])` 与 `<key> notin (<value>[, <value>...])`，`in`、`notin` 必须带括号。
  - 第三类（存在性）：裸 `<key>` 与 `!<key>`，无运算符与值。
- 操作符映射：`=`、`==`、`in` 为 `In`；`!=`、`notin` 为 `NotIn`；`>` 为 `Gt`；`<` 为 `Lt`；裸 `<key>` 为 `Exists`；`!<key>` 为 `DoesNotExist`。
- `gt`、`lt` 不作为接受的操作符 token；`c gt 3`、`c lt 5` 视为无法解析。
- `in`、`notin` 的括号不可省略：`c in a` 视为无法解析；第一类的值也不接受括号：`c > (7)` 视为无法解析。
- `values` 只有两种来源：
  - 第一类：`values` 为单个 token，不再二次拆分；`c != d e`、`c > 1 2` 均视为无法解析。
  - 第二类：剥离括号后仅按 `SPLIT.COMMA` 拆分；括号内空格不参与分隔，`(a b)` 为单值 `a b`。
- 第三类不产生 `values`；`exists`、`doesnotexist` 不作为操作符 token，`c exists d` 视为无法解析。
- `!` 只用于第三类：`!c != d`、`!c > 1` 均视为无法解析。
- string 条目无法解析时 `fail` 中断渲染。
- `matchExpressions` 与 `matchFields` 的 `key` 均按标签键语法校验，不区分字段路径语法。
- `values` 约束：
  - `In`、`NotIn`：值数组必须非空。
  - `Exists`、`DoesNotExist`：值数组必须为空。
  - `Gt`、`Lt`：值数组必须恰好一个元素，且该元素必须为整数；非整数（如 `c > abc`、`c > 3.5`）中断渲染。
- `Gt`、`Lt` 的整数值需归一化：`07` → `7`、`-07` → `-7`、`+3` → `3`、`0000`/`-0`/`+0` → `0`；显式 `0` 合法。
- 第一类的单值与第二类的括号内多个值统一交给 `base.slice.cleanup` 并以 `COMMA` 清洗，两者结果完全一致（`c = 07` 与 `c in (07)` 均得 `7`）；清洗结果即为最终 `values`，另见 [TODO.md](TODO.md)。
- `values` 元素本身不校验字符集，与标签值一致只校验 `key`；除 `base.slice.cleanup` 的数值规范化外不做其他改写，因此 `In`、`NotIn` 的 `07` 同样输出为 `7`。
- 违反 `values` 约束时 `fail` 中断渲染，不交给 API Server 回退。

## 期望输入格式

- 见“需求”中的入参示例；string 条目只有三类：`<key> <op> <value>`（`!=`、`==`、`=`、`>`、`<`）、`<key> (in|notin) (<value>[, <value>...])`、裸 `<key>` 与 `!<key>`。
- 第一类的值必须是单个 token，含空白、逗号或括号即无法解析。
- 第二类先剥离括号取内文，再交给 `base.slice.cleanup` 并以 `COMMA`（`\s*,\s*`）清洗，`xx1, xx2, xx3` 解析为三个值。

## 约束

- string 条目解析参考 [Kubernetes 标签选择器](https://kubernetes.io/zh-cn/docs/concepts/overview/working-with-objects/labels/#label-selectors)。
- 解析使用两个正则：条目主正则只做结构切分（`!`、`key`、运算符、values 原文），values 原文形态由独立正则限定；两者都不区分大小写。
- `key` 在主正则中取宽松 token，标签键语法只在 key 校验阶段判定，不在正则中重复表达。
- 同级 `*Alias` 由 `base.get` 隐式处理，本模板不显式关闭别名识别，也不手工比较别名键。
- `base.slice.cleanup` 会把纯数字字符串转为数值类型；`fromYamlArray` 回读后为 `float64`，向子模板传递前必须用 `toStrings` 转回 string，实测 `123333` 输出为字符串而非数字。
- string 分支与原生 map 分支的归一化、`operator` 输入不区分大小写并映射为大小写敏感的规范枚举、`values` 经 `base.slice.cleanup` 清洗后 `toStrings`、经 `base.field` 输出，均参考 `definitions.labelSelector` 的现有实现形态。
- 实测确认：条目主正则覆盖全部六个 `operator`，`c != d`、`c = d`、`c == d`、`c > 7`、`c < 9`、`aa in (xx1, xx2, xx3)`、`aa notin (xx1, xx2)`、`c IN (a)`、`aaa`、`!aaa` 均能命中并稳定取出 `!`、`key`、运算符、values 原文四个分组；未参与匹配的捕获组取值为空字符串。
- 实测确认：主正则排除 `c gt 3`、`c lt 5`、`c GT 3`、`c exists d`、`c !`、`!!c`、`c in(a)`；`c in a`、`c != d e`、`c != (d, e)` 命中后由 values 原文形态或括号一致性校验中断；`-abc`、`a=b` 命中后由 key 语法校验中断；`!c != d`、`!c > 1` 命中后因 `!` 与运算符同时非空中断。
- 实测确认：括号内文本仅按 `COMMA` 拆分，`(a b)` 为单值 `a b`，`(a,,b)` 为 `a`、`b`，`( a , b )` 为 `a`、`b`，`()` 为空列表。
- 本 change 不再使用 `SPLIT.SPACE_COMMA`；两类条目都只使用 `SPLIT.COMMA`，第一类单 token 不含逗号因此清洗后恒为单元素。
- 实测确认：`fromYaml ""` 返回空 map 且 `base.isFromYamlError` 为 `"false"`，因此两个字段均无内容时返回空字符串可被 `definitions.preferredSchedulingTerm` 安全消费。
- 实测确认：`base.env` 的 `TYPES.INT`（`^[+-]?\d+$`）接受 `3`、`-3`、`+3`、`07`，拒绝 `abc`、`3.5`，可直接用于 `Gt`、`Lt` 的单值校验。
- 实测确认：`=`、`==`、`in` 映射为 `In`，`!=`、`notin` 映射为 `NotIn`，`>` 映射为 `Gt`，`<` 映射为 `Lt`，裸 `<key>` 映射为 `Exists`，`!<key>` 映射为 `DoesNotExist`。
- 实测确认：`base.slice.cleanup` 自身即可完成整数归一化（`07`→`7`、`-07`→`-7`、`+3`→`3`、`0000`/`-0`/`+0`→`0`），不需要额外的字符串归一化步骤。
- 实测确认：把单 token 包成单元素列表后与括号内文本分别交给 `base.slice.cleanup(COMMA)`，在 `07`、`0`、`0000`、`-07`、`-0`、`+3`、`+0`、`3`、`-3`、`d`、`d-e.f`、`@@`、`abc`、`3.5`、`9223372036854775808` 上结果逐项相同，含溢出案例也一致。
- 实测确认：`base.int` 对整数字符串原样返回，不会去前导零；`int64` 与 `atoi` 会把 `9223372036854775808` 静默变为 `0` 或钳到最大值，因此不能用于归一化。

## 非目标

- 不创建 `definitions.nodeSelectorRequirement` 的模板内容。

## 验收

- 示例输入渲染出两条 `NodeSelectorRequirement`：`c != d` 对应 `operator: NotIn`，`aa in (xx1, xx2, 123333)` 对应 `operator: In` 且 `values` 为 `xx1`、`xx2`、`123333`。
- 原生 `NodeSelectorRequirement` array 与 string array 产生相同的输出结构。
- 重复条目与空条目不出现在输出中。
- 空输入或清洗后为空时不渲染。
- `In` 缺 `values`、`Exists` 带 `values`、`Gt` 带两个 `values`（只能由原生 map 条目传入）均中断渲染并给出字段路径。
- `Exists`、`DoesNotExist` 条目向子模板传递的上下文中不存在 `values` 键。
- `aa in (xx1, xx2, 123333)` 的 `values` 元素均为 string，`123333` 不以 int 形式输出。
- `c != d` 的 `values` 为单元素 `d`；`c > 7` 为 `Gt`、`c < 9` 为 `Lt`，`values` 均为单元素。
- `!c` 渲染为 `operator: DoesNotExist` 且无 `values`，裸 `c` 渲染为 `operator: Exists` 且无 `values`。
- `c != d e`、`c > 1 2`、`c exists d`、`c gt 3`、`c lt 5`、`c in a`、`c > (7)`、`!c != d` 均中断渲染。
- `c in ()` 中断渲染（`In` 的值数组不能为空）。
- `c > abc`、`c > 3.5` 均中断渲染；`c > 3`、`c > -3`、`c > 07` 正常渲染。
- `c > 07` 输出 `values` 为 `7`，`c > -07` 为 `-7`，`c > +3` 为 `3`，`c > 0` 与 `c > -0` 均为 `0`。
- `c = 07` 与 `c in (07)` 均输出 `values` 为 `7`；`c = 0000` 与 `c in (0000)` 均为 `0`。
- `c in (@@)` 等非法字符集的值正常渲染，不中断。

## 开放问题

- 无。
