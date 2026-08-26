# Helm 模板工程规则

本文件定义 Helm 模板的通用工程约束；核心命名模板的调用契约由 [`openspec/rules/core-capabilities.md`](core-capabilities.md) 定义。当前规格定义可观察行为；规格、核心能力规则或本文件与实现冲突时停止实现并修正规格或设计，不得自行选择。

## 设计原则

- 尽早报错：必填缺失、类型非法或无法消解的冲突必须通过 `required` 或 `fail` 中断渲染。
- 类型稳定：新 values 字段只定义一种公共类型；已有明确支持多类型的字段必须在上层归一化为 dict 后再委托。
- 最小传参：单值传标量，同构集合传 list，多维状态传 dict；业务模板不得无意义透传 `.`，base 工具可按契约接收根上下文。
- 状态隔离：修改或合并所有权不属于当前模板的 dict、list 或上下文前使用 `mustDeepCopy`；只读透传不复制，调用链不得修改 `.Values` 或跨资源共享输入。需求或冻结契约显式声明向上下文注入或覆盖控制变量时，该写入属于上下文调用契约，不得仅因“修改上下文”判定为违反状态隔离；规划必须明确上下文所有权和允许写入的键，资源专用或父 Chart 构造的局部 map 可按契约原地写入且不使用 `mustDeepCopy`。
- 正则集中：正则统一定义于 [`templates/base/_env.tpl`](../../templates/base/_env.tpl)，使用全大写下划线嵌套键；简单正则可由父模板解析，复杂正则在对应子模板逐级解析。

## 取值与渲染

- 多层字段统一使用 `base.get`；别名字段使用 `base.getWithAlias`，别名优先。入参、优先级、合并和返回值解析必须遵守 [`核心模板能力调用规则`](core-capabilities.md)。
- 字段统一使用 `base.field` 渲染；调用方必须选择真实存在且符合字段类型的渲染模板，不得臆造命名模板。
- `include` 返回字符串。map/list 子模板必须按“`include` → 按必填条件检查空值 → `fromYaml`/`fromYamlArray` → `base.isFromYamlError`/`base.isFromYamlArrayError` → `kindIs` → `base.field` + `base.map`/`base.slice`”处理；不得把结构子模板直接作为 `base.field` 第三个参数。
- 必填字段不得使用默认值掩盖缺失。失败消息统一为 `[模板名] 字段路径: 错误原因`。
- 正则捕获使用 `mustRegexReplaceAll` 后必须 `trim`。
- 优先使用 Helm/Sprig 已提供的 `must*` 变体；使用前必须确认函数真实存在于适配版本。包括 mustToJson、mustToPrettyJson、mustToRawJson、mustToToml、mustRegexMatch、mustRegexFindAll、mustRegexFind、mustRegexReplaceAll、mustRegexReplaceAllLiteral、mustRegexSplit、mustDateModify、mustToDate、mustMerge、mustMergeOverwrite、mustDeepCopy、mustFirst、mustRest、mustLast、mustInitial、mustAppend、mustPrepend、mustReverse、mustUniq、mustWithout、mustHas、mustCompact、mustSlice。

## 边界与 Helm 4.2.2

- 规格未定义的输入字段静默忽略；禁止输出 `status` 字段及相关逻辑。
- 必填字段缺失、为 `nil` 或按规格定义为空时立即失败。
- 非法枚举值必须失败并给出合法范围。
- 类型不匹配时只允许规格明确的安全转换；无法转换必须失败。
- 字段冲突或互斥按当前规格的优先级处理；未定义优先级时必须失败。
- 空值和零值是否输出由字段的生效条件决定。
- map/dict 解析必须使用 `base.isFromYamlError` 拦截 `fromYaml` 的错误 map，并验证真实类型。
- slice/list 解析必须使用 `base.isFromYamlArrayError` 拦截 `fromYamlArray` 的异常结果，并验证真实类型。
- string、map、list 等多类型输入必须先排除解析错误，再判断真实类型。

## 分层与依赖

箭头表示调用方允许通过 `include` 依赖被调用层。每个依赖域都可以按需建立自己的共享结构层；资源层和同域共享结构层分别直接依赖基础层。

```text
父 Chart（跨资源编排、Hooks）
  ↓
领域资源层
  ├─→ 同域共享结构层（可选） ─→ 基础层（base）
  └───────────────────────────→ 基础层（base）
```

