# definitions.volumeMount 设计

## 技术目标

- capability：`definitions.volumeMount`
- artifact-type：Helm library Chart 命名模板
- target：`templates/api-resources/Definitions/_VolumeMount.tpl`

## 设计决策

### Decision: 统一归一化后按 API 顺序渲染

- requirements：`VolumeMount map 渲染`、`VolumeMount 字符串简写解析`、`VolumeMount 字段约束`
- choice：`definitions.volumeMount` 按输入类型分派 map 与 string，两者归一为 `name`、`mountPath`、`readOnly`、`recursiveReadOnly`、`mountPropagation`、`subPath`、`subPathExpr` 局部值，并将 `name` 规范化为小写；先完成全部字段校验，再按 `mountPath`、`mountPropagation`、`name`、`readOnly`、`recursiveReadOnly`、`subPath`、`subPathExpr` 顺序调用 `base.field` 输出已提供字段。
- rationale：map 与字符串简写共享同一校验与渲染路径，避免重复逻辑；字段顺序与 v1.36 API 参考的 VolumeMount 字段表一致。

### Decision: 字符串简写由 definitions.volumeMount 解析

- requirements：`VolumeMount 字符串简写解析`
- choice：`definitions.container.array` 以 `allowString true` 将 string 元素原样传给 `definitions.volumeMount`；`definitions.volumeMount` 使用 `K8S.VOLUME_MOUNT` 整段匹配并提取六个捕获组，第 3 组再使用 `K8S.VOLUME_MOUNT_SUB_PATH_LIKE` 整段匹配决定 `subPathExpr` 或 `subPath`。运行时表达式为 `(?i)^([^,\s]+)[,\s]+([^,\s]+)(?:[,\s]+([^,\s]+))?(?:[,\s]+(true|false))?(?:[,\s]+(Disabled|IfPossible|Enabled))?(?:[,\s]+(Bidirectional|HostToContainer|None))?$` 与 `^\$\([^)]+\)$`；source 写入 `_env.tpl` 双引号 YAML 时按现有 `\\s` 形式转义。
- rationale：VolumeMount 结构归属 `definitions.volumeMount`，父模板只负责数组元素类型准入，不重复子结构语义；`definitions.container.array` 已具备 `allowString` 能力。

### Decision: 复用 base 校验与渲染能力

- requirements：`VolumeMount map 渲染`、`VolumeMount 字段约束`
- choice：map 字段使用 `base.get` 取值，字符串字段使用 `base.string.normalize` 解码；`readOnly` 使用 `base.bool`；`name` 先经 `lower` 规范化为小写，再使用 `base.rfc` 的 `1123` 模式；枚举与字段输出使用 `base.field`。
- rationale：沿用现有 base 契约，避免内联重复的取值、归一、枚举与引号逻辑。

### Decision: 大小写处理

- requirements：`VolumeMount map 渲染`、`VolumeMount 字符串简写解析`、`VolumeMount 字段约束`
- choice：`K8S.VOLUME_MOUNT` 使用 `(?i)` 进行不区分大小写的格式匹配；`name` 在 `base.rfc` 校验与输出前使用 `lower` 规范化为小写；`readOnly`、`recursiveReadOnly` 与 `mountPropagation` 的值校验保持大小写敏感，仅接受规范拼写。
- rationale：格式层容忍大小写，值层保持 API 枚举的精确拼写；名称按 Kubernetes RFC1123 要求输出小写。

### Decision: 容器数组启用 string 元素

- requirements：`Container volumeMounts 混合数组`
- choice：`templates/api-resources/Definitions/_Container.tpl` 的 `volumeMounts` 调用增加 `allowString true`，并更新对应契约注释；不修改 `definitions.container.array`。
- rationale：`definitions.container.array` 已支持 string 元素准入，混合顺序由现有逐项遍历保证。

## 依赖契约

### Dependency: `base.env`

- availability：existing
- source：`templates/base/_env.tpl`
- operation：add
- input：`""`；经 `fromYaml` 恢复常量 map。
- output：常量 map；新增键 `K8S.VOLUME_MOUNT` 与 `K8S.VOLUME_MOUNT_SUB_PATH_LIKE`，并读取现有 `SYS.YAML_QUOTED` 剥离 map 布尔字段的 YAML 外层引号。
- ownership：`base.env` 负责集中常量结构与类型；本层只读取目标键并传给 `mustRegexMatch`/`mustRegexReplaceAll`，不重复构造正则。

### Dependency: `base.get`

- availability：existing
- source：`templates/base/_get.tpl`
- operation：consume
- input：`list <上下文> <点分路径>`；不启用额外强制类型、合并模式或必填参数。
- output：YAML 字符串；路径缺失时为空输出。
- ownership：`base.get` 负责数据源优先级、别名与序列化；本层负责字段存在性与业务校验。

