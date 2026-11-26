# 新增 definitions.iscsiVolumeSource 设计

## 技术目标

- capability：`definitions.iscsiVolumeSource`、`base.net.hostPort`
- artifact-type：Kubernetes 共享结构 Helm 命名模板、base 公共能力
- target：`definitions.iscsiVolumeSource`（`templates/api-resources/Definitions/_ISCSIVolumeSource.tpl`）、`base.net.hostPort`（`templates/base/_validate.tpl`）

## 设计决策

### Decision: base.net.hostPort 解析与归一化

- requirements：`base.net.hostPort host:port 归一化`
- choice：在 `templates/base/_validate.tpl` 新增 `base.net.hostPort`，入参 `list [value, defaultPort, strict]`；用 `NET.IPV4`、`NET.IPV6`、`TYPES.POSITIVE_INT` 校验 host 与端口，支持方括号 IPv6、裸 IPv6、IPv4 与 `IPv4:port`；端口缺省时使用 `defaultPort`；输出 IPv4 为 `host:port`、IPv6 为 `[host]:port`；`strict=true` 非法中断，`strict=false` 非法返回空字符串。
- rationale：现有 `base.net` 仅有 `ip`、`domain`、`dns` 模式，没有 host:port 能力；Helm 模板无法直接调用 Go 标准库 `net.SplitHostPort`，因此用字符串操作与既有网络常量实现等价语义。

### Decision: K8S.VOLUME.ISCSI_PORTAL 扩展

- requirements：`definitions.iscsiVolumeSource 字段渲染`、`definitions.volume iscsi 字符串简写`
- choice：将运行时表达式改为 `^(?:\[[0-9A-Fa-f:.%]+\](?::[0-9]+)?|[0-9]{1,3}(?:\.[0-9]{1,3}){3}(?::[0-9]+)?|[0-9A-Fa-f]*[:.][0-9A-Fa-f:.%]*)$`，用于 portal 形态预过滤；纯端口号不匹配。
- rationale：覆盖 IPv4、IPv6 与可选端口；真正的 IP 与端口校验由 `base.net.hostPort` 收口，形态正则只负责快速拒绝明显非法值。

### Decision: K8S.VOLUME.ISCSI 捕获

- requirements：`definitions.volume iscsi 字符串简写`
- choice：将运行时表达式改为 `^\s*(\S+)\s+([0-9]+)\s+(\S+)(?:\s+((?i:ext4|xfs|ntfs)))?(?:\s+((?i:true|false)))?(?:\s+(\S+))?(?:\s+(\S+))?(?:\s+(?i:(chap))\s*\(\s*((?i:true|false))\s*,\s*((?i:true|false))\s*\))?(?:\s+(?i:(portals))\s*\((.*?)\))?(?:\s+(\S+))?\s*$`，捕获顺序保持 iqn、lun、targetPortal、fsType、readOnly、iscsiInterface、initiatorName、chap 关键字与两个值、portals 关键字与内容、secretRef。
- rationale：targetPortal 由可选改为必填；lun 显式限制为 ASCII 数字；fsType 与 boolean 由通用 token 收紧为大小写不敏感枚举。

### Decision: definitions.iscsiVolumeSource 字段处理

- requirements：`definitions.iscsiVolumeSource 字段渲染`
- choice：按官方顺序处理字段；`iqn`、`lun`、`targetPortal` 必填，`lun` 用 `base.int.positive` 转换后经 `base.int` 渲染以保留 `0`；`fsType` 小写后经 `base.field` 的允许值列表校验；boolean 字段小写后交 `base.bool`；`portals` 经 `base.get` 的 `toStrings` 与 `base.slice.cleanup` 清洗，再逐项用 `K8S.VOLUME.ISCSI_PORTAL` 与 `base.net.hostPort` 非严格模式归一化并丢弃空结果；`secretRef` 区分 string 与 map，清洗为 `dict "name"` 后委托 `definitions.localObjectReference`；`targetPortal` 经 `K8S.VOLUME.ISCSI_PORTAL` 与 `base.net.hostPort` 严格模式归一化。
- rationale：字段顺序与类型来自 Kubernetes v1 core `ISCSIVolumeSource`；单一模板承担全部归一化，父模板只传递捕获值。

### Decision: 父模板 iscsi 简写委托

- requirements：`definitions.volume iscsi 字符串简写`
- choice：`_Volume.tpl` 的 `iscsi` 分支只执行正则捕获和空值判断，将原始捕获值写入上下文；移除本地 targetPortal、fsType、boolean、portals、lun 校验与转换，由 `definitions.iscsiVolumeSource` 统一归一化。
- rationale：避免父模板与子模板重复实现同一校验；非法 portal 的丢弃策略只能由拥有该字段语义的子模板执行。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`update`
- input：`include "base.env" ""` 后经 `fromYaml` 恢复常量 map；读取 `K8S.VOLUME.ISCSI`、`K8S.VOLUME.ISCSI_PORTAL`、`SPLIT.COMMA`。
- output：YAML map 字符串；两个 ISCSI 正则更新为上述运行时表达式。
- ownership：`base.env` 维护常量；`_Volume.tpl` 负责简写捕获；`definitions.iscsiVolumeSource` 负责字段归一化与 portal 过滤。

### Dependency: `base.net.hostPort`

