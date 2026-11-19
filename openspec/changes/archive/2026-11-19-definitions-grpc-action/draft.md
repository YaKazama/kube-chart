---
change-id: definitions-grpc-action
updated_at: "2026-11-19T15:13:07Z"
---

# definitions.grpcAction

## 目标

- 新增 `definitions.grpcAction` 模板，把上下文 map 渲染为 Kubernetes `core/v1` 的 `GRPCAction`。

## 需求

- 输入为上下文 map，字段为 `port` 与 `service`。
- `port` 必填；`service` 可选。
- `port` 缺失、为 `null` 或为空字符串时，不满足必填要求，渲染中断。
- 按官方文档字段顺序渲染：`port` 在前，`service` 在后。
- `port` 支持 integer、纯数字字符串与命名端口，处理方式与 `httpGet`、`tcpSocket` 相同：integer 与纯数字字符串必须在 1 - 65535 之间并以整数输出；命名端口按 Kubernetes `IsValidPortName` 规则校验并以字符串输出；实现参照 `definitions.httpGetAction` 的标量回读、类型归一与范围校验方式。
- `port` 为布尔、带小数数值、map、list 等其他类型时渲染中断。
- `service` 非空时以字符串输出；缺失、为 `null`、为空字符串或仅含空白时不渲染该字段；为布尔、数值、map、list 时渲染中断。

## 期望输入格式

```yaml
port: <integer | string>  # 必填，1 - 65535 或 IANA_SVC_NAME 命名端口
service: <string>         # 可选，gRPC 健康检查服务名
```

## 约束

- 渲染字段顺序遵循 Kubernetes API 官方文档中 `GRPCAction` 的字段顺序（`port` → `service`）。
- `port` 的类型归一与范围校验复用 `definitions.httpGetAction` 中对应的实现方式。
- 已确认接受与官方 `GRPCAction.port` 为 integer 的偏离：本模板允许命名端口并输出字符串，由使用方自行确保调用时的端口形态与集群校验一致。

## 非目标

- 不实现 `Probe` 的动作分派或互斥判定，由 `definitions.probe` 负责。
- 不校验 `service` 指向的 gRPC 服务在运行时是否存在。
- 不拦截与官方 `GRPCAction.port` integer 类型不一致的命名端口输入，也不在渲染期模拟 API Server 的类型校验。

## 验收

- 同时提供 `port` 与 `service` 时，渲染结果的字段顺序为 `port` → `service`。
- 只提供 `port` 时，渲染结果不含 `service` 键。
- `port` 为整数、纯数字字符串或命名端口时分别按对应形态输出。
- `port` 缺失、为 `null`、为空字符串、数值越界、命名端口非法，或类型为布尔／带小数数值／map／list 时渲染中断。
- `service` 缺失、为 `null`、为空字符串或仅含空白时渲染结果不含 `service` 键；为布尔、数值、map、list 时渲染中断。

## 开放问题

- 无。