### Dependency: `base.string.normalize`

- availability：existing
- source：`templates/base/_convert.tpl`
- operation：consume
- input：`base.get` 返回的 YAML 标量文本。
- output：解码后的 string；空输入返回空字符串；非 string 标量或非法 YAML 标量中断。
- ownership：依赖负责标量解码与类型门禁；本层负责 trim、必填判断与字段语义校验。

### Dependency: `base.bool`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：原生 bool 或字面量字符串 `true`/`false`。
- output：`true` 或 `false` 字符串；其他值中断。
- ownership：依赖负责布尔表示校验；本层负责可选字段生效判断与渲染。

### Dependency: `base.field`

- availability：existing
- source：`templates/base/_field.tpl`
- operation：consume
- input：`list <key> <value> <渲染模板> [允许值列表]`。
- output：单字段 YAML 片段；空值不输出；枚举不匹配时中断。
- ownership：依赖负责单字段引号、枚举校验与输出格式；本层负责字段顺序与字段生效判断。

### Dependency: `base.rfc`

- availability：existing
- source：`templates/base/_k8s.tpl`
- operation：consume
- input：`list <小写化 name> "1123"`。
- output：校验通过的字符串；不符合 RFC1123 Label 或超过 63 字符时中断。
- ownership：依赖负责 Volume 名称格式校验；本层负责必填、空值判断与小写规范化。

### Dependency: `definitions.container.array`

- availability：existing
- source：`templates/api-resources/Definitions/_Container.tpl`
- operation：consume
- input：`dict`，含 `key`、`define`、`raw`，并设置 `allowString true`。
- output：Container 单字段 YAML 片段；原始数组为空时无输出；非数组、非法元素类型或子模板非法 YAML 时中断。
- ownership：依赖负责数组解析、string/map 元素准入、逐项委托与字段输出；本层只设置 `allowString` 并更新调用契约。

## 代码边界

### `templates/base/_env.tpl`

- access：write
- operations：在 `K8S` 下新增字符串简写与变量形式常量。
- writable-scopes：`K8S.VOLUME_MOUNT`、`K8S.VOLUME_MOUNT_SUB_PATH_LIKE`

### `templates/api-resources/Definitions/_VolumeMount.tpl`

- access：write
- operations：新增文件、`definitions.volumeMount` 模板及整体契约注释。
- writable-scopes：整个新文件

### `templates/api-resources/Definitions/_Container.tpl`

- access：write
- operations：更新 `definitions.container` 契约注释中的 `volumeMounts` 条目与 string 简写边界行、`volumeMounts` 字段注释；更新 `volumeMounts` 的 `definitions.container.array` 调用参数。
- writable-scopes：`definitions.container` 契约注释的 `volumeMounts` 条目、契约注释的 string 简写边界行、`volumeMounts` 字段注释、`volumeMounts` 的 `definitions.container.array` 调用

### `templates/base/_get.tpl`

- access：read
- operations：复核 `base.get` 调用契约。

### `templates/base/_convert.tpl`

- access：read
- operations：复核 `base.string.normalize` 调用契约。

### `templates/base/_types.tpl`

- access：read
- operations：复核 `base.bool` 调用契约。

### `templates/base/_field.tpl`

- access：read
- operations：复核 `base.field` 调用契约。

### `templates/base/_k8s.tpl`

- access：read
- operations：复核 `base.rfc` 的 `1123` 模式契约。

### `templates/api-resources/Definitions/_VolumeDevice.tpl`

- access：read
- operations：参考同层字段校验、必填判断与渲染结构。

## 验证设计

- 最小有效：实际渲染 `definitions.volumeMount` 的 map（`name` + `mountPath`）与两段字符串，包含大写 `name` 的 map 与 string 输入；并渲染 `definitions.container` 的 map/string 混合 `volumeMounts`，确认字段集合、字段顺序、元素顺序与 `name` 小写输出。真实依赖为 `_env.tpl` 等 base 模板与 `definitions.container`；fixture 只提供 values，不得用同名 fixture 替代 `_env.tpl` 常量。
- 完整有效：覆盖 `name`、`mountPath` 与全部可选字段（`subPath`/`subPathExpr` 分场景）、格式正则大小写不敏感、逗号与空白混合分隔、`readOnly` 省略与显式 `false`、`recursiveReadOnly` 三种枚举、`mountPropagation` 三种枚举及合法的跨字段组合。
- 关键失败：覆盖必填缺失、`name` 规范化后非法、`mountPath` 含 `:`、`subPath`/`subPathExpr` 互斥、布尔非法、枚举非法、`TRUE`/`enabled` 等大小写变体、`recursiveReadOnly` 前提不满足、递归只读与传播模式冲突、字符串格式不匹配、`volumeMounts` 非数组和元素类型非法。
