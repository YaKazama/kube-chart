---
change-id: definitions-lifecycle
updated_at: "2026-11-18T15:14:33Z"
---

# definitions.lifecycle 生命周期模板

## 目标

- 新增 `definitions.lifecycle` 模板。
- 修正父模板 `definitions.container`，把同源 `os` 传入 `definitions.lifecycle`。

## 需求

- `definitions.lifecycle` 的上下文可以是原生 map，也可以是下方“期望输入格式”中的抽象结构。
- 原生 map 指直接采用 Kubernetes 原生生命周期结构。
- 上下文始终是 map；父模板只允许传入 map。
- 原生 map 与抽象结构无需归一为同一种上下文形态，二者均按具有相同生命周期字段的 map 向下传递。
- `postStart` 和 `preStop` 复用同一个子模板 `definitions.lifecycleHandler`。
- `definitions.lifecycleHandler` 在本 change 中仅作为占位引用，不创建实际模板。
- 抽象结构中的 `exec`、`httpGet`、`sleep`、`tcpSocket` 及其全部内容由孙模板处理，`definitions.lifecycle` 不考虑其契约；本模板只负责向下传递并收集结果，用于渲染自身字段。
- `postStart`、`preStop`、`stopSignal` 均为可选字段；存在时渲染，不存在时不渲染。
- `stopSignal` 属于 `definitions.lifecycle`，由本模板校验并渲染。
- `stopSignal` 校验失败时中断报错，可用值参考 Kubernetes 官方文档，并严格区分大小写。
- `stopSignal` 仅可在 `.spec.os.name` 非空时设置；父模板必须将同源 `os` 传入本模板，本 change 同步修正该传递。

## 期望输入格式

原生 map 直接采用 Kubernetes 原生生命周期结构；抽象结构如下：

```yaml
postStart:
  exec:
    - <string array>
  httpGet: [schema] [host] <port> [path] headers (name value, ...)
  sleep: <integer>
  tcpSocket: [host] <port>
preStop:
  exec:
    - <string array>
  httpGet: [schema] [host] <port> [path] headers (name value, ...)
  sleep: <integer>
  tcpSocket: [host] <port>
stopSignal: <string>
```

## 约束

- 原生 map 与抽象结构均属于支持的上下文形态。
- 父模板保证传入 map；本模板不负责把原生 map 与抽象结构归一为同一内部形态。
- `definitions.lifecycle` 不解析 `exec`、`httpGet`、`sleep`、`tcpSocket` 的内部结构，也不负责这些字段的细粒度映射。
- 孙模板的任何内容均不在本模板中处理，也不在本 change 中约束或补齐。
- `stopSignal` 的校验和渲染不得下放给 `definitions.lifecycleHandler` 或孙模板。
- `postStart` 和 `preStop` 只能通过 `definitions.lifecycleHandler` 的统一占位调用渲染，不分别复制处理逻辑。
- 本 change 不创建 `definitions.lifecycleHandler` 的实际内容。
- 父模板向 `definitions.lifecycle` 传递 `os` 的修正属于本 change 范围。

## 非目标

- 不创建 `definitions.lifecycleHandler` 子模板。
- 不扩展或猜测 `stopSignal` 的可用值集合。
- 不处理孙模板负责的 `exec`、`httpGet`、`sleep`、`tcpSocket` 内容。

## 验收

- 上下文包含 `postStart`、`preStop` 或 `stopSignal` 时，渲染对应字段。
- 上下文缺少上述任一字段时，不渲染该字段。
- `postStart` 和 `preStop` 均通过 `definitions.lifecycleHandler` 占位调用渲染。
- 原生 map 按 Kubernetes 原生生命周期结构处理，抽象结构也能作为上下文；二者无需归一化，均以 map 传递。
- `exec`、`httpGet`、`sleep`、`tcpSocket` 的处理结果来自孙模板，`definitions.lifecycle` 不处理其内容。
- `stopSignal` 在 `.spec.os.name` 非空且值合法时由 `definitions.lifecycle` 渲染。
- `stopSignal` 值大小写不匹配或不在允许值内时，渲染中断报错。
- `stopSignal` 存在但 `.spec.os.name` 为空时，渲染中断报错。
- 父模板 `definitions.container` 向 `definitions.lifecycle` 传递同源 `os`。

## 开放问题

- 无。
