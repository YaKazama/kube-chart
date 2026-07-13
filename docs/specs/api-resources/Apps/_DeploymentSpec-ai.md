# apps.DeploymentSpec

## 功能描述

`apps.deploymentSpec` 是 kube-chart 中负责渲染 Kubernetes `Deployment` 资源 `spec` 字段的命名模板。它是 `apps.deployment` 模板（资源级）的下层实现，专门处理 `apps/v1` DeploymentSpec 规范定义的全部 8 个字段，按 K8s API 规范字段顺序输出 YAML 键值对。

模板入口仅接收由 `apps.deployment` 透传的根上下文 `.`，不在 `spec` 字段渲染中引入新的入参范式。其核心特性：

- **统一收口**：所有字段的取值、类型识别、空值守卫、必填校验集中在 `apps.deploymentSpec` 一处处理，上层 `apps.deployment` 不感知 `spec` 内部结构。
- **委托优先**：selector 委托 `definitions.labelSelector`，template 委托 `core.podTemplateSpec`，strategy 委托 `apps.deploymentStrategy`。本层仅做类型规整与参数透传，不重复实现下层语义。
- **规整后透传**：strategy 字段同时支持 string（通过正则解析）与 object（原生定义）两种入参，本层统一规整为 dict 后再透传，下层不再区分类型。
- **基线安全**：默认字段全部以 K8s API 缺省值处理（minReadySeconds=0, paused=false, progressDeadlineSeconds=600, replicas=1, revisionHistoryLimit=10），本层仅在用户显式设置且合法时才输出，避免显式值污染 K8s 默认行为。

## 接口与参数描述

### 入参

唯一上下文 `.`，由 `apps.deployment` 透传。下层解析时通过 `.` 直接读取 `.Context.*` 下的 spec 字段。

### 核心字段

`apps.deploymentSpec` 读取 `Context` 下的以下字段：

| 字段 | 类型 | 必填 | 默认 | 渲染条件 | 渲染方式 |
|------|------|------|------|----------|----------|
| `minReadySeconds` | int | 否 | K8s 默认 0 | 显式值 `> 0` | `base.field` 数字 |
| `paused` | bool | 否 | K8s 默认 false | 显式 `true` | `base.field` 布尔 |
| `progressDeadlineSeconds` | int | 否 | K8s 默认 600 | 显式值 `> 0` | `base.field` 数字 |
| `replicas` | int | 否 | K8s 默认 1 | 显式值 `>= 0` | `base.field` 数字 |
| `revisionHistoryLimit` | int | 否 | K8s 默认 10 | 显式值 `>= 0` | `base.field` 数字 |
| `selector` | object | 是 | 无 | 必填 | 委托 `definitions.labelSelector` |
| `strategy` | string/object | 否 | K8s 默认 RollingUpdate 25% 25% | 显式设置 | 委托 `apps.deploymentStrategy` |
| `template` | object | 是 | 无 | 必填 | 委托 `core.podTemplateSpec` |

### 返回值

返回 DeploymentSpec 资源 YAML 键值对（不含 `spec` 父键），由 `apps.deployment` 调用方包入 `spec` 块。示例：

```yaml
selector:
  matchLabels:
    app: nginx
template:
  metadata: {}
  spec:
    containers: []
```

## 核心业务逻辑与实现细节

按 K8s API 规范字段顺序分 8 步渲染。

### Step 1: minReadySeconds (int)

通过 `base.get` 强制以 int 类型取值，输出 trim 后用 `atoi` 解析为整数。`base.get` 返回的字符串为 `""` 时跳过；解析结果 `> 0` 时通过 `base.field` 渲染。约束：

- `0` 等同缺省：不渲染。
- `< 0` 非法：不渲染。
- 兼容 Helm 4.2.2 `fromYaml` 对基本类型返回错误 map 的 BUG，因此直接对 `base.get` 输出做 `atoi`，而非先 `fromYaml` 再取字段。

### Step 2: paused (bool)

通过 `base.get` 取值后 trim，直接与字符串 `"true"` 等值比较。仅在显式 `true` 时通过 `base.field` 渲染布尔值。

- 兼容 Helm 4.2.2 `fromYaml` 对基本类型返回错误 map 的 BUG：不做 `fromYaml` 转换。
- 显式 `false` 不渲染：交给 K8s 默认值处理，避免与缺省状态重复。

### Step 3: progressDeadlineSeconds (int)

与 Step 1 相同模式。约束：

- `> 0` 时渲染。
- `<= 0` 不渲染（K8s 要求必须为正整数，0 与负数均非法）。

### Step 4: replicas (int)

与 Step 1 相同模式，但允许 `0` 显式设置（K8s 允许 `replicas: 0` 表示缩容到零）。约束：

- `>= 0` 时渲染。
- `< 0` 不渲染。

### Step 5: revisionHistoryLimit (int)

与 Step 4 相同模式，允许 `0` 显式设置（K8s 允许 `revisionHistoryLimit: 0` 表示不保留历史）。约束：

- `>= 0` 时渲染。
- `< 0` 不渲染。

### Step 6: selector (object, 必填)

`selector` 是必填项，处理流程：

1. 通过 `base.get` 取值，trim 后判空（空串或 `"null"` 立即 `fail`）。
2. `fromYaml` 解析为 map，委托 `base.isFromYamlError` 检测 Helm 4.2.2 `fromYaml` BUG，非 map 类型立即 `fail`。
3. 通过 `base.labels` 读取当前上下文的标签集合，与 `selector.matchLabels` 合并：
   - 若 `selector.matchLabels` 已存在（map 类型）：`mustMerge` 合并。
   - 若不存在：直接使用 `base.labels`。
