# 修正 definitions.volume 的 csi string 中 nodePublishSecretRef 为可选设计

## 技术目标

- capability：`definitions.volume` 的 `csi` 字符串简写解析
- artifact-type：Helm library Chart 命名模板与 `base.env` 常量
- target：`definitions.volume`

## 设计决策

### Decision: csi 位置段可选 secret 与枚举归属

- requirements：`csi 卷字符串`
- choice：`K8S.VOLUME.CSI` 保持 6 个捕获组与组序，只把 `nodePublishSecretRef` 捕获组由 `(\S+)` 改为可选 `(?:\s+(\S+))?`。取值后：`$2` 非空且 `lower $2` 命中 `ext4`、`xfs`、`ntfs` 时写入 `fsType`，否则以原始字符串写入 `nodePublishSecretRef`；`$3` 非空时写入 `fsType`；`$4` 非空时经 `lower` 交 `base.bool` 写入 `readOnly`；`$5` 非空时进入既有 attributes 处理。
- rationale：Go RE2 不支持 lookahead，位置可选段只能靠可选捕获组表达；仅放宽 `$2` 使其余组编号与 attributes 分支不变。枚举归属必须在取值后判定，因为正则无法排除 `\S+` 命中枚举字面量。

### Decision: 空值与重复赋值失败边界

- requirements：`csi 卷字符串`
- choice：`$2` 为空串时不写入 `nodePublishSecretRef` 键；`$3`、`$4` 为空串时同样不写入对应键。`$2` 命中枚举且 `$3` 非空时中断。
- rationale：空串来自未匹配的可选捕获组，规格定义其为未提供；`ext4` 等枚举取值归属 `fsType` 后与 `$3` 形成同一字段的两次赋值，项目规则要求未定义优先级时失败，因此中断而不是静默取舍。

### Decision: 错误消息同步

- requirements：`csi 卷字符串`
- choice：`csi` 分支不匹配时使用 `'<driver> [nodePublishSecretRef] [fsType] [readOnly] [attr|volumeAttributes (key value, ...)]'`；重复赋值使用独立消息，前缀沿用 `[definitions.volume] csi:`。
- rationale：提示文案必须与新语法一致，重复赋值与格式不匹配属于不同失败原因，合并会丢失定位信息。

### Decision: 子模板 unavailable 与验证 fixture

- requirements：`csi 卷字符串`
- choice：`definitions.csiVolumeSource` 标记为 `unavailable`，本 change 不创建。验证在 `/tmp/sd-kube-chart/` 最小 application Chart 中提供同名 fixture，回显收到的上下文；fixture 只证明 `definitions.volume` 的解析、键生效与失败行为。
- rationale：项目规则允许引用 unavailable 子模板并使用同名最小 fixture；真实 `CSIVolumeSource` 渲染由独立 change 落地。

## 依赖契约

### Dependency: `base.env`

- availability：existing
- source：`templates/base/_env.tpl`
- operation：update
- input：`""`；经 `fromYaml` 恢复常量 map。
- output：常量 map；`K8S.VOLUME.CSI` 的 `nodePublishSecretRef` 捕获组改为可选，其余字符与组序保持不变。
- ownership：`base.env` 负责集中常量结构与 YAML 转义；本层只读取 `K8S.VOLUME.CSI` 传给 `mustRegexMatch` 与 `mustRegexReplaceAll`。

### Dependency: `base.bool`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：`lower` 后的 `true` / `false` 字符串。
- output：`true` 或 `false` 字符串；其他值中断。
- ownership：依赖负责布尔表示校验；本层负责 `lower`、空值跳过与键写入时机。

### Dependency: `definitions.csiVolumeSource`

- availability：unavailable
- source：无
- operation：consume
- input：csi 上下文 map，含 `driver` 与已提供的 `nodePublishSecretRef`、`fsType`、`readOnly`、`volumeAttributes`；`nodePublishSecretRef` 为原始字符串。
- output：csi source 的 YAML 字段片段；空或非 map 由调用方按 `{}` 处理。
- ownership：子模板负责 `CSIVolumeSource` 字段语义、`nodePublishSecretRef` 清洗与 `definitions.localObjectReference` 委托；本层只负责简写解析、键生效与 source 键包裹。

## 代码边界

### `templates/base/_env.tpl`

- access：write
- operations：改写 `K8S.VOLUME.CSI` 的 `nodePublishSecretRef` 捕获组为可选。
- writable-scopes：`K8S.VOLUME.CSI`。

### `templates/api-resources/Definitions/_Volume.tpl`

- access：write
- operations：更新 `csi` 分支的行内语法注释；捕获后按枚举归属写入 `fsType` 或 `nodePublishSecretRef`，空值跳过键写入，枚举重复赋值中断；更新格式不匹配的错误消息。
- writable-scopes：`definitions.volume` 内 `csi` 分支的 `{{- /* csi: ... */ -}}` 注释行与该 `else if eq $source "csi"` 处理块的变量声明、上下文构造及失败消息。

### `templates/base/_types.tpl`

- access：read
- operations：复核 `base.bool` 的布尔表示与失败契约。

## 验证设计

- 最小有效：在 `/tmp/sd-kube-chart/` 新建最小 application Chart，加载 `_env.tpl`、`_Volume.tpl` 及其 base 依赖，为 `definitions.csiVolumeSource` 提供回显上下文同名 fixture。渲染 `{name: "csi-vol", csi: "driver.example"}`，确认上下文中只有 `driver`、没有 `nodePublishSecretRef` 键。fixture 只证明调用方解析与键生效，不表述为真实 `CSIVolumeSource` 渲染通过。
- 较完整有效：覆盖 `driver.example regcred`、`driver.example ext4`、`driver.example EXT4 true`、`driver.example true`、`driver.example secret ext4 TRUE`、`driver.example secret ext4 TRUE attr (mode 0777, foo:bar)`、`driver.example "" xfs`、`driver.example attr (mode 0777, foo:bar)` 与大小写混合的枚举，确认键存在性、枚举小写归一化与 attributes 处理不变。
- 关键失败：覆盖多余位置段、`driver.example ext4 xfs` 重复 `fsType`、空括号组、属性段缺少 value 与整体不匹配的格式，确认全部中断且消息包含新位置段说明或重复赋值提示。
