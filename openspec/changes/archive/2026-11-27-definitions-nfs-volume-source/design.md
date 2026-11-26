# NFS 卷源定义设计

## 技术目标

- capability：`definitions.nfsVolumeSource`
- artifact-type：`Helm 命名模板`
- target：`templates/api-resources/Definitions/_NFSVolumeSource.tpl`

## 设计决策

### Decision: 字段与渲染顺序

- requirements：`NFSVolumeSource 字段渲染`
- choice：按 `path`、`readOnly`、`server` 顺序逐字段完成取值、校验与 `base.field` 渲染；`readOnly` 为空时跳过。
- rationale：本地 v1.36 API 参考的 `NFSVolumeSource` 字段表按该顺序排列，同级卷源模板沿用官方顺序。

### Decision: path 校验

- requirements：`NFSVolumeSource 字段渲染`、`NFSVolumeSource 输入校验`
- choice：`base.get` 取值后经 `base.string.normalize` 与 `trim` 判空，再委托 `base.path` 的 `abs` 模式归一化，并以 `quote` 渲染。
- rationale：与 `definitions.hostPathVolumeSource` 的绝对路径处理一致，复用 `base.path` 的归一化与绝对路径失败边界。

### Decision: server 校验

- requirements：`NFSVolumeSource 输入校验`
- choice：`base.get` 取值后经 `base.string.normalize` 与 `trim` 判空，再委托 `base.net` 的 `dns` 模式校验，并以 `quote` 渲染。
- rationale：`base.net` 的 `dns` 模式覆盖严格 IPv4、IPv6 与 hostname，且父模板 nfs 简写使用同一模式。

### Decision: readOnly 类型处理

- requirements：`NFSVolumeSource 字段渲染`、`NFSVolumeSource 输入校验`
- choice：`base.get` 取值后用 `SYS.YAML_QUOTED` 剥离 YAML 引号并 `trim`；非空时经 `base.bool` 小写校验，再由 `base.field` 的 `base.bool` 渲染。
- rationale：与 `definitions.iscsiVolumeSource` 的 boolean 字段处理一致，兼容原生 boolean 与布尔字符串，并保留显式 `false`。

### Decision: 父模板保持只读

- requirements：`NFSVolumeSource 字段渲染`
- choice：不修改 `definitions.volume` 的分派逻辑与 `K8S.VOLUME.NFS` 正则。
- rationale：父模板已按 `definitions.<source>VolumeSource` 分派，并已用 `<server> <path> [readOnly]` 正则捕获清洗后的 map，与 draft 约束一致。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [map, 点分路径]`
- output：可解析的 YAML 字符串；路径缺失时为空输出
- ownership：`base.get` 负责多数据源取值与标量序列化；本模板负责必填、类型和业务校验

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 输出的单个 YAML 标量文本
- output：解码后的 string；非 string 标量或非法 YAML 中断
- ownership：只还原 string 标量，不做 trim 或内容改写

### Dependency: `base.path`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：`list [路径, "abs"]`
- output：归一化后的绝对路径；非绝对路径中断
- ownership：负责路径归一化与绝对路径门禁，不验证文件系统语义

### Dependency: `base.net`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：`list [地址, "dns"]`
- output：校验通过的原字符串；非严格 IPv4、IPv6 或 hostname 时中断
- ownership：负责 IP 与 hostname 格式校验，不做 DNS 解析

### Dependency: `base.bool`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：boolean 或 `true`/`false` 字符串
- output：`"true"` 或 `"false"`；其他类型或值中断
- ownership：负责 boolean 类型门禁

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [key, value, 渲染模板]`
- output：YAML 键值对；渲染值为空时不输出
- ownership：负责单字段 YAML 渲染、引号与枚举处理

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`
- output：YAML 常量 Map
- ownership：集中提供固定常量；本模板只读取 `SYS.YAML_QUOTED`

## 代码边界

### `templates/api-resources/Definitions/_NFSVolumeSource.tpl`

- access：`write`
- operations：`add` `definitions.nfsVolumeSource`
- writable-scopes：`define "definitions.nfsVolumeSource"` 及其整体契约注释

### `templates/api-resources/Definitions/_Volume.tpl`

- access：`read`
- operations：`consume` nfs 分派

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume` `base.get`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` `base.string.normalize`

### `templates/base/_validate.tpl`

- access：`read`
- operations：`consume` `base.path`、`base.net`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.bool`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field`

### `templates/base/_env.tpl`

- access：`read`
- operations：`consume` `SYS.YAML_QUOTED`

## 验证设计

- 最小有效：原生 map `{server: "10.0.0.1", path: "/data"}` 直接渲染，只输出 `path` 与 `server`。
- 较完整有效：`{server: "nfs.example.com", path: "/data", readOnly: true}` 输出 `path`、`readOnly: true` 与 `server`。
- 父模板集成：通过 `definitions.volume` 的 nfs string 简写 `10.0.0.1 /data true` 渲染，输出 `path`、`readOnly`、`server`。
- 关键失败：缺少 `server`、缺少 `path`、`server` 非法、`path` 非绝对、`readOnly` 非 boolean 均中断。
- 边界：`path: "/"`、IPv6 `server`、显式 `readOnly: false`。
- 真实依赖：`base.*` 与 `definitions.volume` 均为现有模板；验证在 `/tmp/sd-kube-chart/` 新建的最小 application Chart 中加载真实实现，无 unavailable 依赖或同名 fixture。
