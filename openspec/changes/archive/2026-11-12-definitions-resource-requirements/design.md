# definitions.resourceRequirements 设计

## 技术目标

- capability：`definitions.resourceRequirements`
- artifact-type：Helm 命名模板（Kubernetes 原生 API 共享结构层）
- target：`templates/api-resources/Definitions/_ResourceRequirements.tpl`

## 设计决策

### Decision: 主模板与辅助模板同文件组织

- requirements：`resources 字段渲染`、`limits 与 requests 的 object 形式`、`limits 与 requests 的 string 简写`、`claims 数组`
- choice：`definitions.resourceRequirements` 负责 `claims`、`limits`、`requests` 三个字段的取值与字段级渲染；新增辅助模板 `definitions.resourceRequirements.field` 负责单个 `limits`/`requests` 的类型归一化、白名单筛选、量值校验与渲染，由主模板对 `limits` 与 `requests` 各调用一次。
- rationale：`limits` 与 `requests` 的规则完全同构，抽出辅助模板消除重复分支；`claims` 结构不同，保留在主模板避免辅助模板承担两种语义。辅助模板命名沿用父能力前缀，与既有 `definitions.affinity.schedulingTerm`、`definitions.nodeSelectorTerm.requirementList` 一致。

### Decision: 取值与多类型归一化

- requirements：`limits 与 requests 的 object 形式`、`limits 与 requests 的 string 简写`
- choice：`base.get` 取值后直接 `fromYaml`；解析失败时用 `base.string.normalize` 恢复原始字符串并进入简写分支，解析成功时按 map 处理，不做额外 `kindIs` 判断。
- rationale：`fromYaml` 成功即保证结果是 map，失败仅剩字符串简写一种合法形态；`core.podSpec` 的 `os` 字段已采用同一模式。

### Decision: 简写回溯与占位

- requirements：`limits 与 requests 的 string 简写`
- choice：先用 `K8S.RESOURCE.HUGE_PAGES_PAIR` 匹配括注对，命中时取出该段并用 `mustRegexReplaceAllLiteral` 从原文剔除；剔除后按 `SPLIT.SPACE_COMMA` 拆分外层位置，括注内容剥除括号后按同一分隔符拆分并要求恰好 2 段；外层拆分结果保留全部位置，逐位映射时用 `mustHas` 跳过字面 `""` 与 `''`，`0` 保留到统一零值判断阶段剔除。
- rationale：括注是唯一含空格且位置固定的分段，先剥离再按位置拆分可避免括号与其内部分隔符干扰位置判定；占位必须占据位置，因此外层拆分不得压缩空段，否则后续分段会左移；简写已经 `base.string.normalize` 完整解码，YAML 外层引号已不存在，`""` 与 `''` 只能按字面比对，不得再套用 `SYS.YAML_QUOTED`；`mustHas` 走反射，可直接比较 `[]string` 分段与字面列表。

### Decision: 双形式共用一条校验与渲染路径

- requirements：`limits 与 requests 的 object 形式`、`limits 与 requests 的 string 简写`、`Pod 级 resources 限制`
- choice：map 分支与简写分支都归一化为同一 `dict<资源键, 量值>`，其中简写分支把括注写成 `hugepages-<size>: <hugepages-max>` 键值；随后统一按白名单筛选、Pod 级剔除 `ephemeral-storage`、零值剔除、`cpu` 换算、`hugepages` 校验，非 `cpu` 量值另经 `base.quantity` 校验，最后以 `base.field` 配合 `base.map` 一次性渲染整个资源 map。
- rationale：两种输入形式在规格上必须产生相同结果，共用路径可保证校验与输出完全一致，也避免 Pod 级限制在两处各写一遍。

### Decision: cpu 精度与换算

- requirements：`limits 与 requests 的 object 形式`
- choice：用 `K8S.RESOURCE.CPU` 校验并捕获整数部分、可选小数部分与可选 `m` 后缀；后缀为 `m` 且小数部分非空时中断；小数部分非空时按 `int (mulf (float64 $cores) 1000)` 换算毫核并追加 `m`；整数核数与整数毫核保留原文；换算结果为 `0` 视为未设置。
- rationale：小数位已在正则中限制为 1 至 3 位，毫核换算必为整数，无需额外取整；整数形态保留原文满足“已是整数原样输出”。

