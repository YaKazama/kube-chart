# core.podSpec 设计

## 技术目标

- capability：`core.podSpec`
- artifact-type：命名模板
- target：`templates/api-resources/Core/_PodSpec.tpl` 中的 `define "core.podSpec"`

## 设计决策

### Decision: 目标文件与模板命名

- requirements：`调用上下文与字段取值优先级`
- choice：在 `templates/api-resources/Core/_PodSpec.tpl` 中定义 `core.podSpec`，入参为父级透传的上下文 `.`，不重新包装 `dict`。
- rationale：命名空间 `core.*` 已由 `core.podTemplateSpec` 占用，新模板须与其同目录同级；规格已锁定透传同一上下文的调用方式。

### Decision: 字段取值与别名

- requirements：`调用上下文与字段取值优先级`
- choice：所有字段统一通过 `base.get` 取值，不传 `alias=false`，由 `base.get` 隐式完成同级 `<字段名>Alias` 优先识别；不实现任何额外短别名。
- rationale：规格只要求 `<字段名>Alias` 与规范键，且 `base.get` 已内置该行为；自行实现会与既有能力重复。

### Decision: 输出顺序与字段渲染

- requirements：`字段输出顺序`、`无枚举约束的字符串字段`、`nodeSelector 渲染`
- choice：按固定顺序依次渲染各字段，标量与 map/list 均通过 `base.field` 输出；map/list 先经 `base.map`/`base.slice` 做最终类型门禁再交给 `base.field`。`nodeSelector` 是唯一不经子模板的 map 字段，直接使用 `base.get` + `base.map` + `base.field`；`nodeName`、`priorityClassName`、`runtimeClassName`、`schedulerName`、`serviceAccountName`、`subdomain` 不做枚举校验，非空即经 `base.string` 渲染。单目标类型字段只用 `base.isFromYamlError` 排除解析错误后交给 `base.map`/`base.slice` 做类型门禁，不重复 `kindIs`；只有 map 与 string 等多类型输入才用 `kindIs` 选择归一化分支，数组元素类型仍在本层判定。
- rationale：`base.field` 是既有的统一键值渲染入口，能保证枚举校验与输出格式一致；顺序固定可直接对照官方文档。`fromYaml` 与 `fromYamlArray` 恢复成功即保证目标结构，重复 `kindIs` 不提供额外信息。

### Decision: 枚举校验

- requirements：`枚举字符串字段`
- choice：`dnsPolicy`、`preemptionPolicy`、`restartPolicy` 的允许值以 `base.field` 的 `allows` 参数传入，由 `base.field` 在渲染前完成校验。
- rationale：`base.field` 已支持枚举校验并在越界时失败，错误信息自带键名，满足规格要求的可定位错误。

### Decision: 主机名字段校验

- requirements：`主机名字段校验`
- choice：`hostname` 以 `base.rfc` 的 `1035` 模式校验，`hostnameOverride` 以 `base.rfc` 的 `1123` 模式校验；只在取值非空时校验并渲染，长度上限沿用这两个模式各自的 63 字符限制，不额外叠加 64 字符判断。
- rationale：规格已锁定复用项目既定 RFC 校验能力并接受由此产生的 63 字符收束；重复实现长度判断会与 `base.rfc` 契约冲突。

### Decision: activeDeadlineSeconds 生效判断

- requirements：`数值字段`
- choice：取值经正整数校验通过后，仅在数值大于 `0` 时经 `base.int.positive` 渲染。
- rationale：规格要求 `0` 不渲染，而 `base.int.positive` 接受非负整数，`0` 的排除只能在本层生效判断完成，不能下推给渲染模板。

### Decision: terminationGracePeriodSeconds 生效判断

- requirements：`数值字段`
- choice：取值非空即经 `base.int.positive` 渲染，不追加大于 `0` 的判断。
- rationale：规格要求显式 `0` 渲染为 `terminationGracePeriodSeconds: 0`，`base.int.positive` 的非负语义已满足该要求，追加判断会破坏契约。

### Decision: 仅 true 渲染的布尔字段生效判断

- requirements：`布尔字段生效条件`
- choice：`automountServiceAccountToken`、`hostIPC`、`hostNetwork`、`hostPID`、`setHostnameAsFQDN`、`shareProcessNamespace` 只在归一化结果为 `true` 时经 `base.field` 渲染，`false` 与空值不产生输出。布尔字段的类型门禁与渲染均由 `base.bool` 承担。
- rationale：规格规定这六个字段仅在 `true` 时渲染，生效判断必须在本层完成，不能交给只接收键值对的渲染模板猜测。

### Decision: hostUsers 生效判断

