# apps.DeploymentStrategy

## 1. 目标与交付约定

`apps.deploymentStrategy` 是 kube-chart 中负责渲染 Kubernetes `Deployment` 资源 `spec.strategy` 字段的命名模板。它是 `apps.deploymentSpec` 模板（spec 级）关于 strategy 渲染的下层实现，专门处理 `apps/v1` DeploymentStrategy 规范定义的 2 个字段（rollingUpdate、type），按 K8s API 规范字段顺序输出 YAML 键值对。

- **模板名称**：`apps.deploymentStrategy`
- **交付文件**：`templates/api-resources/Apps/_DeploymentStrategy.tpl`
- **入参来源**：唯一上下文 dict，由 `apps.deploymentSpec` 在 strategy 字段规整（string 走正则、object 走 mustDeepCopy）后透传。下层解析时直接通过 `.` 读取 type、rollingUpdate 字段。
- **整体渲染原则**：strategy 字段规整后的 dict 入参由本层统一收口处理（类型识别、空值守卫、枚举校验），下层不再区分 string/object 类型差异；rollingUpdate 委托 `apps.rollingUpdateDeployment` 渲染，type 通过 `base.field` + `base.string` + 枚举校验渲染。

## 2. 字段级功能需求

严格按照 K8s 官方 API 字段顺序排列。

### 2.1 rollingUpdate

| 属性 | 说明 |
|------|------|
| 类型 | object / map / string |
| 必填 | 否 |
| 默认 | K8s 默认 `maxSurge=25%` `maxUnavailable=25%`（不显式渲染） |
| 渲染条件 | `type == "RollingUpdate"` 且显式提供（`""` / `"null"` / `"{}"` 均视为缺省） |
| 渲染方式 | 委托 `apps.rollingUpdateDeployment` |
| 入参类型处理 | object/map: 原样透传给委托；string: 通过 `^(\d+\%?)?(?:\s+(\d+\%?))?$` 正则解析为 dict 后再委托；其他类型 (slice/int/bool) 立即 `fail` |

**多类型归一化（3 分支）**：

- **case 1 (object/map)**：`fromYaml` 解析为 map 且非 error map → 视为 dict 直接委托。
- **case 2 (string)**：`fromYaml` 返回 error map（Helm 4.2.2 BUG），但剥去 `base.get` 单引号转义后的原始字符串能匹配 rollingUpdate 正则 → 视为 string，按 `${1}` / `${2}` 提取 `maxSurge` / `maxUnavailable` 并 `trim`，构造为 dict 后委托。
- **case 3 (非法类型)**：以上两条均不满足（如 slice、int、bool）→ 立即 `fail`。

### 2.2 type

| 属性 | 说明 |
|------|------|
| 类型 | string |
| 必填 | 否 |
| 默认 | `RollingUpdate` |
| 渲染条件 | 始终渲染（缺省或 `null` 时填充默认值） |
| 渲染方式 | `base.field` + `base.string` + 枚举校验 `["Recreate" "RollingUpdate"]` |

### 2.3 返回值

返回 DeploymentStrategy 资源 YAML 键值对（不含 `strategy` 父键），由 `apps.deploymentSpec` 调用方包入 `strategy` 块。示例：

```yaml
rollingUpdate:
  maxSurge: 25%
  maxUnavailable: 25%
type: RollingUpdate
```

## 3. 核心业务逻辑与实现细节

按 K8s API 规范字段顺序分 3 步渲染。

### Step 1: 计算 type (string, 可选)

通过 `base.get` 取值后直接判空，无需 `trim`：`base.get` 返回的是 `toYamlPretty` 序列化后的字符串或空字符串，本身不带前后空白。处理流程：

1. 缺省时 `$_typeRaw` 为 `""`，通过 `and $_typeRaw (ne $_typeRaw "null") (ne $_typeRaw "")` 守卫拦截，填充默认值 `"RollingUpdate"`。
2. 显式 nil 时 `$_typeRaw` 为字符串 `"null"`，通过 `ne $_typeRaw "null"` 拦截，填充默认值。
3. 显式值（如 `"Recreate"` / `"RollingUpdate"`）时覆盖默认值。
4. 必填校验与枚举校验不放在本步，而是统一延迟到 Step 3 渲染时通过 `base.field` 配合 `base.string` 与 allows 列表完成。
5. 顶层声明 `$strategyType` 避免 Helm 变量作用域在 if 分支内不可见的限制。