4. 委托 `definitions.labelSelector` 渲染，输出非空时通过 `base.field` 渲染。

### Step 7: strategy (string/object)

`strategy` 是可选字段，处理流程：

1. 入口处声明 `$strategyVal := dict`，保证下游统一接收 dict 而非混合类型。
2. 通过 `base.get` 取值并 trim，判空（`""` 或 `"null"` 跳过）。
3. 类型识别 + 规整为 dict：
   - object 路径：`fromYaml` 解析为 map 时（通过 `base.isFromYamlError` + `kindIs "map"` 双重校验），`mustDeepCopy` 复制后赋给 `$strategyVal`，避免污染上游 `.Values`。
   - string 路径：先从 `base.env` 读取 `APPS.DEPLOYMENT.STRATEGY` 正则（集中管理，硬编码到 `templates/base/_env.tpl`），用 `mustRegexMatch` 预校验整串匹配后，通过 `regexReplaceAll` 的三个捕获组提取：
     - `${1}` → `type`（`Recreate` 或 `RollingUpdate`）
     - `${2}` → `rollingUpdate.maxSurge`
     - `${3}` → `rollingUpdate.maxUnavailable`
   - 规整原则：
     - 空字符串不写入 dict（如 `type` 为空时不写入）。
     - `maxSurge` 与 `maxUnavailable` 同时为空时跳过 `rollingUpdate` 整体。
     - 正则整串不匹配时不渲染 strategy 整体（避免 `{type: ""}` 这种无效输出）。
4. 规整完成后，在外层统一 `if $strategyVal` 守卫下委托 `apps.deploymentStrategy`，下层不再区分 string/object 类型。
5. 委托输出非空时通过 `base.field` 渲染。

设计原则：先在 `DeploymentSpec` 层把入参规整为统一的 dict 形态，再透传给下层。下层 `apps.deploymentStrategy` 仅需实现对 dict 的渲染，无需关心 string 解析逻辑。

### Step 8: template (object, 必填)

`template` 是必填项，处理流程：

1. 通过 `base.get` 取值，trim 后判空（空串或 `"null"` 立即 `fail`）。
2. `fromYaml` 解析为 map，委托 `base.isFromYamlError` 检测 Helm 4.2.2 `fromYaml` BUG，非 map 类型立即 `fail`。
3. 委托 `core.podTemplateSpec` 渲染（上下文透传 `.`），输出非空时通过 `base.field` 渲染。

## 系统约束与异常处理

### 边界行为

按 `docs/rules/const-general.md` 强约束执行：

- **必填项缺失**：`selector` 与 `template` 缺失或 `base.get` 返回 `"null"` 时立即 `fail` 中断渲染，错误格式遵循 `[apps.deploymentSpec] 字段路径: 错误原因`。
- **类型非法**：必填项传入非 map 类型时立即 `fail`，避免下游 `fromYaml` 解析异常。
- **Helm 4.2.2 `fromYaml` BUG 兼容**：map/dict 类型字段统一通过 `base.isFromYamlError` 检测后再使用。
- **基本类型 BUG 兼容**：`minReadySeconds` 等 int / bool 字段直接对 `base.get` 输出做 `atoi` 或字符串比较，绕过 `fromYaml`。

### 状态隔离

- object 类型 strategy 通过 `mustDeepCopy` 复制后赋给 `$strategyVal`，避免上游 `.Values` 被修改。
- 委托调用 `definitions.labelSelector` / `core.podTemplateSpec` / `apps.deploymentStrategy` 时分别构造独立上下文（`$selectorVal` / `.` / `$strategyVal`），不直接修改 `.`。

### 集中常量管理

- strategy 正则位于 `templates/base/_env.tpl` 的 `APPS.DEPLOYMENT.STRATEGY` 路径，命名遵循「大写 + 下划线 + 嵌套字典」约定，避免散布在模板中。
- 模板中通过 `include "base.env" "" | fromYaml` 读取，禁止在模板中重复定义正则。

### 错误格式

- 必填缺失：`[apps.deploymentSpec] selector: required field is missing or empty`
- 类型非法：`[apps.deploymentSpec] selector: must be map type`
- 委托输出为空：上层 `apps.deployment` 侧负责检查，本层不重复校验。

### 已知未实现依赖

`apps.deploymentSpec` 委托的以下下层模板当前尚未实现（由后续 spec 任务负责）：

- `apps.deploymentStrategy`：strategy 字段的最终渲染
- `definitions.labelSelector`：selector 字段的最终渲染
- `core.podTemplateSpec`：template 字段的最终渲染

`apps.deploymentSpec` 自身按规范完整实现，对下层的委托调用已具备正确性，但端到端渲染需要在这些下层模板实现后才能通过。

## 参考

- API：
  - <https://kubernetes.io/docs/reference/kubernetes-api/apps/deployment-v1/#DeploymentSpec>
  - <https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#deploymentspec-v1-apps>
- 实现参考：
  - `docs/rules/const-general.md`：通用约束
  - `docs/rules/const-example-code.md`：模板语法示例
  - `docs/samples/env.tpl`：正则常量集中管理参考
  - `templates/base/_env.tpl`：当前正则常量定义
  - `templates/base/_get.tpl`：`base.get` 取值机制
  - `templates/base/_field.tpl`：`base.field` 渲染机制
- 上层调用：
  - `templates/api-resources/Apps/_Deployment.tpl`：`apps.deployment` 资源级模板
  - `docs/specs/api-resources/Apps/_Deployment.md`：上层 spec
