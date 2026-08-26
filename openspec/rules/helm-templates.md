# Helm 模板工程规则

本文件定义 Helm 模板的通用工程约束；核心命名模板的调用契约由 [`openspec/rules/core-capabilities.md`](core-capabilities.md) 定义。当前规格定义可观察行为；规格、核心能力规则或本文件与实现冲突时停止实现并修正规格或设计，不得自行选择。

## 设计原则

- 尽早报错：必填缺失、类型非法或无法消解的冲突必须通过 `required` 或 `fail` 中断渲染。
- 类型稳定：新 values 字段只定义一种公共类型；已有明确支持多类型的字段必须在上层归一化为 dict 后再委托。
- 最小传参：单值传标量，同构集合传 list，多维状态传 dict；业务模板不得无意义透传 `.`，base 工具可按契约接收根上下文。
- 状态隔离：修改 dict、list、上下文或执行合并前，必须使用 `mustDeepCopy` 隔离，严禁污染 `.Values` 和共享输入。
- 正则集中：正则统一定义于 [`templates/base/_env.tpl`](../../templates/base/_env.tpl)，使用全大写下划线嵌套键；简单正则可由父模板解析，复杂正则在对应子模板逐级解析。

## 取值与渲染

- 多层字段统一使用 `base.get`；别名字段使用 `base.getWithAlias`，别名优先。入参、优先级、合并和返回值解析必须遵守 [`核心模板能力调用规则`](core-capabilities.md)。
- 字段统一使用 `base.field` 渲染；调用方必须选择真实存在且符合字段类型的渲染模板，不得臆造命名模板。
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

- 禁止创建未定义或仅占位的模板。
- 实施父模板时，使用冻结契约声明的真实子模板 `include` 引用；该依赖不授权当前 change 创建或修改子模板，正式 `templates/` 中仍禁止空值或假数据占位 `define`。隔离验证父模板时可以在 `/tmp/` 测试 Chart 中提供同名最小 `define` fixture，但必须运行真实 Helm 命令，并在 `records/verification.md` 中记录 fixture、验证边界和限制；不得将其当作真实集成结果。冻结契约要求真实集成时，fixture 结果不能得出通过结论。
- 每个 `define` 块使用中文注释说明功能、边界、入参、返回值和最小示例。
- 模板定义使用 `{{- define "x.y" -}}` 与 `{{- end }}`；使用 2 空格缩进，必要时使用 `{{- nindent 0 "" -}}` 显式建立换行，避免空白裁剪导致相邻 YAML 字段粘连；禁止一行定义。
- 代码按功能块以空行分隔；`{{- else if }}` 与 `{{- else }}` 前保留一个空行。
- 具有稳定业务语义、会在当前功能块内持续参与判断、合并或输出的局部变量使用 `$<name>`，例如 `$selector`。
- 临时变量以 `$_` 或 `$__` 开头，例如 `$_raw`、`$__parsed`；适用于 `base.get` 或 `include` 的原始输出、YAML 解析与类型转换中间值、正则捕获、兼容性或错误探测、循环内暂存，以及合并前后的过渡值。
- `$_<name>` 用于当前处理步骤的一次中间结果；同一语义需要第二级中间结果或嵌套作用域存在重名风险时使用 `$__<name>`。临时变量必须限制在最小可用作用域，完成校验或归一化后应赋给具有业务语义的 `$<name>`，不得跨无关功能块复用。
- 不需要读取返回值的 `set`、`unset` 或纯校验调用使用 `$_` 接收；`$_` 仅表示显式丢弃返回值，不得随后读取。
- 字段按 Kubernetes API 顺序形成处理与渲染闭环；仅关联字段可集中处理后按 API 顺序输出。
- 库 Chart 命名模板首尾不得输出 `---`，不得通过 `range` 自行拼接多个独立资源。

## 资源与父 Chart 边界

- Kubernetes 名称和标签使用 [`核心模板能力调用规则`](core-capabilities.md) 中的共用入口，不得在资源模板重复实现。
- library Chart 负责单个资源渲染和嵌套资源上下文隔离；父 Chart 负责跨资源编排与 Helm Hooks。
- 二级嵌套资源在子模板入口使用 `mustDeepCopy` 与 `mustMergeOverwrite` 构造隔离上下文。
- 父 Chart 构造局部 `$ctx` 注入业务配置，不得直接修改全局上下文。

## 安全与验证

- Pod 安全相关模板默认启用 `runAsNonRoot: true` 和 `readOnlyRootFilesystem: true`，默认禁用 `privileged`、`hostNetwork` 等高危权限。
- values、样例和文档不得硬编码密钥、令牌、证书或私钥。
- 所有模板修改必须实际执行 `/opt/homebrew/bin/helm lint`，并用真实 Helm 命令验证最小有效输入、较完整有效输入和关键失败输入。Markdown checklist、静态推断或臆造的校验器不得作为通过证据。
- 临时验证文件只能创建于 `/tmp/`，完成后必须清理。
