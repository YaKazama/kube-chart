# core.PodTemplateSpec

## 目标与交付约定

新增命名模板 `core.podTemplateSpec`，写入 `templates/api-resources/Core/_PodTemplateSpec.tpl`。入参为唯一上下文 `.`（由上层 `apps.deploymentSpec` 透传），按 K8s 官方 API 字段顺序（`metadata` → `spec`）渲染 `PodTemplateSpec` 资源，不渲染 `status` 字段。

模板仅做字段委托与上下文透传，不在 PodTemplateSpec 层做新增取值或合并逻辑：

- **统一收口**：`metadata` / `spec` 字段的取值、校验、渲染分别委托给 `definitions.objectMeta` / `core.podSpec`，本模板不感知内部细节。
- **透传优先**：两个字段的渲染均直接透传 `.` 上下文，不做中间加工。
- **依赖外置**：`core.podSpec` 由其他 spec 任务负责实现，本模板不创建。
- **入参契约**：调用方需保证 `.` 为 PodTemplateSpec 形态——`metadata` / `spec` 字段位于 `.` 顶层（即 `apps.deploymentSpec` 调用时应提取 `.template` 字段值后透传，而非透传整个 spec 上下文），并设置 `_kind=PodTemplateSpec`（或 `_pkind=PodTemplateSpec`）以使 `definitions.objectMeta` 正确跳过不适用的元数据字段。

## 字段级功能需求

### metadata（object，可选）

- 由 `definitions.objectMeta` 渲染。
- 直接透传 `.` 上下文。
- 下层负责根据 `_kind=PodTemplateSpec` 自动跳过 `annotations` / `name` / `namespace` 字段（PodTemplateSpec 无独立 metadata，仅保留 `labels` 等可选字段）。
- 渲染结果缺失 / 为空时不输出该字段。

### spec（object，必填）

- 委托 `core.podSpec` 渲染。
- 直接透传 `.` 上下文。
- `core.podSpec` 由其他 spec 任务负责实现，本模板不创建。
- 委托输出缺失 / 为空时，本模板应能感知并以"必填"语义反馈给上层（典型实现：依赖上层 `apps.deploymentSpec` 对 `template` 整体输出做必填校验）。

## 专属边界行为

- **委托输出校验**：
  - `metadata` 委托 `definitions.objectMeta` 输出为空时不输出该字段。
  - `spec` 委托 `core.podSpec` 输出为空时由上层 `apps.deploymentSpec` 的 `template` 必填校验统一收口，本模板不重复 fail。
- **版本兼容补强（中间层 BUG 检查）**：
  - 与 `apps.deploymentSpec` 保持"中间层不做 BUG 检查"惯例不同，本模板在中间层主动做 `base.isFromYamlError` + `kindIs "map"` 双重拦截。
  - 委托输出非空但 `fromYaml` 解析为错误 map（Helm 4.2.2 BUG）或非 map 类型时，立即 `fail`，错误格式分别为：
    - `[core.podTemplateSpec] metadata: invalid YAML output from definitions.objectMeta` / `must be map type`
    - `[core.podTemplateSpec] spec: invalid YAML output from core.podSpec` / `must be map type`
  - 设计取舍：偏离 `apps.deploymentSpec` 的中间层惯例，错误定位更精确；顶层 `apps.deployment` 的同检查仍作为兜底保留。
- **必填字段收口**：`spec` 缺失时的最终 fail 由上层 `apps.deploymentSpec` 抛出 `[apps.deploymentSpec] template: required field is missing or empty`，本层不重复报错。
- **入参契约**：本模板不对 `.` 上下文结构做运行时校验（不验证 `metadata` / `spec` 字段是否存在或类型），由调用方保证：
  - `.` 为 PodTemplateSpec 形态（`metadata` / `spec` 字段位于顶层）。
  - `.` 中设置 `_kind=PodTemplateSpec`（或 `_pkind=PodTemplateSpec`）以驱动 metadata 字段过滤。

通用边界场景（`const-boundary.md` 的"输出结构规则 / 异常输入处理 / 字段值渲染 / **版本兼容性**"等所有章节）统一复用 `docs/rules/const-boundary.md`，本 spec 不复述。

## 约束说明

通用约束复用 `docs/rules/const-general.md`，包括：

- 字段处理和渲染顺序严格对齐 K8s 官方 API（`metadata` → `spec`），形成"处理-渲染"单字段闭环。
- 必须使用 `base.get` 取值、`base.field` 渲染，禁止绕开。
- 优先使用 `must` 系列函数。
- 错误格式：`[core.podTemplateSpec] 字段路径: 错误原因`。
- 禁止实现 `status` 字段及相关逻辑。

专属约束：

- `metadata` / `spec` 字段统一直接透传 `.` 上下文，不做额外取值、合并或加工。
- 本模板不创建 `core.podSpec`，由其他 spec 任务负责实现。
- `metadata` 字段渲染时由下层 `definitions.objectMeta` 根据 `_kind=PodTemplateSpec` 自动跳过不适用的 `annotations` / `name` / `namespace`，调用方需保证 `.` 中 `_kind=PodTemplateSpec`（或 `_pkind=PodTemplateSpec`）正确设置。
- `core.podSpec` 的必填校验由该模板自身负责，本模板不重复校验 `spec` 子字段。
- 本模板不实现 `.` 入参结构的运行时校验（避免与 `definitions.objectMeta` / `core.podSpec` 的字段级校验重复），契约由调用方在 spec 层面保证。

## 参考资料

- API：
  - https://kubernetes.io/docs/reference/kubernetes-api/core/pod-template-v1/#PodTemplateSpec
  - https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#podtemplatespec-v1-core
- 委托模板：
  - `templates/api-resources/Definitions/_ObjectMeta.tpl`：`metadata` 字段委托本模板
  - `core.podSpec`：`spec` 字段委托（由其他 spec 任务实现）
- 实现参考：
  - `docs/rules/const-general.md`：通用约束
  - `docs/rules/const-boundary.md`：通用边界
  - `docs/rules/const-example-code.md`：模板语法示例
  - `templates/base/_get.tpl`：`base.get` 取值机制
  - `templates/base/_field.tpl`：`base.field` 渲染机制
- 上层调用：
  - `templates/api-resources/Apps/_DeploymentSpec.tpl`：`template` 字段委托本模板
  - `docs/specs/api-resources/Apps/_DeploymentSpec.md`：上层 spec
- 已知未实现依赖：
  - `core.podSpec`：本模板委托的 `spec` 字段渲染目标，由其他 spec 任务负责实现