- availability：`unavailable`
- source：无
- operation：`add`
- input：`list [value, defaultPort, strict]`；value 为 host 或 host:port 字符串，defaultPort 为数字字符串或空，strict 为 bool。
- output：归一化后的 `host:port` 字符串；IPv6 输出带方括号；strict 模式非法中断，非 strict 模式返回空字符串。
- ownership：本 change 在 `templates/base/_validate.tpl` 新增；`definitions.iscsiVolumeSource` 只消费结果并决定丢弃或中断。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文> "<字段>" [toStrings]`。
- output：YAML 字符串；缺失为空输出。
- ownership：`base.get` 负责取值、别名与序列化。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 的原始输出。
- output：解码后的 string；非 string 标量中断。
- ownership：本模板只消费解码结果并执行 trim 与字段规则。

### Dependency: `base.bool`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：bool 或 `true`/`false` 字符串。
- output：`true` 或 `false` 字符串；其他值中断。
- ownership：本模板负责先 lower 再委托，保证输出小写。

### Dependency: `base.int.positive`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：非负 int/int64/float64 或正整数字符串。
- output：int；负数或非整数中断。
- ownership：本模板先判空，再转换并渲染。

### Dependency: `base.int`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：int/int64/float64 或整数字符串。
- output：十进制字符串，显式 `0` 输出 `0`。
- ownership：由 `base.field` 调用，用于 `lun` 渲染。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list <key> <value> <renderer> [allows]`。
- output：YAML 键值片段；空值不输出；枚举不匹配中断并给出允许值。
- ownership：`base.field` 负责渲染与枚举校验；本模板负责字段生效判断和顺序。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：slice。
- output：YAML 列表；空 slice 为 `[]`。
- ownership：本模板只在过滤后的 `portals` 非空时调用。

### Dependency: `base.slice.cleanup`

- availability：`existing`
- source：`templates/base/_collection.tpl`
- operation：`consume`
- input：`list <portals, SPLIT.COMMA>`。
- output：拆分、trim、去重、去空后的 YAML 列表；`c` 参数未使用，避免非法元素中断。
- ownership：只负责集合清洗；portal 合法性由 `base.net.hostPort` 判定。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 返回值。
- output：布尔字符串。
- ownership：`definitions.iscsiVolumeSource` 在 `portals` 解析后排除错误。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值。
- output：布尔字符串。
- ownership：`definitions.iscsiVolumeSource` 在 `secretRef` 子模板输出后排除错误。

### Dependency: `definitions.localObjectReference`

- availability：`existing`
- source：`templates/api-resources/Definitions/_LocalObjectReference.tpl`
- operation：`consume`
- input：含 `name` 的 map。
- output：`name` 字段片段；name 为空时为空内容；非法 name 中断。
- ownership：子模板负责 name 校验与渲染；本 change 不创建、不修改。

### Dependency: `definitions.iscsiVolumeSource`

- availability：`unavailable`
- source：无
- operation：`add`
- input：含 `iqn`、`lun`、`targetPortal` 与可选字段的 map。
- output：按官方顺序的 `ISCSIVolumeSource` 字段片段；非法输入中断。
- ownership：本 change 在 `templates/api-resources/Definitions/_ISCSIVolumeSource.tpl` 新增；`_Volume.tpl` 只传递捕获值。

## 代码边界

### `templates/base/_env.tpl`

- access：`write`
- operations：`update K8S.VOLUME.ISCSI、K8S.VOLUME.ISCSI_PORTAL`
- writable-scopes：两个键值行

### `templates/base/_validate.tpl`

- access：`write`
- operations：`add base.net.hostPort`
- writable-scopes：新增 `base.net.hostPort` 合约注释与 define 块

### `templates/api-resources/Definitions/_ISCSIVolumeSource.tpl`

- access：`write`
- operations：`add definitions.iscsiVolumeSource`
- writable-scopes：新增文件的合约注释与 define 块

### `templates/api-resources/Definitions/_Volume.tpl`

- access：`write`
- operations：`update iscsi string 简写分支`
- writable-scopes：`iscsi` 分支（从 `iscsi: <iqn> ...` 注释行至 `nfs` 分支之前）

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume base.get`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume base.string.normalize、base.isFromYamlError、base.isFromYamlArrayError`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume base.bool、base.int.positive、base.int、base.slice`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume base.field`

### `templates/base/_collection.tpl`

- access：`read`
- operations：`consume base.slice.cleanup`

### `templates/api-resources/Definitions/_LocalObjectReference.tpl`

- access：`read`
- operations：`consume definitions.localObjectReference`

## 验证设计

- 在 `/tmp/sd-kube-chart/` 新建最小 application Chart，加载真实 `_env.tpl`、`_get.tpl`、`_convert.tpl`、`_field.tpl`、`_types.tpl`、`_collection.tpl`、`_validate.tpl`、`_k8s.tpl`、`_LocalObjectReference.tpl`、`_ISCSIVolumeSource.tpl` 与 `_Volume.tpl`，执行 `/opt/homebrew/bin/helm template`；不提供同名 fixture。
- `base.net.hostPort`：IPv4 省略/显式端口、IPv6 省略/方括号显式端口、纯端口号与非法 IP 的严格/非严格模式。
- `definitions.iscsiVolumeSource`：最小必填含 `lun: 0`、全字段官方顺序、`fsType` 大小写、boolean 大小写、`portals` 合法与非法混排、`secretRef` string/map、缺失必填与非法 `targetPortal`。
- `definitions.volume` 简写：最小简写、缺少 targetPortal、`fsType` 与 boolean 大小写、`portals` 丢弃非法元素、`secretRef` 字符串、非法 targetPortal。
