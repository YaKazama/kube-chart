# base.string.normalize 设计

## 技术目标

- capability：`base.string.normalize`
- artifact-type：Helm 命名模板
- target：`templates/base/_convert.tpl`

## 设计决策

### Decision: 接收标量 string 而非上下文 map

- requirements：`字符串标量解码`、`空输入返回空字符串`、`非法入参中断渲染`
- choice：模板直接接收入参 string，调用方式为 `include "base.string.normalize" $text`；契约注释显式声明接收标量，不使用 `list` 包装；入参不是 string 时立即中断，消息使用本模板前缀与实际类型。
- rationale：本能力只处理单一文本，无需多参数；符合「单值传标量」的传参约定，也让调用点保持单行；前置类型门禁与 `base.string`、`base.string.empty`、`base.ftoi` 等既有 base 能力一致。

### Decision: 一次 YAML 解码完成表示还原

- requirements：`字符串标量解码`
- choice：以 `fromYaml (printf "v: %s" $text)` 把入参作为单键映射的值解码，随后取该键的值；不使用 `SYS.YAML_QUOTED`、不新增正则、不依赖 `base.env`。
- rationale：解码一次即可同时覆盖引号、纯量、块标量指示符与特殊字符；现有 `SYS.YAML_QUOTED` 只匹配成对引号，块标量会泄漏指示符。

### Decision: 解析错误、null 与 string 三支互斥

- requirements：`字符串标量解码`、`空输入返回空字符串`、`非法入参中断渲染`
- choice：先以 `base.isFromYamlError` 判断解码结果是否错误 map，是则中断；再以 `kindOf` 判断解码值：`invalid` 返回空字符串，`string` 返回原值，其余类型中断。
- rationale：空输入与解析失败都会得到 `invalid` 值，只有先排除错误 map 才能区分；空字符串无需单独短路，`v: ` 本身解码为 `nil` 且不报错。

### Decision: 失败消息由本模板维护前缀

- requirements：`非法入参中断渲染`
- choice：解析失败与非 string 类型均使用 `[base.string.normalize]` 前缀，消息中给出实际类型或入参摘要。
- rationale：本能力不接收字段路径，无法生成调用方字段级定位；由调用方在自身消息中补充路径。

## 依赖契约

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值。
- output：字符串 `"true"` 或 `"false"`；仅当值为 map 且含 `Error` 键时返回 `"true"`。
- ownership：错误形态识别由该能力承担；本层只负责在识别为错误时中断。

## 代码边界

### `templates/base/_convert.tpl`

- access：`write`
- operations：新增命名模板 `base.string.normalize`。
- writable-scopes：`base.string.normalize`

## 验证设计

- 最小有效：`/tmp/` 最小 application Chart 加载真实 `templates/base/*.tpl`，直接调用 `base.string.normalize`，入参为 `gpu`，预期输出 `gpu`。
- 较完整有效：同一 fixture 覆盖引号标量、`"007"`、`"a: b"`、含首尾空白的引号标量、块标量 `|` 与折叠标量 `>`，预期值与 YAML 语义一致且不含指示符。
- 关键失败：`a: b`、`- x` 触发解析中断；`true`、`123`、`{a: b}`、`[a, b]` 触发非 string 中断；入参本身不是 string（如直接传入 map）触发参数中断；均预期消息带 `[base.string.normalize]` 前缀。
- 空输入：`""`、`null`、`~` 预期返回空字符串且不中断。
- 依赖边界：`base.isFromYamlError` 为真实模板，不使用同名 fixture 替代。
