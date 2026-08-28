# Helm 模板工程规则

本文件定义 Helm 模板的通用工程约束；核心命名模板调用契约见 [`openspec/rules/core-capabilities.md`](core-capabilities.md)，可观察行为由当前规格定义。任一契约与实现冲突时停止实现并修正规格，不得自行选择。

## 设计原则

- 尽早报错：必填缺失、类型非法或无法消解的冲突必须通过 `required` 或 `fail` 中断渲染。
- 类型稳定：新 values 字段只定义一种公共类型；已有明确支持多类型的字段必须在上层归一化为 dict 后再委托。
- 简洁高效：在不改变规格、类型、失败与隔离边界的前提下，优先使用 Helm/Sprig 内置函数和已有 base 能力直接表达逻辑，消除可合并的重复取值、分支、校验与临时状态；不得以额外 `include`、序列化/反序列化、深拷贝或重复遍历换取表面上的代码缩短，也不得为压缩行数牺牲可读性；不得过度防御编程以及滥用 Helm/Sprig 内置函数。
- 最小传参：单值传标量，同构集合传 list，多维状态传 dict；业务模板不得无意义透传 `.`，base 工具可按契约接收根上下文。
- 状态隔离：修改或合并非当前模板所有的 dict、list 或上下文前使用 `mustDeepCopy`；只读透传不复制，调用链不得修改 `.Values` 或跨资源共享输入。当前契约明确允许注入、覆盖控制变量时，只能修改本模板拥有的上下文和契约允许的键；资源专用或父 Chart 构造的局部 map 可按契约原地写入，无需 `mustDeepCopy`。

## 正则契约

- 项目内固定用于校验、解析、筛选或拆分的正则统一定义于 [`templates/base/_env.tpl`](../../templates/base/_env.tpl) 的 `base.env` 返回 Map；业务模板不得内联、拼接或复制同一表达式。常量使用按领域、能力和语义分层的全大写下划线键，例如 `APPS.DEPLOYMENT.STRATEGY`。
- spec 只记录用户可见的匹配范围、全量或子串语义、捕获结果的顺序与类型，以及不匹配时的失败或忽略边界；不得记录 `base.env` 键路径或源码转义等实现细节。
- design 记录 `base.env` 的调用入参 `""`、精确常量键路径、source、operation 和调用层归属。运行时表达式以 `base.env` 输出经 `fromYaml` 恢复后实际传给正则函数的 string 为准，并与 `_env.tpl` 源码中的 YAML 双引号和反斜杠转义层明确区分。
- `/opsx-spec` 必须从 `_env.tpl` 精确确认现状：既有键的运行时表达式与 spec 行为一致时 operation 为 `consume`，`_env.tpl` 是 read boundary；缺失且当前 change 明确负责新增时 operation 为 `add`，`_env.tpl` 是 write boundary，writable scope 只包含该键；现有表达式冲突且用户未授权改变共享行为时停止。
- 模板使用 `include "base.env" "" | fromYaml` 恢复常量 Map，并直接读取当前 design 已锁定的目标键；`base.env` 负责集中常量的结构与类型有效性，业务模板不得重复添加空输出、YAML、Map 或常量键保护。模板不得从 `.Values`、调用上下文或动态字符串覆盖项目固定正则。
- 需要匹配完整输入的表达式必须使用 `^` 和 `$` 明确锚定；只有规格明确要求查找子串时才允许非锚定表达式。捕获提取前必须先用 `mustRegexMatch` 确认匹配，再按用途选择 `mustRegexFind`、`mustRegexFindAll` 或 `mustRegexReplaceAll`；纯替换或拆分按规格使用 `mustRegexReplaceAll`、`mustRegexReplaceAllLiteral` 或 `mustRegexSplit`，并显式处理无匹配结果。禁止使用非 `must*` 变体吞掉无效表达式错误。
- 捕获组从 `1` 开始引用；独立替换使用 `$n`，仅在需要与相邻文本消歧时使用 `${n}`。每次 `mustRegexReplaceAll` 提取后必须 `trim`。可选捕获组允许得到空 string，但其含义和下游处理必须由规格明确；不得用捕获失败后的空值伪装成合法默认值。
- `base.get` 返回的 YAML string 参与多类型分支时，先完成 `fromYaml` 错误与真实类型检查；进入 string 分支后，使用 `SYS.YAML_QUOTED` 剥离 YAML 外层引号并 `trim`，再执行目标正则。map 与 string 的归一化必须互斥，其他类型或不匹配输入按规格立即失败或忽略，不得静默回退到另一类型。
- 正则解析由拥有归一化边界的模板负责：父模板只解析自身声明的字符串简写并传递规范化结果，嵌套结构的表达式由拥有该结构的子模板继续解析；不得由父模板重复实现子模板内部语义。
- design 的验证设计和 tasks 必须覆盖典型匹配、边界匹配、不匹配、可选捕获为空和非法输入类型；修改 `_env.tpl` 时验证必须加载其真实实现，不得用同名 fixture 替代被修改常量。

