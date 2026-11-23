# definitions.configMapVolumeSource 设计

## 技术目标

- capability：`definitions.configMapVolumeSource`
- artifact-type：Helm library Chart 命名模板
- target：`definitions.configMapVolumeSource`

## 设计决策

### Decision: 字段取值与空值语义

- requirements：`ConfigMapVolumeSource 输入与字段顺序`
- choice：四个字段统一经 `base.get` 取值；`base.get` 返回 YAML 字符串，字符串与布尔字段先用 `SYS.YAML_QUOTED` 剥离外层引号并 trim，再判断是否生效；显式 `0` 与 `false` 视为有效值，缺失、`null` 与空白不进入渲染。按 `defaultMode`、`items`、`name`、`optional` 顺序逐字段完成闭环。不添加入口 `kindIs` 门禁，非 map 上下文由必填 `name` 缺失路径中断。
- rationale：工程规则要求多层字段统一使用 `base.get`，并禁止用渲染器猜测字段是否生效；`base.get` 对标量做 YAML 序列化，`"0644"` 等字符串会带引号返回，必须先剥离引号才能进入文件模式解析。子模板入口类型由调用方保证，重复门禁属于冗余防御。

### Decision: name 校验

- requirements：`name 校验`
- choice：`base.get` 取值后交 `base.string.normalize` 解码，trim 后判空，再交 `base.rfc` 的 `1123sub` 模式；不转小写；通过后由 `base.field` 以 `quote` 渲染。
- rationale：ConfigMap 官方命名规则为 DNS Subdomain；既有 `definitions.configMapEnvSource` 使用同一规则与渲染方式，保持共享结构层一致。

### Decision: defaultMode 归一化

- requirements：`defaultMode 归一化`
- choice：剥离 YAML 引号后交 `base.fileMode`，再由 `base.field` 以 `base.int` 输出。`base.fileMode` 同步扩展：字符串分支校验通过后用 `fromYaml` 按 YAML 标量语义解析得到十进制数值并返回 int，`"0755"` 得到 493；数值分支保持 `0`-`511` 范围校验。
- rationale：Helm/Sprig 没有同时覆盖八进制与十进制的内置转换（`toDecimal` 只按八进制解析，`atoi` 只按十进制解析），YAML 标量解析可同时满足两种写法；统一收口到公共能力可避免子模板与孙模板重复实现。

### Decision: items 解析与 keyToPath 委托

- requirements：`items 归一化与 keyToPath 委托`
- choice：`base.get` 输出直接交 `fromYamlArray`，用 `base.isFromYamlArrayError` 排除解析错误；数组为空时不输出。逐元素按 `kindOf` 分支：map 原样使用；string trim 后为空则跳过，否则用 `K8S.VOLUME.KEY_TO_PATH_ITEM` 捕获并构造 `{key, path}`，`mode` 非空时加入原始捕获字符串；其他类型中断。每个元素 `include "definitions.keyToPath"` 后 `fromYaml`，用 `base.isFromYamlError` 排除解析错误，空 map 中断，结果以 `base.slice` 渲染；列表最终为空时不输出。
- rationale：`items` 是契约允许为空的集合，不预检原始空输出即可依据恢复后的长度判断；`fromYaml` 成功即保证 map，非 map 由错误 helper 覆盖；用户已确认混合元素、空数组不渲染与子模板空输出中断。

### Decision: 文件模式公共能力更新

- requirements：`文件模式归一化`
- choice：更新 `SYS.FILE_MODE`，将十进制分支从必须两位放宽为允许一位，接受 `0`-`511` 全量；`base.fileMode` 的字符串分支返回十进制 int，以 `0` 开头的四位字符串按八进制解释（`"0512"` → 330），契约注释与示例同步更新。
- rationale：现有正则拒绝 `"1"`-`"9"`，与十进制 `0`-`511` 全量合法的规格冲突；`base.fileMode` 当前没有其他调用方，返回类型收口为 int 后可直接作为数值字段输出。

## 依赖契约

### Dependency: `base.env`

