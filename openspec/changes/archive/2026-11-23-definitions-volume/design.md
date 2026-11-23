# definitions.volume 设计

## 技术目标

- capability：`definitions.volume`
- artifact-type：Helm library Chart 命名模板
- target：`definitions.volume`

## 设计决策

### Decision: 输入形状与唯一 source 分派

- requirements：`Volume 输入与渲染契约`
- choice：入参固定为 `{name, <source>}`；`name` 经 `base.get`、`base.string.normalize`、trim 与 `lower` 后交 `base.rfc` 的 `1123` 模式，缺失或非法中断；再遍历除 `name` 外的键，要求恰好一个且命中 13 个受支持 source 之一。source 值为 map 时只读透传；为 string 时进入该 source 的解析分支；为 nil 时替换为 `dict`；其他类型中断。
- rationale：示例已锁定入参形状；唯一 source 分派使互斥校验和渲染顺序可在同一模板内完成。

### Decision: 模板命名与重命名边界

- requirements：`Volume 输入与渲染契约`
- choice：公开命名模板使用 `definitions.volume`；不定义 `definitions.Volume` 别名。同步更新 `_PodSpec.tpl` 的调用与注释、`_Volume.tpl` 的契约注释及错误消息前缀、验证 fixture；模板文件保持 `_Volume.tpl`。
- rationale：与仓库既有 `definitions.*` lower camel case 命名一致；该能力尚未进入稳定 specs 或用户文档，按发布前重命名处理，不引入旧名兼容层。

### Decision: 子模板占位与空输出兜底

- requirements：`Volume 输入与渲染契约`
- choice：按 source 映射直接 `include` 13 个 `definitions.*VolumeSource`；子模板不在本 change 创建。子模板输出以 `body:` 包裹并 `indent 2` 后 `fromYaml`，以便区分合法非 map 与非法 YAML；解析错误时中断，`body` 为空、nil 或非 map 时以 `dict` 交给 `base.field`，最终输出 `source: {}`。
- rationale：项目规则允许引用 design 标记为 unavailable 的子模板；`body:` 包裹使合法 list/scalar 与非法 YAML 可区分，从而按规格把非 map 输出归一为 `{}`；空对象 source（`emptyDir`、`ephemeral`、`projected`）必须在 Volume 中保留 source 键。

### Decision: 字段渲染顺序

- requirements：`Volume 输入与渲染契约`
- choice：按 `configMap`、`csi`、`downwardAPI`、`emptyDir`、`ephemeral`、`fc`、`hostPath`、`image`、`iscsi`、`name`、`nfs`、`persistentVolumeClaim`、`projected`、`secret` 迭代；只输出匹配的 source 键与 `name`，其余键跳过。
- rationale：该顺序与本地 v1.36 API 参考的 Volume 字段表一致，`name` 位于 `iscsi` 与 `nfs` 之间。

### Decision: 字符串解析归属与常量

