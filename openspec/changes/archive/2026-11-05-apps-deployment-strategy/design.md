# Deployment 部署策略设计

## 技术目标

- capability：`apps.deploymentStrategy`
- artifact-type：Helm 命名模板（library Chart）
- target：`templates/api-resources/Apps/_DeploymentStrategy.tpl` 中的 `apps.deploymentStrategy`

## 设计决策

### Decision: 入参形态与字段读取

- requirements：`空入参不渲染`
- choice：把传入上下文直接作为 `base.get` 的上下文，用 `list <上下文> "type"` 与 `list <上下文> "rollingUpdate"` 分别取值，使用默认参数；不为了关闭别名识别而传入位置占位参数；不对入口上下文加 `kindIs "map"` 门禁。
- rationale：父级 `apps.deploymentSpec` 已把归一化后的 map 作为子模板入参，本层只需读取两个已知键；规格已不为 `*Alias` 定义专有行为，本层无需为该键编写逻辑或传参开关；未声明字段不会被渲染。

### Decision: type 空值归一化

- requirements：`type 不带隐式默认值`
- choice：`type` 原始文本经 `SYS.YAML_QUOTED` 剥离引号并 `trim`，结果为空或等于 `null` 时归一化为空字符串 `$type`；非空时原样保留，不做大小写归一。
- rationale：`base.get` 对缺失键返回空、对 `null` 输出 `null` 文本、对空字符串标量不输出，三种来源归并后才能统一驱动“是否渲染 `type`”与“枚举校验”两个分支；保留原值以满足规格的大小写敏感失败边界。

### Decision: type 为空时不渲染字段，仅驱动 rollingUpdate 判定

- requirements：`type 不带隐式默认值`、`rollingUpdate 渲染条件`
- choice：`$type` 为空时完全不调用 `type` 的 `base.field`，因此不输出该字段也不引入任何替代值；同时把空 `$type` 视为隐式默认值 `RollingUpdate`，仅用于推进 `rollingUpdate` 的生效判定。
- rationale：规格要求省略 `type` 时由 Kubernetes API 采用 `RollingUpdate`，本层只借用该语义决定 `rollingUpdate` 是否渲染，不把它渲染成显式字段，避免引入隐式覆盖；空 `$type` 不等于 `Recreate`，判定条件自然成立。

### Decision: type 非空时经 base.field 完成枚举校验

- requirements：`type 不带隐式默认值`
- choice：`$type` 非空时调用 `base.field`，传入允许值列表 `(list "Recreate" "RollingUpdate")`，由其完成枚举校验、失败消息与 `base.string` 渲染。
- rationale：`base.field` 在渲染前完成枚举比对并在失败消息中输出合法范围，满足规格的失败边界，无需自定义校验分支。

### Decision: rollingUpdate 生效条件与委托

- requirements：`空入参不渲染`、`rollingUpdate 渲染条件`、`rollingUpdate 委托渲染`
- choice：`list <上下文> "rollingUpdate"` 取原始文本，经 `fromYaml` 恢复并用 `base.isFromYamlError` 排除解析错误后直接判定是否非空；`$type` 为 `Recreate` 时完全不读取该分支，否则在非空时把恢复值原样传给 `apps.rollingUpdateDeployment`。对子模板返回字符串直接 `fromYaml` 恢复：空输出时跳过该字段且不失败，非空时仅保留 YAML 解析错误检查，最终 map 类型门禁交由 `base.field` 的 `base.map`。
- rationale：`base.get` 对缺失返回空、对空 map 输出 `{}`，先恢复再判定可避免比较原始文本；`Recreate` 分支不进入子模板调用，自然实现“静默忽略且不视为非法”；空输出跳过符合规格“由 API 隐式默认值生效”；`rollingUpdate` 内部字段语义归属孙模板，本层只承担生效条件、容器透传与返回边界。

### Decision: 按 API 字段顺序输出 rollingUpdate 后 type