- availability：existing
- source：`templates/base/_env.tpl`
- operation：update
- input：`""`；经 `fromYaml` 恢复常量 map。
- output：常量 map；更新 `SYS.FILE_MODE` 为 `^(0[0-7]{3}|0|[1-9]\d?|[1-4]\d{2}|50\d|51[0-1])$`；`SYS.YAML_QUOTED` 与 `K8S.VOLUME.KEY_TO_PATH_ITEM` 保持现状。以上为正则运行时表达式；写入 `_env.tpl` 双引号 YAML 时按现有 `\\d` 形式转义。
- ownership：`base.env` 负责常量的结构与转义；本层只读取 `SYS.YAML_QUOTED` 与 `K8S.VOLUME.KEY_TO_PATH_ITEM` 并传给 `mustRegexReplaceAll` / `mustRegexMatch`，不重复构造正则。

### Dependency: `base.get`

- availability：existing
- source：`templates/base/_get.tpl`
- operation：consume
- input：`list <上下文> <字段名>`；不启用强制类型、合并模式或必填参数。
- output：YAML 字符串；字段缺失或为 `null` 时为空输出。
- ownership：依赖负责数据源优先级、别名与序列化；本层负责引号剥离、生效判断与业务校验。

### Dependency: `base.string.normalize`

- availability：existing
- source：`templates/base/_convert.tpl`
- operation：consume
- input：`base.get` 返回的 `name` 标量文本。
- output：解码后的 string；空输入返回空字符串；非 string 标量或非法 YAML 标量中断。
- ownership：依赖负责标量解码与类型门禁；本层负责 trim、空值判断与 RFC 校验。

### Dependency: `base.rfc`

- availability：existing
- source：`templates/base/_k8s.tpl`
- operation：consume
- input：`list <name> "1123sub"`。
- output：校验通过的字符串；不符合 RFC1123 Subdomain 或超过 253 字符时中断。
- ownership：依赖负责名称格式与长度校验；本层负责必填与空值判断。

### Dependency: `base.field`

- availability：existing
- source：`templates/base/_field.tpl`
- operation：consume
- input：`list <key> <value> <渲染模板>`；渲染模板为 `quote`、`base.int` 或 `base.slice`。
- output：单字段 YAML 片段；空值不输出。
- ownership：依赖负责引号、数值格式化与集合缩进输出；本层负责字段顺序与生效判断。

### Dependency: `base.bool`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：剥离引号后的 `true` / `false` 字符串或原生 bool。
- output：`true` 或 `false` 字符串；其他值中断。
- ownership：依赖负责布尔表示校验；本层负责字段生效判断。

### Dependency: `base.int`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：`base.fileMode` 返回的 int。
- output：十进制数字字符串。
- ownership：依赖负责数值格式化；本层负责字段生效判断。

### Dependency: `base.slice`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：`definitions.keyToPath` 渲染结果恢复后的 map 列表。
- output：YAML 数组字符串；空数组渲染为 `[]`。
- ownership：依赖负责数组序列化；本层保证只在列表非空时输出 `items`。

### Dependency: `base.fileMode`

- availability：existing
- source：`templates/base/_validate.tpl`
- operation：update
- input：数值或已剥离 YAML 引号的字符串文件模式。
- output：十进制 int；字符串分支支持八进制 `0000`-`0777` 与十进制 `0`-`511`，越界或非法中断。
- ownership：依赖负责文件模式的格式与范围校验及十进制归一化；本层负责字段生效判断与输出。

### Dependency: `base.isFromYamlArrayError`

- availability：existing
- source：`templates/base/_convert.tpl`
- operation：consume
- input：`fromYamlArray` 对 `items` 原文的恢复结果。
- output：布尔字符串。
- ownership：依赖负责识别 Helm 的 YAML array 错误形态；本层负责 `items` 类型失败分支。

### Dependency: `base.isFromYamlError`

