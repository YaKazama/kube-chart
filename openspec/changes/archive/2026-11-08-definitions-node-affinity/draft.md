---
change-id: definitions-node-affinity
updated_at: "2026-11-07T16:32:54Z"
---

# definitions.nodeAffinity

## 目标

- 新增核心命名模板 `definitions.nodeAffinity`，渲染 Kubernetes `NodeAffinity` 字段片段。

## 需求

- 模板名固定为 `definitions.nodeAffinity`。
- 该模板是 `templates/api-resources/Definitions/_Affinity.tpl` 中 `definitions.affinity` 已委托的三类子结构之一，需能被现有委托调用正常消费。
- 入参为已归一化的 `NodeAffinity` map，由 `definitions.affinity` 向下传递规范长键 `preferredDuringSchedulingIgnoredDuringExecution` 与 `requiredDuringSchedulingIgnoredDuringExecution`。
- 归一化只使用规范长键：两个入参键名由父级 `definitions.affinity` 收敛后传入，本模板不识别短键。
- `preferredDuringSchedulingIgnoredDuringExecution`：`PreferredSchedulingTerm` array，逐项委托子模板 `definitions.preferredSchedulingTerm` 占位，不创建子模板。
  - `weight`：本 change 只判断是否存在；缺失或为空时中断渲染。合法范围 1 - 100 的校验是 `definitions.preferredSchedulingTerm` 的任务。
  - `matchExpressions`、`matchFields` 作为 `preference`（`NodeSelectorTerm`）的字段向下传递；两者都为空时仍向子模板传递空 `preference`。
  - 该字段为空时不输出该字段。
- `requiredDuringSchedulingIgnoredDuringExecution`：`NodeSelector`，把 term 数组包裹为 `nodeSelectorTerms` 后委托子模板 `definitions.nodeSelector` 占位，不创建子模板；后续 `definitions.nodeSelector` 从 `nodeSelectorTerms` 键取值。
  - `matchExpressions`、`matchFields` 作为 `nodeSelectorTerms`（`NodeSelectorTerm` array）的元素字段向下传递；两者都为空时仍向子模板传递空 term。
  - 该字段为空时不输出该字段。
- 任一 term 不是 map 时中断渲染。
- 子项字段识别 `weightAlias`、`matchExpressionsAlias`、`matchFieldsAlias`；向子模板传递的是清洗后的数据，`*Alias` 由 `base.get` 隐式归一化为规范键，不使用 `base.get` 时才需显式列出别名键向下传递。
- 读取两个规范长键时通过 `base.get` 显式关闭别名识别。
- 模板输出可嵌入 `affinity.nodeAffinity` 下的 YAML 字段片段。

## 期望输入格式

- 入参数据示例：

```text
  preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 1
      matchExpressions:
        - c != d
      matchFields:
        - aa in (xx1, xx2, 123333)
  requiredDuringSchedulingIgnoredDuringExecution:
    - matchExpressions:
        - a = b
      matchFields:
        - key: fields
          operator: NotIn
          values:
          - value1
          - value2
```

- `preferredDuringSchedulingIgnoredDuringExecution` 向下传递的数据示例：

```text
weight: 1
preference:
  matchExpressions:
    - xxx
  matchFields:
    - xxx
```

- `requiredDuringSchedulingIgnoredDuringExecution` 向下传递的数据示例：

```text
nodeSelectorTerms:
  - matchExpressions:
      - xxx
    matchFields:
      - xxx
```

## 约束

- 遵循现有 Definitions 目录已落地模板的取值、规范化与失败处理约定。
- `definitions.preferredSchedulingTerm` 与 `definitions.nodeSelector` 只以模板名称占位引用，本 change 不创建其 `define` 实现。
- 新增模板文件固定为 `templates/api-resources/Definitions/_NodeAffinity.tpl`。

## 非目标

- 不修改 `definitions.affinity` 的既有委托行为。
- 不实现 `definitions.preferredSchedulingTerm`、`definitions.nodeSelector`、`definitions.nodeSelectorTerm` 等被依赖的结构模板。
- 不纳入 `nodeSelector` 字段：`NodeAffinity` 在 Kubernetes v1.36 官方字段表中只有上述两个字段。

## 验收

- `definitions.nodeAffinity` 可被 `definitions.affinity` 的 `nodeAffinity` 分支调用并渲染出符合 K8s API 规范的片段。
- 在 `/tmp/` 最小 application Chart 中执行 `helm template` 通过；该 Chart 以同名 fixture 提供 `definitions.preferredSchedulingTerm` 与 `definitions.nodeSelector`，验收时假设两者返回的数据正确，只验证本模板的取值、包裹、委托与输出行为。

## 开放问题

- 无。