- requirements：`Volume 字符串通用规则`、`configMap 与 secret 卷字符串`、`csi 卷字符串`、`downwardAPI 卷字符串`、`emptyDir 卷字符串`、`fc 卷字符串`、`hostPath、image、nfs 与 persistentVolumeClaim 卷字符串`、`iscsi 卷字符串`、`core.podSpec volumes 归一化`
- choice：`core.podSpec` 只使用 `K8S.VOLUME.SHORT` 拆出类型、名称与余下原文；所有 source 级字符串由 `definitions.volume` 解析。以下为正则运行时表达式；写入 `_env.tpl` 双引号 YAML 时按现有 `\\s` 形式转义：
  - `SHORT`：`^((?i:cm|configMap|secret|pvc|persistentVolumeClaim|emptyDir|hostPath|nfs|image|fc|iscsi|csi|api|downwardAPI))(?:\s+([^\s]+))(?:\s+(.*))?$`
  - `UNSUPPORTED_SHORT`：`^(?i:ephemeral|projected)(?:\s|$)`
  - `KEY_TO_PATH_SOURCE`：`^\s*([^\s,]+)(?:\s+((?i:true|false)))?(?:\s+(\d+))?(?:\s+(?i:(items))\s*\((.*)\))?\s*$`；捕获源名称、optional、defaultMode、items 关键字、items 内容
  - `KEY_TO_PATH_ITEM`：`^\s*([^\s,]+)\s+([^\s,]+)(?:\s+([^\s,]+))?\s*$`；捕获 key、path、mode
  - `CSI`：`^\s*([^\s,]+)\s+(\S+)(?:\s+((?i:ext4|xfs|ntfs)))?(?:\s+((?i:true|false)))?(?:\s+(?i:(attr|volumeAttributes))\s*\((.*)\))?\s*$`；捕获 driver、nodePublishSecretRef、fsType、readOnly、属性关键字、属性内容
  - `CSI_ATTRIBUTE`：`^\s*([^:\s]+)\s*[: ]+\s*(.*?)\s*$`；捕获 key、value
  - `DOWNWARD_API`：`^\s*(?:(\d+)(?:\s+(?i:(items))\s*\((.*)\))?|(?i:(items))\s*\((.*)\))?\s*$`；捕获 defaultMode、带 defaultMode 的 items 关键字与内容、items-only 关键字与内容
  - `DOWNWARD_API_FIELD_ITEM`：`^\s*([^\s,]+)\s+(?i:field)\s+(\S+)(?:\s+([^\s,]+))?\s*$`；捕获 path、fieldPath、mode
  - `DOWNWARD_API_RESOURCE_ITEM`：`^\s*([^\s,]+)\s+(?i:resource)\s+(\S+)(?:\s+(\S+))?(?:\s+(\S+))?(?:\s+(\S+))?\s*$`；捕获 path、resource、containerName、divisor、mode
  - `EMPTY_DIR`：`^\s*(?:(?i:(memory))(?:\s+|$))?(\S+)?\s*$`；捕获 medium、sizeLimit
  - `FC`：`^\s*(?:(\d+)\s+)?((?i:ext4|xfs|ntfs))(?:\s+((?i:true|false)))?(?:\s+(?i:(targetWWNs))\s*\((.*?)\))?(?:\s+(?i:(wwids))\s*\((.*?)\))?\s*$`；捕获 lun、fsType、readOnly、targetWWNs 关键字与内容、wwids 关键字与内容
  - `HOST_PATH`：`^\s*(/\S*)(?:\s+(""|[^\s]+))?\s*$`；捕获 path、type
  - `IMAGE`：`^\s*(\S+)(?:\s+((?i:always|ifnotpresent|never)))?\s*$`；捕获 reference、pullPolicy
  - `ISCSI`：`^\s*(\S+)\s+(\d+)(?:\s+(\S+))?(?:\s+(\S+))?(?:\s+(\S+))?(?:\s+(\S+))?(?:\s+(\S+))?(?:\s+(?i:(chap))\s*\(\s*([^(),]+)\s*,\s*([^(),]+)\s*\))?(?:\s+(?i:(portals))\s*\((.*?)\))?(?:\s+(\S+))?\s*$`；捕获 iqn、lun、targetPortal、fsType、readOnly、iscsiInterface、initiatorName、chap 关键字与两个值、portals 关键字与内容、secretRef.name
  - `ISCSI_PORTAL`：`^(?:\d{1,3}(?:\.\d{1,3}){3}|\d+)(?::\d+)?$`
  - `NFS`：`^\s*(\S+)\s+(/\S*)(?:\s+((?i:true|false)))?\s*$`；捕获 server、path、readOnly
  - `PERSISTENT_VOLUME_CLAIM`：`^\s*(\S+)(?:\s+((?i:true|false)))?\s*$`；捕获 claimName、readOnly
- rationale：父模板只拥有短写拆分；source 级语法由 `definitions.volume` 解析，孙模板结构由子模板/孙模板解析。固定正则集中在 `base.env`，避免业务模板内联表达式。

### Decision: 位置可选段空字符串占位

- requirements：`Volume 字符串通用规则`、`csi 卷字符串`、`downwardAPI 卷字符串`、`iscsi 卷字符串`
- choice：`csi` 的 `nodePublishSecretRef` 位置必须存在；为空时使用 `""` 或 `''` 占位，原始字符串直接交给子模板，由子模板/孙模板解码。`iscsi` 的 `targetPortal`、`fsType`、`readOnly`、`iscsiInterface`、`initiatorName` 按固定顺序捕获；跳过任一位置时使用 `""` 或 `''` 占位，这些直接子模板字段由本层经 `base.string.normalize` 解码。`iscsi.secretRef` 的占位值作为原始字符串交给子模板/孙模板解码。`downwardAPI` resource item 的 `containerName`、`divisor` 保留在原始 item 字符串中，由子模板/孙模板解码。
- rationale：Go RE2 不支持 lookahead，类型不同的相邻可选段无法仅靠模式区分；固定位置加空字符串占位使解析结果唯一，并延续仓库既有 `""` / `''` 占位模式。孙模板字段原样下传，避免本层提前构造下游 map。

