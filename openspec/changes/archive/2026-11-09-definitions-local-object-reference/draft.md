---
change-id: definitions-local-object-reference
updated_at: "2026-11-09T13:33:26Z"
---

# definitions.localObjectReference

## 目标

- 提供可复用的 `definitions.localObjectReference` 模板。

## 需求

- 模板接受父级传递的上下文对象。
- 输入示例：

  ```yaml
  name: xxx
  ```

- `name` 值采用 RFC 1035 校验。
- `name` 为空或缺失时不渲染。
- `name` 不符合 RFC 1035 时中断渲染并报错。
- 输出为 Kubernetes `LocalObjectReference` 结构，仅包含 `name` 字段，与官方文档一致。

## 期望输入格式

- 上下文对象提供 `name` 字段。

## 约束

- 入参由父级上下文传入，模板不负责构造完整父对象。
- 校验失败的错误信息由各自主导模板持有：本模板自身产生的失败使用本模板前缀，委托的其他模板保留其自身前缀。

## 非目标

- 不覆盖 `ObjectReference`、`SecretReference`、`TypedLocalObjectReference` 等其他引用类型。

## 验收

- 合法 `name` 渲染为 `LocalObjectReference` 结构。
- `name` 为空或缺失时不产生渲染内容。
- 不符合 RFC 1035 的 `name` 渲染失败。
