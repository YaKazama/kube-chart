# apps.DeploymentStrategy

## 功能描述

`apps.deploymentStrategy` 是 kube-chart 中负责渲染 Kubernetes `Deployment` 资源 `spec.strategy` 字段的命名模板。它是 `apps.deploymentSpec` 模板（spec 级）关于 strategy 渲染的下层实现，专门处理 `apps/v1` DeploymentStrategy 规范定义的 2 个字段（rollingUpdate、type），按 K8s API 规范字段顺序输出 YAML 键值对。

模板入口仅接收由 `apps.deploymentSpec` 透传的 dict 上下文（规整后的 `{type, rollingUpdate}`），不再区分入参的 string/object 类型差异。其核心特性：

- **统一收口**：所有字段的取值、类型识别、空值守卫、枚举校验集中在 `apps.deploymentStrategy` 一处处理，上层 `apps.deploymentSpec` 不感知 strategy 内部结构。
- **委托优先**：rollingUpdate 委托 `apps.rollingUpdateDeployment` 渲染。本层仅做类型校验与参数透传，不重复实现下层语义。
- **type 必渲染**：K8s 中 `type` 字段始终存在（隐式默认 `RollingUpdate`），本层无论上游是否显式设置均会渲染 type 字段，确保 K8s 端不会出现"type 缺失"这种隐式状态。
- **rollingUpdate 条件渲染**：严格遵循 K8s 规范"仅在 DeploymentStrategyType = RollingUpdate 时才渲染 rollingUpdate"，Recreate 类型时即使上游传入了 rollingUpdate 也会被静默跳过。
- **基线安全**：type 枚举仅允许 `Recreate` / `RollingUpdate`，非法值立即 `fail`，避免 K8s 静默接受未知策略。

## 接口与参数描述

### 入参

唯一上下文 dict，由 `apps.deploymentSpec` 在 strategy 字段规整（string 走正则、object 走 mustDeepCopy）后透传。下层解析时直接通过 `.` 读取 type、rollingUpdate 字段。

### 核心字段

`apps.deploymentStrategy` 读取上下文中的以下字段：

| 字段 | 类型 | 必填 | 默认 | 渲染条件 | 渲染方式 |
|------|------|------|------|----------|----------|
| `rollingUpdate` | object | 否 | K8s 默认 maxSurge=25% maxUnavailable=25% | `type == "RollingUpdate"` 且显式提供 | 委托 `apps.rollingUpdateDeployment` |
| `type` | string | 否 | `RollingUpdate` | 始终渲染 | `base.field` + `base.string` + 枚举校验 |

### 返回值

返回 DeploymentStrategy 资源 YAML 键值对（不含 `strategy` 父键），由 `apps.deploymentSpec` 调用方包入 `strategy` 块。示例：

```yaml
rollingUpdate:
  maxSurge: 25%
  maxUnavailable: 25%
type: RollingUpdate
```

## 核心业务逻辑与实现细节

按 K8s API 规范字段顺序分 3 步渲染。

### Step 1: 计算 type (string, 可选)

通过 `base.get` 取值后直接判空，无需 `trim`：`base.get` 返回的是 `toYamlPretty` 序列化后的字符串或空字符串，本身不带前后空白。处理流程：

1. 缺省时 `$_type` 为 `""`，落入 `else` 分支，填充默认值 `"RollingUpdate"`。
2. 显式 nil 时 `$_type` 为字符串 `"null"`，通过 `ne $_type "null"` 拦截，填充默认值。
3. 显式值（如 `"Recreate"` / `"RollingUpdate"`）时覆盖默认值。
4. 必填校验与枚举校验不放在本步，而是统一延迟到 Step 3 渲染时通过 `base.field` 配合 `base.string` 与 allows 列表完成。

设计原则：Step 1 只做默认值填充，类型合法性交给 Step 3 统一处理，避免重复校验逻辑。

### Step 2: rollingUpdate (object, 可选)

按 K8s API 字段顺序先于 type 渲染。处理流程：

1. 外层守卫：`type == "RollingUpdate"` 时进入分支；`Recreate` 类型时直接跳过本步，不渲染 rollingUpdate（即使上游 dict 中携带了 rollingUpdate 字段）。
2. 入口通过 `base.get` 取值后判空（`""` 或 `"null"` 跳过本步，不渲染）。
3. `fromYaml` 解析为 map，委托 `base.isFromYamlError` 检测 Helm 4.2.2 `fromYaml` BUG；解析失败或非 map 类型立即 `fail`。
4. 委托 `apps.rollingUpdateDeployment` 渲染（上下文透传 `$rollingUpdateVal`）。
5. 委托输出非空时通过 `base.field`（`base.map` 模式）渲染 `rollingUpdate` 键值对。