### Decision: 括号组与数组空值

- requirements：`configMap 与 secret 卷字符串`、`csi 卷字符串`、`downwardAPI 卷字符串`、`fc 卷字符串`、`iscsi 卷字符串`
- choice：所有括号组在关键字命中后要求内容 trim 后非空；数组内容按 `SPLIT.COMMA` 拆分、逐项 trim 并剔除空段，最终数组为空时中断。`targetWWNs`、`wwids`、`portals`、`items`、`volumeAttributes` 均使用该规则。
- rationale：规格要求每类括号内至少一个元素；统一的空内容校验避免各 source 分支重复实现。

### Decision: 枚举与布尔归一化

- requirements：`Volume 字符串通用规则`、`configMap 与 secret 卷字符串`、`csi 卷字符串`、`emptyDir 卷字符串`、`fc 卷字符串`、`hostPath、image、nfs 与 persistentVolumeClaim 卷字符串`、`iscsi 卷字符串`
- choice：枚举过滤不区分大小写，渲染统一为官方拼写。`medium` 使用 `dict "memory" "Memory"`；`pullPolicy` 使用 `always` / `ifnotpresent` / `never` 到官方拼写的映射；`hostPath.type` 使用官方八值映射，空字符串映射为空；显式 `""` 通过原始捕获非空区分于省略，省略时不输出该字段，显式时输出 `type: ""`；`fsType` 统一 `lower`；`optional`、`readOnly`、`chapAuthDiscovery`、`chapAuthSession` 统一 `lower` 后交 `base.bool`；`lun` 交 `base.int.positive`；`sizeLimit` 交 `base.quantity`；`nfs.server` 交 `base.net` 的 `dns` 模式；`targetPortal` 与 `portals` 元素交 `ISCSI_PORTAL`。
- rationale：符合“过滤不区分大小写、渲染区分大小写”的已确认规则；映射只在 `definitions.volume` 内维护，避免扩散到子模板未实现的当前阶段。

### Decision: 不过度清洗与下游校验

- requirements：`Volume 输入与渲染契约`、`configMap 与 secret 卷字符串`、`csi 卷字符串`、`downwardAPI 卷字符串`、`fc 卷字符串`、`iscsi 卷字符串`
- choice：本层只构造直接子模板的顶层 map；`configMap` / `secret` 的 `items` 以原始 item 字符串列表下传，`downwardAPI` 的 `items` 以原始 item 字符串列表下传，`csi.nodePublishSecretRef` 与 `iscsi.secretRef` 以原始字符串下传；`items` 元素、`fieldRef` / `resourceFieldRef`、`nodePublishSecretRef` / `secretRef` 等孙模板 map 不在本层构造。`defaultMode`、item `mode`、`fieldPath`、`<resource>`、`containerName`、`divisor`、`csi` 属性值、`fc` WWN 列表、`iscsi` portal 列表均按捕获原文下传；本层只做顶层结构拆分、显式关键字归属、item 形态校验及直接子模板字段的枚举/布尔/数量/路径/portal 校验，不把 mode 转为十进制，不校验 `fieldPath` / `<resource>` 的官方取值集。
- rationale：这些值由子模板或更下游模板消费；`definitions.objectFieldSelector` 与 `definitions.resourceFieldSelector` 已具备最终校验能力，本层重复构造或校验会破坏“不过度清洗”边界。

### Decision: core.podSpec volumes 归一化

- requirements：`core.podSpec volumes 归一化`
- choice：`volumes` 仍只接受 array；移除 `SPLIT.SPACE_COMMA` 归一化，改为 `trim` 后直接匹配 `K8S.VOLUME.SHORT`。`volumeTypes` 新增 `csi`、`downwardapi`、`api`。原生 map 分支在 `name` 外取唯一键并组装 `{name, <canonicalSource>: <value>}`；string 分支用 `SHORT` 捕获类型、名称与余下原文并组装同一形状，余下原文为空时写入空字符串。`ephemeral` / `projected` 的 string array 元素先用 `UNSUPPORTED_SHORT` 中断；原生 map 中对应键为 string 时同样中断。
- rationale：局部空白收敛保持共享 `SPLIT.SPACE_COMMA` 与其他模板行为不变；统一形状让 `definitions.volume` 只处理一种入参。

