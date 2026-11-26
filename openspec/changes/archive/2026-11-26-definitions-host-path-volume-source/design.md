# 新增 definitions.hostPathVolumeSource 设计

## 技术目标

- capability：`definitions.hostPathVolumeSource`
- artifact-type：Kubernetes 共享结构 Helm 命名模板
- target：`definitions.hostPathVolumeSource`（`templates/api-resources/Definitions/_HostPathVolumeSource.tpl`）

## 设计决策

### Decision: 定义模板字段归一化与渲染

- requirements：`definitions.hostPathVolumeSource 字段渲染`
- choice：`path` 依次经 `base.get`、`base.string.normalize`、`trim`、非空校验、`base.path` 的 `abs` 模式归一化，并以 `base.field` 的 `quote` 渲染；`type` 经相同取值与解码链后为空则跳过，非空时以 `base.field` + `base.string` + 官方枚举允许值列表校验并渲染；输出顺序为 `path`、`type`。
- rationale：字段顺序与枚举来自 Kubernetes v1 core `HostPathVolumeSource` 官方定义；`base.path` 是既有的绝对路径归一化能力，`base.field` 的允许值列表提供大小写敏感枚举校验与合法范围错误。

### Decision: 父模板 hostPath 简写正则与枚举归一化

- requirements：`definitions.volume hostPath 字符串简写`
- choice：将 `K8S.VOLUME.HOST_PATH` 的运行时表达式改为 `^\s*(/\S*)(?:\s+((?i:""|DirectoryOrCreate|Directory|FileOrCreate|File|Socket|CharDevice|BlockDevice)))?\s*$`；`_Volume.tpl` 捕获后剥离 YAML 引号，`type` 为空则不下传，非空时经小写字典映射为官方枚举后下传，并删除已由正则保证的二次枚举失败分支。
- rationale：保留 `(/\S*)` 在解析层拒绝空路径与相对路径；`(?i:...)` 使 `type` 匹配不区分大小写但捕获值保留输入大小写，因此仍需映射为官方枚举；非法 `type` 由正则不匹配按已接受的 `does not match '<path> [type]'` 中断。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`update`
- input：`include "base.env" ""` 后经 `fromYaml` 恢复常量 map；本 change 读取 `K8S.VOLUME.HOST_PATH`。
- output：YAML map 字符串；更新后的 `K8S.VOLUME.HOST_PATH` 为锚定正则，捕获组 1 为非空绝对路径，捕获组 2 为大小写不敏感的官方枚举或 `""`。
- ownership：`base.env` 维护常量结构与正则表达式；`_Volume.tpl` 负责捕获、引号剥离、空值处理和枚举归一化。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文> "path"` 与 `list <上下文> "type"`。
- output：可解析的 YAML 字符串；字段缺失或空标量时为空输出。
- ownership：`base.get` 负责别名识别、数据源优先级和序列化；本模板负责必填、类型与枚举校验。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 的原始输出文本。
- output：解码后的 string；空输入或 null 返回空字符串；非 string 标量中断。
- ownership：本模板只消费解码结果并执行 trim 与后续字段规则。

### Dependency: `base.path`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：`list <path> "abs"`。
- output：归一化后的绝对路径；非绝对路径中断。
- ownership：`base.path` 负责 trim、`.` / `..` 段归一化与绝对路径校验；本模板负责非空校验和渲染。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list "path" <value> "quote"` 或 `list "type" <value> "base.string" <官方枚举列表>`。
- output：YAML 键值片段；值为空时不输出；枚举不匹配时中断并给出允许值。
- ownership：`base.field` 负责渲染、引号与枚举校验；本模板负责字段生效判断和调用顺序。

### Dependency: `definitions.hostPathVolumeSource`

- availability：`unavailable`
- source：无
- operation：`add`
- input：含 `path` 与可选 `type` 的 map。
- output：`path` 必输出，`type` 非空且合法时输出；非法输入中断。
- ownership：本 change 在 `templates/api-resources/Definitions/_HostPathVolumeSource.tpl` 新增；`_Volume.tpl` 只负责 string 简写归一化并委托。

## 代码边界

### `templates/base/_env.tpl`

- access：`write`
- operations：`update K8S.VOLUME.HOST_PATH`
- writable-scopes：`K8S.VOLUME.HOST_PATH` 键值行

### `templates/api-resources/Definitions/_HostPathVolumeSource.tpl`

- access：`write`
- operations：`add definitions.hostPathVolumeSource`
- writable-scopes：新增文件的合约注释与 `definitions.hostPathVolumeSource` define 块

### `templates/api-resources/Definitions/_Volume.tpl`

- access：`write`
- operations：`update hostPath string 简写分支`
- writable-scopes：`hostPath` 分支（从 `hostPath: <path> [type]` 注释行至 `image` 分支之前）

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume base.get`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume base.string.normalize`

### `templates/base/_validate.tpl`

- access：`read`
- operations：`consume base.path`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume base.field`

## 验证设计

- 在 `/tmp/sd-kube-chart/` 新建最小 application Chart，加载真实 `templates/base/_env.tpl`、`templates/base/_get.tpl`、`templates/base/_convert.tpl`、`templates/base/_validate.tpl`、`templates/base/_field.tpl`、`templates/api-resources/Definitions/_HostPathVolumeSource.tpl` 与 `templates/api-resources/Definitions/_Volume.tpl`，执行 `/opt/homebrew/bin/helm template`；不为上述真实依赖提供同名 fixture。
- 最小有效：`definitions.hostPathVolumeSource` 输入 `{path: "/data"}`，输出仅 `path: "/data"`。
- 较完整有效：输入 `{path: "/data/../logs", type: "DirectoryOrCreate"}`，输出按序 `path: "/logs"`、`type: DirectoryOrCreate`；输入 `{path: "/data", type: ""}` 时无 `type`。
- 关键失败：`path` 缺失、空、相对或非 string，以及 `type` 小写、非法或非 string 均中断。
- 父模板简写：`definitions.volume` 输入 `{name: data, hostPath: "/data"}`、`{name: data, hostPath: "/data directoryorcreate"}`、`{name: data, hostPath: "/data \"\""}` 分别验证仅 path、官方枚举归一化、空 type 不渲染；`{name: data, hostPath: "data"}`、`{name: data, hostPath: ""}`、`{name: data, hostPath: "/data Invalid"}` 验证 `does not match '<path> [type]'` 中断。
