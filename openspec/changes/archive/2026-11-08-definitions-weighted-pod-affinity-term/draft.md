---
change-id: definitions-weighted-pod-affinity-term
updated_at: "2026-11-08T15:33:08Z"
---

# definitions.weightedPodAffinityTerm

## 目标

- 新增核心命名模板 `definitions.weightedPodAffinityTerm`，渲染 Kubernetes `WeightedPodAffinityTerm` 结构。

## 需求

- 入参由父模板传入，为 `preferredDuringSchedulingIgnoredDuringExecution` 下的单项 map，包含 `weight` 与 `podAffinityTerm`。
- 扁平形态（term 字段与 `weight` 同级）由父模板 `definitions.podAffinity` 归一化为嵌套形态后传入；本模板只接收已归一化、恒为嵌套形态的 map。
- `weight` 为必填 integer，由 `base.get` 校验；缺失或非法时报错中断。
- `weight` 取值必须是 1 - 100 范围内的 int 数字，其他类型或越界时报错中断。
- 带引号的数字（如 `weight: "11"`）剥离 YAML 引号后按整数接受。
- `podAffinityTerm` 为必填，使用子模板 `definitions.podAffinityTerm` 占位，本 change 不创建该子模板。
- `podAffinityTerm` 为空 map 或非法时报错中断。
- `podAffinityTerm` 的内容原样直接向子模板 `definitions.podAffinityTerm` 传递，本模板不拆分或重组其内部字段。
- 验收时假设子模板回收的是正确的 map。
- 本模板以 map 形态返回，由调用方配合 `fromYaml` 回收。
- 输出字段顺序为 `weight` 在后、`podAffinityTerm` 在前；YAML 键序不影响语义。

## 期望输入格式

- 用户给出的入参示例：

```yaml
weight: 11
podAffinityTerm:
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

- `weight` 与 `podAffinityTerm` 的任何校验失败都必须中断并报错，不得静默跳过或替换为默认值。
- `base.get` 隐式识别 `*Alias`，本模板不额外实现别名映射。
- 子模板 `definitions.podAffinityTerm` 只引用、不创建。

## 非目标

- 不创建 `definitions.podAffinityTerm` 子模板。
- 不处理 `podAffinityTerm` 内部字段（`topologyKey`、`labelSelector`、`namespaceSelector`、`matchLabelKeys`、`namespaces` 等）的取值校验与归一化。
- 不实现扁平形态到嵌套形态的归一化，该职责属于父模板 `definitions.podAffinity`。
- 不实现去重、去空。

## 验收

- 传入符合示例形态的数据时，输出包含 `weight` 与 `podAffinityTerm` 的 `WeightedPodAffinityTerm` 结构，其中 `podAffinityTerm` 由 `definitions.podAffinityTerm` 生成。
- `weight` 缺失、非 int 数字或超出 1 - 100 时，渲染中断并返回错误。
- `podAffinityTerm` 缺失、为空 map 或非法时，渲染中断并返回错误。

## 开放问题

<!-- 暂无。 -->
