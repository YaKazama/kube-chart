# `definitions.ephemeralVolumeSource` 设计

## 技术目标

- capability：`definitions.ephemeralVolumeSource`
- artifact-type：Kubernetes 共享结构命名模板（library chart）
- target：`templates/api-resources/Definitions/_EphemeralVolumeSource.tpl`

## 设计决策

### Decision: base.get 取值与必填非空校验

- requirements：`volumeClaimTemplate 必填且可恢复为非空 map`、`原生 map 上下文与字段范围`
- choice：使用 `base.get` 读取 `volumeClaimTemplate` 并用 `fromYaml` 恢复为 map；依次检查解析错误与空值，不使用 `kindIs "map"` 类型门禁；不读取其他键。
- rationale：`fromYaml` 成功即保证结果为 map，重复 `kindIs` 属于冗余检查；`base.get` 负责多数据源取值与别名识别，空 map 与缺失统一按必填非空失败。

### Decision: 子模板委托与条件输出

- requirements：`子模板委托与字段输出`
- choice：以非空 `volumeClaimTemplate` map 为上下文调用 `definitions.persistentVolumeClaimTemplate`；子模板返回非空内容时经 `base.field` 输出 `volumeClaimTemplate`，返回空内容时跳过；本 change 不创建该子模板。
- rationale：spec 要求字段由子模板决定；子模板当前 `unavailable`，真实渲染需其实现，隔离验证在 `/tmp/sd-kube-chart/` 提供同名 fixture。Helm 4.3.2 对未定义模板执行 `include` 会中断，因此子模板缺失时真实渲染不可用。

## 依赖契约

### Dependency: `definitions.persistentVolumeClaimTemplate`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`volumeClaimTemplate` 的非空原生 map，类型为 Kubernetes PersistentVolumeClaimTemplate
- output：可嵌入 `volumeClaimTemplate` 的 YAML 字段片段；返回空内容时本层跳过字段输出。当前未实现，真实调用会因模板未定义而中断
- ownership：本层负责必填非空 map 校验、调用与条件渲染；子模板负责 `metadata`、`spec` 等内部结构校验与渲染

## 代码边界

### `templates/api-resources/Definitions/_EphemeralVolumeSource.tpl`

- access：`write`
- operations：新增 `definitions.ephemeralVolumeSource` 命名模板及其契约注释
- writable-scopes：整个新文件，仅限 `definitions.ephemeralVolumeSource` 与紧邻契约注释

### `templates/api-resources/Definitions/_Volume.tpl`

- access：`read`
- operations：复核 `ephemeral` 分派及原生 map 透传契约

## 验证设计

- 最小有效：在同一隔离 Chart 中提供返回非空内容的 `definitions.persistentVolumeClaimTemplate` fixture，调用本模板，预期输出包含 `volumeClaimTemplate`。
- 较完整有效：fixture 返回空内容，预期输出不包含 `volumeClaimTemplate` 且不报错；未声明键被忽略。
- 关键失败：缺失、null、`{}`、无法恢复为 map 的字符串与列表输入分别中断，失败消息包含 `[definitions.ephemeralVolumeSource] volumeClaimTemplate`。
- 真实依赖 `definitions.persistentVolumeClaimTemplate` 当前 unavailable；fixture 只证明本模板自身的调用与条件渲染，不代表子模板集成通过。
