---
status: reviewed
updated_at: "2026-08-28T06:55:59Z"
---

# definitions.objectMeta 命名模板规格

## 技术目标

- capability：`definitions.objectMeta`
- artifact-type：Helm 命名模板（Kubernetes 原生 API 共享结构）
- target：`templates/api-resources/Definitions/_ObjectMeta.tpl` 中的 `definitions.objectMeta`
- direct-dependencies：`base.get`、`base.field`、`base.map`、`base.isFromYamlError`、`base.rfc`、`base.labels`、`base.name`、`base.namespace`

## 代码锚点

- `templates/api-resources/Definitions/_ObjectMeta.tpl`

## Purpose

提供可由 Kubernetes 原生资源模板复用的 `ObjectMeta` YAML 字段片段，并按资源身份统一选择注解来源、名称校验模式和命名空间渲染边界。

## ADDED Requirements

### Requirement: 上下文身份与输出边界

系统 MUST 以传入的 map 上下文 `.` 作为唯一调用上下文，并以非空 `_pkind` 优先于非空 `_kind` 的顺序确定有效资源身份。系统 MUST 只读使用 `_pkind` 和 `_kind`，不得渲染、注入或覆盖这两个控制字段。

系统 MUST 输出不包含 `metadata` 外层键的 `ObjectMeta` YAML 字段片段，并按 `annotations`、`generateName`、`labels`、`name`、`namespace` 的顺序处理本规格允许生效的字段。

#### Scenario: 父资源身份覆盖当前资源身份

- **WHEN** `_pkind` 与 `_kind` 均为非空字符串
- **THEN** 所有按资源身份决定的字段来源、渲染条件和校验模式 MUST 使用 `_pkind`

#### Scenario: 退回当前资源身份

- **WHEN** `_pkind` 缺失或为空且 `_kind` 为非空字符串
- **THEN** 所有按资源身份决定的字段来源、渲染条件和校验模式 MUST 使用 `_kind`

#### Scenario: 控制字段不进入输出

- **WHEN** 模板完成有效上下文的渲染
- **THEN** 输出 MUST NOT 包含 `_pkind` 或 `_kind` 字段，也 MUST NOT 包含本规格未列出的其他 `ObjectMeta` 字段

### Requirement: annotations 来源隔离

系统 MUST 将 `annotations` 作为可选的 `map[string]string` 字段。有效资源身份为 `PodTemplateSpec`、`JobTemplateSpec` 或 `PersistentVolumeClaim` 时，系统 MUST 分别只从 `podAnnotations`、`jobAnnotations` 或 `pvcAnnotations` 读取该字段；其他资源身份 MUST 从 `annotations` 读取。专用来源不得与通用 `annotations` 合并，也不得在专用来源缺失或为空时回退到通用 `annotations`。

#### Scenario: Pod 模板使用专用注解

- **WHEN** 有效资源身份为 `PodTemplateSpec` 且 `podAnnotations` 为非空 map
- **THEN** 系统 MUST 将 `podAnnotations` 渲染为 `annotations`，并忽略通用 `annotations`

#### Scenario: Job 模板使用专用注解

- **WHEN** 有效资源身份为 `JobTemplateSpec` 且 `jobAnnotations` 为非空 map
- **THEN** 系统 MUST 将 `jobAnnotations` 渲染为 `annotations`，并忽略通用 `annotations`

#### Scenario: PVC 使用专用注解且不回退

- **WHEN** 有效资源身份为 `PersistentVolumeClaim`、`pvcAnnotations` 缺失或为空且通用 `annotations` 非空
- **THEN** 系统 MUST NOT 渲染 `annotations`

#### Scenario: 普通资源使用通用注解

- **WHEN** 有效资源身份不属于三个专用注解资源且 `annotations` 为非空 map
- **THEN** 系统 MUST 将通用 `annotations` 渲染为 `annotations`

#### Scenario: 注解值类型非法

- **WHEN** 当前有效注解来源为非空值但不能恢复为 map
- **THEN** 系统 MUST 中断渲染并报告 `definitions.objectMeta` 的注解字段类型错误

### Requirement: generateName 与 name 互斥

系统 MUST 通过 `base.get` 的既有数据源优先级解析 `name` 和 `generateName`。系统 MUST 将 `generateName` 作为可选字符串，并且仅在 `name` 的解析结果为空时允许其生效。生效的 `generateName` MUST 先由 `base.rfc` 的 `1035` 模式校验；校验成功后系统 MUST 渲染 `generateName` 并省略 `name`。`name` 的解析结果非空时，系统 MUST 忽略 `generateName`。

对于允许渲染 `name` 的资源身份，如果 `generateName` 未生效，系统 MUST 通过 `base.name` 渲染必需的 `name` 字段；不得以其他调用替代 `base.name`，且 `definitions.objectMeta` 对 `base.name` 的直接调用不得用于其他字段。

#### Scenario: 显式空 name 启用 generateName

- **WHEN** `name` 显式传入空字符串、其他数据源也没有可用的非空 `name`，且 `generateName` 的解析结果为非空字符串
- **THEN** 系统 MUST 以 `1035` 模式校验并渲染 `generateName`，且 MUST NOT 渲染 `name`

