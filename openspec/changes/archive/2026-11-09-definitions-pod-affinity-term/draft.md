---
change-id: definitions-pod-affinity-term
updated_at: "2026-11-08T15:46:49Z"
---

# definitions.podAffinityTerm

## 目标

- 新增核心命名模板 `definitions.podAffinityTerm`，渲染 Kubernetes `PodAffinityTerm` 结构。

## 需求

- 入参为父模板传入的上下文 map 中的所有字段，统一由 `base.get` 取值，`*Alias` 由 `base.get` 隐式处理。
- 字段按 K8s 官方文档字段表顺序输出：`labelSelector`、`matchLabelKeys`、`mismatchLabelKeys`、`namespaceSelector`、`namespaces`、`topologyKey`。
- `labelSelector`：LabelSelector，可选，期望 map，数据交由 `definitions.labelSelector` 模板处理并回收 map；为空时不渲染；去重、去空由被委托模板负责。
- `namespaceSelector`：同 `labelSelector`。
- `matchLabelKeys`：string array，可选，期望 array，为空时不渲染；列表项按标签键语法校验并去重、去空。
- `mismatchLabelKeys`：同 `matchLabelKeys`。
- `namespaces`：string array，可选，为空时不渲染；列表项若为 `a b` 形式，由公共模板按 `SPACE_COMMA` 分隔符清洗并解析为 `[a, b]`；清洗结果去重、去空，并按命名空间名语法校验（RFC1123）。
- `topologyKey`：string，必填，非空且通过标签键语法校验（前缀可选 + 名称段）；为空或非法时报错中断。
- `matchLabelKeys`、`mismatchLabelKeys` 的标签键校验与 `topologyKey` 使用同一套规则（前缀可选 + 名称段）。
- 本模板以 map 形态返回，由调用方配合 `fromYaml` 回收。

## 期望输入格式

- 用户给出的入参示例：

```yaml
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
```

## 约束

- `topologyKey` 缺失、为空或非法必须中断并报错，不得静默跳过或替换为默认值。
- `labelSelector`、`namespaceSelector` 的内部结构由 `definitions.labelSelector` 负责，本模板不解析 `matchExpressions`、`matchLabels`。
- `namespaces` 的拆分与清洗由公共模板完成，本模板不内联分隔符正则。
- 去重、去空统一使用底层 Helm/Sprig 能力，本模板不实现自建清洗逻辑。

## 非目标

- 不创建 `definitions.labelSelector` 模板。
- 不处理 `labelSelector`、`namespaceSelector` 内部的 `matchExpressions`、`matchLabels` 及其字符串简写。
- 不实现去重、去空的自定义算法。

## 验收

- 传入符合示例形态的数据时，输出包含已提供字段的 `PodAffinityTerm` 结构，字段顺序为文档序，`namespaces` 中的 `aaa bbb` 被解析为 `aaa`、`bbb` 两项。
- `topologyKey` 缺失、为空或不符合标签键语法时，渲染中断并返回错误。
- `matchLabelKeys`、`mismatchLabelKeys`、`namespaces` 为空 array 或清洗后为空时，不渲染对应字段。
- `labelSelector`、`namespaceSelector` 为空 map 或委托模板返回空内容时，不渲染对应字段。

## 开放问题

<!-- 暂无。 -->
