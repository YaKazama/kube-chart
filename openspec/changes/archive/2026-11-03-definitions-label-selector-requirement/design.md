# Definitions LabelSelectorRequirement 设计

## 技术目标

- capability：`definitions.labelSelectorRequirement`
- artifact-type：Helm 共享结构命名模板与基础正则常量新增
- target：`templates/api-resources/Definitions/_LabelSelectorRequirement.tpl#definitions.labelSelectorRequirement`

## 设计决策

### Decision: 新增模板文件与 define 名称

- requirements：`输入契约与失败消息归属`、`渲染顺序与 values 生效`
- choice：在 `templates/api-resources/Definitions/` 下新增 `_LabelSelectorRequirement.tpl`，只包含 `define "definitions.labelSelectorRequirement"` 与紧邻的中文整体契约注释，按 `key`、`operator`、`values` 顺序完成字段闭环。
- rationale：该结构与 `definitions.labelSelector` 同属 Kubernetes 原生 API 共享结构层，文件名与 Kind 一致；draft 已锁定模板名且当前 Chart 中不存在同名 `define`。

### Decision: 标签键正则作为项目固定常量新增

- requirements：`key 标签键语法`
- choice：在 `base.env` 的 `K8S.SELECTOR` 下新增 `KEY_NAME_FOR_APPS` 与 `KEY_PREFIX_FOR_APPS` 两个键，值分别为 draft 已锁定的名称段与前缀段正则，键名沿用现有 `<能力>_FOR_APPS` 风格。
- rationale：工程规则要求项目内固定正则集中声明于 `base.env`，业务模板不得内联；draft 明确要求这两个常量由本 change 新增，并允许后续出现更贴切领域层级时迁移。

### Decision: 直接读取入参 map 字段并显式校验类型

- requirements：`输入契约与失败消息归属`
- choice：`key`、`operator`、`values` 均以 `hasKey` / `get` 直接从入参 map 读取，不调用 `base.get`；`key` 与 `operator` 在取值后显式执行缺失与 `kindIs "string"` 校验，失败使用本模板前缀。
- rationale：入参是父级已归一化的单个结构项，不是多层配置上下文；`base.get` 会引入 `.Context`、`.Values` 回退，改变语义。`key` 与 `operator` 的入口类型错误必须由本模板给出带自身前缀的失败消息；`values` 是单一目标类型，其类型门禁由最终 `base.slice` 负责，本模板不重复同类 `kindIs`。

### Decision: 按单个斜杠拆分并分段校验

- requirements：`key 标签键语法`
- choice：先用 `splitList "/" $key` 拆分；长度大于 2 时以整体 `key` 失败；长度为 2 时以 `mustFirst` 取 `$prefix`、`mustLast` 取 `$name`，长度为 1 时仅 `$name`。先对 `$name` 用 `KEY_NAME_FOR_APPS` 全量匹配，再对存在的 `$prefix` 用 `KEY_PREFIX_FOR_APPS` 全量匹配并以 `len` 判定 253 字符上限。
- rationale：名称段与前缀段的失败消息必须分开归属，显式空前缀与空名称分别落入前缀段与名称段；先校验名称段后再校验前缀段，可使 `/name` 归属 `key.prefix`、`prefix/` 归属 `key.name`。253 字符上限无法由正则表达，只能单独用 `len` 判定。

### Decision: key 使用 base.rawString 渲染

- requirements：`key 标签键语法`
- choice：`key` 以 `base.field` 的第三个参数 `base.rawString` 渲染，不使用默认的 `base.string`。
- rationale：`base.string` 会 `trim` 并对 `TYPES.ZERO` 匹配值做零折叠，会改变标签键原值，与规格“按原值输出”冲突；`base.rawString` 只执行 string 类型门禁并原样返回。`key` 的类型已在入口显式校验，该渲染模板不引入重复校验。

### Decision: operator 枚举交由 base.field 允许值列表

- requirements：`operator 枚举`
- choice：模板内持有 `list "In" "NotIn" "Exists" "DoesNotExist"` 作为允许值，`operator` 只委托 `base.field` 并传入该允许值列表；不在模板内编写枚举分支或归一化逻辑。
- rationale：draft 要求枚举由渲染层允许值列表二次校验、大小写敏感、失败消息给出合法范围；`base.field` 在指定允许值列表时强制 `base.string` 渲染并在输出前校验，失败消息本身包含允许值列表。

### Decision: values 只按非空生效并委托渲染能力

- requirements：`渲染顺序与 values 生效`
- choice：`values` 存在且为真值时调用 `base.field` 并选用 `base.slice`，序列化与最终类型门禁由 `base.slice` 完成；缺失、空 array 或其他标量假值直接跳过；不判断 `operator`，不清理元素，不自行执行 `kindIs`。
- rationale：draft 要求 `values` 渲染完全委托 `base.field`、不自行实现转换或清理；工程规则规定单一目标类型由最终 `base.*` 渲染模板执行类型门禁，调用方不得重复同类 `kindIs`。非空判断直接使用集合真值，可使空 array 不输出，同时使非空非 array 输入在 `base.slice` 处失败。

### Decision: 不实现 fromYamlArray 错误保护

