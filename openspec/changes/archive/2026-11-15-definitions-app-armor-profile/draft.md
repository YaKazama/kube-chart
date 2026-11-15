---
change-id: definitions-app-armor-profile
updated_at: "2026-11-15T15:38:13Z"
---

# definitions.appArmorProfile

## 目标

- 新建公共模板 `definitions.appArmorProfile`，渲染 Kubernetes Pod 级 AppArmor 配置结构。

## 需求

- 上下文为 map，字段为 `localhostProfile` 与 `type`，与“期望输入格式”一致。
- `type` 枚举校验值为 `Localhost`、`RuntimeDefault`、`Unconfined`。
- `type` 枚举校验大小写敏感，`localhost` 等大小写变体视为非法值。
- `type` 为必填字段：缺失、`null` 或空字符串时报错中断。
- 仅当 `type` 为 `Localhost` 时才渲染 `localhostProfile`。
- `type` 为非 `Localhost` 时，即使输入了 `localhostProfile` 也不渲染该字段，且不报错。
- `type` 为 `Localhost` 但 `localhostProfile` 缺失、`null` 或空字符串时报错中断。
- `localhostProfile` 非 string 类型（数字、布尔、map、array）时报错中断，不做类型归一化。
- `type` 非 string 类型（数字、布尔、map、array）时报错中断，不做类型归一化。
- `type` 为 string 且不在枚举内时报错中断，失败信息给出合法范围。
- 字段值为 string 时先 `trim`，只含空白按空字符串处理。

## 期望输入格式

```yaml
localhostProfile: string
type: string
```

## 约束

- 无用户指定的额外限制。

## 非目标

- 不实现 AppArmorProfile 结构以外的字段或其他安全上下文结构。

## 验收

- `type` 为 `Localhost` 且提供 `localhostProfile` 时，输出包含 `type` 与 `localhostProfile`。
- `type` 为 `RuntimeDefault` 或 `Unconfined` 时，输出只包含 `type`。
- `type` 为 `RuntimeDefault` 或 `Unconfined` 且同时输入 `localhostProfile` 时，渲染成功且输出只包含 `type`。
- `type` 非法时（含 `localhost` 等大小写变体）报错并中断渲染。
- `type` 缺失、为 `null` 或为空字符串时报错并中断渲染。
- `type` 为 `Localhost` 但 `localhostProfile` 缺失、为 `null` 或为空字符串时报错并中断渲染。
- `type` 为 `Localhost` 且 `localhostProfile` 为数字、布尔、map 或 array 时报错并中断渲染。
- `type` 为数字、布尔、map 或 array 时报错并中断渲染。

## 开放问题

- 无。
