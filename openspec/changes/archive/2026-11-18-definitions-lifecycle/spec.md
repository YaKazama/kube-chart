---
updated_at: "2026-11-18T15:26:05Z"
---

# definitions.lifecycle 生命周期模板规格

## Purpose

提供可复用的 Kubernetes 容器生命周期片段渲染能力，按需输出 `postStart`、`preStop` 和 `stopSignal`。

## ADDED Requirements

### Requirement: 生命周期 Handler 委托

`definitions.lifecycle` 的调用上下文 MUST 为 map；原生上下文直接采用 Kubernetes Lifecycle 结构，也可使用同字段抽象结构。系统 MUST 将 `postStart` 和 `preStop` 的 Handler map 原样交由 `definitions.lifecycleHandler` 处理，并回收非空结果作为对应字段的值；本模板 MUST NOT 解析或校验 `exec`、`httpGet`、`sleep`、`tcpSocket` 及其内部结构，也不得在不同 Handler 之间复制处理逻辑。

#### Scenario: 同时渲染 postStart 与 preStop

- **WHEN** 上下文同时包含非空 `postStart` 和 `preStop` map，且 `definitions.lifecycleHandler` 返回非空 map
- **THEN** 输出 `postStart` 和 `preStop`，两者的值均为对应 Handler 的返回结果

#### Scenario: 仅渲染存在的 Handler

- **WHEN** 上下文只包含 `postStart` 或只包含 `preStop`
- **THEN** 只输出存在的字段，缺失字段不输出

#### Scenario: 原样传递 Handler 上下文

- **WHEN** `postStart` 或 `preStop` 使用 Kubernetes 原生 Handler map 或抽象结构
- **THEN** 该 map 不做归一化或字段改写，直接作为 `definitions.lifecycleHandler` 的上下文

#### Scenario: Handler 返回空结果

- **WHEN** Handler 输入非空，但 `definitions.lifecycleHandler` 返回空内容
- **THEN** 对应 `postStart` 或 `preStop` 字段不输出

#### Scenario: Handler 输入或输出非法

- **WHEN** `postStart` 或 `preStop` 不是 map，或 `definitions.lifecycleHandler` 返回不可解析为 map 的内容
- **THEN** 渲染中断报错

### Requirement: stopSignal 校验与渲染

系统 MUST 仅当 `stopSignal` 存在时校验并渲染该字段。值 MUST 为 string，去除首尾空白后必须严格匹配 Kubernetes v1.36 `Lifecycle.stopSignal` 的官方枚举值，且大小写敏感；同时，`.spec.os.name` 必须非空，`definitions.container` MUST 将同一 Pod 的 `os` 传入本模板。任一校验失败 MUST 中断渲染。

允许值严格限定为：`SIGABRT`、`SIGALRM`、`SIGBUS`、`SIGCHLD`、`SIGCLD`、`SIGCONT`、`SIGFPE`、`SIGHUP`、`SIGILL`、`SIGINT`、`SIGIO`、`SIGIOT`、`SIGKILL`、`SIGPIPE`、`SIGPOLL`、`SIGPROF`、`SIGPWR`、`SIGQUIT`、`SIGRTMAX`、`SIGRTMAX-1`、`SIGRTMAX-10`、`SIGRTMAX-11`、`SIGRTMAX-12`、`SIGRTMAX-13`、`SIGRTMAX-14`、`SIGRTMAX-2`、`SIGRTMAX-3`、`SIGRTMAX-4`、`SIGRTMAX-5`、`SIGRTMAX-6`、`SIGRTMAX-7`、`SIGRTMAX-8`、`SIGRTMAX-9`、`SIGRTMIN`、`SIGRTMIN+1`、`SIGRTMIN+10`、`SIGRTMIN+11`、`SIGRTMIN+12`、`SIGRTMIN+13`、`SIGRTMIN+14`、`SIGRTMIN+15`、`SIGRTMIN+2`、`SIGRTMIN+3`、`SIGRTMIN+4`、`SIGRTMIN+5`、`SIGRTMIN+6`、`SIGRTMIN+7`、`SIGRTMIN+8`、`SIGRTMIN+9`、`SIGSEGV`、`SIGSTKFLT`、`SIGSTOP`、`SIGSYS`、`SIGTERM`、`SIGTRAP`、`SIGTSTP`、`SIGTTIN`、`SIGTTOU`、`SIGURG`、`SIGUSR1`、`SIGUSR2`、`SIGVTALRM`、`SIGWINCH`、`SIGXCPU`、`SIGXFSZ`。

#### Scenario: 合法 stopSignal

- **WHEN** `stopSignal` 为允许值，且 `.spec.os.name` 非空
- **THEN** 输出 `stopSignal`，值为该允许值

#### Scenario: 缺少 stopSignal

- **WHEN** 上下文不包含 `stopSignal`
- **THEN** 不输出 `stopSignal`，且不因 `.spec.os.name` 为空而失败

#### Scenario: stopSignal 缺少 os.name

- **WHEN** 上下文包含 `stopSignal`，但 `.spec.os.name` 缺失或归一化后为空
- **THEN** 渲染中断报错

#### Scenario: stopSignal 值非法

- **WHEN** `stopSignal` 不是允许值，包括大小写不匹配或不是 string
- **THEN** 渲染中断报错

#### Scenario: 通过 Container 渲染 stopSignal

- **WHEN** 容器 lifecycle 包含合法 `stopSignal`，PodSpec 提供非空 `os.name`
- **THEN** `definitions.container` 将同源 `os` 传入本模板，`stopSignal` 正常输出

## 非目标

- 不创建 `definitions.lifecycleHandler`。
- 不解析、校验或渲染 `exec`、`httpGet`、`sleep`、`tcpSocket` 的内部结构。
- 不实现 Lifecycle 的其他字段。
