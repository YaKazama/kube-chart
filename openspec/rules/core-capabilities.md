# 核心模板能力调用规则

本文件定义资源模板和共享结构模板调用核心命名模板时必须遵守的工程契约。它不替代 [`openspec/specs/`](../specs/) 中经过验证的可观察行为规格；核心能力的输出或失败行为被用户变更触及时，必须按工作流建立或修改对应能力规格。

只允许调用 [`templates/base/`](../../templates/base/) 中真实存在或已由批准变更引入的命名模板。可以保留明确标记的预留扩展协议，用于约束后续能力设计；预留协议不是当前可调用实现，也不能替代能力规格和实际验证。

## `base.get`

- 调用格式为 `list <上下文> <点分路径> [强制类型] [合并模式] [必填] [调试]`；上下文和点分路径必填，调用方不得传入占位参数规避类型或必填校验。
- 数据源优先级为输入上下文本身 > `.Context` > `.Values` > `.Values.global`。Helm CLI 覆盖已由 Helm 合并进 `.Values`，不得虚构独立的 CLI 数据源。
- 强制类型只允许 `int`、`int64`、`float64`、`atoi`、`toString`、`toStrings`、`toDecimal`、`quote` 或 `squote`；不需要转换时传空字符串或省略该参数。
- 标量使用首个非空命中值。dict 的 `left` 模式保留先命中的高优先级值，`right` 模式允许后命中的低优先级值覆盖；list 的 `concat` 模式按数据源顺序拼接并去重，`replace` 模式以后命中的非空 list 替换累计结果。
- 所有集合读取和合并必须基于 `mustDeepCopy`，不得修改输入上下文、`.Values` 或共享集合。
- 返回值是 YAML 字符串。bool 可直接比较；map 使用 `fromYaml`；list 使用 `fromYamlArray`，并执行本文件的解析保护。
- 非必填路径全部缺失时返回空输出，不得假定会返回目标类型零值；必填路径缺失或按契约为空时必须失败。

## `base.getWithAlias`

- 调用格式为 `list <上下文> <路径列表> [强制类型] [合并模式] [必填]`；路径按从高到低的优先级排列，空路径只用于显式跳过，不得包含非字符串元素。
- 标量和 list 使用首个非空有效路径；dict 可以按 `left` 或 `right` 合并后续低优先级路径，`replace` 只使用首个非空有效路径。
- 别名字段必须放在规范字段之前。所有路径均未命中且 `必填=true` 时必须失败。
- 强制类型、返回值解析和集合隔离遵循 `base.get` 的规则；调用方不得把 Helm 4.2.2 的解析错误 map 当作有效命中。

## `base.field`

- 调用格式为 `list <key> <value> [渲染模板] [允许值列表]`；参数数量必须为 2 至 4，key 必须为非空字符串。
- 渲染模板默认是 `base.string`，也可以是当前 Chart 中真实存在且符合 value 类型的命名模板。`quote` 表示单行值强制双引号，`containers.env` 路由到容器环境变量专用处理。
- 指定允许值列表时，`base.field` 使用 `base.string` 渲染并在输出前校验枚举；不在列表中的值必须失败。
- 渲染结果为空时不输出字段；map、list 和容器环境变量以换行缩进形式输出，多行字符串使用 `|-` 块标量，其他值使用单行键值对。
- 必填字段必须在调用 `base.field` 前完成存在性和类型校验，不得用默认值或空渲染掩盖缺失。
- 不得引用不存在的 `base.int64`、`base.float64` 等渲染模板。数值渲染器必须以当前实际 `define` 和对应能力规格为准。

## YAML 解析保护

- `fromYaml` 的结果必须先通过 `base.isFromYamlError` 排除错误 map，再验证 `kindIs "map"`。
- `fromYamlArray` 的结果必须先通过 `base.isFromYamlArrayError` 排除异常结果，再验证 `kindIs "slice"`。
- `base.isFromYamlError` 和 `base.isFromYamlArrayError` 返回字符串布尔值，条件判断必须显式比较 `"true"` 或 `"false"`。
- string、map、list 等多类型输入必须先排除解析错误，再按真实类型分支；禁止以 `fromYaml` 是否返回非空作为类型判断。

## Kubernetes 共用入口

- Kubernetes 资源和共享结构需要生成名称时使用 `base.name`。map 上下文按 `fullname` > `name` > 自动生成值取值；`name`、`rbac` 和 `apiservice` 模式分别执行对应格式及长度校验。
- Kubernetes 资源和共享结构需要生成标签时使用 `base.labels`。`justNameLabel=true` 时只输出 name 标签；否则合并自定义 `labels` 和可选 `helmLabels`，自定义标签优先于默认 Helm 标签，最终为空时补充 name 标签。
- `base.name` 和 `base.labels` 的用户可观察行为被变更触及时，必须先通过独立能力规格和 Helm 场景验证确认；静态实现说明不能替代当前规格。

## Kubernetes 字段引用扩展协议

`*FieldRefs` 是为 Kubernetes 字段来源扩展预留的协议族，其中 `*` 必须由具体能力的字段前缀替换。该协议用于统一文件、结构化配置和内联配置的来源选择，不表示当前已经实现任意具体的 `*FieldRefs` 字段或同名命名模板。

- 来源优先级统一为 `*FileRefs` > 结构化字段 > 内联字段；同一目标字段存在多个来源时只使用最高优先级的有效来源。
- `*FileRefs.filePath` 必须是 Chart 内相对路径，并在读取前通过 `base.path` 的 `rel` 模式校验。`rel` 模式只排除绝对路径，实现还必须拒绝归一化结果为 `..` 或以 `../` 开头的 Chart 根目录逃逸路径。
- 容器级引用可以使用 `fieldPaths` 从文件内容按点分路径提取字段。
- 配置级引用可以使用 `key` 指定目标键；`key` 为空时使用文件名。
- 实现具体 `*FieldRefs` 能力前，变更规格必须明确 `*` 对应的字段前缀、各来源的数据类型、生效条件、互斥与回退规则、文件格式、路径边界和关键失败场景。
- 未经批准的变更规格、模板实现和 Helm 验证，不得在当前规格、values、Schema 或用户文档中宣称某个具体 `*FieldRefs` 能力已经可用。