## 取值与渲染

- 多层字段统一使用 `base.get`；别名字段使用 `base.getWithAlias`，别名优先。入参、优先级、合并和返回值解析必须遵守 [`核心模板能力调用规则`](core-capabilities.md)。
- 字段统一使用 `base.field` 渲染；调用方必须选择真实存在且符合字段类型的渲染模板，不得臆造命名模板。
- `include` 返回字符串。map/list 子模板须遵循核心能力规则的解析保护和字段生效约束，按“`include` → `fromYaml`/`fromYamlArray` → 错误保护 → `kindIs` → 按契约判断恢复后的集合空值 → `base.field` + `base.map`/`base.slice`”处理；不得把结构子模板直接作为 `base.field` 第三个参数。要求非空的集合不得在解析前重复检查原始空输出或 `null`；只有契约允许真实空集合、且 Helm 恢复行为会使非法原始值与空集合无法区分时，才检查原始字符串。
- 必填字段不得使用默认值掩盖缺失。失败消息统一为 `[模板名] 字段路径: 错误原因`。
- 优先使用适配版本中真实存在的 Helm/Sprig `must*` 变体；使用前必须确认。包括 mustToJson、mustToPrettyJson、mustToRawJson、mustToToml、mustRegexMatch、mustRegexFindAll、mustRegexFind、mustRegexReplaceAll、mustRegexReplaceAllLiteral、mustRegexSplit、mustDateModify、mustToDate、mustMerge、mustMergeOverwrite、mustDeepCopy、mustFirst、mustRest、mustLast、mustInitial、mustAppend、mustPrepend、mustReverse、mustUniq、mustWithout、mustHas、mustCompact、mustSlice。

## 边界与 Helm 4.2.2

- 规格未定义的输入字段静默忽略；禁止输出 `status` 字段及相关逻辑。
- 必填字段缺失、为 `nil` 或按规格定义为空时立即失败。
- 非法枚举值必须失败并给出合法范围。
- 类型不匹配时只允许规格明确的安全转换；无法转换必须失败。
- 字段冲突或互斥按当前规格的优先级处理；未定义优先级时必须失败。
- 空值和零值是否输出由调用方字段生效条件决定，不得交给只接收 key/value 的通用渲染器猜测。结构与多类型输入的解析、错误拦截和真实类型检查遵循核心能力规则。

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

- `base` 提供取值、校验、转换、序列化、路径、错误及 Kubernetes 基础值等无状态原子能力和项目级基础类型；只能依赖 `base` 内模板，不得感知具体资源、CRD 或云厂商。
- 每个 `Definitions` 只保存所属域内可跨资源复用的结构；可依赖 `base` 和同一 Definitions 内模板，不得依赖资源模板、其他域的 Definitions 或执行跨资源编排。
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
- Helm 命名模板位于全局命名空间；新增 `define` 前必须查重。已发布名称属于调用契约，未经规格迁移不得改名或复用为其他语义。
- 非 base 文件围绕与文件名对应的主模板组织；辅助模板沿用同一命名空间和能力前缀，不得在同一文件混入无关能力。

