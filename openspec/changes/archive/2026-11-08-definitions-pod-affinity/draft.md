---
change-id: definitions-pod-affinity
updated_at: "2026-11-08T14:25:04Z"
---

# definitions.podAffinity 模板

## 目标

- 新增核心命名模板 `definitions.podAffinity`，渲染 Kubernetes `PodAffinity` 字段片段。

## 需求

- `preferredDuringSchedulingIgnoredDuringExecution`：WeightedPodAffinityTerm array，逐项使用子模板 `definitions.weightedPodAffinityTerm` 占位。
- `requiredDuringSchedulingIgnoredDuringExecution`：PodAffinityTerm array，逐项使用子模板 `definitions.podAffinityTerm` 占位。
- 本模板只负责准备子模板所需的数据：把列表中每个 map 元素原样向下传递，不拆分 `weight`、不重组元素。
- 两个字段按 K8s 字段顺序（preferred 先、required 后）输出。
- 字段取值不是 array 或元素不是 map 时 fail-fast。
- 空 array 与空元素跳过，不输出。
- 两个占位子模板 `definitions.weightedPodAffinityTerm`、`definitions.podAffinityTerm` 在本 change 中不创建。

## 期望输入格式

- 入参为扁平形态：term 字段（`topologyKey`、`labelSelector`、`namespaceSelector`、`matchLabelKeys`、`namespaces`）与 `weight` 同级，不嵌套 `podAffinityTerm`。
- 用户给出的入参示例：

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

## 约束

- 顶层两个键仅识别规范长键并显式关闭别名；短键 `preferred`、`required` 由父级 `definitions.affinity` 归一化（同 `definitions.nodeAffinity`）。
- `*Alias` 由 `base.get` 隐式处理，本模板不显式编写别名逻辑。
- 子模板所需的去重、去空由底层 Helm 函数处理，本模板不实现清洗。
- `namespaces` 属于列表元素的内部字段，本模板不处理，交由后续子/孙模板处理。

## 非目标

- 不处理 `matchExpressions` 与 `matchFields`。
- 不处理元素内部字段（`topologyKey`、`labelSelector`、`namespaceSelector`、`matchLabelKeys`、`namespaces`、`weight` 的取值校验与归一化）。
- 不实现去重、去空。
- 不创建 `definitions.weightedPodAffinityTerm`。
- 不创建 `definitions.podAffinityTerm`。

## 验收

- `include "definitions.podAffinity"` 可渲染出合法 `PodAffinity` YAML 字段片段。
- 两个可选字段按 K8s 字段顺序输出，均无有效内容时不输出空字段。

## 开放问题

<!-- 暂无。 -->
