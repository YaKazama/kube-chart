# apps.Deployment

## 功能描述

`apps.deployment` 是 kube-chart 中负责渲染 Kubernetes `Deployment` 资源（`apps/v1`）的命名模板，位于 `templates/api-resources/Apps/_Deployment.tpl`。它是父 Chart 编排 Deployments 时的入口模板，输出完整的 `Deployment` 资源 YAML（不含顶级 `---` 分隔符），由调用方决定是否插入文档边界。

模板只关心 4 个顶级字段（`apiVersion` / `kind` / `metadata` / `spec`），具体业务字段全部委托给下层：

- `metadata` 委托 `definitions.objectMeta`
- `spec` 委托 `apps.deploymentSpec`

核心设计原则：

- **职责收口**：本层不实现任何 spec 内部逻辑，仅做字段顺序编排与必要的必填校验，遵循「库 Chart 资源模板」职责边界。
- **顶层字段固定**：`apiVersion` / `kind` 是 K8s 资源身份字段，硬编码为 `apps/v1` / `Deployment`，不暴露给用户覆盖。
- **下层委托**：`metadata` 与 `spec` 字段的所有细节（标签、注解、选择器、副本数、模板等）由下层模板全权处理，本层不感知。
- **必填强校验**：`metadata` / `spec` 任一渲染失败立即 `fail`，遵循 `AGENTS.md`「尽早报错」硬约束。

## 接口与参数描述

### 入参

唯一上下文 `.`，由父 Chart 通过 `merge (dict "Context" .Values.Deployment) .` 构造后传入。模板内部通过 `.Context.*` 读取所有业务字段。

### 核心字段

| 字段 | 来源 | 类型 | 必填 | 渲染方式 |
|------|------|------|------|----------|
| `apiVersion` | 模板硬编码 | string | 必填 | `nindent 0 ""` 输出 `apps/v1` |
| `kind` | 模板硬编码 | string | 必填 | `nindent 0 ""` 输出 `Deployment` |
| `metadata` | `definitions.objectMeta` | object | 必填 | 委托渲染，必填校验 |
| `spec` | `apps.deploymentSpec` | object | 必填 | 委托渲染，必填校验 |

`Context` 下的元数据相关字段（`annotations` / `generateName` / `labels` / `name` / `namespace` 等）由 `definitions.objectMeta` 直接透传读取，详见该模板文档。

### 返回值

完整的 Deployment 资源 YAML 字段（不含顶级 `---`）。典型结构：

```yaml
apiVersion: "apps/v1"
kind: "Deployment"
metadata:
  name: nginx
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata: {}
    spec:
      containers: []
```

## 核心业务逻辑与实现细节

模板实现分为 3 个 Step，严格按 K8s API 规范字段顺序输出。

### Step 1: apiVersion / kind 硬编码

`apiVersion` 与 `kind` 是 K8s 资源的身份字段，由本层固定输出为 `apps/v1` 与 `Deployment`，不接受任何入参覆盖。

```go
{{- nindent 0 "" -}}apiVersion: "apps/v1"
{{- nindent 0 "" -}}kind: "Deployment"
```

- 使用 `nindent 0 ""` 而非字符串硬连接，确保前缀空白被精确控制为 0，与调用方注入的缩进对齐。
- 强约束：本层不读取任何入参的 `apiVersion` / `kind` 字段，下层模板与父 Chart 均不应尝试覆盖。

### Step 2: metadata (object, 必填)

`metadata` 是必填字段，委托 `definitions.objectMeta` 渲染。处理流程：

1. 在当前上下文上设置 `_kind = "Deployment"`，供 `definitions.objectMeta` 内部按资源类型决定字段裁剪（如是否包含 `namespace`）。
   - `definitions.objectMeta` 内部不修改源上下文（按其设计约定），无需 `mustDeepCopy`。
2. 委托 `definitions.objectMeta` 渲染，`fromYaml` 解析为 map。
3. 渲染结果为空（`metadata` 缺失）立即 `fail` 报错。
4. 渲染结果非空时通过 `base.field` 输出。

`definitions.objectMeta` 内部逻辑（由该模板独立负责）：

- 按 `_pkind > _kind` 取值，支持嵌套资源场景。
- 跳过 `PodTemplateSpec` / `JobTemplateSpec` / `StatefulSetSpec` 等嵌套资源不需要的字段。
- 元数据相关字段从 `.Context > .Values > .Values.global` 逐层取值。
- 名称字段遵循 RFC1035 校验，超 63 字符立即 `fail`。

