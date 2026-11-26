# 新增 definitions.imageVolumeSource 设计

## 技术目标

- capability：`definitions.imageVolumeSource`
- artifact-type：Kubernetes 共享结构 Helm 命名模板
- target：`definitions.imageVolumeSource`（`templates/api-resources/Definitions/_ImageVolumeSource.tpl`）

## 设计决策

### Decision: 定义模板字段归一化与渲染

- requirements：`definitions.imageVolumeSource 字段渲染`
- choice：`pullPolicy` 依次经 `base.get`、`base.string.normalize`、`trim`，为空则跳过，非空时以 `base.field` 的 `quote` 与官方枚举允许值列表校验并渲染；`reference` 经相同取值与解码链，非空校验后以 `base.field` 的 `quote` 渲染；输出顺序为 `pullPolicy`、`reference`。
- rationale：字段顺序与枚举来自 Kubernetes v1 core `ImageVolumeSource` 官方定义；`base.field` 的允许值列表提供大小写敏感枚举校验与合法范围错误，`base.string.normalize` 负责非 string 标量中断。

### Decision: 父模板 image 简写正则

- requirements：`definitions.volume image 字符串简写`
- choice：将 `K8S.VOLUME.IMAGE` 的运行时表达式改为 `^\s*(\S+)(?:\s+((?i:Always|IfNotPresent|Never)))?\s*$`；`_Volume.tpl` 现有 `pullPolicy` 小写字典映射保留，空值不下传。
- rationale：`(?i:...)` 使 `pullPolicy` 匹配不区分大小写但捕获值保留输入大小写，因此仍需映射为官方枚举；非法 `pullPolicy` 由正则不匹配中断；`reference` 的非空 token 约束由 `(\S+)` 保持。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`update`
- input：`include "base.env" ""` 后经 `fromYaml` 恢复常量 map；本 change 读取 `K8S.VOLUME.IMAGE`。
- output：YAML map 字符串；更新后的 `K8S.VOLUME.IMAGE` 为锚定正则，捕获组 1 为 reference，捕获组 2 为大小写不敏感的官方枚举。
- ownership：`base.env` 维护常量结构与正则表达式；`_Volume.tpl` 负责捕获与枚举归一化。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文> "pullPolicy"` 与 `list <上下文> "reference"`。
- output：可解析的 YAML 字符串；字段缺失或空标量时为空输出。
- ownership：`base.get` 负责别名识别、数据源优先级和序列化；本模板负责必填、类型与枚举校验。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 的原始输出文本。
- output：解码后的 string；空输入或 null 返回空字符串；非 string 标量中断。
- ownership：本模板只消费解码结果并执行 trim 与后续字段规则。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list "pullPolicy" <value> "quote" <官方枚举列表>` 或 `list "reference" <value> "quote"`。
- output：YAML 键值片段；值为空时不输出；枚举不匹配时中断并给出允许值。
- ownership：`base.field` 负责渲染、引号与枚举校验；本模板负责字段生效判断和调用顺序。

### Dependency: `definitions.imageVolumeSource`

- availability：`unavailable`
- source：无
- operation：`add`
- input：含 `reference` 与可选 `pullPolicy` 的 map。
- output：`reference` 必输出，`pullPolicy` 非空且合法时输出；非法输入中断。
- ownership：本 change 在 `templates/api-resources/Definitions/_ImageVolumeSource.tpl` 新增；`_Volume.tpl` 只负责 string 简写归一化并委托。

## 代码边界

### `templates/base/_env.tpl`

- access：`write`
- operations：`update K8S.VOLUME.IMAGE`
- writable-scopes：`K8S.VOLUME.IMAGE` 键值行

### `templates/api-resources/Definitions/_ImageVolumeSource.tpl`

- access：`write`
- operations：`add definitions.imageVolumeSource`
- writable-scopes：新增文件的合约注释与 `definitions.imageVolumeSource` define 块

### `templates/api-resources/Definitions/_Volume.tpl`

- access：`read`
- operations：`consume definitions.imageVolumeSource、K8S.VOLUME.IMAGE`

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume base.get`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume base.string.normalize`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume base.field`

## 验证设计

- 在 `/tmp/sd-kube-chart/` 新建最小 application Chart，加载真实 `templates/base/_env.tpl`、`templates/base/_get.tpl`、`templates/base/_convert.tpl`、`templates/base/_field.tpl`、`templates/base/_types.tpl`、`templates/base/_k8s.tpl`、`templates/api-resources/Definitions/_ImageVolumeSource.tpl` 与 `templates/api-resources/Definitions/_Volume.tpl`，执行 `/opt/homebrew/bin/helm template`；不为上述真实依赖提供同名 fixture。
- 最小有效：`definitions.imageVolumeSource` 输入 `{reference: "nginx:1.27"}`，输出仅 `reference: "nginx:1.27"`。
- 较完整有效：输入 `{reference: "nginx:1.27", pullPolicy: "Always"}`，输出按序 `pullPolicy: "Always"`、`reference: "nginx:1.27"`；输入 `{reference: "nginx:1.27", pullPolicy: ""}` 时无 `pullPolicy`。
- 关键失败：`reference` 缺失、空或非 string，以及 `pullPolicy` 小写、非法或非 string 均中断。
- 父模板简写：`definitions.volume` 输入 `{name: data, image: "nginx:1.27"}`、`{name: data, image: "nginx:1.27 always"}`、`{name: data, image: "nginx:1.27 IfNotPresent"}` 分别验证仅 reference、官方枚举归一化、其他枚举值；`{name: data, image: ""}`、`{name: data, image: "nginx:1.27 Sometimes"}` 验证 `does not match '<reference> [pullPolicy]'` 中断。
