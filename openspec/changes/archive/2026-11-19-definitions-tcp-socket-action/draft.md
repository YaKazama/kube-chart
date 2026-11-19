---
change-id: definitions-tcp-socket-action
updated_at: "2026-11-19T14:24:04Z"
---

# definitions.tcpSocketAction

## 目标

- 新增 `definitions.tcpSocketAction` 模板，把上下文 map 渲染为 Kubernetes `core/v1` 的 `TCPSocketAction`。

## 需求

- 输入为上下文 map，字段为 `host` 与 `port`。
- `port` 必填，支持 integer、纯数字字符串和命名端口；integer 与纯数字字符串必须在 1 - 65535 之间并以整数输出；命名端口须符合 Kubernetes `IsValidPortName` 规则并以字符串输出；缺失、越界或其他类型渲染中断。
- `host` 可选；提供时必须为域名、IPv4 或 IPv6 地址并以字符串输出；缺失或为空时不渲染；CIDR、URL 等非法值渲染中断。
- 输出按官方文档字段顺序渲染：`host` 在前，`port` 在后。
- 未提供的字段不予渲染，不输出空值。

## 期望输入格式

```yaml
host: <string>            # 可选，域名、IPv4 或 IPv6 地址
port: <integer | string>  # 必填，1 - 65535 或 IANA_SVC_NAME 命名端口
```

## 约束

- 渲染字段顺序遵循 Kubernetes API 官方文档中 `TCPSocketAction` 的字段顺序（`host` → `port`）。
- `host` 与 `port` 的取值校验和类型分派与 `definitions.httpGetAction` 保持一致。
- 复用方式：把 `_HTTPGetAction.tpl` 中 `host` 与 `port` 的取值、校验与类型分派实现同步复现到 `definitions.tcpSocketAction` 自身模板内，以等价语句直接书写；不通过 `include` 委托同一模板的处理逻辑，不新增共享 base 模板，也不修改已实现的 `definitions.httpGetAction`。
- 只复用公共 `base.*` 能力（`base.get`、`base.string.normalize`、`base.net`、`base.port`、`base.field`、`base.int`、`base.env` 常量）；不在两个 Action 模板之间建立 include 调用关系。

## 非目标

- 不涉及其他 Action 类型（`exec`、`httpGet`、`grpc`、`sleep`）及其调用方模板（probe、lifecycle handler）。

## 验收

- 同时提供 `host` 与 `port` 时，渲染结果的字段顺序为 `host` → `port`。
- 未提供 `host` 时，渲染结果不含 `host` 键。
- `port: 8080` 与 `port: "8080"` 均输出整数端口；`port: http` 输出命名端口字符串。
- `host` 非法、`port` 缺失、数值越界或命名端口非法时渲染中断。

## 开放问题

- 无。
