# definitions.fcVolumeSource 定义模板设计

## 技术目标

- capability：`definitions.fcVolumeSource` 与 `definitions.volume` 的 `fc` 字符串清洗
- artifact-type：Helm library Chart 命名模板
- target：`templates/api-resources/Definitions/_FCVolumeSource.tpl` 的 `definitions.fcVolumeSource` 与 `templates/api-resources/Definitions/_Volume.tpl` 的 `fc` 分支

## 设计决策

### Decision: 文件命名与调用入口

- requirements：`上下文与输出范围`
- choice：新增 `templates/api-resources/Definitions/_FCVolumeSource.tpl`，定义 `definitions.fcVolumeSource`，不新增其他命名模板。
- rationale：`definitions.volume` 已按 `definitions.<source>VolumeSource` 调用 `fc` 分支；同一域既有 `_CSIVolumeSource.tpl` 使用官方缩写大写文件名，`fc` 的命名模板名保持不变。

### Decision: 字段归一化通道

- requirements：`fsType 枚举`、`lun 整数`、`readOnly 布尔`、`WWN 分支与组合约束`
- choice：
  - `fsType`：`base.get` → `base.string.normalize` → `trim`；非空时交给 `base.field` 的允许值列表 `ext4`、`xfs`、`ntfs`。
  - `readOnly`：`base.get` → `trim` → `SYS.YAML_QUOTED` 剥离 → `trim`；非空时交给 `base.field` + `base.bool`。
  - `lun`：`base.get` → `trim`；非空时交给 `base.field` + `base.int.positive`。
  - `targetWWNs`、`wwids`：`base.get` → `trim`；非空时 `fromYamlArray` 恢复并先经 `base.isFromYamlArrayError` 排除解析错误，再逐元素执行 `kindIs "string"` 门禁；非空列表最终交给 `base.field` + `base.slice`。
- rationale：枚举、布尔、非负整数与 slice 序列化能力均已由 `base.*` 提供，项目规则禁止内联；该组合与 `definitions.csiVolumeSource`、`definitions.execAction`、`definitions.podSecurityContext` 的既有处理一致。`fsType` 不做大小写归一，父模板 string 分支已输出小写。

### Decision: 父模板 fc 上下文类型归一与契约说明

- requirements：`fc 卷字符串清洗`
- choice：在 `_Volume.tpl` 的 `fc` 分支把 `base.int.positive` 的结果以 `int` 写入上下文 `lun`；`fc` 分支契约注释显式写明 `lun` 仅在 `targetWWNs` 出现时写入、`targetWWNs` 缺 `lun` 由 `definitions.fcVolumeSource` 中断、`wwids` 分支忽略 `lun`；父模板不新增 `targetWWNs` 与 `lun` 的组合校验。
- rationale：子模板按原生整数校验 `lun`，父模板此前写入 `base.int.positive` 返回的字符串，导致清洗后 map 与原生 map 不等价；组合规则已由子模板负责，父模板重复校验会违反单一职责。契约注释与规格同时说明边界，避免调用方依赖隐含行为。

### Decision: WWN 分支判定与优先级

- requirements：`WWN 分支与组合约束`
- choice：先解析 `targetWWNs`；结果非空时选择 `targetWWNs` 分支，此时不读取 `wwids`，并要求 `lun` 原始取值非空，否则本层中断；`targetWWNs` 为空时再解析 `wwids`，非空时选择 `wwids` 分支且不读取 `lun`；两者皆空时本层中断。空 array、null 与缺失统一按未提供处理。
- rationale：规格锁定 `targetWWNs` 优先、`targetWWNs` 与 `lun` 整组出现、`wwids` 分支不渲染 `lun`；只读取当前分支字段可避免被抑制字段影响结果。

### Decision: 输出顺序与显式零值

- requirements：`上下文与输出范围`、`lun 整数`、`readOnly 布尔`
- choice：按 `fsType`、`lun`、`readOnly`、`targetWWNs`、`wwids` 顺序输出；字段生效判定使用归一化前的非空原始取值，`lun` 为 `0`、`readOnly` 为 `false` 时均调用 `base.field` 输出；`targetWWNs` 与 `wwids` 只输出当前分支字段。
- rationale：字段顺序遵循本地 Kubernetes v1.36 API 镜像；显式 `0` 与 `false` 是有效取值，不能以真值判断代替生效判断。

### Decision: 失败消息边界

- requirements：`上下文与输出范围`、`WWN 分支与组合约束`
- choice：本层产生的消息统一为 `[definitions.fcVolumeSource] <字段路径>: <原因>`；组合错误使用 `targetWWNs`、`wwids`、`lun` 字段路径；由 `base.string.normalize`、`base.field`、`base.bool`、`base.int.positive` 产生的消息保留其自身前缀。
- rationale：项目规则要求失败消息带模板名与字段路径；Helm 无法改写被 include 模板的消息，`definitions.csiVolumeSource` 已采用同一边界。

### Decision: 验证边界

- requirements：`上下文与输出范围`、`fsType 枚举`、`lun 整数`、`readOnly 布尔`、`WWN 分支与组合约束`
- choice：在 `/tmp/sd-kube-chart/` 新建最小 application Chart，加载真实 `_FCVolumeSource.tpl`、`_Volume.tpl` 及 base 依赖，通过直接 include、`definitions.volume` 的 `fc` 原生 map 与 `fc` 字符串三条入口渲染，并核对 `_Volume.tpl` 的 `fc` 契约注释包含三条组合边界；全部依赖均为 existing，不使用 fixture。
- rationale：目标模板与父模板均已由当前代码提供真实调用契约，临时 Chart 可直接验证真实递归依赖；字符串入口可覆盖清洗后 map 的等价性与组合边界。

## 依赖契约

