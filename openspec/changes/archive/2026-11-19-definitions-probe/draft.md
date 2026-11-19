---
change-id: definitions-probe
updated_at: "2026-11-19T14:49:26Z"
---

# definitions.probe

## 目标

- 新增 `definitions.probe` 模板，把上下文 map 渲染为 Kubernetes `core/v1` 的 `Probe`。

## 需求

- 输入为上下文 map，可包含 `exec`、`failureThreshold`、`grpc`、`httpGet`、`initialDelaySeconds`、`periodSeconds`、`successThreshold`、`tcpSocket`、`terminationGracePeriodSeconds`、`timeoutSeconds`。
- 所有字段可选；`exec`、`grpc`、`httpGet`、`tcpSocket` 互斥，按 key 是否存在判定，最多只提供一个，同时提供多个时渲染中断。
- 输出按官方文档字段顺序渲染：`exec`、`failureThreshold`、`grpc`、`httpGet`、`initialDelaySeconds`、`periodSeconds`、`successThreshold`、`tcpSocket`、`terminationGracePeriodSeconds`、`timeoutSeconds`。
- 未提供的字段不予渲染，不输出空值。
- 生效的动作字段值为 `null` 或空 map 时，渲染中断。
- 动作字段按以下子模板映射委托渲染：`exec` → `definitions.execAction`、`grpc` → `definitions.grpcAction`、`httpGet` → `definitions.httpGetAction`、`tcpSocket` → `definitions.tcpSocketAction`。
- `exec`、`httpGet`、`tcpSocket` 的取值形态与解析参照 `definitions.lifecycleHandler` 中的处理：原生 map 直接传递，简写先解析为 map 再传递。
- `grpc` 字符串简写格式为 `[service] <port>`，分隔符为空格或逗号，语义与 `base.env` 的 `SPLIT.SPACE_COMMA`（`[,\s]+`）一致；原生 map 直接传递，字符串先按该格式解析为 map 再传递。
- integer 字段按整数语义接受原生整数与无小数的数值（Helm 4 将 YAML 数值解析为 `float64`，如 `3`、`3.0`）；字符串、布尔、带小数数值、map、list 等其他类型渲染中断。

## 期望输入格式

```yaml
exec: {}
failureThreshold: <integer>
grpc: {}
httpGet: {}
initialDelaySeconds: <integer>
periodSeconds: <integer>
successThreshold: <integer>
tcpSocket: {}
terminationGracePeriodSeconds: <integer>
timeoutSeconds: <integer>
```

`grpc` 字符串简写为 `[service] <port>`，其中 `service` 可选，`port` 必填；`service` 与 `port` 之间的分隔符为空格或逗号。

## 约束

- 渲染字段顺序遵循 Kubernetes API 官方文档中 `Probe` 的字段顺序。
- `definitions.grpcAction` 不在本 change 创建，仅作为已锁定的调用边界占位。

## 非目标

- 不创建 `definitions.grpcAction`，不实现 GRPCAction 的字段校验与渲染。
- 不支持 `sleep` 动作。

## 验收

- 只提供 `failureThreshold: 3` 时，渲染结果只含该字段，不含任何动作字段。
- 同时提供两个及以上动作字段时渲染中断。
- 生效的动作字段值为 `null` 或空 map 时渲染中断。
- 同时提供动作与 integer 阈值时，输出顺序为官方字段顺序。
- integer 字段传入字符串、布尔或带小数数值时渲染中断；传入 `3` 与 `3.0` 时均按整数渲染。
- `grpc` 的字符串简写与原生 map 两种形态均可传递到 `definitions.grpcAction`。
- `grpc` 简写 `grpc-health 8080` 与 `grpc-health,8080` 均可解析，分隔符为空格或逗号。

## 开放问题

- 无。