- requirements：`输入契约与失败消息归属`
- choice：本模板不调用 `fromYamlArray`，也不设置对应错误保护分支。
- rationale：draft 已锁定该链路不会产生 `fromYamlArray` 的错误形态输入，因此不为它定义任何失败边界；设置保护属于 [`openspec/rules/helm-templates.md`](../../rules/helm-templates.md) 设计原则中禁止的过度防御编程。

### Decision: 失败消息前缀按来源区分

- requirements：`输入契约与失败消息归属`
- choice：模板自身的 `key`、`key.prefix`、`key.name`、`operator` 缺失与非 string 类型失败统一写作 `[definitions.labelSelectorRequirement] <字段路径>: <原因>`；`operator` 枚举失败与 `values` 类型失败由 `base.field`、`base.slice` 产生，保留其自身前缀。
- rationale：draft 明确要求本模板主动产生的消息使用该前缀，委托公共模板时保留公共模板前缀；`operator` 的类型错误属于本模板的入口校验，枚举错误属于渲染层校验，两者消息归属不同。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`add`
- input：`""`
- output：可由 `fromYaml` 恢复的常量 Map；`K8S.SELECTOR` 下新增 `KEY_NAME_FOR_APPS`、`KEY_PREFIX_FOR_APPS` 两个字符串常量。
- ownership：`base.env` 只声明静态常量并负责结构与类型有效性；本模板直接读取这两个键并交给 `mustRegexMatch`，不重复添加常量为空的保护。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list <key> <value> [渲染模板] [允许值列表]`
- output：YAML 键值片段；渲染值为空时不输出；指定允许值列表时先校验枚举，不匹配即失败。
- ownership：`base.field` 负责单字段格式化、枚举校验与允许值失败消息；本模板负责字段生效条件、字段顺序与渲染模板选择。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：slice
- output：`toYamlPretty` 序列化结果；非 slice 输入失败并中断渲染。
- ownership：`base.slice` 负责 `values` 的最终类型门禁与序列化；本模板负责非空生效判断，不重复同类 `kindIs` 校验。

### Dependency: `base.rawString`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：string 值。
- output：原字符串，不执行 trim、零折叠或其他规范化；非 string 输入失败并中断渲染。
- ownership：`base.rawString` 只负责原样返回；本模板已在入口完成 `key` 的存在性与 string 类型校验。

## 代码边界

### `templates/api-resources/Definitions/_LabelSelectorRequirement.tpl`

- access：`write`
- operations：`add` `define "definitions.labelSelectorRequirement"`、`include "base.env"`、`include "base.field"`（含 `base.rawString` 作为 `key` 渲染模板）及紧邻中文契约注释与字段注释
- writable-scopes：整个新文件。

### `templates/base/_env.tpl`

- access：`write`
- operations：`add` `K8S.SELECTOR.KEY_NAME_FOR_APPS`、`K8S.SELECTOR.KEY_PREFIX_FOR_APPS`
- writable-scopes：上述两个常量键的字符串值。

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field` 入参、枚举校验与空渲染不输出契约。

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.slice` 类型门禁与序列化契约。

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` `base.rawString` 原样返回契约。

### `templates/api-resources/Definitions/_LabelSelector.tpl`

- access：`read`
- operations：`consume` 既有调用契约：父级已完成字符串简写解析、`In`/`NotIn` 的 `values` 存在性与数组类型校验、空集合判定、结果组装与 YAML 恢复保护；本模板不重复承担这些职责，也不修改该文件。

## 验证设计

全部场景在 `/tmp/` 最小 application Chart 中加载真实 `_env.tpl`、base 模板与新模板后执行 `helm template`；不使用同名 fixture 替代被修改常量，也不进入 `definitions.labelSelector` 完整链路。

- 最小有效：`{key: app, operator: Exists}`，输出只含 `key` 与 `operator`。
- 较完整有效：`{key: app.kubernetes.io/name, operator: In, values: [web, api]}`，输出字段顺序为 `key`、`operator`、`values`，`values` 为 string array；`key` 为 `app.kubernetes.io`（无前缀段）时通过校验。
- 原值保留：`key` 为 `007` 等仅由数字构成且能被渲染层零折叠的名字时，输出与输入完全一致。
- 入口失败：`key` 缺失、`key` 为 int、`operator` 缺失、`operator` 为 int，均失败并带本模板前缀与字段路径。
- 长度边界：名称段 63 个字符通过、64 个字符失败并归属 `key.name`；前缀段总长 253 个字符通过、254 个字符失败并归属 `key.prefix`；前缀段中单个 DNS 标签为 64 个字符时失败并归属 `key.prefix`。
- key 关键失败：`app-`、`-app`、`a b` 归属 `key.name`；`App.io/name`、`app..io/name`、`/name` 归属 `key.prefix`；`prefix/` 归属 `key.name`；`a/b/c` 归属整体 `key`。
- operator 关键失败：`in`、`exist`、`Other`，断言失败并包含四个合法值。
- 生效与门禁边界：`values` 为空 array 时不输出 `values`；`operator` 为 `Exists` 且 `values` 非空时仍输出 `values`；`operator` 为 `In` 且缺 `values` 时不失败；非空的非 array `values` 由 `base.slice` 失败并保留该前缀。
