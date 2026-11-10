# base.string.normalize 存量调用点改造设计

## 技术目标

- capability：`base.string.normalize`
- artifact-type：既有命名模板的调用点重构，不新增能力
- target：`templates/api-resources/` 下 13 个既有模板文件

## 设计决策

### Decision: 以统一解码能力替换内联引号剥离

- requirements：`字符串字段按 YAML 标量语义解码`
- choice：string 字段一律改为 `include "base.string.normalize" (include "base.get" (list <上下文> "<字段>")) | trim`，删除 `mustRegexReplaceAll $_const.SYS.YAML_QUOTED ... "$1"` 与随附的 `kindIs "string" (fromYaml (printf "v: %s" ...)).v` 类型判定。
- rationale：`base.string.normalize` 已由既有能力规格锁定「解码一次覆盖引号、纯量、块标量与特殊字符」，并在解码结果不是 string 时中断；调用方保留内联剥离与类型判定会形成第二套等价实现，违反 DRY 与「单一入口」目标。

### Decision: 归一化入参保持 base.get 原始输出

- requirements：`字符串字段按 YAML 标量语义解码`
- choice：把原本的 `include "base.get" (...) | trim` 拆成「取原始输出 → 归一化 → trim」，仅在归一化之后 trim；`core.podSpec` 的 `os` 字段额外把存在性判断改为对原始输出判断，`fromYaml` 恢复仍使用原始输出。
- rationale：`base.string.normalize` 的既有能力规格要求入参是 `include` 输出的原始文本，预先 trim 会改变块标量与引号标量的解码输入；trim 后置可保持既有「首尾空白剥离、仅空白等同未设置」的可观察行为。

### Decision: 失败消息由归一化能力统一产出

- requirements：`字符串字段按 YAML 标量语义解码`
- choice：删除各调用方的 `[...] <字段>: must be string type` 失败分支，类型非法时直接由 `base.string.normalize` 中断；字段自身的必填为空、语法与枚举校验仍由原调用方承担并保留原有前缀。
- rationale：该能力不接收字段路径，其规格已明确失败消息使用自身前缀；调用方若要保留字段路径需在归一化前重复类型判定，与上一条决策冲突。

### Decision: DeploymentSpec 整数字段收敛为统一三步链

- requirements：`渲染 DeploymentSpec 整数字段`
- choice：四个字段统一为「`base.get` 原始输出 → `base.int` 校验整数形态并转换 → `base.int.range (list <int> 0 2147483647)` 校验字段自定义上下限并以其返回值作为字段值」，删除逐字符 `substr`/`contains` 校验、去前导零循环、字符串字典序上限比较与 `SYS.YAML_QUOTED` 引号剥离；四个字段均不赋默认值，缺失或为空时不进入处理。
- rationale：`base.int` 的字符串分支已用 `^[+-]?\d+$` 覆盖整数形态校验，`base.int.range` 的闭区间校验直接作用于 int 并承载字段自定义的 int32 上下限；两处能力均为既有实现。不剥离引号使 `base.get` 序列化后的带引号纯数字字符串自然被 `base.int` 拒绝，与 spec 的「只接受十进制整数形态」一致。Helm 把 `values.yaml` 的数值统一解析为 `float64`，`3` 与 `3.0` 在运行时是同一个值，`base.get` 序列化均为 `3`，因此整数值浮点无法也不应单独拒绝，带非零小数部分的取值会被 `base.int` 的整数正则拦下。四个字段的默认值与 Kubernetes API 自身默认值相同，模板重复声明不会改变最终对象，反而让 `helm template` 输出误示为 Chart 决策，故一律省略。

### Decision: PodSpec 整数字段删除重复正则与二次解析