- requirements：`布尔字段生效条件`
- choice：`hostUsers` 在布尔型取值存在时即经 `base.field` 渲染，`true` 与 `false` 均输出。布尔字段的类型门禁与渲染均由 `base.bool` 承担。
- rationale：规格规定 `hostUsers` 的 `false` 也必须输出，与仅 `true` 渲染的布尔字段条件不同，不能共用同一判断。

### Decision: 互斥校验

- requirements：`字段互斥约束`
- choice：在读取完相关字段后、渲染对应字段前集中校验：`hostPID` 与 `shareProcessNamespace` 同时为真、`hostnameOverride` 非空且 `hostNetwork` 为真、`hostnameOverride` 非空且 `setHostnameAsFQDN` 为真时 `fail`。
- rationale：三组约束都跨字段，只能在本模板内判断；集中在渲染前校验可避免先输出部分字段后失败。

### Decision: affinity 合并

- requirements：`affinity 合并与委托`
- choice：以 `mustDeepCopy` 复制 `affinity` 取值，再用 `mustMerge`（低优先级补缺）把同级的 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 补入，从而保持 `affinity` 优先；不识别任何短键。
- rationale：`mustMerge` 的补缺语义正好等价于“`affinity` 内已有同名键不被覆盖”，且不会修改输入上下文。

### Decision: containers 输入形态归一化

- requirements：`containers 与 initContainers 委托`
- choice：`base.get` 取值后先按 `fromYamlArray` 恢复；恢复失败再按 `fromYaml` 解析，解析成功则视为单个容器并用 `list` 包装为单元素数组。逐项委托 `definitions.container` 时，用 `mustMerge` 把当前元素（键名 `containers`）与 `os` 和循环外一次性 `pick` 得到的 `Files`、`Values`、`Context` 合并为新上下文，输入上下文与元素均不被修改。`containers` 在有效输出为空时 `fail`。
- rationale：规格要求 map 与数组产出相同结果且子模板上下文边界固定；`pick` 是 Helm 内置函数，能精确满足白名单要求；白名单只在循环外求值一次可避免逐项重复计算。

### Decision: 字符串简写解析

- requirements：`hostAliases 归一化与委托`、`名称类数组字段归一化与委托`、`volumes 归一化与委托`
- choice：`hostAliases`、`resourceClaims` 使用 `base.env` 的 `SPLIT.SPACE_COMMA` 切分；`volumes` 字符串项使用 `base.env` 的 `K8S.VOLUME.SHORT` 三组捕获；`volumeType` 通过 `lower` 归一 + 模板内映射表转换为官方键名。业务模板不内联任何正则表达式。
- rationale：项目正则契约要求固定正则统一存放于 `base.env`，且规格已限定分隔符只含空格与逗号；当前 `SPLIT.ALL` 会按 `.`、`/` 等切分，无法满足规格，必须在 `_env.tpl` 新增专用常量。

### Decision: volumes 原生项拆分与唯一性

- requirements：`volumes 归一化与委托`
- choice：遍历第一层键，`name` 归入 `volumeName`，遇到第一个非 `name` 键记录为 `volumeType` 与其值为 `volumeData`，若再遇到第二个非 `name` 键则 `fail`。
- rationale：规格要求非 `name` 键互斥且唯一，必须在拆分阶段判定，无法留到子模板。

### Decision: 逐项委托类字段的上下文构造

- requirements：`名称类数组字段归一化与委托`、`resources 与 securityContext 委托`、`tolerations 与 topologySpreadConstraints 委托`
- choice：`imagePullSecrets`、`readinessGates`、`resourceClaims`、`tolerations`、`topologySpreadConstraints` 逐元素委托，元素本身即子模板上下文；`os` 作为单对象委托；`resources` 用 `pick` 从取值中只取 `claims`、`limits`、`requests`；`securityContext` 用取值本身并用 `set` 注入同源的 `os`。
- rationale：规格逐字段锁定了传入上下文的内容；`pick` 能保证 `resources` 不夹带多余键，`set` 能保证 `securityContext` 携带 `os` 而不修改原上下文副本。

### Decision: 委托输出解析保护与数组回收

- requirements：`委托输出保护与数组回收`
- choice：数组项的委托结果用 `fromYaml` 解析并用 `base.isFromYamlError` 排除解析错误，排除后为空则剔除该项；数组字段的输入统一用 `fromYamlArray` 恢复并用 `base.isFromYamlArrayError` 排除解析错误。去重由 `mustUniq` 完成，字符串数组在归一化阶段由 `mustWithout` 剔除空字符串。
- rationale：规格要求解析错误不得当作有效输出，且数组必须去重去空；把回收放在归一化与委托两侧可覆盖两种污染来源。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`add`
- input：`include "base.env" "" | fromYaml`。
- output：常量 Map；本次新增两个键：
  - `SPLIT.SPACE_COMMA`：运行时表达式 `\s*[,\s]+\s*`，`_env.tpl` 源码写作 `"\\s*[,\\s]+\\s*"`。
  - `K8S.VOLUME.SHORT`：运行时表达式 `^((?i:cm|configMap|secret|pvc|persistentVolumeClaim|emptyDir|hostPath|nfs|image|fc|iscsi))(?:\s+(.*?))(?:\s+(.*?))?$`，`_env.tpl` 源码中的 `\s` 按 YAML 双引号规则写作 `\\s`；捕获组 1 为 `volumeType` 且该组内容大小写不敏感，组 2 为 `volumeName`，组 3 为 `volumeData`。
