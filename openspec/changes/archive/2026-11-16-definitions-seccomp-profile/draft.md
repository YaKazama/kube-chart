---
change-id: definitions-seccomp-profile
updated_at: "2026-11-15T16:19:16Z"
---

# definitions.seccompProfile

## 目标

- 新建公共模板 `definitions.seccompProfile`，渲染 Kubernetes 容器 seccomp 配置结构。

## 需求

- 上下文为 map，字段为 `localhostProfile`、`type`，与“期望输入格式”一致。
- 两个字段均为 string 类型。
- 两个字段取值均先去除首尾空白，判空、枚举校验与输出均使用去除后的结果。
- `type` 必填，缺失时中断渲染。
- `type` 只允许 `Localhost`、`RuntimeDefault`、`Unconfined`，取值大小写敏感。
- `type` 不在允许范围时中断渲染。
- `type` 为 `Localhost` 时 `localhostProfile` 必填，缺失时中断渲染。
- `type` 为 `RuntimeDefault` 或 `Unconfined` 时 `localhostProfile` 不得渲染。
- 输出字段顺序按 Kubernetes v1.36 官方字段表，即 `localhostProfile` 在 `type` 之前。
- 输出字段值统一以双引号包裹。
- `type` 为 `Localhost` 时，`localhostProfile` 去除首尾空白后为空则中断渲染。
- 除 `type`、`localhostProfile` 以外的输入键静默忽略，不参与渲染也不触发失败。
- `type` 非 `Localhost` 时 `localhostProfile` 不参与渲染，也不做类型校验。

## 期望输入格式

```yaml
localhostProfile: string
type: string
```

## 约束

- 当前唯一调用点是 `templates/api-resources/Definitions/_PodSecurityContext.tpl`，通过 `definitions.podSecurityContext.struct` 委托 `definitions.seccompProfile`；模板 `definitions.securityContext` 当前不存在。本 change 需保持该调用点的上下文契约不变。

## 非目标

- 不实现 seccompProfile 结构以外的字段或其他安全上下文结构。
- 不校验 `localhostProfile` 指向的配置文件路径是否在设计节点上真实存在。

## 验收

- `type` 为 `Localhost` 且 `localhostProfile` 非空时，输出同时包含 `type` 与 `localhostProfile`。
- `type` 为 `RuntimeDefault` 或 `Unconfined` 时，即使输入带 `localhostProfile`，输出也只包含 `type`。
- `type` 缺失、为空字符串、只含空白或超出枚举范围时报错并中断渲染。
- `type` 取 `localhost`、`RUNTIMEDEFAULT` 等大小写变体时报错并中断渲染。
- `type` 取 `" Localhost "` 时校验通过，输出取值为去除首尾空白后的 `Localhost`。
- `type` 为 `Localhost` 但 `localhostProfile` 缺失时报错并中断渲染。
- 输出顺序为 `localhostProfile` 在前、`type` 在后。
- 输出字段值均带双引号。
- `type` 为 `Localhost` 且 `localhostProfile` 为空字符串或只含空白时报错并中断渲染。
- 输入含 `foo: bar` 等范围外键时静默忽略，输出与不含该键时一致。
- `type` 为 `RuntimeDefault` 且 `localhostProfile` 取数字或 map 时渲染成功，且输出只包含 `type`。
- `localhostProfile` 取 `"  profiles/a.json  "` 时输出取值为去除首尾空白后的 `profiles/a.json`。

## 开放问题

- 无。