- requirements：`渲染 PodSpec 整数字段`
- choice：删除 `mustRegexMatch $_const.TYPES.POSITIVE_INT` 前置判断、随后的 `atoi` 重复解析与 `SYS.YAML_QUOTED` 引号剥离，改用同一条 `base.int` + `base.int.range (list <int> 0)` 链路；`activeDeadlineSeconds` 保留 `gt 0` 输出条件，`terminationGracePeriodSeconds` 直接输出。
- rationale：两个字段的上下限都是 `0 - +∞`，`base.int.range` 的两参数形式 `(num, min)` 已足够表达；与 DeploymentSpec 四个字段共用同一链路，保持类型稳定与低重复。

### Decision: 引号剥离只保留在 IntOrString 与 weight 链路

- requirements：`渲染 DeploymentSpec 整数字段`、`渲染 PodSpec 整数字段`
- choice：6 处整数字段不再调用 `SYS.YAML_QUOTED`；`_RollingUpdateDeployment.tpl` 的 `maxSurge`、`maxUnavailable` 与两个 `weight` 继续保留引号剥离，行为不变。
- rationale：整数字段改用 `base.int` 后，带引号的纯数字字符串本身就是 spec 要拒绝的输入，剥离引号反而会把非法输入转为合法；`IntOrString` 允许百分比且 `weight` 已在既有规格中接受带引号数字，两者不在本次行为变更范围。

### Decision: strategy 简写先归一化再匹配，占位符用 trimAll 折叠

- requirements：`渲染 DeploymentSpec selector 与 strategy`
- choice：字符串简写分支先对 `strategy` 的 `base.get` 原始输出调用 `base.string.normalize` 并 trim，删除原 `fromYaml (printf "v: %s" ...)`、`toString` 与 `isFromYamlError` 三步；三个捕获结果不再使用 `SYS.YAML_QUOTED`，改用 `trimAll "\"'"` 折叠 `""`、`''` 空占位符。
- rationale：归一化后已是真实 string，YAML 引号层已消失，`SYS.YAML_QUOTED` 在该处只剩折叠占位符的作用；捕获组字母表只有 `\d+`、`\d+%`、`""`、`''`，`trimAll` 只削首尾引号，对数字与百分比无影响，可等价替代且不引入新常量。子模板的 `base.get` 只过滤真空值，两字符占位符会被当作非空文本继续进入 `IntOrString` 正则，因此折叠必须留在父级。

### Decision: 删除两条不可达的 null 判断

- requirements：`渲染 DeploymentSpec selector 与 strategy`、`渲染 DeploymentStrategy type 字段`
- choice：删除 `apps.deploymentSpec` 中 `eq ($_selectorRaw | trim) "null"` 与 `ne $_strategyTypeRaw "null"` 两个判断；删除 `apps.deploymentStrategy` 中把 `$type` 由 `"null"` 归一化为空字符串的分支。
- rationale：`base.get` 对标量空值与显式 null 一律返回空输出，两处父级判断在 `base.get` 语义下不可达；子模板的 `"null"` 归一化分支会放行字面字符串 `null` 进入枚举校验前的空值分支，与「`type` 只允许两个合法值」冲突。

### Decision: 引号标量的零折叠留给既有渲染器

- requirements：`字符串字段按 YAML 标量语义解码`
- choice：只负责把 YAML 序列化文本解码为真实 string；引号数字不再在调用方做额外保护，最终由 `base.field` 的 `quote` 路由到 `base.string` 输出。
- rationale：实测 `base.string.normalize "\"007\""` 返回 `007`，而同一值经 `base.field` 的 `quote` 渲染为 `07`，因为 `base.string` 的 `TYPES.ZERO` 规则会把前导零折叠为一个。旧实现（`SYS.YAML_QUOTED`）同样得到 `007` 再渲染为 `07`，改造前后一致，因此该折叠不属于本次变更范围；改用 `base.rawString` 会失去引号保护，`on`、`yes` 等名称会被 YAML 解析为布尔值。

### Decision: 整数字段有效上限由序列化形态决定