- ownership：`base.env` 负责常量结构与类型有效性；本层负责按这两个键读取并执行匹配与捕获，不重复添加空输出或 YAML 保护。既有键 `SPLIT.ALL`、`SPLIT.COMMA`、`K8S.*` 保持 `consume`，不修改。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文> <点分路径>`，不传强制类型以外的可选参数，保持别名默认开启。
- output：可 `fromYaml` 解析的 YAML 字符串；路径全缺失时返回空输出。
- ownership：本层负责字段生效判断与类型分支；`base.get` 负责取值优先级、别名识别与跨源合并。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list <键名> <已归一化值> [渲染模板] [允许值列表]`。
- output：YAML 键值片段；渲染结果为空时不输出；枚举越界时失败。
- ownership：本层负责决定字段是否生效；`base.field` 负责枚举校验与输出格式。

### Dependency: `base.int.positive`、`base.bool`、`base.map`、`base.slice`、`base.string`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：对应目标类型的原始值。
- output：目标类型的文本表示；类型不符时失败。
- ownership：本层负责选取渲染模板；依赖负责最终类型门禁。

### Dependency: `base.rfc`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：`list <取值> "1035"` 或 `list <取值> "1123"`。
- output：校验通过的字符串；非法格式或超出该模式长度上限时失败。
- ownership：本层只负责决定校验时机；长度与格式规则由依赖的 `1035`/`1123` 模式决定。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值。
- output：布尔值，指示是否为解析错误形态。
- ownership：本层负责在排除解析错误后决定剔除或渲染。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 的返回值。
- output：布尔值，指示是否为解析错误形态。
- ownership：本层负责在排除解析错误后决定按单元素 map 归一化还是视为数组。

### Dependency: `definitions.affinity`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：合并后的 Affinity 对象。
- output：可 `fromYaml` 解析的 YAML 字符串；无有效内容时为空输出。
- ownership：合并与生效判断由本层负责；字段级结构与 `os` 相关约束由依赖层负责。规格已锁定调用契约，本 change 不实现。

### Dependency: `definitions.container`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：只包含 `containers`、`os`、`Files`、`Values`、`Context` 的上下文 map。
- output：可 `fromYaml` 解析的单个 Container YAML 片段。
- ownership：容器上下文构造由本层负责；容器字段与 `securityContext` 语义由依赖层负责。本 change 不实现。

### Dependency: `definitions.hostAlias`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：包含 `ip` 与 `hostnames` 的 map。
- output：可 `fromYaml` 解析的 HostAlias YAML 片段。
- ownership：字符串解析与去重由本层负责；结构输出由依赖层负责。本 change 不实现。

### Dependency: `definitions.localObjectReference`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：包含 `name` 的 map。
- output：可 `fromYaml` 解析的 LocalObjectReference YAML 片段。
- ownership：字符串归一化由本层负责；输出结构由依赖层负责。本 change 不实现。

### Dependency: `definitions.podOS`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：包含 `name` 的 map。
- output：可 `fromYaml` 解析的 PodOS YAML 片段。
- ownership：字符串归一化由本层负责；`name` 枚举与输出结构由依赖层负责。本 change 不实现。

### Dependency: `definitions.podReadinessGate`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：包含 `conditionType` 的 map。
- output：可 `fromYaml` 解析的 PodReadinessGate YAML 片段。
- ownership：字符串归一化由本层负责；输出结构由依赖层负责。本 change 不实现。

### Dependency: `definitions.podResourceClaim`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：包含 `name` 及可选 `resourceClaimName`、`resourceClaimTemplateName` 的 map。
- output：可 `fromYaml` 解析的 PodResourceClaim YAML 片段。
- ownership：字符串解析与缺省部分省略由本层负责；互斥约束由调用方或依赖层负责。本 change 不实现。

### Dependency: `definitions.resourceRequirements`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：包含 `claims`、`limits`、`requests` 的 map。
- output：可 `fromYaml` 解析的 ResourceRequirements YAML 片段。
- ownership：取键白名单由本层负责；各子字段校验由依赖层负责。本 change 不实现。

