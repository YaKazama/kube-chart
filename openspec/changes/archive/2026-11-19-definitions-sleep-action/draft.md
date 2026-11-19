---
change-id: definitions-sleep-action
updated_at: "2026-11-19T14:04:50Z"
---

# 新增 definitions.sleepAction 模板

## 目标

- 新增模板 `definitions.sleepAction`，用于渲染 Kubernetes `SleepAction` 字段片段。

## 需求

- 模板上下文为 map。
- 输入字段为 `seconds`，只接受整数语义：`int`、`int64`、值为整数的 `float64`。
- 字符串（包括纯数字字符串）、bool、非整数值的 `float64`、list、map 均非法，中断报错。
- `float64` 的整数值（如 `30.0`）合法，渲染为 integer。
- `seconds` 缺失、为 `null` 或为空字符串 `""` 时不渲染，模板输出为空内容且不报错。
- `seconds` 必须大于 0；0 与负数中断报错。
- `seconds` 超过 `float64` 安全整数上限 9007199254740991 时中断报错。

## 期望输入格式

- map，包含 `seconds: integer`。
- `seconds` 只接受整数语义数值；`null`、空字符串 `""` 与缺失等价，均不渲染。

## 约束

- 本次只新增 `definitions.sleepAction` 模板。
- `*Alias` 由 `base.get` 隐式处理，本模板不单独定义别名规则。
- 不重复、不过度判断上下文是否为 map。

## 非目标

- 不处理 `lifecycle`、`postStart`、`preStop` 等父级字段。
- 不校验 sleep 时长在 Kubernetes 运行时的实际约束。

## 验收

- `seconds` 为 `int`、`int64` 或整数值 `float64` 时正常渲染，输出 `seconds` 为 integer。
- `seconds` 缺失、为 `null` 或 `""` 时输出为空内容，不报错。
- `seconds` 为 0、负数、字符串（含纯数字字符串）、bool、小数 `float64`、list 或 map 时中断报错。
- `seconds` 超过 9007199254740991 时中断报错，不因精度丢失而静默截断。
