# Apps Deployment 设计

## 技术目标

- capability：`apps-deployment`
- artifact-type：Helm 命名模板（Kubernetes 资源）
- target：`templates/api-resources/Apps/_Deployment.tpl` 中的 `apps.deployment`

## 设计决策

### Decision: 原地设置资源身份

- requirements：`Deployment 上下文标识`
- choice：在任何字段委托前通过 `set` 将当前可写 map 的 `_kind` 覆盖为 `Deployment`，metadata 与 spec 子模板直接接收同一个上下文，不执行 `mustDeepCopy`。
- rationale：draft 明确要求原地设置 `_kind` 并向两个子模板直接传递当前上下文。

### Decision: 结构化子模板输出恢复

- requirements：`metadata 与 spec 委托`、`子模板失败边界`
- choice：两个字段分别执行 `include` → `fromYaml` → `base.isFromYamlError` → 显式非空检查；解析错误或空结果由 `apps.deployment` 按字段失败，非空结果直接交给 `base.field` 与 `base.map` 渲染。
- rationale：用户确认 metadata 与 spec 是必填非空 map；Helm 4.2.4 实测中，空字符串、`null` 和 `{}` 经 `fromYaml` 均恢复为空 map，因此非空判断必须位于解析错误检查之后并由调用方负责。

### Decision: map 类型失败归属

- requirements：`子模板失败边界`
- choice：调用方不重复执行 `kindIs "map"`；任何到达 map 渲染器的非 map 值由 `base.map` 中断渲染。
- rationale：`base.map` 的正式实现已包含非 map 快速失败逻辑；本次同步说明确认单一目标类型由最终 `base.*` 模板执行类型门禁，并同步收口工程规则，避免上层重复校验。

### Decision: 依赖只读

- requirements：`metadata 与 spec 委托`
- choice：`definitions.objectMeta` 与 `apps.deploymentSpec` 的当前实现作为只读依赖；它们在工作区中的修改不归属于本 change。
- rationale：本次同步说明明确限定两个依赖为只读。

## 依赖契约

### Dependency: `definitions.objectMeta`

- availability：`existing`
- source：`templates/api-resources/Definitions/_ObjectMeta.tpl`
- operation：`consume`
- input：父模板当前可写 map，调用前 `_kind` 已设置为 `Deployment`
- output：可恢复为 map 的 ObjectMeta YAML 字段片段；依赖内部失败由 Helm 传播
- ownership：依赖负责 ObjectMeta 字段行为；`apps.deployment` 只负责上下文传递、结构恢复和 `metadata` 外层字段渲染

### Dependency: `apps.deploymentSpec`

- availability：`existing`
- source：`templates/api-resources/Apps/_DeploymentSpec.tpl`
- operation：`consume`
- input：父模板当前可写 map，调用前 `_kind` 已设置为 `Deployment`
- output：可恢复为 map 的 DeploymentSpec YAML 字段片段；依赖内部失败由 Helm 传播
- ownership：依赖负责 DeploymentSpec 字段行为；`apps.deployment` 只负责上下文传递、结构恢复和 `spec` 外层字段渲染

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值
- output：仅在 Helm `fromYaml` 错误 map 形态下返回字符串 `true`，包括空 map 在内的其他结果返回字符串 `false`
- ownership：依赖只识别解析错误形态；调用方负责字段必填非空判断、字段路径和失败消息

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：字段名、恢复后的值和 `base.map` 渲染器组成的 list
- output：带正确缩进的单个 YAML 字段，或传播渲染器失败
- ownership：依赖负责字段外层与缩进；调用方负责字段必填非空判断、生效条件和依赖选择

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：待序列化值
- output：map 序列化为 YAML，空 map 输出 `{}`；非 map 立即失败
- ownership：依赖负责 map 类型门禁和序列化；调用方负责先排除 `fromYaml` 错误形态

## 代码边界

### `templates/api-resources/Apps/_Deployment.tpl`

- access：`write`
- operations：更新 `apps.deployment` 的 metadata 与 spec 结构恢复、解析错误保护、必填非空检查、map 渲染委托及契约注释
- writable-scopes：文件级契约注释与 `apps.deployment` define

### `templates/api-resources/Definitions/_ObjectMeta.tpl`

- access：`read`
- operations：消费 `definitions.objectMeta` 当前返回契约；工作区现有修改不归属于本 change

### `templates/api-resources/Apps/_DeploymentSpec.tpl`

- access：`read`
- operations：消费 `apps.deploymentSpec` 当前返回契约；工作区现有修改不归属于本 change

### `templates/base/_convert.tpl`

- access：`read`
- operations：消费 `base.isFromYamlError`

### `templates/base/_field.tpl`

- access：`read`
- operations：消费 `base.field`

### `templates/base/_types.tpl`

- access：`read`
- operations：消费 `base.map`

### `openspec/rules/helm-templates.md`

- access：`write`
- operations：更新结构化子模板输出的解析保护、单一目标类型门禁和多类型分支规则
- writable-scopes：“取值与渲染”、“边界与 Helm 4.2.2”、“模板定义与排版”和“资源与父 Chart 边界”中直接涉及上述职责边界的条目

### `openspec/rules/core-capabilities.md`

- access：`write`
- operations：更新 `base.field` 与“YAML 解析保护”中的调用方和最终 `base.*` 类型校验职责
- writable-scopes：“`base.field`”和“YAML 解析保护”中直接涉及上述职责边界的条目

## 验证设计

- 在 `/tmp/` 最小 application Chart 中加载当前 `apps.deployment` 与真实直接依赖，覆盖最小有效输入和较完整有效输入，确认字段顺序、固定身份、上下文透传与单资源输出。
- 使用同名最小 fixture 分别让 metadata 与 spec 子模板返回无效 YAML，确认 `apps.deployment` 的字段级解析错误消息；fixture 结果只证明调用方行为。
- 使用同名最小 fixture 覆盖空字符串、`null` 和空 map，确认解析错误检查完成后由 `apps.deployment` 以字段级必填非空错误中断渲染。
- 静态核对两个工程规则文件，确认单一目标类型不再要求调用方重复 `kindIs`，且多类型输入仍要求在排除解析错误后按真实类型分支。

## 已解决核对

### YAML 解析与最终类型门禁

- 无需 YAML 恢复的 string 通常直接交给选定的 `base.*` 渲染模板，由该模板执行目标类型校验。
- map/list 子模板输出先经 `fromYaml`/`fromYamlArray` 和对应错误 helper 拦截解析错误，再交给 `base.map`/`base.slice` 执行最终 `kindIs` 类型门禁。
- 调用方不重复最终渲染模板已有的同类 `kindIs`，从而减少重复分支；只有 string、map、list 等多类型输入才由调用方在排除解析错误后使用 `kindIs` 选择归一化分支。
- Helm 4.2.4 探针表明，list 或 scalar YAML 经 `fromYaml` 会成为带 `Error` 键的 map，并先由 `base.isFromYamlError` 拦截；`base.map` 只负责实际到达它的非 map 值。

### 必填结构输出与空值职责

- `base.isFromYamlError` 不把空 map 判定为解析错误，只识别 Helm 的 `Error` map；该职责允许可选字段或允许空集合的调用方继续使用同一 helper。
- metadata 与 spec 的必填非空语义由 `apps.deployment` 显式处理，判断顺序固定为解析错误检查之后、`base.field` 与 `base.map` 之前。
- Helm 4.2.4 无法在 `fromYaml` 后区分空字符串、`null` 和 `{}`，三者统一按空 map 触发对应字段的必填错误。