### Dependency: `definitions.podSecurityContext`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：包含原生 `securityContext` 字段与 `os` 的 map。
- output：可 `fromYaml` 解析的 PodSecurityContext YAML 片段。
- ownership：`os` 注入由本层负责；`os` 与 `securityContext` 的互斥校验由依赖层负责。本 change 不实现。

### Dependency: `definitions.toleration`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：单个 Toleration 元素。
- output：可 `fromYaml` 解析的 Toleration YAML 片段。
- ownership：数组遍历与去重由本层负责；结构输出由依赖层负责。本 change 不实现。

### Dependency: `definitions.topologySpreadConstraint`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：单个 TopologySpreadConstraint 元素。
- output：可 `fromYaml` 解析的 TopologySpreadConstraint YAML 片段。
- ownership：数组遍历与去重由本层负责；结构输出由依赖层负责。本 change 不实现。

### Dependency: `definitions.Volume`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：包含 `volumeType`、`volumeName`、`volumeData` 的 map。
- output：以 `volumeName` 作为 `name` 的 Volume YAML 片段。
- ownership：输入形态归一化、`volumeType` 映射和唯一性校验由本层负责；`volumeType` 到具体卷结构的展开由依赖层负责。本 change 不实现。

## 代码边界

### `templates/api-resources/Core/_PodSpec.tpl`

- access：`write`
- operations：`add` `define "core.podSpec"`，包含模板注释、字段取值、生效判断、互斥校验、子模板委托与委托输出保护。
- writable-scopes：新建文件整体；`define "core.podSpec"` 块。

### `templates/base/_env.tpl`

- access：`write`
- operations：`add` `SPLIT.SPACE_COMMA` 与 `K8S.VOLUME.SHORT` 两个常量键。
- writable-scopes：`define "base.env"` 块内的 `SPLIT` 下新增 `SPACE_COMMA` 行；`K8S` 下新增 `VOLUME` 分组及其 `SHORT` 键。既有常量行不得修改。

### `templates/base/_get.tpl`

- access：`read`
- operations：读取 `base.get` 的入参与返回契约，确认别名默认开启与空输出行为。

### `templates/base/_field.tpl`

- access：`read`
- operations：读取 `base.field` 的枚举校验与输出格式契约。

### `templates/base/_types.tpl`

- access：`read`
- operations：读取 `base.map`、`base.slice`、`base.string`、`base.bool`、`base.int.positive` 的类型门禁契约。

### `templates/base/_k8s.tpl`

- access：`read`
- operations：读取 `base.rfc` 的 `1035` 与 `1123` 模式正则及长度上限。

### `templates/base/_convert.tpl`

- access：`read`
- operations：读取 `base.isFromYamlError` 与 `base.isFromYamlArrayError` 的解析错误识别契约。

### `templates/api-resources/Core/_PodTemplateSpec.tpl`

- access：`read`
- operations：读取既有 `core.podSpec` 调用方式，确认上下文透传边界与返回值消费方式。

## 验证设计

- `containers` 必填失败：`/tmp/` 最小 application Chart 中提供 `containers` 缺失、`containers` 为空数组两种输入，验证渲染中断并报错。
- 枚举与数值边界：提供越界 `restartPolicy`、负值 `activeDeadlineSeconds`、`terminationGracePeriodSeconds: 0`，验证前三者分别中断与正常输出 `0`。
- 类型门禁：提供非 map 类型的 `nodeSelector`，验证中断。
- 互斥约束：分别提供 `hostPID` + `shareProcessNamespace`、`hostnameOverride` + `hostNetwork`、`hostnameOverride` + `setHostnameAsFQDN` 三组冲突输入，验证中断。
- 输入形态等价：同一容器分别以数组与 map 提供，比较两次渲染结果一致。
- affinity 合并优先级：同时提供 `affinity.nodeAffinity` 与同级 `nodeAffinity`，用 fixture 输出收到的上下文验证 `affinity` 内取值胜出。
- volumes 归一化：提供原生项、多非 `name` 键项、字符串简写项、`secret` 项、无法匹配正则的字符串项，验证拆分结果与中断行为。
- 依赖边界：所有 `definitions.*` 依赖均使用 `/tmp/` 测试 Chart 中的同名最小 fixture `define`，结论只证明 `core.podSpec` 自身行为，不表述为真实依赖集成通过。
- 解析保护与回收：fixture 返回空内容与非法 YAML，验证元素被剔除；提供重复 `imagePullSecrets`，验证去重后只剩一个元素。
- 正则常量：因本 change 修改 `templates/base/_env.tpl`，全部字符串简写场景必须加载真实 `_env.tpl` 实现，不得用同名 fixture 替代；需覆盖典型匹配、边界匹配（空格与逗号混合、多余分隔符）、不匹配与可选捕获为空。