### Dependency: `base.get`

- availability：existing
- source：`templates/base/_get.tpl`
- operation：consume
- input：`list <上下文> <点分路径>`，路径为 `targetWWNs`、`wwids`、`lun`、`fsType`、`readOnly`。
- output：可交给 `fromYamlArray` 或标量归一能力的 YAML 字符串；路径缺失或为 null 时为空字符串。
- ownership：依赖负责取值、别名识别与跨源合并；本层负责字段生效判定、解析与归一化。

### Dependency: `base.string.normalize`

- availability：existing
- source：`templates/base/_convert.tpl`
- operation：consume
- input：`base.get` 返回的 `fsType` YAML 标量文本。
- output：解码后的 string；空输入返回空字符串；非 string 标量中断。
- ownership：依赖负责 YAML 标量解码与类型门禁；本层负责 trim 与空值跳过。

### Dependency: `base.isFromYamlArrayError`

- availability：existing
- source：`templates/base/_convert.tpl`
- operation：consume
- input：`fromYamlArray` 返回值。
- output：布尔字符串；解析失败时为 `true`。
- ownership：依赖负责识别 Helm 的 YAML array 解析错误形态；本层负责失败消息与后续元素校验。

### Dependency: `base.field`

- availability：existing
- source：`templates/base/_field.tpl`
- operation：consume
- input：`list [key, value, 渲染模板, 允许值列表]`，用于 `fsType`、`lun`、`readOnly`、`targetWWNs`、`wwids` 的输出。
- output：单字段 YAML 片段；值为空时不输出；枚举或类型不匹配时中断。
- ownership：依赖负责字段输出格式、枚举校验与最终类型门禁；本层负责字段生效判定与值归一化。

### Dependency: `base.bool`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：剥离 YAML 引号后的 `true` / `false` 字符串。
- output：`true` / `false`；其他取值中断。
- ownership：依赖负责布尔表示校验；本层负责引号剥离、trim 与空值跳过。

### Dependency: `base.int.positive`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：`base.get` 返回的 `lun` 原始文本。
- output：非负整数；负值、非整数文本或其他类型中断。
- ownership：依赖负责非负整数门禁与转换；本层负责空值跳过与输出顺序。

### Dependency: `base.slice`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：已恢复且元素均为 string 的非空列表。
- output：`toYamlPretty` 序列化后的 YAML 列表；非 slice 中断。
- ownership：依赖负责列表序列化与类型门禁；本层负责元素校验、分支选择与空列表判定。

### Dependency: `base.env`

- availability：existing
- source：`templates/base/_env.tpl`
- operation：consume
- input：`""`；经 `fromYaml` 恢复常量 map。
- output：常量 map；本层只读取 `SYS.YAML_QUOTED`。
- ownership：依赖负责集中常量；本层不得内联等价正则。

## 代码边界

### `templates/api-resources/Definitions/_FCVolumeSource.tpl`

- access：write
- operations：新增 `definitions.fcVolumeSource` 及文件头整体契约注释；实现五个字段的取值、归一、校验、WWN 分支判定与按 API 顺序渲染。
- writable-scopes：文件头整体契约注释与 `definitions.fcVolumeSource` define 块。

### `templates/api-resources/Definitions/_Volume.tpl`

- access：write
- operations：将 `fc` 分支的 `lun` 上下文写入类型改为原生整数；在 `fc` 分支契约注释中补充三条组合边界；不修改正则、其他 source 分支或文件级 source 列表。
- writable-scopes：`definitions.volume` 的 `fc` 分支契约注释与 `lun` 上下文写入语句。

### `templates/api-resources/Definitions/_CSIVolumeSource.tpl`

- access：read
- operations：对照同域卷源模板的字段归一、空值跳过与失败消息模式。

### `templates/base/_get.tpl`

- access：read
- operations：复核取值、别名、空输出与 slice 合并语义。

### `templates/base/_convert.tpl`

- access：read
- operations：复核 `base.string.normalize` 与 `base.isFromYamlArrayError` 契约。

### `templates/base/_field.tpl`

- access：read
- operations：复核渲染模板、允许值列表与空值输出契约。

### `templates/base/_types.tpl`

- access：read
- operations：复核 `base.bool`、`base.int.positive` 与 `base.slice` 契约。

### `templates/base/_env.tpl`

- access：read
- operations：复核 `SYS.YAML_QUOTED` 常量。

## 验证设计

- 最小有效：在最小 application Chart 中直接 include `definitions.fcVolumeSource` 并传 `{targetWWNs: ["10:20:30:40:50:60:70:80"], lun: 0}`，输出仅含 `lun: 0` 与 `targetWWNs` 且顺序符合 API。
- 较完整有效：直接 include 传 `fsType: xfs`、`readOnly: false`、`targetWWNs` 与 `wwids` 同时存在，确认只输出 `targetWWNs` 分支且保留显式 `false`；再传 `wwids` 与 `lun` 且不传 `targetWWNs`，确认输出仅含 `wwids`；随后经 `definitions.volume` 的 `fc` 原生 map 渲染完整 Volume，确认字段片段一致。
- 关键失败：`targetWWNs` 缺少 `lun`、两个 WWN 组均缺失或为空 array、`fsType: EXT4`、`lun: -1`、`readOnly: yes`、`targetWWNs` 为非 array 或含非 string 元素；确认全部中断且消息前缀归属符合失败消息边界。
- 字符串入口：经 `definitions.volume` 传 `fc: "0 xfs targetWWNs (10:20:30:40:50:60:70:80) wwids (0x5001)"`，输出与等价原生 map 一致；传 `fc: "xfs targetWWNs (...)"` 中断；传 `fc: "xfs wwids (...)"` 不输出 `lun`；并核对 `fc` 契约注释包含三条组合边界。