## 模板定义与排版

- 新增或修改直接 `include` 时，被调用模板的 `define` 名称、传入上下文和最小返回边界必须由当前 spec、design 与适用规则唯一确定；否则不得生成执行契约。可以引用 design 标记为 unavailable 的被调用模板，但不得在当前 change 中创建未经授权的实现或占位 `define`。
- 隔离验证调用方模板时，可以在 `/tmp/` 测试 Chart 中提供同名最小 fixture；结果不得作为真实依赖集成通过的证据。
- 每个命名模板必须使用中文整体契约注释，且紧邻对应 `{{- define "x.y" -}}` 之前，不得写入 `define` 块内；契约内容与排版遵循 [`命名模板注释`](../references/template-snippets.md#命名模板注释) 示例。
- 直接渲染 Kubernetes API 字段时，按 API 字段顺序实现当前层负责的字段并遵守官方类型；委托字段不得重复实现子模板内部结构。
- API 类型必须按官方字段表原样记录；Schema 约束与 Helm/Sprig 运行时类型不得替代或拼接为 API 类型。典型映射见 [`API 类型表达`](../references/template-snippets.md#api-类型表达)。
- 直接渲染 Kubernetes API 字段时，每个字段必须在 `define` 块内、紧邻对应处理闭环之前使用中文注释；整体契约中的字段概述不得替代该注释。字段注释内容遵循 [`命名模板注释`](../references/template-snippets.md#命名模板注释) 示例。
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
- `_kind` 是资源身份控制键，通常只由顶层资源模板或明确拥有当前资源的特定资源模板写入；不拥有当前资源的下游定义和子模板只读使用或继续传递，不得自行新增或覆盖。当前规格或变更规格明确要求设置 `_kind` 时，拥有当前资源的模板可以原地覆盖已有值并继续传递同一上下文；该契约写入不要求使用 `mustDeepCopy`。
- 二级嵌套资源在子模板入口使用 `mustDeepCopy` 与 `mustMergeOverwrite` 构造隔离上下文。
- 父 Chart 通过局部 `$ctx` 注入业务配置，不得直接修改全局上下文。

## 安全与验证

- Pod 安全相关模板默认启用 `runAsNonRoot: true` 和 `readOnlyRootFilesystem: true`，默认禁用 `privileged`、`hostNetwork` 等高危权限。
- values、样例和文档不得硬编码密钥、令牌、证书或私钥。
- `/opsx-code` 和 `/opsx-fix` 修改 Helm 模板后，只对当前已变更的精确 write boundary 执行空白、冲突标记和文件末尾换行等静态检查；不得为轻量检查扫描或 lint 整个 Chart。
- `/opsx-code` 和 `/opsx-fix` 必须在 `/tmp/` 最小 application Chart 中加载当前已变更模板及其必要依赖，并实际执行 `/opt/homebrew/bin/helm template`。
- 最小 Chart 验证必须覆盖最小有效输入、较完整有效输入和关键失败输入。使用同名最小 fixture 时，只能证明当前模板自身的调用和分支行为，不得表述为真实依赖集成通过。
- `/ck-deploy` 必须对整个 Chart 实际执行 `/opt/homebrew/bin/helm lint .`，并用仓库真实存在的 Helm 命令验证完整 Chart 的核心样例和关键失败输入。
- 轻量静态检查、隔离 Chart、Markdown checklist、静态推断或臆造的校验器不得替代 `/ck-deploy` 的发布检查。
- 临时验证文件只能创建于 `/tmp/`；验证完成后直接保留，由用户统一清理。
