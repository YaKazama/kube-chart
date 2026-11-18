---
change-id: definitions-lifecycle-handler
updated_at: "2026-11-18T15:58:20Z"
---

# definitions.lifecycleHandler

## 目标

- 新增模板 `definitions.lifecycleHandler`，处理生命周期处理器上下文。
- 模板同时支持原生 map 和抽象后的 map，并把解析结果交给对应子模板渲染。

## 需求

- 上下文可以是原生 map 或抽象后的 map。
- `exec`、`httpGet`、`sleep`、`tcpSocket` 四选一，不按官方定义将全部动作字段视为可选。
- 抽象 map 由本模板解析，解析后的字段名按官方文档定义确定；多余的字段可以继续向下传递，但实际不会使用。
- 子模板对应关系：
  - `exec` -> `definitions.execAction`
  - `httpGet` -> `definitions.httpGetAction`
  - `sleep` -> `definitions.sleepAction`
  - `tcpSocket` -> `definitions.tcpSocketAction`
- 所有子模板的上下文均为 map。
- `httpGet` 和 `tcpSocket` 按位置取值；对应位置没有值时得到空字符串。
- `httpGet` 的 `headers` 是特殊关键字：括号内容按逗号拆成不同数组元素，每个 `name value` 对应孙模板 `definitions.httpHeader` 的 `name` 和 `value`。
- `headers` 及其括号内容均可省略；省略时按位置取得空值。
- 括号外使用空格和逗号作为分隔符；括号内多组之间同样使用空格和逗号，同组 `name value` 之间只能使用空格。相关正则位于 `templates/base/_env.tpl`。
- 解析 `definitions.httpGetAction` 的上下文时，原生 map 的 `httpHeaders` 直接向下传递；抽象 map 的 `httpHeaders` 为 `<string array>`，其解析交由 `definitions.httpHeader`。
- 渲染字段按官方文档顺序。

## 期望输入格式

```text
exec:
  - <string array>
httpGet: [schema] [host] <port> [path] [headers (name value, ...)]
sleep: <integer>
tcpSocket: [host] <port>
```

`headers` 及其括号内容均可省略。

## 约束

- 子模板只在本模板中占位，不在本变更创建。
- 孙模板 `definitions.httpHeader` 不在本模板处理范围内。

## 非目标

- 不创建 `definitions.execAction`、`definitions.httpGetAction`、`definitions.sleepAction` 和 `definitions.tcpSocketAction`。
- 不处理 `definitions.httpHeader` 的内部逻辑。

## 验收

- 原生 map 和抽象 map 均可进入对应子模板。
- 四种动作按四选一处理。
- 抽象 map 的 `httpGet` 与 `tcpSocket` 在位置缺省时产生空字符串。
- `httpGet` 的 `headers` 能按约定拆分并交给 `definitions.httpHeader`。
- `headers` 及其括号内容省略时取得空值。
- `httpGet.httpHeaders` 在原生 map 下直接传递，在抽象 map 下以 `<string array>` 交给 `definitions.httpHeader`。
- 最终字段顺序与官方文档一致。

## 开放问题

- 无。