- availability：existing
- source：`templates/base/_convert.tpl`
- operation：consume
- input：`fromYaml` 对 `definitions.keyToPath` 输出的恢复结果。
- output：布尔字符串。
- ownership：依赖负责识别 Helm 的 YAML 错误形态；本层负责空输出与非 map 失败分支。

### Dependency: `definitions.keyToPath`

- availability：unavailable
- source：无
- operation：consume
- input：map，含 `key`、`path` 与可选 `mode`；`mode` 为原始捕获字符串，由该模板自行清洗。
- output：KeyToPath 的 YAML 字段片段；空内容、非 map 或非法 YAML 由调用方中断。
- ownership：子模板负责 `key`、`path`、`mode` 的语义校验与渲染；本 change 只负责元素解析和调用，不创建该模板。

## 代码边界

### `templates/base/_env.tpl`

- access：write
- operations：更新 `SYS.FILE_MODE` 的十进制分支，接受 `0`-`511` 全量。
- writable-scopes：`SYS.FILE_MODE`。

### `templates/base/_validate.tpl`

- access：write
- operations：更新 `base.fileMode` 的字符串分支为返回十进制 int，并同步契约注释、返回值说明与示例。
- writable-scopes：`base.fileMode` 的契约注释与 `define` 块。

### `templates/api-resources/Definitions/_ConfigMapVolumeSource.tpl`

- access：write
- operations：新增文件、`definitions.configMapVolumeSource` 命名模板与整体契约注释；实现字段顺序、`name` 校验、`defaultMode` 归一化、`items` 解析、`definitions.keyToPath` 调用与失败分支。
- writable-scopes：整个新文件。

### `templates/base/_get.tpl`

- access：read
- operations：复核 `base.get` 调用与返回值契约。

### `templates/base/_convert.tpl`

- access：read
- operations：复核 `base.string.normalize`、`base.isFromYamlError` 与 `base.isFromYamlArrayError` 调用契约。

### `templates/base/_types.tpl`

- access：read
- operations：复核 `base.bool`、`base.int` 与 `base.slice` 调用契约。

### `templates/base/_field.tpl`

- access：read
- operations：复核 `base.field` 的 `quote`、`base.int` 与 `base.slice` 渲染契约。

### `templates/base/_k8s.tpl`

- access：read
- operations：复核 `base.rfc` 的 `1123sub` 模式契约。

### `templates/api-resources/Definitions/_Volume.tpl`

- access：read
- operations：复核 configMap source 的调用边界与原始 `items` 字符串下传方式。

## 验证设计

- 最小有效：在 `/tmp/sd-kube-chart/` 新建最小 application Chart，加载真实的 `_env.tpl`、`_validate.tpl`、`_ConfigMapVolumeSource.tpl` 及其 base 依赖，为 unavailable 的 `definitions.keyToPath` 提供同名 fixture。渲染只含 `name` 的输入，确认只输出 `name`。
- 较完整有效：渲染含 `name`、`defaultMode: "0755"`、`optional: false` 与混合 `items`（一个 map 元素、一个带 `mode` 的 string 元素、一个不带 `mode` 的 string 元素）的输入，确认字段顺序、`defaultMode: 493`、`mode` 原样下传与元素顺序。
- 文件模式：直接加载真实 `_env.tpl` 与 `_validate.tpl` 渲染 `base.fileMode`，覆盖 `"0000"` → 0、`"0777"` → 511、`"0512"` → 330、`"9"` → 9、`"493"` → 493、数值 `0` 与 `511` 通过，以及 `"9999"`、`"0778"`、数值 `512` 中断。
- 关键失败：覆盖 `name` 缺失/空/大写/超长、`defaultMode` 越界或非法、`items` 非数组、元素类型非法、string 元素段数不在 2-3、`optional` 非布尔、`definitions.keyToPath` 返回空内容/非 map/非法 YAML。
- 集成边界：用真实 `definitions.volume` 接收 configMap 字符串简写 `cm TRUE 0644 items (key path, key1 path1 0400)`，确认原始 item 字符串可被本模板解析；`definitions.keyToPath` 仍为 fixture，只证明调用方行为，不代表真实子模板集成通过。