### Decision: 子模板 unavailable 与验证 fixture

- requirements：`Volume 输入与渲染契约`
- choice：13 个 `definitions.*VolumeSource` 在 design 中标记为 `unavailable`，本 change 不创建。验证在 `/tmp/sd-kube-chart/` 最小 application Chart 中提供同名 fixture；fixture 只证明 `definitions.volume` 的调用、空输出兜底和错误保护，不作为真实子模板集成通过的证据。
- rationale：项目规则允许引用 unavailable 子模板并使用同名最小 fixture；真实子模板由后续 change 落地。

## 依赖契约

### Dependency: `base.env`

- availability：existing
- source：`templates/base/_env.tpl`
- operation：update
- input：`""`；经 `fromYaml` 恢复常量 map。
- output：常量 map；`K8S.VOLUME.SHORT` 更新为短写正则，并新增 `UNSUPPORTED_SHORT`、`KEY_TO_PATH_SOURCE`、`KEY_TO_PATH_ITEM`、`CSI`、`CSI_ATTRIBUTE`、`DOWNWARD_API`、`DOWNWARD_API_FIELD_ITEM`、`DOWNWARD_API_RESOURCE_ITEM`、`EMPTY_DIR`、`FC`、`HOST_PATH`、`IMAGE`、`ISCSI`、`ISCSI_PORTAL`、`NFS`、`PERSISTENT_VOLUME_CLAIM`。
- ownership：`base.env` 负责集中常量的结构与转义；本层只读取目标键并传给 `mustRegexMatch` / `mustRegexReplaceAll` / `mustRegexSplit`，不重复构造正则。

### Dependency: `base.get`

- availability：existing
- source：`templates/base/_get.tpl`
- operation：consume
- input：`list <上下文> <点分路径>`；不启用额外强制类型、合并模式或必填参数。
- output：YAML 字符串；路径缺失时为空输出。
- ownership：依赖负责数据源优先级、别名与序列化；本层负责字段存在性与业务校验。

### Dependency: `base.string.normalize`

- availability：existing
- source：`templates/base/_convert.tpl`
- operation：consume
- input：`base.get` 返回的 YAML 标量文本。
- output：解码后的 string；空输入返回空字符串；非 string 标量或非法 YAML 标量中断。
- ownership：依赖负责标量解码与类型门禁；本层负责 trim、空值语义与字段校验。

### Dependency: `base.bool`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：原生 bool 或字面量字符串 `true` / `false`。
- output：`true` 或 `false` 字符串；其他值中断。
- ownership：依赖负责布尔表示校验；本层负责先 `lower` 并决定字段是否输出。

### Dependency: `base.field`

- availability：existing
- source：`templates/base/_field.tpl`
- operation：consume
- input：`list <key> <value> <渲染模板> [允许值列表]`。
- output：单字段 YAML 片段；空值不输出；枚举不匹配时中断。
- ownership：依赖负责单字段引号、枚举校验与输出格式；本层负责字段顺序与生效判断。

### Dependency: `base.rfc`

- availability：existing
- source：`templates/base/_k8s.tpl`
- operation：consume
- input：`list <小写化 name> "1123"`。
- output：校验通过的字符串；不符合 RFC1123 Label 或超过 63 字符时中断。
- ownership：依赖负责 Volume 名称格式校验；本层负责必填、空值判断与小写规范化。

### Dependency: `base.quantity`

- availability：existing
- source：`templates/base/_k8s.tpl`
- operation：consume
- input：string 形式的 sizeLimit。
- output：校验通过的 Quantity 字符串；非法时中断。
- ownership：依赖负责 Quantity 形态校验；本层负责 emptyDir 字段生效判断。

### Dependency: `base.int.positive`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：捕获的 lun 字符串。
- output：非负 int；非法或负数时中断。
- ownership：依赖负责非负整数校验与转换；本层负责 fc/iscsi 字段生效判断。