- requirements：`渲染 DeploymentSpec 整数字段`、`渲染 PodSpec 整数字段`
- choice：保留 `base.int.range (list <int> 0 2147483647)` 的 int32 上限校验，同时不对 `values.yaml` 来源的科学计数法做额外兼容。
- rationale：实测 Helm 把 `values.yaml` 的数值统一解析为 `float64`，`base.get` 的 `toYamlPretty` 对 7 位及以上整数使用科学计数法：`999999` 仍为 `999999`，`1000000` 变为 `1e+06`，`2147483647` 变为 `2.147483647e+09`，后两者会被 `base.int` 的整数正则拒绝。直接以 int 传入上下文时序列化为 `2147483647`，不触发该限制。改造前的逐字符校验遇 `e` 同样中断，属既有行为；若改为先单值解码，`1.5` 会变为 `2`、带引号的 `"3"` 会变为 `3`，同时破坏已确认的非整数与带引号字符串两条中断规则，因此不采纳。

### Decision: selector 的类型门禁沿用 YAML 错误检测

- requirements：`渲染 DeploymentSpec selector 与 strategy`
- choice：`selector` 保留「原始输出为空即缺失或 null」判断与 `base.isFromYamlError` 检查，不新增 `kindIs "map"` 门禁。
- rationale：实测 Helm 的 `fromYaml` 只接受 map，对标量（`"null"`、`5`、`[]`）返回包含 `Error` 键的错误 map，因此现有错误检测已能拦截非 map 输入；空 map 的原始输出为 `{}` 且解析成功，需继续通过与基础标签的合并路径，不能被「空即缺失」判断拦截。对恢复结果再判断 `kindIs "map"` 属于重复类型检查，由 `core-capabilities` 规则禁止。

## 依赖契约

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 的原始输出文本，未预先 trim、`fromYaml` 或拼接。
- output：解码后的 string；空内容与 `null` 返回空字符串；解码结果不是 string 或入参不是 string 时中断，消息使用 `[base.string.normalize]` 前缀且不含字段路径。
- ownership：解码与类型门禁由该能力承担；调用方只负责取值、trim、必填为空判断与后续字段语法校验。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文> <点分路径> [强制类型] [合并模式] [必填] [别名] [调试]`，本次调用均只使用上下文与点分路径，部分保留必填参数。
- output：可 `fromYaml` 解析的 YAML 字符串；标量取首个非空命中值，显式 null 视为空输出。
- ownership：取值、别名与数据源优先级由该能力承担；调用方不重复判空以外的保护。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list <key> <value> [渲染模板] [允许值列表]`。
- output：YAML 键值片段；值为空时不输出。
- ownership：渲染格式与枚举校验由该能力承担；调用方只完成字段生效判断。

### Dependency: `base.int`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：本次链路传入 `base.get` 的序列化文本，即 `^[+-]?\d+$` 的整数字符串或带引号文本；该能力的 `int`/`int64`/`float64` 分支不由本链路经过。
- output：整数形态返回十进制数字字符串；带引号文本、带小数点的文本、非数字文本与其他无法匹配的输入中断。
- ownership：整数形态校验由该能力承担；调用方用 `int` 转换后交给区间校验。

### Dependency: `base.int.range`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：`list [数值, 最小值, 最大值]`，只接受 int、int64、float64；DeploymentSpec 四个字段使用三参数闭区间，两个 PodSpec 字段使用 `list [数值, 0]` 的双参数形式。
- output：校验通过的数值；越界时中断并使用 `[base.int.range]` 前缀。
- ownership：闭区间校验由该能力承担；int32 上限与各字段零值语义的取值属本层字段语义。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：空字符串，经 `fromYaml` 恢复为常量 Map。
- output：常量 Map；本次只读取 `SYS.YAML_QUOTED` 与 `APPS.DEPLOYMENT.STRATEGY`。
- ownership：常量定义由该能力承担；本次不新增、不修改任何键。

