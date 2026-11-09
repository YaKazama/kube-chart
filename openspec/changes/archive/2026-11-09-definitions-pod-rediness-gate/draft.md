---
change-id: definitions-pod-rediness-gate
updated_at: "2026-11-09T14:03:17Z"
---

# definitions.podReadinessGate 模板

## 目标

- 新增模板 `definitions.podReadinessGate`，供父级渲染 Pod readinessGate 条目。

## 需求

- 创建模板 `definitions.podReadinessGate`。
- 入参为父级传递的上下文，示例：`conditionType: xxx`。
- `conditionType` 仅允许 string 类型；非法类型指非 string，不校验取值合法性。
- `conditionType` 为空时不渲染；键缺失与值为 `null` 均视为空。
- 输出遵循 Kubernetes 官方 `PodReadinessGate` 定义，只包含 `conditionType` 字段。
- `conditionType` 去除首尾空白后必须强制加引号输出，避免 `on`、`yes`、`true` 等文本被父级 YAML 重解析为非字符串。
- 模板渲染单个 readinessGate 条目，`readinessGates` 数组的循环与条目合并由父级负责。

## 期望输入格式

- 父级上下文传入 `conditionType`，示例：

  ```yaml
  conditionType: xxx
  ```

## 约束

- 类型报错由本模板自行维护，不扩散到公共模板或其他 definitions 模板。

## 验收

- 父级传入非空 string 类型的 `conditionType` 时，模板正常渲染该条目。
- 渲染结果中的值以带引号标量输出。
- `conditionType` 为空时不渲染该项。
- `conditionType` 为非法类型时模板渲染失败并报错。
