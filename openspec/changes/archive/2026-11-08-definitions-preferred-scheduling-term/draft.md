---
change-id: definitions-preferred-scheduling-term
updated_at: "2026-11-08T06:35:15Z"
---

# definitions.PreferredSchedulingTerm

## 目标

- 新增 `definitions.PreferredSchedulingTerm` 模板，用于渲染 Kubernetes `PreferredSchedulingTerm` 结构。

## 需求

- 入参由父模板传入，为 `preferredDuringSchedulingIgnoredDuringExecution` 下的单项数据，类型为 map，可包含 `weight` 与 `preference`。
- `weight` 为必填 integer，取值只能是数字，非数字时中断报错；取值范围 1 - 100，不在范围内同样中断报错。
- `preference` 不是必填；缺失或为空时不渲染该字段，只输出 `weight`。
- `preference` 直接向下传递，作为子模板 `definitions.nodeSelectorTerm` 的入参。
- `preference` 使用子模板 `definitions.nodeSelectorTerm` 占位，本次不创建该子模板。
- 子模板返回的数据是 map，配合 `fromYaml` 处理，与其他模板的处理方式一致。
- 本模板同样以 map 形态返回，由调用方配合 `fromYaml` 回收。
- 子模板回收结果必须为 map；本 change 只关注该结果是否为 map。

## 期望输入格式

- 用户给出的入参示例：

```text
weight: 1
preference:
  matchExpressions:
    - c != d
  matchFields:
    - aa in (xx1, xx2, 123333)
```

## 约束

- `weight` 校验失败必须中断并报错，不得静默跳过或替换为默认值。
- `weightAlias`、`preferenceAlias` 由 `base.get` 隐式识别，本模板不额外实现别名映射。
- 本 change 只交付 `definitions.PreferredSchedulingTerm`；`definitions.nodeSelectorTerm` 只引用、不创建，其入参由本 change 直接把 `preference` 向下传递。
- 子模板回收结果只按 map 判定，与其他模板的处理方式保持一致。

## 非目标

- 不创建 `definitions.nodeSelectorTerm` 子模板。

## 验收

- 传入符合示例形态的数据时，输出包含 `weight` 与 `preference` 的 `PreferredSchedulingTerm` 结构，其中 `preference` 由 `definitions.nodeSelectorTerm` 生成。
- `weight` 缺失、非数字或超出 1 - 100 时，渲染中断并返回错误。
- `preference` 缺失或为空时，输出只包含 `weight`，不输出 `preference` 字段。
- 子模板回收结果不是 map 时渲染中断。

## 开放问题

- 暂无。