### Decision: hugepages 字节换算与倍数校验

- requirements：`hugepages 量值约束`
- choice：`<size>` 与 `hugepages-max` 均用 `K8S.RESOURCE.HUGE_PAGES_QUANTITY` 拆分为数值与可选单位；单位字符串必须相等（均无单位时相等）；按 `Ki|Mi|Gi|Ti|Pi|Ei` 查表取 1024 的幂作为倍数，用 `mul` 换算字节数；用 `gt` 校验 `max` 更大，用 `mod` 校验余数为 `0`；渲染沿用原值不换算。
- rationale：单位强制相同后倍数只来源于单位表，换算只用整数乘法避免浮点误差；`<size>` 本身也是键的一部分，原样保留才能表达 `hugepages-<size>`。
- doc：模板整体契约注释 MUST 说明用 `cat /proc/meminfo | grep -i huge` 查看宿主机 `Hugepagesize` 与 `HugePages_Total`，据此决定 `size` 与 `max`；该说明属于使用指引，不参与渲染。

### Decision: claims 逐项委托

- requirements：`claims 数组`
- choice：`fromYamlArray` 取值，解析失败直接中断；逐项用 `kindIs` 区分 string 与 map，string 项按 `SPLIT.SPACE_COMMA` 拆分为最多 2 段并构造 `name`、`request`，map 项只读透传；每项调用 `definitions.resourceClaim`，`fromYaml` 后经错误保护判断是否非空，非空则追加；最终列表为空时不输出字段。
- rationale：数组元素是未经 YAML 恢复的原始值，`kindIs` 属于规则允许的多类型分支；父层只解析自身声明的字符串简写，`name`/`request` 的字段校验留在子模板。

### Decision: core.podSpec 透传 resources

- requirements：`core.podSpec 的 resources 透传`、`Pod 级 resources 限制`
- choice：`base.get` 取值并 `fromYaml` 后，用 `mustMerge (dict "_kind" "PodSpec") $_resourcesParsed` 构造子上下文并委托 `definitions.resourceRequirements`；移除原 `pick` 裁剪，且不深拷贝。
- rationale：`mustMerge` 只写第一个参数，父级上下文与解析结果均不被修改，满足“只写入传给本模板的子上下文”；不深拷贝符合只读透传约束，子模板内部只构造新 dict。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文> <点分路径>`；本 change 只读取 `_kind`、`claims`、`limits`、`requests`，别名保持默认开启。
- output：可 `fromYaml` 解析的 YAML 字符串；全部缺失时为空输出。
- ownership：`base.get` 负责数据源优先级、`*Alias` 识别与合并；本层负责解析、类型分支与失败语义。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list <键名> <已归一化值> <渲染模板>`；本层使用 `base.quantity`、`base.map`、`base.slice`。
- output：单行或缩进形式的 YAML 键值对；渲染结果为空时不输出。
- ownership：`base.field` 只负责渲染与枚举校验；字段生效判断由本层完成。

### Dependency: `base.map` 与 `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`base.map` 接收 map，`base.slice` 接收 list。
- output：`toYamlPretty` 序列化结果；类型不匹配时中断。
- ownership：`base.map`/`base.slice` 承担最终类型门禁，本层不重复 `kindIs`。

### Dependency: `base.quantity`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：string、int 或 float64 形式的 Quantity 值。
- output：合法时返回原值，非法时以 `[base.quantity]` 前缀中断。
- ownership：`base.quantity` 只做格式校验；`cpu` 精度与毫核规则、`hugepages` 倍数关系由本层额外承担。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 输出的原始文本。
- output：解码后的 string；解码结果不是 string 时中断。
- ownership：`base.string.normalize` 负责 YAML 标量解码，本层负责其后的分段解析。