| 依赖域 | 资源层 | 同域共享结构层 |
|---|---|---|
| Kubernetes 原生 API | `api-resources/<APIGroup>` | `api-resources/Definitions` |
| 云厂商 | `cloud/<Provider>` | `cloud/<Provider>/Definitions` |
| 扩展项目 | `extensions/<Project>` | `extensions/<Project>/Definitions` |

- `base` 提供无状态原子能力和项目级基础类型，包括取值、校验、转换、序列化、路径、错误及 Kubernetes 基础值；只能依赖 `base` 内其他模板，不得感知具体资源、CRD 或云厂商。
- 每个 `Definitions` 只保存所属依赖域内可跨资源复用的结构；可以依赖 `base` 和同一 Definitions 内其他模板，不得依赖资源模板、其他依赖域的 Definitions 或执行跨资源编排。
- `api-resources/<APIGroup>` 对齐 Kubernetes 官方 API；可以依赖 `base`、`api-resources/Definitions` 和同 API 组模板。只有目标 API 字段确实嵌套其他 API 组结构时才允许跨组依赖，不得借此组合多个独立资源。
- `cloud/<Provider>` 可以依赖 `base` 和本厂商的 `cloud/<Provider>/Definitions`；`extensions/<Project>` 可以依赖 `base` 和本项目的 `extensions/<Project>/Definitions`。禁止跨云厂商、跨扩展项目或借用 `api-resources/Definitions` 作为自身共享结构层。
- cloud 或 extensions 的 API schema 明确嵌套 Kubernetes 原生类型时，可以依赖对应的 `api-resources/<APIGroup>` 类型模板；该依赖不得用于组合独立资源。extensions 模板必须明确对应的 CRD API group 和 version。
- 禁止循环依赖和下层反向依赖上层。多个独立资源的组合、执行顺序和 Helm Hooks 只由父 Chart 负责。

## 目录、文件与模板命名

- 模板目标产物必须记录 define 名称和 `templates/` 下的路径，并符合本节的命名空间、依赖域、目录和文件名规则。
- 一级分类目录只使用 `base`、`api-resources`、`cloud` 和 `extensions`。`<APIGroup>` 使用 Kubernetes 官方 API group 的稳定目录名；`<Provider>` 与 `<Project>` 使用对应厂商或扩展项目的正式名称，禁止为同一来源创建大小写或别名不同的重复目录。`Definitions` 只允许出现在上表规定的同域共享结构层位置。
- [`templates/`](../../templates/) 下除 `NOTES.txt` 外的文件必须以 `_` 开头。
- `templates/base/` 文件使用 `_<小写能力名>.tpl`；资源、共享结构和 CRD 文件使用与 Kubernetes Kind 或结构名一致的 `_<名称>.tpl`，保留 `API` 等官方缩写，例如 `_Deployment.tpl` 和 `_APIGroup.tpl`。
- 命名模板使用稳定命名空间：base 为 `base.<能力>`；Kubernetes 共享结构与资源分别为 `definitions.<能力>` 和 `<小写 API 组>.<能力>`；云厂商资源与共享结构分别为 `cloud.<小写厂商>.<能力>` 和 `cloud.<小写厂商>.definitions.<能力>`；扩展项目资源与共享结构分别为 `extensions.<小写项目>.<能力>` 和 `extensions.<小写项目>.definitions.<能力>`。
- 能力名使用小驼峰；官方缩写可以保留大写，例如 `apps.deployment`、`definitions.objectMeta` 和 `definitions.APIGroup`。
- Helm 命名模板位于全局命名空间；新增 `define` 前必须检查重名。已发布的模板名属于调用契约，未经规格迁移不得改名或复用为其他语义。
- 非 base 文件围绕与文件名对应的主模板组织；辅助模板沿用同一命名空间和能力前缀，不得在同一文件混入无关能力。

## 模板定义与排版

