---
change-id: definitions-pod-os
updated_at: "2026-11-09T13:47:06Z"
---

# definitions.podOS

## 目标

- 提供可复用的 `definitions.podOS` 模板。

## 需求

- 模板接受父级传递的上下文对象。
- 输入示例：

  ```yaml
  name: linux
  ```

- `name` 枚举校验 `linux`、`windows`。
- `name` 统一强制小写。
- `name` 为空时不渲染。
- `name` 非法时报错并中断渲染。
- 枚举校验交由 `base.field` 承担时，失败处理由 `base.field` 持有。

## 期望输入格式

- 上下文对象提供 `name` 字段。

## 约束

- 入参由父级上下文传入，模板不负责构造完整父对象。
- 校验失败的错误信息归各自主导模板处理，委托的其他模板保留其自身前缀。

## 非目标

- 不覆盖 `PodOS` 以外的其他结构，如 `PodSchedulingGate`、`PodResourceClaim`。

## 验收

- 合法 `name` 渲染为 `PodOS` 结构。
- 大写或其他大小写混合的合法值归一化为小写后渲染。
- `name` 为空时不产生渲染内容。
- `name` 不是 `linux` 或 `windows` 时报错并中断渲染。