### Dependency: `base.labelKey`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：`list [标签键, 调用方模板名, 调用方字段路径]`，标签键为非空 string。
- output：trim 后校验通过的标签键；语法非法时使用调用方模板名与字段路径中断。
- ownership：标签键语法与 trim 由该能力承担；本次只改变传入值的解码方式。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值。
- output：字符串 `"true"` 或 `"false"`。
- ownership：错误形态识别由该能力承担；调用方据此选择归一化分支或中断。

## 代码边界

### `templates/api-resources/Apps/_DeploymentSpec.tpl`

- access：`write`
- operations：`update` `apps.deploymentSpec` 中 `minReadySeconds`、`progressDeadlineSeconds`、`replicas`、`revisionHistoryLimit` 的取值、校验与渲染链；`update` `selector` 的 null 判断；`update` `strategy` 的 map 分支 `type` 归一化与字符串简写分支。
- writable-scopes：`apps.deploymentSpec` 内上述字段处理闭环与 `selector`、`strategy` 两个处理闭环。

### `templates/api-resources/Apps/_DeploymentStrategy.tpl`

- access：`write`
- operations：`update` `apps.deploymentStrategy` 的 `type` 取值与 null 归一化分支。
- writable-scopes：`apps.deploymentStrategy` 中 `type` 处理闭环。

### `templates/api-resources/Core/_PodSpec.tpl`

- access：`write`
- operations：`update` `core.podSpec` 中 `os` 字符串简写、`hostnameOverride`、`dnsPolicy`、`hostname`、`nodeName`、`preemptionPolicy`、`priorityClassName`、`restartPolicy`、`runtimeClassName`、`schedulerName`、`serviceAccountName`、`subdomain` 的取值链；`update` `activeDeadlineSeconds` 与 `terminationGracePeriodSeconds` 的取值与校验链。
- writable-scopes：`core.podSpec` 内上述字段处理闭环；不含 `automountServiceAccountToken` 等 7 个布尔字段。

### `templates/api-resources/Definitions/_HostAlias.tpl`

- access：`write`
- operations：`update` `definitions.hostAlias` 的 `ip` 取值链。
- writable-scopes：`definitions.hostAlias` 中 `ip` 处理闭环。

### `templates/api-resources/Definitions/_LabelSelector.tpl`

- access：`write`
- operations：`update` `definitions.labelSelector` 中原生 map 条目的 `key` 与 `operator` 取值链。
- writable-scopes：`definitions.labelSelector` 中原生 map 条目的 `key`、`operator` 处理闭环。

### `templates/api-resources/Definitions/_LabelSelectorRequirement.tpl`

- access：`write`
- operations：`update` `definitions.labelSelectorRequirement` 的 `key` 与 `operator` 取值链。
- writable-scopes：`definitions.labelSelectorRequirement` 中 `key`、`operator` 处理闭环。

### `templates/api-resources/Definitions/_LocalObjectReference.tpl`

- access：`write`
- operations：`update` `definitions.localObjectReference` 的 `name` 取值链。
- writable-scopes：`definitions.localObjectReference` 中 `name` 处理闭环。

### `templates/api-resources/Definitions/_NodeSelectorRequirement.tpl`

- access：`write`
- operations：`update` `definitions.nodeSelectorRequirement` 中 `key`、`operator` 的循环取值链。
- writable-scopes：`definitions.nodeSelectorRequirement` 中 `key`、`operator` 处理闭环。

### `templates/api-resources/Definitions/_NodeSelectorTerm.tpl`

- access：`write`
- operations：`update` `definitions.nodeSelectorTerm.requirementList` 中原生 map 条目的 `key` 与 `operator` 取值链。
- writable-scopes：`definitions.nodeSelectorTerm.requirementList` 中原生 map 条目的 `key`、`operator` 处理闭环。

### `templates/api-resources/Definitions/_PodAffinityTerm.tpl`