- 规划包含直接 `include` 的命名模板时，必须确定每个被调用模板的 `define` 名称、调用位置、传入上下文和最小返回边界；前三项写入 `plan/design.md`，可观察的返回边界写入 `plan/spec.md`。无法唯一确定或存在冲突时保持 `draft`。
- 新增或修改的直接 `include` 必须由当前规格或冻结变更契约声明。可以引用尚未实现的被调用模板，但不得在当前 change 中创建未经授权的实现或占位 `define`。
- 隔离验证调用方模板时，可以在 `/tmp/` 测试 Chart 中提供同名最小 fixture；结果不得作为真实依赖集成通过的证据。
- 每个命名模板的整体契约使用中文注释说明功能、边界、入参、返回值和最小示例。该注释必须紧邻并写在对应 `{{- define "x.y" -}}` 之前，不得写入 `define` 块内。
- 规划直接渲染 Kubernetes API 字段的命名模板时，`plan/design.md` 必须按目标 API 字段顺序逐项记录该模板直接负责的字段名称或路径、Kubernetes 官方 API 文档类型和功能说明；委托给子模板的字段只记录当前层字段及官方 API 类型，不展开子模板内部字段。
- 实现上述命名模板时，每个 API 字段的中文注释必须写在 `define` 块内，紧邻并位于对应字段处理闭环之前；不得集中写入 `define` 之前的整体契约注释，也不得与实际处理字段分离。字段注释必须包含字段名称或路径、Kubernetes 官方 API 文档类型和功能说明；类型使用 `string`、`ObjectMeta`、`DeploymentSpec` 等官方类型名称，不得以 Helm/Sprig 的运行时 `kind` 代替 API 类型。
- 模板定义使用 `{{- define "x.y" -}}` 与 `{{- end }}`；使用 2 空格缩进，必要时使用 `{{- nindent 0 "" -}}` 显式建立换行，避免空白裁剪导致相邻 YAML 字段粘连；禁止一行定义。
- 代码按功能块以空行分隔；`{{- else if }}` 与 `{{- else }}` 前保留一个空行。
- 具有稳定业务语义、会在当前功能块内持续参与判断、合并或输出的局部变量使用 `$<name>`，例如 `$selector`。
- 临时变量以 `$_` 或 `$__` 开头，例如 `$_raw`、`$__parsed`；适用于 `base.get` 或 `include` 的原始输出、YAML 解析与类型转换中间值、正则捕获、兼容性或错误探测、循环内暂存，以及合并前后的过渡值。
- `$_<name>` 用于当前处理步骤的一次中间结果；同一语义需要第二级中间结果或嵌套作用域存在重名风险时使用 `$__<name>`。临时变量必须限制在最小可用作用域，完成校验或归一化后应赋给具有业务语义的 `$<name>`，不得跨无关功能块复用。
- 不需要读取返回值的 `set`、`unset` 或纯校验调用使用 `$_` 接收；`$_` 仅表示显式丢弃返回值，不得随后读取。
- 字段按 Kubernetes API 顺序完成“取值/调用 → 解析 → 错误与类型检查 → 归一化 → `base.field` 渲染”闭环后再处理下一字段；仅关联字段可集中处理。
- 库 Chart 命名模板首尾不得输出 `---`，不得通过 `range` 自行拼接多个独立资源。

## 资源与父 Chart 边界

- Kubernetes 名称和标签使用 [`核心模板能力调用规则`](core-capabilities.md) 中的共用入口，不得在资源模板重复实现。
- library Chart 负责单个资源渲染和嵌套资源上下文隔离；父 Chart 负责跨资源编排与 Helm Hooks。
- 父 Chart 必须以可写 map 构造局部 `$ctx` 并将其作为顶层资源模板的上下文；顶层资源模板依赖该调用契约，不重复使用 `kindIs "map"` 等入口类型门禁。该约定不适用于 `include` 返回字符串的结构恢复，子模板输出仍须执行 YAML 错误保护和真实类型检查。
- `_kind` 是资源身份控制键，通常只由顶层资源模板或明确拥有当前资源的特定资源模板写入；不拥有当前资源的下游定义和子模板只读使用或继续传递，不得自行新增或覆盖。当前需求或冻结契约明确要求设置 `_kind` 时，拥有当前资源的模板可以原地覆盖已有值并继续传递同一上下文；该契约写入不要求使用 `mustDeepCopy`。
- 二级嵌套资源在子模板入口使用 `mustDeepCopy` 与 `mustMergeOverwrite` 构造隔离上下文。
- 父 Chart 通过局部 `$ctx` 注入业务配置，不得直接修改全局上下文。

## 安全与验证

- Pod 安全相关模板默认启用 `runAsNonRoot: true` 和 `readOnlyRootFilesystem: true`，默认禁用 `privileged`、`hostNetwork` 等高危权限。
- values、样例和文档不得硬编码密钥、令牌、证书或私钥。
- 所有模板修改必须实际执行 `/opt/homebrew/bin/helm lint`，并用真实 Helm 命令验证最小有效输入、较完整有效输入和关键失败输入。Markdown checklist、静态推断或臆造的校验器不得作为通过证据。
- 临时验证文件只能创建于 `/tmp/`，完成后必须清理。
