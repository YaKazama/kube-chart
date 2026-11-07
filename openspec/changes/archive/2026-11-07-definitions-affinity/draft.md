---
change-id: definitions-affinity
updated_at: "2026-11-07T14:34:43Z"
---

# Definitions Affinity

## 目标

- 为 Chart 补充 Affinity 相关的命名模板能力，使调用方可以按统一入口渲染调度亲和性结构。

## 需求

- 本 change 只实现 `definitions.affinity`：读取 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 三类子结构，完成字段取值与别名归一化后向下传递。
- 子结构模板分别为 `definitions.nodeAffinity`、`definitions.podAffinity`、`definitions.podAntiAffinity`；本 change 只以模板名称占位引用，不创建其实现。
- 向下传递的上下文是包含 `preferredDuringSchedulingIgnoredDuringExecution`、`requiredDuringSchedulingIgnoredDuringExecution` 的 map。
- 向下传递的 map 使用长键名 `preferredDuringSchedulingIgnoredDuringExecution`、`requiredDuringSchedulingIgnoredDuringExecution` 作为规范键名，短键名不出现在输出中。
- `preferredDuringSchedulingIgnoredDuringExecution` 的显式别名是 `preferred`。
- `requiredDuringSchedulingIgnoredDuringExecution` 的显式别名是 `required`。
- 构造向下传递的 map 的固定顺序：先取 `preferred` / `required` 的值，非空时即作为最终值；短键为空或缺失时退化取对应规范长键的值；两者都为空时该字段不向下传递。
- `preferred` / `required` 与对应长键不是互斥关系；短键优先级高于长键，与别名优先级约束一致。
- `preferred`、`required` 与对应规范长键各自的 `<叶子>Alias` 交给 `base.get` 隐式处理，本层不额外建立别名映射；短键作为长键的显式别名，同时仍然继承自身叶子的 `*Alias`。
- 整体取值优先级为：`preferred` / `required` 的同级 `*Alias` > `preferred` / `required` > 对应长键的同级 `*Alias` > 对应长键。
- `preferred`、`required` 或对应规范长键的取值不是 array（如 map、string）时中断渲染并报错。
- 子结构中不属于 `preferred` / `required` 映射的其余字段丢弃，不向下传递；只有丢弃需要大量独立代码时才改为原样传递。
- 本模板只负责取到当前层所需字段并继续向下传递；字段内部语义（`labelSelector`、`namespaceSelector`、`matchExpressions`、`namespaces`、`matchLabelKeys` 等）交由子模板处理，本模板不解析、不重排、不校验。
- `nodeAffinity` 与 `podAffinity`、`podAntiAffinity` 同批实现：`preferred` 对应 `preferredDuringSchedulingIgnoredDuringExecution`，`required` 对应 `requiredDuringSchedulingIgnoredDuringExecution`，两侧取值形态均按「期望输入格式」中的 array 处理。
- `nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution` 在本层是下层数据抽象后的统一形态，目的是与其他 Affinity 类型对齐；具体处理不在本 change 范围内。

## 期望输入格式

```text
nodeAffinity:
  preferred:
    - weight: 1
      matchExpressions:
        - c != d
      matchFields:
        - aa in (xx1, xx2, 123333)
  required:
    - matchExpressions:
        - a = b
    - matchFields:
        - key: fields
          operator: NotIn
          values:
          - value1
          - value2
podAffinity:
  preferred:
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
  required:
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
podAntiAffinity:
  preferred:
    - weight: 22
      topologyKey: topologyKey-preferred
      namespaceSelector:
        matchExpressions:
          - partition1
        matchLabels:
          matchLabels-pod-affinity: zzz
      labelSelector:
        matchExpressions:
          - aaa = cxxx
        matchLabels:
          matchLabels-pod-affinity: zzz
      matchLabelKeys:
        - labels1 labels2
  required:
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

- `definitions.affinity` 只出现在 `templates/api-resources/Definitions/` 共享结构层，命名空间为 `definitions.*`。
- 输入中 `preferred`、`required` 与对应规范长键的数据类型都是 array，与「期望输入格式」示例保持一致。
- 本 change 只组织向下传递的 map 的组织方式；孙模板所需的数据由子模板内部自行处理，本层不做任何预处理、派生或补齐。
- 本 change 不创建 `definitions.nodeAffinity`、`definitions.podAffinity`、`definitions.podAntiAffinity` 的 `define` 实现。
- 本 change 只新增 `definitions.affinity` 模板本身；`templates/api-resources/Core/_PodSpec.tpl` 已按既有方式调用该模板，不在本 change 修改。

## 非目标

- 不实现 `definitions.nodeAffinity`、`definitions.podAffinity`、`definitions.podAntiAffinity` 的内部字段渲染。
- 不实现 `PodAffinityTerm`、`WeightedPodAffinityTerm`、`PreferredSchedulingTerm`、`NodeSelector`、`NodeSelectorTerm`、`NodeSelectorRequirement` 的独立子模板。
- 不在本 change 处理 `mismatchLabelKeys`、`weight` 范围、`topologyKey` 非空等子结构字段校验。
- 不修改 `templates/api-resources/Core/_PodSpec.tpl`：该文件已存在 `include "definitions.affinity"` 调用，本 change 只需补齐被调用模板。
- 不校验子模板返回结构：验收时按规则约束假设子模板回传的数据正确。
- 不为孙模板（`preferredDuringSchedulingIgnoredDuringExecution`、`requiredDuringSchedulingIgnoredDuringExecution` 内部结构）构造任何数据形态。

## 开放问题

- 无。

## 验收

- `nodeAffinity`、`podAffinity`、`podAntiAffinity` 三个键的字段均被取到并按规范长键向下传递。
- `preferred` 与 `required` 别名输入归一化为 `preferredDuringSchedulingIgnoredDuringExecution`、`requiredDuringSchedulingIgnoredDuringExecution` 后向下传递：短键非空时取短键值，短键为空或缺失时取长键值，两者都为空时不输出该键。
- 取值顺序符合「短键别名 > 短键 > 长键别名 > 长键」，且短键与长键共用非空即生效的优先级链。
- `preferred` / `required` 或对应规范长键的取值不是 array 时渲染中断，错误信息包含 `[definitions.affinity]` 前缀与对应字段名。
- 验收只覆盖 `definitions.affinity` 自身的取值、别名归一化与向下传参；子模板回传数据按规则约束假设正确，不需要端到端渲染成功。
- 可通过 `helm template` 在 `/tmp/` 最小 Chart 中配合同名 fixture 子模板验证取值与传参边界。
