---
change-id: definitions-container-restart-rule-on-exit-codes
updated_at: "2026-11-19T17:49:24Z"
---

# definitions.containerRestartRuleOnExitCodes

## 目标

- 新增命名模板 `definitions.containerRestartRuleOnExitCodes`，渲染 Kubernetes `ContainerRestartRuleOnExitCodes` 字段片段。

## 需求

- 模板上下文为 map，字段为 `operator` 与 `values`。
- `operator` 为 string，`values` 为 integer array。
- 所有字段必填。
- `operator` 按 `In` / `NotIn` 枚举校验，校验大小写不敏感。
- `operator` 归一化由本模板完成，输出官方枚举值 `In` / `NotIn`。
- `values` 元素数量为 1 - 255，不允许空数组，也不能超过 255 个元素。
- 显式整数 `0` 允许作为 values 元素。
- values 元素必须是整数，输入中的整数类型与取值必须保留。

## 期望输入格式

```yaml
operator: string
values:
  - integer array
```

## 约束

- 不满足必填、类型、枚举或数量边界时中断报错。
- `base.field` 传入的允许值列表以官方文档允许的 `In` / `NotIn` 为准。

## 验收

- 合法 map 能渲染出 `operator` 与 `values`。
- `operator` 缺失、类型非法或不在 `In` / `NotIn` 枚举内（大小写不敏感）时中断报错。
- `operator` 为 `in`、`notin` 等大小写变体时归一化输出为 `In` / `NotIn`。
- `values` 缺失、类型非法、为空数组、包含非整数元素或元素数量超过 255 时中断报错。
- values 元素数量为 1 和 255 时均能正常输出，显式 `0` 不被丢弃。