#### Scenario: 缺失 name 启用 generateName

- **WHEN** `name` 的解析结果为空且 `generateName` 的解析结果为非空字符串
- **THEN** 系统 MUST 以 `1035` 模式校验并渲染 `generateName`，且 MUST NOT 渲染 `name`

#### Scenario: name 抑制 generateName

- **WHEN** `name` 与 `generateName` 的解析结果均为非空字符串
- **THEN** 系统 MUST NOT 渲染 `generateName`，并 MUST 按有效资源身份通过 `base.name` 渲染 `name`

#### Scenario: generateName 校验失败

- **WHEN** 生效的 `generateName` 不符合 `base.rfc` 的 `1035` 契约
- **THEN** 系统 MUST 中断渲染并传播 `base.rfc` 的失败

### Requirement: name 资源模式

系统 MUST 根据有效资源身份选择 `base.name` 的校验模式：`ClusterRole`、`Role`、`ClusterRoleBinding` 和 `RoleBinding` 使用 `rbac` 模式，`APIService` 使用 `apiservice` 模式，其他允许渲染名称的资源身份使用 `base.name` 的默认 `name` 模式。有效资源身份为 `PodTemplateSpec` 或 `JobTemplateSpec` 时，系统 MUST NOT 渲染 `name`。

#### Scenario: RBAC 名称校验

- **WHEN** 有效资源身份为 `ClusterRole`、`Role`、`ClusterRoleBinding` 或 `RoleBinding` 且 `generateName` 未生效
- **THEN** 系统 MUST 将原始上下文 `.` 和 `rbac` 模式传给 `base.name`，并将其结果渲染为 `name`

#### Scenario: APIService 名称校验

- **WHEN** 有效资源身份为 `APIService` 且 `generateName` 未生效
- **THEN** 系统 MUST 将原始上下文 `.` 和 `apiservice` 模式传给 `base.name`，并将其结果渲染为 `name`

#### Scenario: 嵌套模板不渲染 name

- **WHEN** 有效资源身份为 `PodTemplateSpec` 或 `JobTemplateSpec`
- **THEN** 系统 MUST NOT 渲染 `name`

#### Scenario: 名称依赖校验失败

- **WHEN** `base.name` 拒绝当前上下文或名称
- **THEN** 系统 MUST 中断渲染并传播 `base.name` 的失败

### Requirement: labels 委托

系统 MUST 将 `labels` 作为可选的 `map[string]string` 字段，并且 MUST 将原始上下文 `.` 直接传给 `base.labels`。`definitions.objectMeta` MUST 按 `base.labels` 的既有契约决定缺省输出，不得增加调用条件、合并规则或缺省值。

#### Scenario: labels 输入存在

- **WHEN** 原始上下文包含 `base.labels` 支持的标签输入
- **THEN** 系统 MUST 将 `base.labels` 返回的 map 渲染为 `labels`

#### Scenario: labels 输入缺失

- **WHEN** 原始上下文不包含可用的 `labels`
- **THEN** 系统 MUST 仍调用 `base.labels`，并按其既有缺省契约处理 `labels`

#### Scenario: labels 返回值非法

- **WHEN** `base.labels` 的非空返回值不能恢复为 map
- **THEN** 系统 MUST 中断渲染并报告 `definitions.objectMeta` 的 `labels` 返回类型错误

### Requirement: namespace 委托与资源边界

系统 MUST 将 `namespace` 作为可选字符串。有效资源身份不属于 `PodTemplateSpec`、`JobTemplateSpec`、`PersistentVolumeClaim`、`ClusterRole` 和 `ClusterRoleBinding` 时，系统 MUST 将原始上下文 `.` 直接传给 `base.namespace` 并将返回值渲染为 `namespace`；`definitions.objectMeta` 不得增加调用条件或缺省值。属于上述资源身份时，系统 MUST NOT 渲染 `namespace`。

#### Scenario: 普通命名空间资源

- **WHEN** 有效资源身份不属于 namespace 排除列表
- **THEN** 系统 MUST 按 `base.namespace` 的既有契约渲染 `namespace`

#### Scenario: 嵌套或集群级对象不渲染 namespace

- **WHEN** 有效资源身份为 `PodTemplateSpec`、`JobTemplateSpec`、`PersistentVolumeClaim`、`ClusterRole` 或 `ClusterRoleBinding`
- **THEN** 系统 MUST NOT 渲染 `namespace`

#### Scenario: namespace 依赖校验失败

- **WHEN** `base.namespace` 拒绝当前上下文或 namespace 值
- **THEN** 系统 MUST 中断渲染并传播 `base.namespace` 的失败

## 非目标

- 不新增或修改 `annotations`、`podAnnotations`、`jobAnnotations`、`pvcAnnotations`、`generateName`、`labels`、`name`、`namespace` 的 values、Schema、样例或用户文档。
- 不修改 `base.get`、`base.field`、`base.map`、`base.isFromYamlError`、`base.rfc`、`base.labels`、`base.name` 或 `base.namespace` 的既有契约与实现。
- 不渲染本规格列出的五个字段以外的 `ObjectMeta` 字段，也不负责渲染外层 `metadata` 字段。
