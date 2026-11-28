# definitions.volumeProjection 设计

## 技术目标

- capability：`definitions.volumeProjection`
- artifact-type：Helm 命名模板
- target：`templates/api-resources/Definitions/_VolumeProjection.tpl`（define `definitions.volumeProjection`）

## 设计决策

### Decision: 以字段表收集出现字段并强制恰好一个

- requirements：`渲染 VolumeProjection 字段片段`
- choice：按官方字段顺序定义 `{key, define}` 表；用 `hasKey` 收集实际出现的字段键，`len` 不为 1 时中断并列出实际字段名；随后只渲染该字段。
- rationale：官方定义要求 exactly one of these fields must be set；`definitions.envVarSource` 已使用同类互斥字段表与 `hasKey` 收集的事实；错误需要可定位实际出现的字段。

### Decision: 字段值必须为非空原生 map

- requirements：`渲染 VolumeProjection 字段片段`
- choice：用 `base.get` 取出唯一字段值，经 `fromYaml` 恢复并以 `base.isFromYamlError` 保护；取值后不是非空原生 map 时中断；不提供 string 简写。
- rationale：官方六个字段类型均为 object；工程规则要求多层字段统一使用 `base.get`；规格要求为空或非法时中断；父模板以原生 map 条目传入。

### Decision: 委托子模板并拒绝空输出

- requirements：`渲染 VolumeProjection 字段片段`
- choice：以字段值 `include` 对应子模板，`fromYaml` 后用 `base.isFromYamlError` 保护；空结果中断；最终用 `base.field` + `base.map` 输出。
- rationale：六个子模板当前不可用且不在本 change 实现；必填字段不允许因空渲染静默消失；`base.map` 执行最终 map 类型门禁，调用方不重复类型检查。

## 依赖契约

### Dependency: `definitions.clusterTrustBundleProjection`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`ClusterTrustBundleProjection` 原生 map。
- output：非空 YAML map；空输出或非法 YAML 由本模板中断。
- ownership：子模板负责字段识别、校验与渲染；本模板只负责互斥、字段生效判断与委托。

### Dependency: `definitions.configMapProjection`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`ConfigMapProjection` 原生 map。
- output：非空 YAML map；空输出或非法 YAML 由本模板中断。
- ownership：子模板负责字段识别、校验与渲染；本模板只负责互斥、字段生效判断与委托。

### Dependency: `definitions.downwardAPIProjection`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`DownwardAPIProjection` 原生 map。
- output：非空 YAML map；空输出或非法 YAML 由本模板中断。
- ownership：子模板负责字段识别、校验与渲染；本模板只负责互斥、字段生效判断与委托。

### Dependency: `definitions.podCertificateProjection`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`PodCertificateProjection` 原生 map。
- output：非空 YAML map；空输出或非法 YAML 由本模板中断。
- ownership：子模板负责字段识别、校验与渲染；本模板只负责互斥、字段生效判断与委托。

### Dependency: `definitions.secretProjection`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`SecretProjection` 原生 map。
- output：非空 YAML map；空输出或非法 YAML 由本模板中断。
- ownership：子模板负责字段识别、校验与渲染；本模板只负责互斥、字段生效判断与委托。

### Dependency: `definitions.serviceAccountTokenProjection`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`ServiceAccountTokenProjection` 原生 map。
- output：非空 YAML map；空输出或非法 YAML 由本模板中断。
- ownership：子模板负责字段识别、校验与渲染；本模板只负责互斥、字段生效判断与委托。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文 map> "<点分路径>"`
- output：YAML string，需 `fromYaml` 恢复；缺失或空值返回空输出。
- ownership：`base.get` 负责数据源优先级、叶子别名与 Map 合并；本模板负责 YAML 解析、类型与空值判断。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list <字段名> <子模板恢复的 map> "base.map"`
- output：可嵌入父 map 的单字段 YAML 片段。
- ownership：`base.field` 负责字段渲染；本模板负责字段名、值生效判断与错误保护。

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：子模板恢复后的 map。
- output：YAML map；非 map 类型时中断。
- ownership：`base.map` 执行最终 map 类型门禁；本模板不重复 `kindIs "map"` 检查。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：子模板输出的 `fromYaml` 恢复结果。
- output：`"true"` 或 `"false"`。
- ownership：`base.isFromYamlError` 只识别解析错误；本模板负责失败消息与空结果判断。

## 代码边界

### `templates/api-resources/Definitions/_VolumeProjection.tpl`

- access：write
- operations：`add`
- writable-scopes：`definitions.volumeProjection` 的契约注释与 define 块

### `templates/api-resources/Definitions/_ProjectedVolumeSource.tpl`

- access：read
- operations：`consume` 既有 `sources` 条目委托，不修改

## 验证设计

- 最小有效：`{configMap: {name: "cfg"}}` 输出以 `configMap` 为键的 map 片段。
- 较完整有效：六个官方字段分别单独输入时，输出对应字段键并调用各自的子模板。
- 关键失败：无字段、两个及以上字段同时出现、字段为空 map、字段为 null、字段为 string、子模板输出为空内容或非法 YAML 时均中断并报错。
- 依赖边界：六个子模板当前不可用，使用 `/tmp/sd-kube-chart/` 最小 Chart 中的同名 fixture；结果只证明本模板的互斥、校验与委托行为，不证明真实子模板集成。
