# SELinuxOptions 共享结构设计

## 技术目标

- capability：`definitions.seLinuxOptions`
- artifact-type：Kubernetes 共享结构命名模板
- target：`templates/api-resources/Definitions/_SELinuxOptions.tpl` 中 `define "definitions.seLinuxOptions"`

## 设计决策

### Decision: 目标文件与命名模板归属

- requirements：`渲染 SELinuxOptions 字段片段`
- choice：新增 `templates/api-resources/Definitions/_SELinuxOptions.tpl`，文件内只定义 `definitions.seLinuxOptions`。
- rationale：`SELinuxOptions` 是 Kubernetes 官方结构，被 `PodSecurityContext` 与 `SecurityContext` 共用，属可跨资源复用的同域共享结构，只能落在 `api-resources/Definitions`；该目录现有 `_AppArmorProfile.tpl`、`_PodOS.tpl` 等沿用 `_<结构名>.tpl` 与 `definitions.<能力>` 命名。该 `define` 在全 Chart 不存在，属纯新增；既有调用点 `templates/api-resources/Definitions/_PodSecurityContext.tpl` 已以 `dict "key" "seLinuxOptions" "define" "definitions.seLinuxOptions"` 委托，本 change 补齐该被委托能力。

### Decision: 四字段同构处理与顺序

- requirements：`渲染 SELinuxOptions 字段片段`
- choice：以 `range` 遍历固定键列表 `level`、`role`、`type`、`user`，在一次循环内完成取值、归一、判空、跳过与输出，循环外不保留中间列表。
- rationale：四个字段类型相同、处理完全同构且无互斥关系，逐字段展开会产生四段重复代码，违反 DRY；固定键列表的顺序即 Kubernetes 官方字段表顺序，`range` 天然保序，无需额外排序。`templates/api-resources/Core/_PodSpec.tpl` 的布尔字段也用同一模式集中遍历，属项目既有做法。四个字段全不生效时循环不输出任何内容，模板自然返回空内容，无需额外判空分支。

### Decision: 字段取值、归一与空值跳过

- requirements：`字段取值与空值跳过`
- choice：循环内以 `base.get` 的 `list [上下文, <键名>]` 非必填取值，结果经 `base.string.normalize` 解码并 `trim` 后赋给局部变量；结果为空字符串时用 `continue` 跳过该字段。
- rationale：`base.get` 对标量缺失、`null` 与空字符串统一返回空输出，`base.string.normalize` 对空输入返回空字符串，两者串联即可让缺失、`null`、空字符串三条路径都落到 `trim` 后的空串，一条判空覆盖全部跳过条件。`base.get` 对标量返回 `toYamlPretty` 序列化文本，含首尾空白的字符串会被加上 YAML 引号，空白位于引号内部，`normalize` 一次解码即还原，再接 `trim` 满足规格要求的“去除首尾空白后判断与输出”。`normalize` 对数字、布尔与结构输入中断，一条委托即满足“不是 string 时中断且不归一化”，无需额外 `kindIs`。不使用 `base.get` 的 `required=true`：本模板四个字段全部可选，不存在必填校验。

### Decision: 字段值输出形态

- requirements：`字段值输出形态`
- choice：以 `base.field` 的 `list [<键名>, 归一化后的值, "quote"]` 输出，强制双引号。
- rationale：`base.string` 默认不加引号，`level: on`、`role: yes`、`type: true` 会被父级 `fromYaml` 回收为布尔，破坏 string 契约；`quote` 保证单行值输出为 `level: "s0"`，回读仍是 string。`base.field` 只在渲染结果非空时输出字段，与循环内的跳过判断形成双重保证；归一化与判空已由本层完成，`base.field` 只承担引号与输出。

### Decision: 返回值形态

- requirements：`渲染 SELinuxOptions 字段片段`
- choice：模板只输出字段片段，不输出父级 `seLinuxOptions` 键、`---`、`apiVersion` 或 `kind`；四个字段全不生效时返回空内容。
- rationale：既有调用点 `definitions.podSecurityContext.struct` 以 `include $define $_parsed | fromYaml` 回收，结果非空时以 `base.field` + `base.map` 嵌入父字段，为空时按“不输出该字段”处理。本模板允许返回空内容，与该回收契约一致，因此调用点无需改动。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, "<字段名>"]` 形式的非必填取值，键名取自 `level`、`role`、`type`、`user`；别名保持默认开启。
- output：可由 `fromYaml` 解析的 YAML 字符串；标量经 `toYamlPretty` 序列化并带尾随换行，字符串可能带 YAML 引号；路径缺失、为 `null` 或为空字符串时为空输出。
- ownership：数据源优先级、别名识别与标量序列化由依赖层负责；取值路径、判空与后续归一由本层负责。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 返回的原始文本。
- output：解码后的 string；空输入返回空字符串；非 string 标量或非法 YAML 标量中断，且不做 `trim`。
- ownership：YAML 标量解码与 string 类型门禁由依赖层负责；`trim`、判空与跳过决策由本层负责。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [<字段名>, 归一化后的值, "quote"]`。
- output：值生效时输出带双引号的单行字段片段；渲染结果为空时不输出；多行值退化为块标量，本模板的 `trim` 已保证取值单行。
- ownership：引号处理与输出格式由依赖层负责；字段生效条件与归一化结果由本层负责。

## 代码边界

### `templates/api-resources/Definitions/_SELinuxOptions.tpl`

- access：`write`
- operations：`add define "definitions.seLinuxOptions"`、`add 紧邻 define 之前的中文整体契约注释`、`add 字段级中文注释`
- writable-scopes：文件内 `definitions.seLinuxOptions` 的契约注释与 `define` 块

## 验证设计

- `/tmp/` 最小 application Chart 加载本 change 的目标模板与真实 `base` 依赖，不需要任何 fixture：本模板无 unavailable 依赖，全部场景都是真实依赖集成。
- 最小有效输入：`{level: s0}`，断言输出只含 `level: "s0"` 且可被 `fromYaml` 回收为 map。
- 较完整有效输入：四字段完整、部分字段、`{level: "  s0  "}`、`{level: "on", role: "yes", type: "true"}`、范围外键，断言字段顺序、取值已 `trim`、值带双引号且回读均为 string。
- 关键失败输入：任一字段为 `123`、`true`、`{a: b}`、`[a]`，逐项断言渲染中断。
- 跳过边界输入：`{}`、`{level: "", role: "   ", type: null}`、单字段空串、单字段纯空白、单字段 `null`，断言渲染成功且输出为空内容或只含生效字段。
- 静态检查：目标模板无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