### Step 3: spec (object, 必填)

`spec` 是必填字段，委托 `apps.deploymentSpec` 渲染。处理流程：

1. 透传上下文 `.` 给 `apps.deploymentSpec`。
2. 委托输出原始字符串，三重判空：
   - `$specRaw` 为空（下游模板未输出任何内容）：`fail` 报错。
   - `$specRaw | fromYaml` 解析后为空（下游输出但解析后是空 map）：`fail` 报错。
   - `base.isFromYamlError` 检测为 `true`（Helm 4.2.2 `fromYaml` BUG 导致返回错误 map）：`fail` 报错。
3. 解析结果非 map 类型：`fail` 报错。
4. 校验通过后通过 `base.field` 输出 `spec` 字段。

`apps.deploymentSpec` 内部处理 8 个字段（`minReadySeconds` / `paused` / `progressDeadlineSeconds` / `replicas` / `revisionHistoryLimit` / `selector` / `strategy` / `template`），详见 `_DeploymentSpec-ai.md`。

## 系统约束与异常处理

### 边界行为

按 `docs/rules/const-general.md` 与 `AGENTS.md` 强约束执行：

- **必填缺失**：`metadata` 或 `spec` 委托渲染结果为空时立即 `fail` 中断渲染。
- **类型非法**：`spec` 委托输出非 dict 类型时立即 `fail`。
- **Helm 4.2.2 `fromYaml` BUG 兼容**：`spec` 解析失败时委托 `base.isFromYamlError` 检测后再判断。
- **不兜底默认值**：`metadata` / `spec` 缺失不提供任何默认兜底（与 `AGENTS.md`「严禁用默认值兜底必填项缺失」一致）。

### 状态隔离

- `_kind` 直接设置在当前上下文上，依赖 `definitions.objectMeta` 内部不修改源上下文的设计约定，无需 `mustDeepCopy` 隔离。
- 不修改 `.Context` / `.Values` 任何字段。
- 委托调用 `definitions.objectMeta` 与 `apps.deploymentSpec` 时透传 `.`，由下层模板自行处理状态隔离。

### 渲染控制

- 模板首尾不输出 `---` 分隔符，符合 `AGENTS.md`「库 Chart 模板首尾严禁输出 `---`」硬约束。
- 顶层 4 个字段按 `apiVersion` → `kind` → `metadata` → `spec` 严格顺序输出，与 K8s API 规范一致。
- 顶部字段使用 `nindent 0 ""` 强制 0 缩进；委托字段使用 `base.field` 自动处理缩进与换行。

### 错误格式

- 必填缺失：`[apps.deployment] metadata: required field is missing or empty`
- 必填缺失：`[apps.deployment] spec: required field is missing or empty`
- 委托输出非法：`[apps.deployment] spec: invalid YAML output from definitions.deploymentSpec`
- 类型非法：`[apps.deployment] spec: must be dict type`

错误格式严格遵循 `AGENTS.md`「[模板名] 字段路径: 错误原因」约定。

### 已知未实现依赖

`apps.deployment` 委托的以下下层模板当前实现状态：

- `definitions.objectMeta`：已实现，位于 `templates/api-resources/Definitions/_ObjectMeta.tpl`。
- `apps.deploymentSpec`：已实现，位于 `templates/api-resources/Apps/_DeploymentSpec.tpl`。
- `apps.deploymentSpec` 内部委托的 `definitions.labelSelector` / `core.podTemplateSpec` / `apps.deploymentStrategy` 尚未实现（由后续 spec 任务负责）。

## 参考

- API：
  - <https://kubernetes.io/docs/reference/kubernetes-api/apps/deployment-v1/#Deployment>
  - <https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#deployment-v1-apps>
- 实现参考：
  - `docs/rules/const-general.md`：通用约束
  - `docs/rules/const-example-code.md`：模板语法示例
  - `AGENTS.md`：项目级硬约束（职责边界、状态隔离、错误格式等）
  - `templates/api-resources/Apps/_DeploymentSpec.tpl`：下层 `apps.deploymentSpec` 实现
  - `templates/api-resources/Definitions/_ObjectMeta.tpl`：下层 `definitions.objectMeta` 实现
  - `templates/base/_field.tpl`：`base.field` 渲染机制
  - `templates/base/_get.tpl`：`base.get` 取值机制
- 下层 spec：
  - `docs/specs/api-resources/Apps/_DeploymentSpec.md`：spec 描述
  - `docs/specs/api-resources/Apps/_DeploymentSpec-ai.md`：spec AI 重写版