### Step 3: type (string, 可选)

按 K8s API 字段顺序后渲染。处理流程：

1. 通过 `base.field` 调用 `base.string` 模板 + allows 列表 `["Recreate" "RollingUpdate"]` 完成渲染与枚举校验。
2. 渲染前自动执行枚举校验：值不在允许列表中时立即 `fail`，错误信息遵循 `[base.field] type: value 'xxx' not in allowed list '[...]'` 格式。
3. `base.string` 内部完成 trim 与零模式折叠（与 type 字段实际值无交集），最终输出 `type: RollingUpdate` 或 `type: Recreate`。

设计原则：type 字段始终渲染，依赖 `base.field` 的非空输出机制 + `base.string` 的字符串校验，与 K8s 端"type 必存在"的语义对齐。

## 系统约束与异常处理

### 边界行为

按 `docs/rules/const-general.md` 强约束执行：

- **空值守卫**：`type` 缺省或 nil 时填充默认值 `"RollingUpdate"`，不报错；`rollingUpdate` 缺省或 nil 时跳过渲染，不报错。
- **必填项缺失**：本模板内无业务必填项（type 与 rollingUpdate 均为可选），无 `fail` 拦截。
- **类型非法**：`rollingUpdate` 传入非 map 类型（如 string、slice、int）时立即 `fail`，错误格式遵循 `[apps.deploymentStrategy] rollingUpdate: must be map type`。
- **枚举校验**：`type` 传入非 `Recreate` / `RollingUpdate` 字符串（包括数字、bool、空字符串、`"null"` 等）时立即 `fail`，由 `base.field` 拦截。
- **Helm 4.2.2 `fromYaml` BUG 兼容**：rollingUpdate 字段通过 `base.isFromYamlError` 检测后再使用；type 字段走 `base.field` + `base.string` 路径不触发该 BUG。
- **`base.get` 输出特性**：`base.get` 返回 `toYamlPretty` 序列化后的字符串或空字符串，不带前后空白，模板中无需 `trim`。

### 状态隔离

- 委托调用 `apps.rollingUpdateDeployment` 时透传 `$rollingUpdateVal`（`fromYaml` 后的独立 map 副本），不直接修改 `.`，避免污染上游 `.Context`。
- 不使用 `mustDeepCopy` 显式隔离：`fromYaml` 已返回新对象，调用方传入的 dict 在本层只读不写。

### 集中常量管理

- type 枚举列表 `["Recreate", "RollingUpdate"]` 直接内联在本模板 Step 3 的 `$typeAllows` 局部变量中，K8s 规范明文规定的有限枚举，无抽象价值，避免引入 `base.env` 间接层。
- 无新增正则常量。

### 错误格式

- rollingUpdate 类型非法：`[apps.deploymentStrategy] rollingUpdate: must be map type`
- type 枚举非法：`[base.field] type: value 'xxx' not in allowed list '[Recreate RollingUpdate]'`
- 委托模板 `apps.rollingUpdateDeployment` 不存在：底层 `include` 报错，错误信息由 Helm 默认提供。

### 已知未实现依赖

`apps.deploymentStrategy` 委托的以下下层模板当前尚未实现（由后续 spec 任务负责）：

- `apps.rollingUpdateDeployment`：rollingUpdate 字段的最终渲染

`apps.deploymentStrategy` 自身按规范完整实现，对下层的委托调用已具备正确性，但端到端渲染需要在 `apps.rollingUpdateDeployment` 实现后才能通过。

## 参考

- API：
  - <https://kubernetes.io/docs/reference/kubernetes-api/apps/deployment-v1/#DeploymentSpec>
  - <https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#deploymentstrategy-v1-apps>
- 实现参考：
  - `docs/rules/const-general.md`：通用约束
  - `docs/rules/const-example-code.md`：模板语法示例
  - `templates/base/_env.tpl`：当前正则常量定义（strategy 正则在 `APPS.DEPLOYMENT.STRATEGY`，由 `apps.deploymentSpec` 使用）
  - `templates/base/_get.tpl`：`base.get` 取值机制
  - `templates/base/_field.tpl`：`base.field` 渲染机制
  - `templates/base/_convert.tpl`：`base.isFromYamlError` 错误 map 检测
- 上层调用：
  - `templates/api-resources/Apps/_DeploymentSpec.tpl`：`apps.deploymentSpec` 模板（strategy 字段规整与透传）
  - `docs/specs/api-resources/Apps/_DeploymentSpec.md`：上层 spec