- access：`write`
- operations：`update` `definitions.podAffinityTerm` 的 `topologyKey` 取值链。
- writable-scopes：`definitions.podAffinityTerm` 中 `topologyKey` 处理闭环。

### `templates/api-resources/Definitions/_PodOS.tpl`

- access：`write`
- operations：`update` `definitions.podOS` 的 `name` 取值链。
- writable-scopes：`definitions.podOS` 中 `name` 处理闭环。

### `templates/api-resources/Definitions/_PodReadinessGate.tpl`

- access：`write`
- operations：`update` `definitions.podReadinessGate` 的 `conditionType` 取值链。
- writable-scopes：`definitions.podReadinessGate` 中 `conditionType` 处理闭环。

### `templates/api-resources/Definitions/_PodResourceClaim.tpl`

- access：`write`
- operations：`update` `definitions.podResourceClaim` 的 `name`、`resourceClaimName`、`resourceClaimTemplateName` 取值链。
- writable-scopes：`definitions.podResourceClaim` 中上述三个字段的处理闭环。

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` `base.string.normalize` 与 `base.isFromYamlError` 的当前实现与契约注释。

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.int` 的当前实现与契约注释。

### `templates/base/_validate.tpl`

- access：`read`
- operations：`consume` `base.int.range` 的当前实现与契约注释。

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume` `base.get` 的返回值形态与标量空值语义。

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field` 的空值不输出与渲染模板选择契约。

### `templates/base/_env.tpl`

- access：`read`
- operations：`consume` `SYS.YAML_QUOTED` 与 `APPS.DEPLOYMENT.STRATEGY` 的运行时表达式。

### `templates/base/_k8s.tpl`

- access：`read`
- operations：`consume` `base.labelKey` 的入参、trim 与失败消息契约。

## 验证设计

- 最小有效：`/tmp/` 最小 application Chart 加载真实 `templates/base/*.tpl` 与本次变更的全部 `templates/api-resources/` 模板，渲染只提供 `selector` 的 Deployment，预期输出 `paused: false`、仅含基础标签的 `matchLabels`，且不出现 `minReadySeconds`、`replicas`、`progressDeadlineSeconds`、`revisionHistoryLimit`、`strategy` 等未提供字段。
- 较完整有效：同一 fixture 覆盖带引号标量（`nodeName: "007"` → `"07"`、`dnsPolicy: "None"` → `None`）、首尾空白（`'  spaced  '` → `spaced`）、`selector: {}`、`strategy: "RollingUpdate 25% 10%"`、`strategy: "RollingUpdate \"\" 10%"`、`replicas: 3`、`replicas: 999999`、`terminationGracePeriodSeconds: 0`，预期字段值与 spec 场景一致。
- 零值语义：`replicas: 0` 输出 `replicas: 0`；`minReadySeconds: 0`、`progressDeadlineSeconds: 0`、`revisionHistoryLimit: 0`、`activeDeadlineSeconds: 0` 不输出对应字段；`terminationGracePeriodSeconds: 0` 输出 0。
- 缺失语义：四个 DeploymentSpec 整数字段全部省略时不输出其中任何一个，渲染不中断，输出中不出现模板默认值。
- 关键失败：`nodeName: true`、`topologyKey: 5`、`conditionType: [a]` 触发 `[base.string.normalize]` 前缀中断；`replicas: -1`、`replicas: "3"`、`activeDeadlineSeconds: 1.5`、`replicas: 1000000`、`replicas: 2147483648` 触发数值链路中断；`type: "null"`、`strategy: 5`、`selector: "null"` 触发对应字段中断。
- 边界通过：`strategy: "\"\""` 不输出 `strategy` 且渲染不中断；直接以原生整数传入 `progressDeadlineSeconds: 2147483647` 时输出该值。
- 依赖边界：`templates/base/*.tpl` 使用当前真实实现，不使用同名 fixture 替代；`/tmp/` fixture 只提供 Chart 元数据与 values。