### Dependency: `base.net`

- availability：existing
- source：`templates/base/_validate.tpl`
- operation：consume
- input：`list <server> "dns"`。
- output：校验通过的原始字符串；非法时中断。
- ownership：依赖负责 IPv4、IPv6 或域名校验；本层负责 nfs 字段映射。

### Dependency: `base.isFromYamlError`

- availability：existing
- source：`templates/base/_convert.tpl`
- operation：consume
- input：子模板输出经 `body:` 包裹并 `indent 2` 后再 `fromYaml` 恢复的结果。
- output：布尔字符串。
- ownership：依赖负责识别 Helm 的 YAML 错误形态；本层负责失败与 `{}` 兜底分支。

### Dependency: `base.isFromYamlArrayError`

- availability：existing
- source：`templates/base/_convert.tpl`
- operation：consume
- input：`fromYamlArray` 对 `volumes` 原文的恢复结果。
- output：布尔字符串。
- ownership：依赖负责识别 Helm 的 YAML array 错误形态；本层负责 `volumes` 数组失败分支。

### Dependency: `base.map`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：map。
- output：YAML 字符串；空 map 渲染为 `{}`。
- ownership：依赖负责 map 序列化；本层负责 source 值恢复与输出。

### Dependency: `definitions.configMapVolumeSource`

- availability：unavailable
- source：无
- operation：consume
- input：configMap source 上下文 map，含 `name`、`optional`、`defaultMode`、`items` 中已提供的字段；`items` 为原始 item 字符串列表（`<key> <path> [mode]`），由子模板/孙模板解析为 `KeyToPath`。
- output：configMap source 的 YAML 字段片段；空或非 map 由调用方按 `{}` 处理。
- ownership：子模板负责 configMap source 字段语义与渲染；本 change 只负责上下文归一化和 source 键包裹。

### Dependency: `definitions.csiVolumeSource`

- availability：unavailable
- source：无
- operation：consume
- input：csi source 上下文 map，含 `driver`、`nodePublishSecretRef`、`fsType`、`readOnly`、`volumeAttributes` 中已提供的字段；`nodePublishSecretRef` 为原始字符串，由子模板/孙模板解析为 `LocalObjectReference`；`volumeAttributes` 为直接子模板 map。
- output：csi source 的 YAML 字段片段；空或非 map 由调用方按 `{}` 处理。
- ownership：子模板负责 csi source 字段语义与渲染；本 change 只负责上下文归一化和 source 键包裹。

### Dependency: `definitions.downwardAPIVolumeSource`

- availability：unavailable
- source：无
- operation：consume
- input：downwardAPI source 上下文 map，含 `defaultMode`、`items` 中已提供的字段；`items` 为原始 item 字符串列表（`<path> field <fieldPath> [mode]` 或 `<path> resource <resource> [containerName] [divisor] [mode]`），由子模板解析为 `DownwardAPIVolumeFile` 并委托 objectFieldSelector / resourceFieldSelector。
- output：downwardAPI source 的 YAML 字段片段；空或非 map 由调用方按 `{}` 处理。
- ownership：子模板负责 downwardAPI source 字段语义与渲染，并继续委托 objectFieldSelector / resourceFieldSelector；本 change 只负责上下文归一化和 source 键包裹。

### Dependency: `definitions.emptyDirVolumeSource`

- availability：unavailable
- source：无
- operation：consume
- input：emptyDir source 上下文 map，含 `medium`、`sizeLimit` 中已提供的字段；无字段时为空 map。
- output：emptyDir source 的 YAML 字段片段；空或非 map 由调用方按 `{}` 处理。
- ownership：子模板负责 emptyDir source 字段语义与渲染；本 change 只负责上下文归一化和 source 键包裹。

### Dependency: `definitions.ephemeralVolumeSource`

- availability：unavailable
- source：无
- operation：consume
- input：ephemeral source 原始 map；string 输入在 `definitions.volume` 入口中断。
- output：ephemeral source 的 YAML 字段片段；空或非 map 由调用方按 `{}` 处理。
- ownership：子模板负责 ephemeral source 字段语义与渲染；本 change 只负责 map 透传和 source 键包裹。

### Dependency: `definitions.fcVolumeSource`

