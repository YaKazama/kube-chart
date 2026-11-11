---
change-id: definitions-node-selector
updated_at: "2026-11-11T12:42:04Z"
---

# 新增 definitions.nodeSelector 模板

## 目标

- 创建缺失的 `definitions.nodeSelector` 命名模板，补齐 `definitions.nodeAffinity` 的 `requiredDuringSchedulingIgnoredDuringExecution` 分支所依赖的能力。

## 需求

- 创建命名模板 `definitions.nodeSelector`，放在 `templates/api-resources/Definitions/` 下的新文件中。
- 该模板 MUST 能被现有调用点 `templates/api-resources/Definitions/_NodeAffinity.tpl` 以 `include "definitions.nodeSelector" (dict "nodeSelectorTerms" $terms)` 的形式调用，并返回可由 `fromYaml` 恢复为 map 的 YAML 字段片段。
- 模板产出 MUST 作为 `requiredDuringSchedulingIgnoredDuringExecution` 的值，即包含 `nodeSelectorTerms` 字段的 NodeSelector 结构。
- `nodeSelectorTerms` 为 NodeSelectorTerm array，在 NodeSelector 结构中为 Required，必须有内容。
- `nodeSelectorTerms` 的输入只接受父级已归一化的 map 数组，本模板不解析字符串简写；数组元素不是 map 时中断渲染。
- `nodeSelectorTerms` 缺失、为空 array 或不是 array 时中断渲染。
- 列表中的每一项 MUST 传递到 `definitions.nodeSelectorTerm` 处理并回收其结果；不在本模板重复实现 `matchExpressions`、`matchFields` 的解析与校验。
- `definitions.nodeSelectorTerm` 返回空内容时不并入收集列表；收集结果为空 array 时中断渲染。
- 输出只包含 `nodeSelectorTerms` 一个字段，与官方 NodeSelector 结构一致。
- 本模板自身产生的失败消息统一使用 `[definitions.nodeSelector]` 前缀，并携带 `nodeSelectorTerms[<index>]` 路径。

## 期望输入格式

```
nodeSelectorTerms:
  - matchExpressions:
      - a = b
    matchFields:
      - key: fields
        operator: NotIn
        values:
        - value1
        - value2
      - aa in (xx1, xx2, 123333)
```

## 约束

- 仅使用 Helm 内置函数、Go Template、Sprig 与 Helm 特有函数。
- 命名模板使用 `definitions.<能力>` 命名空间，文件为 `templates/api-resources/Definitions/_NodeSelector.tpl`，满足 `templates/` 下文件以 `_` 开头的约定。
- 保持与既有 `Definitions` 模板一致的字段注释与契约注释风格。

## 非目标

- 不修改 `definitions.nodeAffinity`、`definitions.nodeSelectorTerm` 及其他既有模板。
- 不处理 `definitions.affinity` 中 `nodeAffinity` 之外的字段。
- 不新增或修改任何 `base.*` 公共能力模板。

## 验收

- `templates/api-resources/Definitions/` 下存在定义 `definitions.nodeSelector` 的文件。
- 以 `dict "nodeSelectorTerms" <map 数组>` 调用时返回只含 `nodeSelectorTerms` 的合法 YAML。
- 每项按输入顺序委托 `definitions.nodeSelectorTerm` 并回收其结果；子模板返回空内容的项不出现在输出中。
- 收集结果为空 array 时渲染中断。
- `nodeSelectorTerms` 缺失、为空 array、不是 array 或含非 map 元素时渲染中断，失败消息使用 `[definitions.nodeSelector]` 前缀并携带 `nodeSelectorTerms[<index>]`。
- `definitions.nodeAffinity` 的 `requiredDuringSchedulingIgnoredDuringExecution` 分支可完整渲染，不再因模板缺失而中断。
- 既有 `preferredDuringSchedulingIgnoredDuringExecution` 分支行为不变。

## 开放问题

- 无。