### Dependency: `base.isFromYamlError` 与 `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 或 `fromYamlArray` 的返回结果。
- output：布尔值，指示是否为解析错误形态。
- ownership：两个 helper 只识别错误形态；错误分支选择由本层完成。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`add`
- input：空字符串占位，经 `fromYaml` 恢复常量 Map。
- output：常量 Map；本 change 新增 `K8S.RESOURCE` 下的三个键。
- ownership：`base.env` 只集中声明常量；本层负责调用正则函数并解释捕获组。
- 新增键与运行时表达式（源码层使用 YAML 双引号包裹并转义反斜杠）：
  - `K8S.RESOURCE.HUGE_PAGES_PAIR`：运行时 `\([^()]*\)`，匹配一对不含嵌套括号的括注。
  - `K8S.RESOURCE.HUGE_PAGES_QUANTITY`：运行时 `^(\d+)(Ki|Mi|Gi|Ti|Pi|Ei)?$`，依次捕获数值与可选二进制单位。
  - `K8S.RESOURCE.CPU`：运行时 `^(\d+)(\.\d{1,3})?(m?)$`，依次捕获整数部分、可选小数部分与可选毫核后缀。

### Dependency: `definitions.resourceClaim`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：单个 ResourceClaim 描述 map，由本层把 string 简写归一化为 `name`、`request`。
- output：可嵌入 `claims` 数组元素的 YAML 字段片段。
- ownership：本 change 只保留调用，不创建实现；真实 Chart 中非空 `claims` 会因模板缺失中断，验证只能由 `/tmp/` 同名 fixture 覆盖。

## 代码边界

### `templates/base/_env.tpl`

- access：`write`
- operations：在 `K8S` 下新增 `RESOURCE` 分组及 `HUGE_PAGES_PAIR`、`HUGE_PAGES_QUANTITY`、`CPU` 三个常量。
- writable-scopes：`K8S.RESOURCE.HUGE_PAGES_PAIR`、`K8S.RESOURCE.HUGE_PAGES_QUANTITY`、`K8S.RESOURCE.CPU`

### `templates/api-resources/Definitions/_ResourceRequirements.tpl`

- access：`write`
- operations：新增 `definitions.resourceRequirements` 与辅助模板 `definitions.resourceRequirements.field`。
- writable-scopes：`definitions.resourceRequirements`、`definitions.resourceRequirements.field`

### `templates/api-resources/Core/_PodSpec.tpl`

- access：`write`
- operations：替换 `resources` 字段处理块为透传并追加 `_kind="PodSpec"`。
- writable-scopes：`core.podSpec` 中 `resources` 字段处理块

### `templates/base/_get.tpl`

- access：`read`
- operations：复核取值、别名与合并契约。

### `templates/base/_field.tpl`

- access：`read`
- operations：复核字段渲染与枚举行为。

### `templates/base/_types.tpl`

- access：`read`
- operations：复核 `base.map`、`base.slice` 类型门禁。

### `templates/base/_k8s.tpl`

- access：`read`
- operations：复核 `base.quantity` 校验与返回边界。

### `templates/base/_convert.tpl`

- access：`read`
- operations：复核 `base.string.normalize` 与 YAML 错误 helper。

## 验证设计

- 最小有效输入：仅 `limits: {cpu: 500m}` 的原生 map，确认字段渲染与空字段省略。
- 较完整有效输入：原生 map 覆盖 `cpu` 小数换算、`memory`、`ephemeral-storage`、合法 `hugepages-<size>`；字符串简写覆盖完整分段与 `""`/`0` 占位；`claims` 覆盖 string、map 与混用。
- 关键失败输入：`cpu: 1.5m`、`cpu: 0.0005`、`hugepages` 单位不同、非整数倍、`max` 不大于 `size`、括号不成对、`claims` 非数组。
- Pod 级场景：真实 `core.podSpec` 传递 `resources`，确认 `_kind` 标记、`claims` 忽略、`ephemeral-storage` 丢弃与 `*Alias` 生效。
- fixture 边界：`/tmp/` 最小 application Chart 中提供同名 `definitions.resourceClaim` 与 `definitions.container` fixture，只证明本 change 模板的调用与分支行为，不代表真实依赖集成。