- availability：unavailable
- source：无
- operation：consume
- input：fc source 上下文 map，含 `lun`、`fsType`、`readOnly`、`targetWWNs`、`wwids` 中已提供的字段。
- output：fc source 的 YAML 字段片段；空或非 map 由调用方按 `{}` 处理。
- ownership：子模板负责 fc source 字段语义与渲染；本 change 只负责上下文归一化和 source 键包裹。

### Dependency: `definitions.hostPathVolumeSource`

- availability：unavailable
- source：无
- operation：consume
- input：hostPath source 上下文 map，含 `path`、`type` 中已提供的字段。
- output：hostPath source 的 YAML 字段片段；空或非 map 由调用方按 `{}` 处理。
- ownership：子模板负责 hostPath source 字段语义与渲染；本 change 只负责上下文归一化和 source 键包裹。

### Dependency: `definitions.imageVolumeSource`

- availability：unavailable
- source：无
- operation：consume
- input：image source 上下文 map，含 `reference`、`pullPolicy` 中已提供的字段。
- output：image source 的 YAML 字段片段；空或非 map 由调用方按 `{}` 处理。
- ownership：子模板负责 image source 字段语义与渲染；本 change 只负责上下文归一化和 source 键包裹。

### Dependency: `definitions.iscsiVolumeSource`

- availability：unavailable
- source：无
- operation：consume
- input：iscsi source 上下文 map，含 `iqn`、`lun`、`targetPortal`、`fsType`、`readOnly`、`iscsiInterface`、`initiatorName`、`chapAuthDiscovery`、`chapAuthSession`、`portals`、`secretRef` 中已提供的字段；`secretRef` 为原始字符串，由子模板/孙模板解析为 `LocalObjectReference`。
- output：iscsi source 的 YAML 字段片段；空或非 map 由调用方按 `{}` 处理。
- ownership：子模板负责 iscsi source 字段语义与渲染；本 change 只负责上下文归一化和 source 键包裹。

### Dependency: `definitions.nfsVolumeSource`

- availability：unavailable
- source：无
- operation：consume
- input：nfs source 上下文 map，含 `server`、`path`、`readOnly` 中已提供的字段。
- output：nfs source 的 YAML 字段片段；空或非 map 由调用方按 `{}` 处理。
- ownership：子模板负责 nfs source 字段语义与渲染；本 change 只负责上下文归一化和 source 键包裹。

### Dependency: `definitions.persistentVolumeClaimVolumeSource`

- availability：unavailable
- source：无
- operation：consume
- input：persistentVolumeClaim source 上下文 map，含 `claimName`、`readOnly` 中已提供的字段。
- output：persistentVolumeClaim source 的 YAML 字段片段；空或非 map 由调用方按 `{}` 处理。
- ownership：子模板负责 persistentVolumeClaim source 字段语义与渲染；本 change 只负责上下文归一化和 source 键包裹。

### Dependency: `definitions.projectedVolumeSource`

- availability：unavailable
- source：无
- operation：consume
- input：projected source 原始 map；string 输入在 `definitions.volume` 入口中断。
- output：projected source 的 YAML 字段片段；空或非 map 由调用方按 `{}` 处理。
- ownership：子模板负责 projected source 字段语义与渲染；本 change 只负责 map 透传和 source 键包裹。

### Dependency: `definitions.secretVolumeSource`

- availability：unavailable
- source：无
- operation：consume
- input：secret source 上下文 map，含 `secretName`、`optional`、`defaultMode`、`items` 中已提供的字段；`items` 为原始 item 字符串列表（`<key> <path> [mode]`），由子模板/孙模板解析为 `KeyToPath`。
- output：secret source 的 YAML 字段片段；空或非 map 由调用方按 `{}` 处理。
- ownership：子模板负责 secret source 字段语义与渲染；本 change 只负责上下文归一化和 source 键包裹。

## 代码边界

### `templates/base/_env.tpl`

- access：write
- operations：更新 `K8S.VOLUME.SHORT`；新增 `K8S.VOLUME` 下的 `UNSUPPORTED_SHORT`、`KEY_TO_PATH_SOURCE`、`KEY_TO_PATH_ITEM`、`CSI`、`CSI_ATTRIBUTE`、`DOWNWARD_API`、`DOWNWARD_API_FIELD_ITEM`、`DOWNWARD_API_RESOURCE_ITEM`、`EMPTY_DIR`、`FC`、`HOST_PATH`、`IMAGE`、`ISCSI`、`ISCSI_PORTAL`、`NFS`、`PERSISTENT_VOLUME_CLAIM`。
- writable-scopes：`K8S.VOLUME` 子树。

