# definitions.projectedVolumeSource 设计

## 技术目标

- capability：`definitions.projectedVolumeSource`
- artifact-type：Helm 命名模板
- target：`templates/api-resources/Definitions/_ProjectedVolumeSource.tpl`（define `definitions.projectedVolumeSource`）

## 设计决策

### Decision: defaultMode 复用既有 mode 归一化

- requirements：`渲染 ProjectedVolumeSource 字段片段`
- choice：使用 `base.get` 取值，经 `base.env` 的 `SYS.YAML_QUOTED` 剥离引号后交由 `base.fileMode` 校验并归一化为十进制 int，再用 `base.field` 以 `base.int` 渲染；空值不输出。
- rationale：当前 `definitions.configMapVolumeSource` 与 `definitions.downwardAPIVolumeSource` 已采用同一模式；工程规则要求复用 `base.*` 的取值、归一、校验与渲染能力，不重复实现 mode 语义。

### Decision: sources 逐项委托并回收

- requirements：`渲染 ProjectedVolumeSource 字段片段`
- choice：`base.get` 取原始值后用 `fromYamlArray` 解析并以 `base.isFromYamlArrayError` 保护；逐项要求 `kindIs "map"`，以条目的原生 map 为上下文 `include "definitions.volumeProjection"`，`fromYaml` 后以 `base.isFromYamlError` 保护；空渲染结果不追加，最终用 `mustUniq` 去重并通过 `base.field` + `base.slice` 渲染；集合为空时不输出 `sources`。
- rationale：规格要求原生 map 条目、逐项委托、空结果剔除与保序去重；`mustUniq` 按深度相等保留首个，符合去重语义；`fromYamlArray`/`fromYaml` 保护与 `base.slice` 类型门禁是工程规则规定的结构模板解析路径。

### Decision: volumeProjection 保留占位调用

- requirements：`渲染 ProjectedVolumeSource 字段片段`
- choice：直接 `include "definitions.volumeProjection"`，本 change 不创建该模板。
- rationale：规格与依赖契约均声明该子模板当前不可用且不在本 change 实现；`core.persistentVolumeClaimSpec` 对未实现子模板已有同类调用占位事实。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文 map> "<点分路径>"`
- output：YAML string；路径缺失时为空输出。
- ownership：`base.get` 负责数据源优先级、别名与取值；本模板负责 YAML 解析、类型判断与字段生效判断。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`
- output：常量 Map 的 YAML string，需经 `fromYaml` 恢复。
- ownership：`base.env` 维护常量结构与类型；本模板只读取 `SYS.YAML_QUOTED`。

### Dependency: `base.fileMode`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：int、int64、float64，或八进制/十进制文件模式字符串。
- output：十进制 int；非法类型、格式或范围时中断。
- ownership：`base.fileMode` 负责 mode 格式与范围校验；本模板不重复校验。

### Dependency: `base.int`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`base.fileMode` 返回的十进制 int。
- output：int 标量；非目标类型时中断。
- ownership：`base.int` 执行最终 int 类型门禁；本模板不重复类型检查。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list <key> <已归一化 value> <base.int | base.slice>`
- output：可嵌入父 map 的 YAML 字段片段；渲染为空时不输出。
- ownership：`base.field` 负责字段渲染与渲染模板委派；本模板负责取值、解析、错误保护和字段生效判断。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`sources` 回收后的非空 list。
- output：YAML 数组；非 list 时中断。
- ownership：`base.slice` 执行最终 list 类型门禁；本模板不重复 `kindIs "slice"` 检查。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 的恢复结果。
- output：`"true"` 或 `"false"`；本模板据此判断 `sources` 原始值是否为合法数组。
- ownership：`base.isFromYamlArrayError` 只识别解析错误；本模板负责失败消息与非空判断。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的恢复结果。
- output：`"true"` 或 `"false"`；本模板据此判断 `definitions.volumeProjection` 输出是否为合法 YAML。
- ownership：`base.isFromYamlError` 只识别解析错误；本模板负责失败消息与空结果剔除。

### Dependency: `definitions.volumeProjection`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：单个 `VolumeProjection` 原生 map。
- output：可嵌入 `sources` 数组元素的 YAML map；空输出表示该条目被剔除；非法 YAML 由本模板中断。
- ownership：子模板负责条目字段识别、校验与渲染；本模板只负责逐项调用、空结果剔除、去重与渲染 `sources` 字段。

## 代码边界

### `templates/api-resources/Definitions/_ProjectedVolumeSource.tpl`

- access：write
- operations：`add`
- writable-scopes：`definitions.projectedVolumeSource` 的契约注释与 define 块

### `templates/api-resources/Definitions/_Volume.tpl`

- access：read
- operations：`consume` 既有 `projected` 委托，不修改

## 验证设计

- 最小有效：空 map 输出空内容；`defaultMode: "0644"` 输出 `defaultMode: 420`；`defaultMode: 0` 输出 `defaultMode: 0`。
- 较完整有效：`defaultMode` 与多个 `sources` 同时输入时按 `defaultMode`、`sources` 顺序输出；空渲染条目被剔除，完全相同的条目只保留首个且保持输入顺序；全部条目为空时不输出 `sources`。
- 关键失败：`defaultMode: "9999"`、`sources` 为 map、`sources` 条目为 string、子模板返回非法 YAML 时均中断并报错。
- 依赖边界：`definitions.volumeProjection` 当前不可用，使用 `/tmp/sd-kube-chart/` 最小 Chart 中的同名 fixture；结果只证明本模板的调用与回收行为，不证明真实子模板集成。
