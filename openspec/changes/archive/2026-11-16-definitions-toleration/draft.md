---
change-id: definitions-toleration
updated_at: "2026-11-16T04:30:15Z"
---

# definitions.toleration 模板

## 目标

- 新增 `definitions.toleration` 模板，用于渲染 Kubernetes `Toleration` 子对象。

## 需求

- 支持渲染 `effect`、`key`、`operator`、`tolerationSeconds`、`value` 五个字段。
- 调用与入参形态为原生 map：以单个上下文 map 作为入参，从该 map 读取上述五个字段。
- 所有字段均为可选。
- 任一字段有值时，必须满足 `key`、`operator`、`value` 之间的互斥关系。
- 互斥关系按官方字段说明推理：`key` 为空时 `operator` 必须是 `Exists`；`operator` 为 `Exists` 时 `value` 必须为空；`operator` 为 `Gt`、`Lt` 时 `value` 必须非空。
- 互斥校验仅在 `key`、`operator`、`value` 中至少一个字段有值时执行；三者均未提供时按全部缺省处理。
- `key`、`value` 为 `null`、空字符串或仅含空白时不渲染该字段，并在互斥判定中按未提供处理。
- `operator` 大小写敏感，候选枚举值为 `"Equal"`、`"Exists"`、`"Gt"`、`"Lt"`；省略时不输出该字段。
- `effect` 的候选枚举值为 `"NoExecute"`、`"NoSchedule"`、`"PreferNoSchedule"`；省略或为空字符串时跳过输出。
- `tolerationSeconds` 为显式 `0` 时照常渲染；负值按官方语义交给集群处理，不在模板侧改写。
- 字段按官方文档顺序渲染。

## 期望输入格式

```yaml
effect: <string>
key: <string>
operator: <string>
tolerationSeconds: <integer>
value: <string>
```

## 约束

- 字段顺序固定为 `effect`、`key`、`operator`、`tolerationSeconds`、`value`，与官方文档顺序一致。

## 非目标

- 本 change 不处理 Schema。

## 验收

- 仅提供部分字段时，输出只包含已提供的字段，且顺序符合约束。
- 全部字段缺省时模板可正常渲染，不产生错误。
- `key`、`value` 为 `null`、空字符串或仅含空白时，输出中不包含对应字段，且不中断渲染。
- `key` 为空但 `operator` 不是 `Exists` 时渲染中断。
- `operator` 为 `Exists` 但 `value` 非空时渲染中断。
- `operator` 为 `Gt` 或 `Lt` 但 `value` 为空时渲染中断。
- `operator` 省略时输出中不包含 `operator` 字段。
- `operator`、`effect` 取值不在给定枚举内时渲染中断；`operator` 小写形式（如 `exists`）同样中断。
- `effect` 为空字符串时输出中不包含该字段，且不中断渲染。
- `tolerationSeconds` 为 `0` 时输出为 `0`；为负数时按原值输出。

## 开放问题

- 无。
