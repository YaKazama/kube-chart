---
change-id: definitions-node-selector-requirement
updated_at: "2026-11-08T13:59:52Z"
---

# definitions.nodeSelectorRequirement 模板

## 目标

- 新增命名模板 `definitions.nodeSelectorRequirement`，渲染 Kubernetes `NodeSelectorRequirement` 字段片段。
- 该模板是 `definitions.nodeSelectorTerm` 已存在但当前缺失的依赖：父模板已完成条目归一化，逐条把清洗后的 map 委托给本模板。

## 需求

- 渲染单个 `NodeSelectorRequirement` 字段片段，供 `selector.nodeSelectorTerms` 的 `matchExpressions`、`matchFields` 条目使用。
- `key`、`operator`、`values` 三个字段的取值统一使用 `base.get`，不使用直接 map 读取。
- `*Alias` 由 `base.get` 隐式处理：`keyAlias`、`operatorAlias`、`valuesAlias` 非空时优先于对应规范键，本模板不额外维护别名映射。
- 入参为空 map（不含任何键）时不渲染，返回空字符串，不报错。
- `key` 为必填；非空 map 中缺失或为空时报错中断渲染，必填校验交给 `base.get` 的必填参数承担。
- `operator` 只接受 `DoesNotExist`、`Exists`、`Gt`、`In`、`Lt`、`NotIn`，校验大小写敏感；缺失或枚举校验不通过时报错中断渲染，必填校验交给 `base.get` 的必填参数承担。
- 本模板内重复校验 values 与 operator 的一致性：`In`、`NotIn` 必须非空；`Exists`、`DoesNotExist` 必须为空；`Gt`、`Lt` 必须恰好一个整数。不满足时报错中断渲染。
- `values` 元素为非 string 类型（如整数）时在本层转为 string。
- `values` 不再去重，按父级传入的顺序原样输出。
- `values` 不是数组类型时报错中断渲染。
- 输出按 API 字段顺序 `key`、`operator`、`values`。
- `Exists`、`DoesNotExist` 不输出 `values`，该行为必须显式表达，不依赖 `values` 为空时的省略逻辑。
- 本模板主动产生的失败消息使用 `[definitions.nodeSelectorRequirement]` 前缀，并携带字段名；委托其他能力完成的校验保留其自身前缀：`base.get` 的必填与取值保留 `[base.get]` 前缀，`base.field` 的枚举校验保留 `[base.field]` 前缀并输出合法枚举范围。

## 期望输入格式

- 入参是父级模板清洗后的 map，包含 `key`、`operator`、`values` 三个字段。
- 每个字段除规范键外还可以同名 `Alias` 键给出，别名由 `base.get` 隐式识别。
- `values` 的拆分、去空、去重与数值规范化由父级完成；本层只做元素字符串化和与 `operator` 的一致性校验。

## 约束

- 只消费父级清洗结果，不再重复父模板已完成的条目形态解析与 values 拆分去重。
- 别名识别全部由 `base.get` 隐式完成，本层不维护别名映射、不做别名与规范键的优先级判断。
- 信任父级内容：父级已对 values 去重，本层不再做去重或其他重复性处理。

## 非目标

- 不处理 string 条目解析、条目去重与 values 拆分或数值规范化；这些由 `definitions.nodeSelectorTerm` 承担。
- 不负责 `matchExpressions`、`matchFields` 两个数组字段的取值、去重与输出顺序。
- 本次不修改 `definitions.nodeSelectorTerm` 的既有实现。

## 验收

- 以 `{key: "kubernetes.io/os", operator: "In", values: ["linux"]}` 调用时输出合法的 `NodeSelectorRequirement` 片段。
- 六种 `operator` 枚举均可正常渲染。
- `values` 中的整数元素输出为字符串。
- 直调方传入重复 `values` 元素时按原样输出，不做去重。
- `keyAlias`、`operatorAlias`、`valuesAlias` 非空时优先于对应规范键生效。
- 空 map 入参返回空字符串且不产生输出。
- 缺少 `key`（字段缺失或空字符串）时渲染中断并返回错误。
- `key` 不是 string 类型时渲染中断并返回错误。
- `key` 或 `operator` 只含空白字符时渲染中断并返回错误。
- `operator` 不在六个枚举内，或以非规范大小写给出（如 `in`）时渲染中断并返回错误。
- `In`、`NotIn` 的 `values` 为空时渲染中断并返回错误。
- `Exists`、`DoesNotExist` 携带 `values` 时渲染中断并返回错误。
- `Exists`、`DoesNotExist` 的渲染结果中不含 `values` 字段，且该行为由显式分支保证。
- `Gt`、`Lt` 的 `values` 不是恰好一个整数时渲染中断并返回错误。
- `values` 不是数组类型时渲染中断并返回错误。

## 开放问题

- 无。
