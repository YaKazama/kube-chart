---
change-id: base-string-normalize
updated_at: "2026-11-09T16:56:12Z"
---

# base.string.normalize 字符串二次归一化

## 目标

- 新增 base 层公共模板 `base.string.normalize`，作为 `base.get` 之后 string 分支的二次归一化步骤：把 `include` 返回的 YAML 序列化文本还原为真实 string 值，不做空白归一；空白处置由调用方决定。
- 存量调用点的批量改造不在本 change 内处理，范围与待决事项记录于根目录 `TODO.md`，待本 change 完成后再行推进。

## 需求

- 入参为 string，通常直接是 `include "base.get"` 的返回值原文；调用方不得预先 `trim`、`fromYaml` 或拼接；入参不是 string 时中断渲染。
- 类型确认与 YAML 解码全部在模板内部完成，一次解码得到真实标量值，不使用 `SYS.YAML_QUOTED` 或其他去引号正则，也不依赖 `base.env`。
- 不内置 `trim`：只做解码与类型确认，不改变值的内容与首尾空白；空白处置由调用方自行完成。
- 入参为空字符串、显式 `null` 或路径未命中时均返回空字符串，不视为类型错误。
- 仅空白值（如 `v: "   "`）与多行值按解码结果原样返回，不做归一化。
- 空输入与解析失败不混淆：空输入返回空字符串，解析失败中断渲染。
- 解码结果为非 string 时中断渲染。
- 失败消息由本模板维护前缀。
- 新能力放在 `templates/base/_convert.tpl`。

## 约束

- `base.get` 返回值恒为 string 是 `include` 机制，不是本能力需要声明的契约。
- `base.get` 的 map、array 结果继续由调用方的 `fromYaml`、`fromYamlArray` 处理，本能力不介入该分层。
- 本能力不替代 `base.get`，也不替代任何已有类型处理模板。
- 本 change 不修改 `base.get`：其取值、必填、`false` / `0` 与空字符串语义均无需调整，本 change 只新增取值后的二次归一化。
- `base.string.verify` 保留，不删除、不改名、不改契约。

## 非目标

- 不实现第二套取值、别名识别、数据源优先级或合并语义。
- 不处理 map、array、多类型字段、数值字段与布尔字段。
- 不合并进 `base.string.verify`。
- 不把空值渲染委派给 `base.slice.cleanup` 或 `base.field`。

## 验收

- 调用方以单行 include 取得归一化 string，无需自行 `fromYaml` 或去引号。
- 布尔、数值、map、list 输入均中断渲染，消息带本模板前缀。
- 解析失败的入参中断渲染，不静默返回空字符串。
- 多行块标量输入不再泄漏 `|`、`>` 指示符，换行内容按原值保留。
- 输出与解码结果一致，不改变值的内容与首尾空白。

## 取值与空值语义

已按 Helm 4.3.1 官方 Template Function List 确认：

- `toYaml` / `toYamlPretty`：无法转换为 YAML 时返回空字符串；`toYamlPretty` 与 `toYaml` 等价，仅额外缩进列表元素，不涉及标量渲染方式。
- `fromYaml`：把 YAML 字符串转为可在模板中使用的对象。
- `get`：键不存在时返回 `""`，不报错。
- `default` / `empty` / `required` 共用同一空值定义：`0`、`""`、`[]`、`{}`、`false`、`nil`。

对应到本能力：`base.get` 路径未命中时输出空字符串是官方函数行为，normalize 收到空字符串时返回空字符串不作类型错误，两者一致。

补充事实：`base.get` 不把 `false` 与 `0` 判为空，这是有意设计，不是与官方 `empty` 的偏差。原因是这类值必须能被显式输出，例如 `core.podSpec` 中的 `hostUsers: false` 与 `terminationGracePeriodSeconds: 0`。若按官方 `empty` 判空，这些字段会与「未设置」无法区分，取值将不可表达。实测 `hostUsers: false` 与 `terminationGracePeriodSeconds: 0` 的原始输出分别为 `"false"` 与 `"0"`，均非空字符串，下游 `if` 判定为已设置。

对本质的边界：normalize 只接受解码后为 string 的值；布尔与数值字段走 `base.bool`、`base.int`，不经过 normalize。

空字符串不可用参数区分：`v: ""`、`v: null` 与路径未命中在 `base.get` 层输出完全相同，且 `base.get` 已统一判为 empty，故不设参数开关。

空输入与解析失败可区分（实测）：

| 入参 | `fromYaml` 错误 | 解码类型 | 判定 |
|---|---|---|---|
| 空字符串 | `false` | `invalid` | 未设置，返回空字符串 |
| `a: b` | `true` | `invalid` | 入参不合法，中断 |
| `hello` | `false` | `string` | 正常值 |
| `- x` | `true` | `invalid` | 入参不合法，中断 |

### 不内置 trim 的依据

`base.get` 输出对单行标量不附尾部换行（`hello` 长度为 5），因此 `trim` 不是解码后必要的后处理。`trim` 会丢弃引号内显式书写的前后空白，而 `fromYaml` 是表示形态的无损还原，两者性质不同，不应捆绑在同一能力中。

| 输入 | `base.get` 输出 | 解码结果 | `trim` 后 |
|---|---|---|---|
| `v: "  spaced  "` | `'  spaced  '`（长 12） | `  spaced  `（长 10） | `spaced`（长 6） |
| `v: "   "` | `'   '`（长 5） | `   `（长 3） | 空（长 0） |
| `v: abc  `（不加引号） | `abc` | `abc` | `abc` |

normalize 输出解码结果；需要去空白的调用方自行追加 `trim` 或使用 `base.string` 等既有模板。
