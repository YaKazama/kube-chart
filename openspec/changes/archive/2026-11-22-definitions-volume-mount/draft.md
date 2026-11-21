---
change-id: definitions-volume-mount
updated_at: "2026-11-21T16:44:41Z"
---

# definitions.volumeMount

## 目标

- 提供 `definitions.volumeMount` 模板，将用户输入渲染为合法的 Kubernetes `volumeMount`。
- 使父级模板同时接受原生 map 和 `string array` 两种 `volumeMount` 输入形态。

## 需求

- 模板上下文为 map，字段集合与语义按 Kubernetes 官方文档确定，字段顺序按官方文档渲染。
- 父级模板扩展为同时支持原生 map 与 `string array`。
- 父级模板的 `volumeMounts` 本身为 array；列表元素可以是原生 map 或抽象 string，混合出现时按列表顺序处理。
- `string array` 按 token 位置解析，并把各捕获组映射到对应字段；可选捕获组未传递时取空值。
- 第 3 组按 `mountSubPathLike` 整段匹配；匹配成功时作为 `subPathExpr`，否则作为 `subPath`。

## 期望输入格式

原生 map 字段：

```yaml
name: <string>
mountPath: <string>
readOnly: <bool>
recursiveReadOnly: <enum>
mountPropagation: <enum>
subPath: <string>
subPathExpr: <string>
```

`string array` 元素格式：

```text
<name> <mountPath> [subPath|subPathExpr] [readOnly] [recursiveReadOnly] [mountPropagation]
```

- token 分隔符为逗号和空格。
- `readOnly` 仅接受 `true` 或 `false`。
- 可选段未提供时，对应捕获组为空值，渲染时省略该字段。
- 第 3 组的变量形式使用参考正则 `mountSubPathLike` 判定。
- 参考正则（原始版本，分隔符部分需按上述规则调整）：

```text
mount: "^(\\S+)(?:\\s+(\\S+))(?:\\s+(\\S+))?(?:\\s+(true|false))?(?:\\s+(Disabled|IfPossible|Enabled))?(?:\\s+(Bidirectional|HostToContainer|None))?$"
mountSubPathLike: "\\$\\([^)]+\\)"
```

## 约束

- `name` 必须规范化为小写，再通过名称正则校验并以小写渲染。
- `mountPath` 不得包含 `:`。
- `name` 与 `mountPath` 为必填字段；缺失或为空时中断报错。
- `subPath` 与 `subPathExpr` 互斥，不得同时出现。
- `readOnly` 未提供时省略该字段；显式提供时按布尔值渲染。
- `readOnly` 为 `false` 时，`recursiveReadOnly` 无意义，必须留空。
- `recursiveReadOnly` 与 `mountPropagation` 的可取值按官方文档做枚举校验。
- 正则匹配不区分大小写；`readOnly`、`recursiveReadOnly` 与 `mountPropagation` 的值校验区分大小写，仅接受规范拼写。
- `recursiveReadOnly` 为 `IfPossible` 或 `Enabled` 时，`mountPropagation` 必须为 `None` 或未设置。
- 其他校验失败一律中断渲染并报错。
- `volumeMount` 字段顺序按官方文档；父级模板现有渲染字段与顺序正确，不得改动。

## 非目标

- 不覆盖 `volumeMount` 以外的 Kubernetes 字段或资源类型。

## 验收

- map 输入可渲染出符合官方字段与顺序的 `volumeMount`；未提供的可选字段省略。
- `string array` 输入可按逗号和空格分隔解析，并正确区分 `subPath` 与 `subPathExpr`。
- 父级模板的 `volumeMounts` 列表混合 map 与 string 元素时，按原顺序渲染。
- `name`、`mountPath` 缺失或为空，以及违反 `mountPath`、互斥、`recursiveReadOnly` 前提、跨字段或枚举约束的输入会中断报错。
- 大写 `name` 输入会规范化为小写并通过 RFC1123 校验，且输出为小写。
- 父级模板对 map 和 `string array` 两种输入均可调用，且现有渲染字段与顺序不变。

## 开放问题

- 无。