设计原则：Step 1 只做默认值填充，类型合法性交给 Step 3 统一处理，避免重复校验逻辑。

### Step 2: rollingUpdate (object/map/string, 可选)

按 K8s API 字段顺序先于 type 渲染。处理流程：

1. **外层守卫**：`type == "RollingUpdate"` 时进入分支；`Recreate` 类型时直接跳过本步，不渲染 rollingUpdate（即使上游 dict 中携带了 rollingUpdate 字段，K8s 会忽略）。
2. **缺省守卫**：通过 `base.get` 取值后判空，兼容三种"无值"情形并跳过渲染：
   - `""`（缺省）
   - `"null"`（显式 nil）
   - `"{}"`（显式空 map，`base.get` 返回字面量 `{}`，`fromYaml "{}"` 在 Helm 4.2.2 返回 nil，BUG 需短路保护）
3. **类型归一化（3 分支）**：
   - `fromYaml` 解析为 `$parsed`，计算 `$isErr := eq (include "base.isFromYamlError" $parsed) "true"`、`$isMap := and (kindIs "map" $parsed) (not $isErr)`、`$rUnquoted := regexReplaceAll $const.SYS.YAML_QUOTED $_rollingUpdateRaw "$1" | trim`（剥去 `base.get` 对含前后空白字符串的单引号转义并 trim 内部残留空白）、`$isRuString := and $isErr (mustRegexMatch $ruPattern $rUnquoted)`。
   - **case 1 (object/map)**：`if $isMap` → 委托 `apps.rollingUpdateDeployment` 渲染（上下文透传 `$parsed`），输出非空时通过 `base.field`（`base.map` 模式）渲染。
   - **case 2 (string)**：`else if $isRuString` → 通过 `regexReplaceAll` 提取 `${1}` / `${2}` 捕获组并 `trim`，构造 `$ruDict := dict "maxSurge" $maxSurge "maxUnavailable" $maxUnavailable` 后委托 `apps.rollingUpdateDeployment`，输出非空时通过 `base.field` 渲染。
   - **case 3 (非法类型)**：`else` → 立即 `fail`，错误格式遵循 `[apps.deploymentStrategy] rollingUpdate: must be map or string type, got '<raw>' (kind: <kind>)`。

### Step 3: type (string, 可选)

按 K8s API 字段顺序后渲染。处理流程：

1. 通过 `base.field` 调用 `base.string` 模板 + allows 列表 `["Recreate" "RollingUpdate"]` 完成渲染与枚举校验。
2. 渲染前自动执行枚举校验：值不在允许列表中时立即 `fail`，错误信息遵循 `[base.field] type: value 'xxx' not in allowed list '[Recreate RollingUpdate]'` 格式。
3. `base.string` 内部完成 trim 与零模式折叠（与 type 字段实际值无交集），最终输出 `type: RollingUpdate` 或 `type: Recreate`。

设计原则：type 字段始终渲染，依赖 `base.field` 的非空输出机制 + `base.string` 的字符串校验，与 K8s 端"type 必存在"的语义对齐。

## 4. 专属边界行为

按 `docs/rules/const-general.md` + `docs/rules/const-boundary.md` 强约束执行。

### 通用边界

- **空值守卫**：`type` 缺省或 nil 时填充默认值 `"RollingUpdate"`，不报错；`rollingUpdate` 缺省 / nil / 空 map 时跳过渲染，不报错。
- **必填项缺失**：本模板内无业务必填项（type 与 rollingUpdate 均为可选），无 `fail` 拦截。
- **Helm 4.2.2 `fromYaml` BUG 兼容**：map/dict 类型字段通过 `base.isFromYamlError` 检测后再使用；type 字段走 `base.field` + `base.string` 路径不触发该 BUG。

### 专属边界

