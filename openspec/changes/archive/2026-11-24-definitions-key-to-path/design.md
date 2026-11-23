# definitions.keyToPath 设计

## 技术目标

- capability：`definitions.keyToPath`
- artifact-type：Helm library Chart 命名模板
- target：`definitions.keyToPath`

## 设计决策

### Decision: 字段取值与输出顺序

- requirements：`KeyToPath 输入与字段顺序`
- choice：三个字段统一经 `base.get` 取值；`key`、`path` 用 `base.string.normalize` 解码后 trim，`mode` 用 `SYS.YAML_QUOTED` 剥离外层引号后 trim；只处理 `key`、`mode`、`path`，按该顺序逐字段完成闭环。不添加入口 `kindIs` 门禁，非 map 上下文由必填 `key` 缺失路径中断。
- rationale：工程规则要求多层字段统一使用 `base.get`，并禁止子模板重复入口类型门禁；`base.get` 对标量做 YAML 序列化，字符串可能带引号返回。

### Decision: key 校验

- requirements：`key 校验`
- choice：解码并 trim 后判空，再交 `K8S.DATA_KEY` 正则校验字符集，最后用 `base.field` 的 `quote` 渲染。
- rationale：ConfigMap/Secret 的 data key 使用同一字符集；既有 `definitions.configMapKeySelector` 与 `definitions.secretKeySelector` 已用同一常量与流程。

### Decision: path 归一化与逃逸防护

- requirements：`path 归一化`
- choice：解码并 trim 后判空，交 `base.path` 的 `rel` 模式归一化并拒绝绝对路径；再拒绝归一化结果为 `..` 或以 `../` 开头；最后用 `base.field` 的 `quote` 渲染。
- rationale：`base.path` 的 `rel` 模式已完成 trim、`clean` 与绝对路径拒绝；它不拒绝残留的前导 `..`，需在本层补足 Kubernetes 约束。该判断使用字符串相等与 `hasPrefix`，不引入新正则常量。

### Decision: mode 归一化

- requirements：`mode 归一化`
- choice：剥离 YAML 引号后交 `base.fileMode` 归一化为十进制 int，空值省略，再由 `base.field` 的 `base.int` 渲染。
- rationale：与 `definitions.configMapVolumeSource` 的 `defaultMode` 共用同一公共文件模式能力，保持八进制与十进制语义一致。

## 依赖契约

### Dependency: `base.env`

- availability：existing
- source：`templates/base/_env.tpl`
- operation：consume
- input：`""`；经 `fromYaml` 恢复常量 map。
- output：常量 map；读取 `K8S.DATA_KEY` 与 `SYS.YAML_QUOTED`，不修改现有表达式。
- ownership：`base.env` 负责常量的结构与转义；本层只读取目标键，不重复构造正则。

### Dependency: `base.get`

- availability：existing
- source：`templates/base/_get.tpl`
- operation：consume
- input：`list <上下文> <字段名>`；不启用强制类型、合并模式或必填参数。
- output：YAML 字符串；字段缺失或为 `null` 时为空输出。
- ownership：依赖负责数据源优先级、别名与序列化；本层负责解析、生效判断与业务校验。

### Dependency: `base.string.normalize`

- availability：existing
- source：`templates/base/_convert.tpl`
- operation：consume
- input：`base.get` 返回的 `key`、`path` 标量文本。
- output：解码后的 string；空输入返回空字符串；非 string 标量或非法 YAML 标量中断。
- ownership：依赖负责标量解码与类型门禁；本层负责 trim、空值判断与字段校验。

### Dependency: `base.path`

- availability：existing
- source：`templates/base/_validate.tpl`
- operation：consume
- input：`list <path> "rel"`。
- output：trim 并 `clean` 后的相对路径；绝对路径中断；不拒绝前导 `..`。
- ownership：依赖负责路径归一化与绝对路径拒绝；本层负责空值判断与前导 `..` 防护。

### Dependency: `base.fileMode`

- availability：existing
- source：`templates/base/_validate.tpl`
- operation：consume
- input：已剥离 YAML 引号的字符串或数值文件模式。
- output：十进制 int；八进制 `0000`-`0777` 与十进制 `0`-`511` 合法，越界或非法中断。
- ownership：依赖负责文件模式校验与十进制归一化；本层负责字段生效判断。

### Dependency: `base.field`

- availability：existing
- source：`templates/base/_field.tpl`
- operation：consume
- input：`list <key> <value> <渲染模板>`；渲染模板为 `quote` 或 `base.int`。
- output：单字段 YAML 片段；空值不输出。
- ownership：依赖负责引号与数值格式化；本层负责字段顺序与生效判断。

### Dependency: `base.int`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：`base.fileMode` 返回的 int。
- output：十进制数字字符串。
- ownership：依赖负责数值格式化；本层负责字段生效判断。

## 代码边界

### `templates/api-resources/Definitions/_KeyToPath.tpl`

- access：write
- operations：新增文件、`definitions.keyToPath` 命名模板与整体契约注释；实现字段顺序、`key` 校验、`path` 归一化与前导 `..` 防护、`mode` 归一化及失败分支。
- writable-scopes：整个新文件。

### `templates/base/_env.tpl`

- access：read
- operations：复核 `K8S.DATA_KEY` 与 `SYS.YAML_QUOTED` 常量。

### `templates/base/_get.tpl`

- access：read
- operations：复核 `base.get` 调用与返回值契约。

### `templates/base/_convert.tpl`

- access：read
- operations：复核 `base.string.normalize` 调用契约。

### `templates/base/_validate.tpl`

- access：read
- operations：复核 `base.path` 的 `rel` 模式与 `base.fileMode` 契约。

### `templates/base/_field.tpl`

- access：read
- operations：复核 `base.field` 的 `quote` 与 `base.int` 渲染契约。

### `templates/base/_types.tpl`

- access：read
- operations：复核 `base.int` 契约。

### `templates/api-resources/Definitions/_ConfigMapVolumeSource.tpl`

- access：read
- operations：复核调用方传入 `{key, path, mode}` 与空输出中断边界。

## 验证设计

- 最小有效：在 `/tmp/sd-kube-chart/` 新建最小 application Chart，加载真实的 `_KeyToPath.tpl`、`_env.tpl`、`_validate.tpl` 及其 base 依赖。渲染 `{key: "LOG_LEVEL", path: "app/config.conf"}`，确认只输出 `key` 与 `path`。
- 较完整有效：渲染 `{key: "LOG_LEVEL", path: "app/config.conf", mode: "0400"}`，确认顺序为 `key`、`mode: 256`、`path`；另覆盖十进制 `493` → 493 与 `"0777"` → 511。
- path 归一化：覆盖 `a/../b` → `b`、`./app//config.conf` → `app/config.conf`，以及绝对路径 `/etc/passwd`、`../x`、`..`、空字符串中断。
- 关键失败：覆盖 `key` 缺失/空/含空格、`mode` 为 `"0778"`/数值 `512`、非 map 上下文、`key` 或 `path` 为错误类型。
- 集成边界：用真实 `definitions.configMapVolumeSource` 接收 `items: ["key path", "key1 path1 0400"]`，确认 `definitions.keyToPath` 的真实实现被调用，不再使用 fixture。