### `templates/api-resources/Definitions/_Volume.tpl`

- access：write
- operations：新增文件、`definitions.volume` 命名模板及整体契约注释；实现入参分派、source 字符串解析、枚举归一化、子模板 include、`{}` 兜底与字段顺序渲染。
- writable-scopes：整个新文件。

### `templates/api-resources/Core/_PodSpec.tpl`

- access：write
- operations：更新 `volumes` 字段注释与处理块：移除 `SPLIT.SPACE_COMMA` 归一化，扩展 `volumeTypes`，将原生 map 与 string 统一归一化为 `{name, <source>: <value>}`，增加 `ephemeral` / `projected` string 拒绝，保留 `definitions.volume` 调用与数组输出。
- writable-scopes：`volumes（Volume array, 可选）` 注释与对应的 `if $_volumesRaw` 至 `end` 处理块。

### `templates/base/_get.tpl`

- access：read
- operations：复核 `base.get` 调用契约。

### `templates/base/_convert.tpl`

- access：read
- operations：复核 `base.string.normalize` 与 `base.isFromYamlError` 调用契约。

### `templates/base/_types.tpl`

- access：read
- operations：复核 `base.bool`、`base.map` 与 `base.int.positive` 调用契约。

### `templates/base/_field.tpl`

- access：read
- operations：复核 `base.field` 调用契约。

### `templates/base/_k8s.tpl`

- access：read
- operations：复核 `base.rfc` 与 `base.quantity` 调用契约。

### `templates/base/_validate.tpl`

- access：read
- operations：复核 `base.net` 的 `dns` 模式契约。

### `templates/api-resources/Definitions/_ObjectFieldSelector.tpl`

- access：read
- operations：复核 downwardAPI `fieldRef` 的最终校验与字段映射边界。

### `templates/api-resources/Definitions/_ResourceFieldSelector.tpl`

- access：read
- operations：复核 downwardAPI `resourceFieldRef` 的最终校验与字段映射边界。

### `templates/api-resources/Definitions/_VolumeMount.tpl`

- access：read
- operations：参考同层字符串简写、占位、枚举与字段渲染结构。

### `templates/api-resources/Definitions/_VolumeDevice.tpl`

- access：read
- operations：参考同层必填判断与字段渲染结构。

## 验证设计

- 最小有效：在 `/tmp/sd-kube-chart/` 新建最小 application Chart，加载 `_env.tpl`、`_Volume.tpl`、`_PodSpec.tpl` 及其 base 依赖；为 13 个 unavailable 子模板提供同名 fixture。渲染 `definitions.volume` 的 map 输入（`{name, emptyDir: {}}`）与 `core.podSpec` 的单 string 输入，确认 `name` 与 source 键顺序、`{}` 输出和 fixture 调用。fixture 只证明调用方行为。
- 较完整有效：覆盖 11 类可解析 source 的 string 输入，包括 configMap/secret 的 optional/defaultMode/items、csi 的空 secretRef/枚举/属性、downwardAPI 两种 item 与末尾 mode、emptyDir 的 medium/sizeLimit、fc 的两组 WWN 与 lun、hostPath 的显式空 type、image 的 pullPolicy、iscsi 的空占位/chap/portals、nfs 与 pvc 的 readOnly；同时覆盖枚举大小写归一化、八进制与十进制 mode 原样下传、map/string 混合 `volumes`，并确认 `ephemeral` / `projected` string 中断。
- 关键失败：覆盖 name 缺失/非法、source 数量为零或多、名单外 source、`ephemeral` / `projected` 的 string array 元素与原生 map string 值、非法枚举/布尔/lun/sizeLimit/绝对路径/portal、items 或属性括号为空、字符串格式不匹配、子模板非法 YAML。
- 空输出与占位：fixture 分别返回空内容、合法非 map（如 list）与非法 YAML，确认前两者输出 `source: {}`、非法 YAML 中断。
- 真实依赖边界：13 个子模板在 design 中标记为 unavailable，当前验证不得表述为真实子模板集成通过；真实子模板落地后由后续 change 的验证补充。
