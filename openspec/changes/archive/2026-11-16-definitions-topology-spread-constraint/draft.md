---
change-id: definitions-topology-spread-constraint
updated_at: "2026-11-16T05:37:50Z"
---

# definitions.topologySpreadConstraint 模板

## 目标

- 新增 `definitions.topologySpreadConstraint` 模板，用于渲染 Kubernetes `TopologySpreadConstraint` 子对象。

## 需求

- 支持渲染 `labelSelector`、`matchLabelKeys`、`maxSkew`、`minDomains`、`nodeAffinityPolicy`、`nodeTaintsPolicy`、`topologyKey`、`whenUnsatisfiable` 八个字段。
- 调用与入参形态为原生 map：以单个上下文 map 作为入参，从该 map 读取上述八个字段。
- `whenUnsatisfiable`、`topologyKey`、`maxSkew` 必填，其余字段可选。
- `whenUnsatisfiable` 按 `DoNotSchedule`、`ScheduleAnyway` 枚举校验。
- `nodeAffinityPolicy`、`nodeTaintsPolicy` 按 `Honor`、`Ignore` 枚举校验。
- 所有枚举校验大小写敏感，不做大小写归一化。
- `maxSkew` 不允许为 `0`，为 `0` 时渲染中断。
- `minDomains` 必须大于 `0`，小于等于 `0` 时渲染中断。
- `labelSelector` 直接向子模板 `definitions.labelSelector` 透传数据；本模板只传递上下文、引用、回收结果并渲染，其余交由子模板处理。
- 未设置 `labelSelector` 时不得设置 `matchLabelKeys`，违反时渲染中断。
- `matchLabelKeys` 逐项按 string 校验，剔除空项后去重，复用既有公共模板处理。
- `topologyKey` 复用 `base.labelKey` 校验。
- 字段按官方文档顺序渲染。

## 期望输入格式

```yaml
labelSelector: <map>              # LabelSelector，透传 definitions.labelSelector
matchLabelKeys: <string array>
maxSkew: <integer>
minDomains: <integer>
nodeAffinityPolicy: <string>
nodeTaintsPolicy: <string>
topologyKey: <string>
whenUnsatisfiable: <string>
```

`labelSelector` 示例：

```yaml
matchExpressions:
  - "!partition1"
matchLabels:
  matchLabels11: xxx
```

## 约束

- 字段顺序固定为 `labelSelector`、`matchLabelKeys`、`maxSkew`、`minDomains`、`nodeAffinityPolicy`、`nodeTaintsPolicy`、`topologyKey`、`whenUnsatisfiable`；已在本地参考 `openspec/references/kubernetes-api-v1.36.html` 的 `TopologySpreadConstraint` 定义处核对一致。
- `maxSkew`、`minDomains` 为整数；`maxSkew` 不允许为 `0`，`minDomains` 必须大于 `0`。
- `matchLabelKeys` 为字符串数组。

## 非目标

- 本 change 不处理 Schema。
- 不处理其他 PodSpec 字段，也不组合多个资源。

## 验收

- 仅提供部分字段时，输出只包含已提供的字段，且顺序符合约束。
- `whenUnsatisfiable`、`topologyKey` 或 `maxSkew` 缺失时渲染中断。
- `whenUnsatisfiable` 取值不在 `DoNotSchedule`、`ScheduleAnyway` 内时渲染中断；小写形式（如 `donotschedule`）同样中断。
- `nodeAffinityPolicy`、`nodeTaintsPolicy` 取值不在 `Honor`、`Ignore` 内时渲染中断；小写形式（如 `honor`）同样中断。
- `maxSkew` 为 `0` 时渲染中断。
- `minDomains` 为 `0` 或负数时渲染中断。
- `labelSelector` 有值时输出以 `labelSelector` 为父键的字段片段，内容由 `definitions.labelSelector` 决定。
- `matchLabelKeys` 有值但 `labelSelector` 未设置时渲染中断。
- `matchLabelKeys` 中的空项被剔除，重复项被去重，非 string 元素中断。
- `topologyKey` 不符合标签键语法时渲染中断。

## 开放问题

- 无。