- **rollingUpdate 多类型归一化**：`rollingUpdate` 接受 object/map/string 三种入参，本层统一规整为 dict 后再委托 `apps.rollingUpdateDeployment`；string 走 `APPS.DEPLOYMENT.ROLLING_UPDATE` 正则解析（`templates/base/_env.tpl`），object/map 原样透传；其他类型 (slice/int/bool) 立即 `fail`。
- **string 检测必须叠加正则匹配**：单纯依赖 `base.isFromYamlError` 不足以区分 string 与 slice —— Helm 4.2.2 `fromYaml` 对 YAML 列表输入（如 `- a\n- b`）同样返回 error map BUG。必须在 `isErr` 基础上叠加 `mustRegexMatch $ruPattern $rUnquoted` 二次校验，slice 等非预期类型才会落入 case 3 fail 路径。
- **空 map 短路保护**：`base.get` 对空 map 返回字面量 `{}`，Helm 4.2.2 `fromYaml "{}"` 返回 nil（与正常 map 的 error map 表现不同），需用 `ne $raw "{}"` 守卫拦截，避免 `kindIs "map" nil` 误判导致静默跳过。
- **`base.get` 单引号转义剥离**：`base.get` 对含前后空白的字符串会包单引号（YAML 转义），正则解析前需用 `regexReplaceAll "^'(.*)'$" $_rollingUpdateRaw "$1"` 剥去外层单引号。
- **捕获组 trim**：regexReplaceAll 提取的 `${1}` / `${2}` 必须立即 `trim` 删除前后空格，避免空字符串导致 `apps.rollingUpdateDeployment` 渲染异常。
- **Recreate 静默跳过 rollingUpdate**：`type == "Recreate"` 时即使上游 dict 中携带了 rollingUpdate 字段也跳过渲染，符合 K8s 规范"仅在 RollingUpdate 时存在"。
- **type 必渲染**：与 K8s 端"type 必存在"语义对齐，无论上游是否显式设置均渲染 type 字段，避免 K8s 出现"type 缺失"隐式状态。

### 状态隔离

- 委托调用 `apps.rollingUpdateDeployment` 时透传 `$parsed`（`fromYaml` 后的独立 map 副本）或 `$ruDict`（本层构造的独立 dict），不直接修改 `.`，避免污染上游 `.Context`。
- 不使用 `mustDeepCopy` 显式隔离：`fromYaml` 已返回新对象，调用方传入的 dict 在本层只读不写。

### 集中常量管理

- type 枚举列表 `["Recreate", "RollingUpdate"]` 直接内联在本模板 Step 3 的 `$typeAllows` 局部变量中，K8s 规范明文规定的有限枚举，无抽象价值，避免引入 `base.env` 间接层。
- rollingUpdate 正则位于 `templates/base/_env.tpl` 的 `APPS.DEPLOYMENT.ROLLING_UPDATE` 路径，命名遵循「大写 + 下划线 + 嵌套字典」约定，模板中通过 `include "base.env" "" | fromYaml` 读取，禁止在模板中重复定义正则。
- YAML 单引号转义剥离正则位于 `templates/base/_env.tpl` 的 `SYS.YAML_QUOTED` 路径，集中管理。

### 错误格式

- rollingUpdate 类型非法：`[apps.deploymentStrategy] rollingUpdate: must be map or string type, got '<raw>' (kind: <kind>)`
- type 枚举非法：`[base.field] type: value 'xxx' not in allowed list '[Recreate RollingUpdate]'`
- 委托模板 `apps.rollingUpdateDeployment` 不存在：底层 `include` 报错，错误信息由 Helm 默认提供。

### 已知未实现依赖

`apps.deploymentStrategy` 委托的以下下层模板当前尚未实现（由后续 spec 任务负责）：

- `apps.rollingUpdateDeployment`：rollingUpdate 字段的最终渲染

`apps.deploymentStrategy` 自身按规范完整实现，对下层的委托调用已具备正确性，但端到端渲染需要在 `apps.rollingUpdateDeployment` 实现后才能通过。

## 5. 参考资料

- API：
  - <https://kubernetes.io/docs/reference/kubernetes-api/apps/deployment-v1/#DeploymentSpec>
  - <https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#deploymentstrategy-v1-apps>
- 实现参考：
  - `docs/rules/const-general.md`：通用约束
  - `docs/rules/const-boundary.md`：通用边界
  - `docs/rules/const-example-code.md`：模板语法示例
  - `templates/base/_env.tpl`：正则常量定义（`APPS.DEPLOYMENT.ROLLING_UPDATE`、`SYS.YAML_QUOTED`）
  - `templates/base/_get.tpl`：`base.get` 取值机制
  - `templates/base/_field.tpl`：`base.field` 渲染机制
  - `templates/base/_convert.tpl`：`base.isFromYamlError` 错误 map 检测
- 上层调用：
  - `templates/api-resources/Apps/_DeploymentSpec.tpl`：`apps.deploymentSpec` 模板（strategy 字段规整与透传）
  - `docs/specs/api-resources/Apps/_DeploymentSpec.md`：上层 spec
- 下层委托（待实现）：
  - `templates/api-resources/Apps/_RollingUpdateDeployment.tpl`（占位名 `apps.rollingUpdateDeployment`）