- requirements：工程规则 `openspec/rules/helm-templates.md` 的“按 API 字段顺序实现当前层负责的字段”
- choice：先完成 `rollingUpdate` 的渲染与输出，再渲染 `type`。
- rationale：`DeploymentStrategy` 官方字段表顺序为 `rollingUpdate`、`type`；空入参场景下两个分支都不输出，自然得到空结果，无需额外早退逻辑。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：空 string `""`
- output：可由 `fromYaml` 恢复的非空 YAML map；本模板只读取 `SYS.YAML_QUOTED`
- ownership：提供集中常量；本模板负责剥离 `type` 外层引号

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <当前上下文> "type"` 与 `list <当前上下文> "rollingUpdate"`
- output：YAML 文本；缺失或空字符串标量时为空输出
- ownership：提供多层取值、别名默认语义与序列化；本模板负责空值判据与渲染条件

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：任意 `fromYaml` 返回值
- output：string boolean，仅错误 map 返回 `"true"`
- ownership：识别 Helm YAML 错误形态；本模板负责在错误时失败

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list "rollingUpdate" <子模板恢复值> "base.map"` 与 `list "type" <type> "" (list "Recreate" "RollingUpdate")`
- output：字段 YAML；渲染为空时不输出
- ownership：负责字段序列化与 `type` 枚举校验；本模板负责字段生效条件与是否调用

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`apps.rollingUpdateDeployment` 返回并经 `fromYaml` 恢复的值
- output：map YAML；非 map 立即失败
- ownership：执行 `rollingUpdate` 的最终 map 类型门禁

### Dependency: `apps.rollingUpdateDeployment`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`rollingUpdate` 恢复后的非空值，原样透传
- output：RollingUpdateDeployment YAML map；空输出由本模板跳过，无效 YAML 由本模板失败，非 map 由 `base.map` 失败
- ownership：依赖负责 `maxSurge`、`maxUnavailable` 的取值、校验与渲染；本模板负责生效条件、透传和返回边界，本 change 不创建该模板

## 代码边界

### `templates/api-resources/Apps/_DeploymentStrategy.tpl`

- access：`write`
- operations：add `apps.deploymentStrategy` 命名模板及其整体契约注释；add `rollingUpdate`、`type` 两个字段功能块与紧邻字段注释；add `type` 空值归一化与 `rollingUpdate` 委托调用
- writable-scopes：新建文件的全部内容

### `templates/base/_env.tpl`

- access：`read`
- operations：consume `base.env` 的 `SYS.YAML_QUOTED`

### `templates/base/_get.tpl`

- access：`read`
- operations：consume `base.get`

### `templates/base/_convert.tpl`

- access：`read`
- operations：consume `base.isFromYamlError`

### `templates/base/_field.tpl`

- access：`read`
- operations：consume `base.field`

### `templates/base/_types.tpl`

- access：`read`
- operations：consume `base.map`

## 验证设计

- 在 `/tmp/` 最小 application Chart 中加载真实 `_DeploymentStrategy.tpl`、真实 `_env.tpl`、真实 `_get.tpl`、真实 `_convert.tpl`、真实 `_field.tpl` 与真实 `_types.tpl`，`apps.rollingUpdateDeployment` 用同名 fixture 放行；不宣称真实子模板集成通过。
- 最小有效场景覆盖 `{type: "RollingUpdate"}` 与 `{type: "Recreate"}`，确认只输出 `type`。
- 较完整有效场景覆盖 `type` 为 `RollingUpdate` 且带 `rollingUpdate`、`type` 为 `Recreate` 且带 map 与非 map `rollingUpdate`、未定义字段共存，以及字段顺序 `rollingUpdate` 先于 `type`。
- 空 `type` 场景覆盖 `type` 缺失、`null`、空字符串分别与空 / 非空 `rollingUpdate` 组合：非空时只输出 `rollingUpdate`，为空时输出为空。
- 空入参场景覆盖空 map、`{type: ""}`、`{type: null}`、`{rollingUpdate: {}}` 与未提供入参，预期均为空输出且不失败。
- 关键失败场景覆盖 `type` 为 `rollingupdate`、`recreate`、`BlueGreen`，以及 fixture 分别返回无效 YAML、YAML 标量和 YAML 数组，预期全部中断渲染；fixture 返回空输出时预期只输出 `type` 或为空，不失败。
- 不将 `*Alias` 键纳入预期断言：本层不为其编写逻辑，其取值结果取决于 `base.get` 默认语义，不属于当前能力契约。
- fixture 只证明本模板自身的调用、分支与返回边界，不得表述为 `apps.rollingUpdateDeployment` 集成通过；静态检查只覆盖 write boundary 的空白、冲突标记、Go Template 结构与文件末尾单一换行。
