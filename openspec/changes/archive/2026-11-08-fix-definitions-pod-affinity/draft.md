---
change-id: fix-definitions-pod-affinity
updated_at: "2026-11-08T15:14:06Z"
---

# 修正 definitions.podAffinity 的 weightedPodAffinityTerm 上下文

## 目标

- 修正 `definitions.podAffinity` 中对子模板 `definitions.weightedPodAffinityTerm` 的上下文处理逻辑。

## 需求

- `definitions.weightedPodAffinityTerm` 的上下文必须是 map，包含 `podAffinityTerm` 与 `weight` 两个键。
- 构造该上下文时，元素中除 `weight` 及其同级 `weightAlias` 外的其余字段必须原样放到 `podAffinityTerm` 键下。
- `weight` 与 `weightAlias` 由 `base.get` 隐式处理，`weightAlias` 不得进入 `podAffinityTerm`。
- `weight` 缺失、为 `null` 或为空字符串时必须中断报错。
- `weight` 只能是 integer，其他类型必须中断报错；带引号的数字必须中断报错。
- `weight` 的 1-100 取值范围不在本层校验。
- 向子模板传递的 `podAffinityTerm` 是必填项，合并结果为空 map 或取值非法时必须中断报错。
- 元素本身已含 `podAffinityTerm` 键时，其余字段必须合并到该 `podAffinityTerm` map 内，不得再嵌套一层。
- 合并时以元素已有的 `podAffinityTerm` 为主：同名键冲突时保留 `podAffinityTerm` 内的值。
- 元素已有的 `podAffinityTerm` 为空 map 时按 map 接受并继续合并；不是 map 时必须中断报错。
- `requiredDuringSchedulingIgnoredDuringExecution` 对 `definitions.podAffinityTerm` 的现有处理不变。

## 期望输入格式

- `definitions.podAffinity` 的入参仍为扁平形态：`weight` 与术语字段在同一个元素 map 中同级。
- 用户给出的入参示例（沿用上一 change 记录）：

```yaml
preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 11
    topologyKey: topologyKey-preferred
    namespaceSelector:
      matchExpressions:
        - "!partition1"
      matchLabels:
        matchLabels-pod-affinity: zzz
    labelSelector:
      matchExpressions:
        - "!partition2"
      matchLabels:
        matchLabels-pod-affinity: zzz
    matchLabelKeys: []
    namespaces:
      - aaa bbb
      - c
requiredDuringSchedulingIgnoredDuringExecution:
  - topologyKey: topologyKey-required
    namespaceSelector:
      matchExpressions:
        - "!partition1"
      matchLabels:
        matchLabels-pod-affinity: zzz
    labelSelector:
      matchExpressions:
        - "partition2"
        - ssss != aaa
      matchLabels:
        matchLabels-pod-affinity: zzz
    matchLabelKeys: []
    namespaces:
      - aaa bbb
      - c
```

## 非目标

- 不创建 `definitions.weightedPodAffinityTerm`。
- 不创建 `definitions.podAffinityTerm`。
- 不处理术语字段（`topologyKey`、`labelSelector`、`namespaceSelector`、`matchLabelKeys`、`namespaces`）的内部语义。
- 不修改 `requiredDuringSchedulingIgnoredDuringExecution` 的透传行为。

## 验收

- `definitions.weightedPodAffinityTerm` 收到 `weight` 与 `podAffinityTerm` 两个键，`podAffinityTerm` 下含元素其余全部字段且取值不变。
- `weight` 缺失、为 `null` 或为空字符串时渲染中断并返回错误。
- `weight` 为 string、bool、map 或 array 时渲染中断并返回错误。
- `weight` 为带引号的数字时渲染中断并返回错误；`weight` 超出 1-100 时不中断。
- 元素只有 `weight` 时，渲染中断并返回错误（`podAffinityTerm` 必填）。
- 元素已含 `podAffinityTerm` 时，其余字段出现在该 map 内，且层级不增加。
- 同名键冲突时，输出采用 `podAffinityTerm` 内的值。
- 元素已有的 `podAffinityTerm` 为空 map 且存在其他字段时继续合并；合并后仍为空 map 或不是 map 时渲染中断并返回错误。
- `weightAlias` 与 `weight` 同时存在时，`weight` 取值遵循 `base.get` 别名优先规则，且 `weightAlias` 不出现在 `podAffinityTerm` 下。
- `definitions.podAffinityTerm` 仍收到未经包装的元素本体。

## 开放问题

<!-- 暂无。 -->
