---
change-id: definitions-resource-claim
updated_at: "2026-11-15T09:03:54Z"
---

# definitions.resourceClaim 模板

## 目标

- 新增命名模板 `definitions.resourceClaim`，把父级传入的 `resourceClaim` 映射为容器 `resources.claims` 数组元素。

## 需求

- 模板名为 `definitions.resourceClaim`。
- 入参为单个 map，`name` 与 `request` 均为 string。
- 入参已由父级模板清洗，本模板不承担入参归一化职责。
- `name` 在设置该条资源声明时必填；缺失或为空白时中断渲染。
- `request` 可选；未设置时不输出该字段。
- 入参中 `name`、`request` 之外的键静默忽略，只输出这两个字段。
- `name` 不做名称格式校验，只做标量解码与空值判断。
- 返回值为 map，允许为空；调用方以空结果剔除该条目。
- 输出字段与 Kubernetes v1.36 `core/v1 ResourceClaim` 一致，顺序为 `name`、`request`。
- 未配置资源声明时不渲染任何内容，该判断由父级调用点负责。
- 返回形式为可由 `fromYaml` 解析为 map 的 YAML 片段，与同域 definitions 模板一致。
- `request` 按 YAML 标量解码并 trim 后为空时视为未设置。

## 期望输入格式

- 单个 map 参数，键为 `name`、`request`，值均为 string。
- 额外键允许存在，但不参与渲染。

## 约束

- 遵循项目基线：Kubernetes API `>= v1.36.0`，Helm `>= 4.0.0`。
- 仅使用 Helm 内置函数、Go Template、Sprig 与 Helm 特有函数。
- 只做入参到输出的映射，不引入额外字段或默认值策略。
- 调用方 `definitions.resourceRequirements` 以 `include` + `fromYaml` 委托本模板，空或非法 YAML 结果由调用方剔除。

## 非目标

- 不修改父级模板的调用点或 Pod spec 集成。
- 除 `name` 必填判定外，不新增其他校验、清洗或默认值补全逻辑。
- 不校验 `name` 与 Pod `spec.resourceClaims` 条目的对应关系。
- 不更新 README、`docs/` 或样例。

## 验收

- 命名模板 `definitions.resourceClaim` 存在且可被 `include` 调用。
- 传入含非空 `name` 且 `request` 为空的 map 时，返回仅含 `name` 的 map。
- 传入含 `name` 与 `request` 的 map 时，返回依 `name`、`request` 顺序排列的 map。
- `name` 缺失或为空白时渲染中断。
- 入参含额外键时，输出不包含这些键。

## 开放问题

- 无。
