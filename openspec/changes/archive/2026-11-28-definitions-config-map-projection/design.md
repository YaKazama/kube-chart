# definitions.configMapProjection 设计

## 技术目标

- capability：`definitions.configMapProjection`
- artifact-type：Helm 命名模板
- target：`definitions.configMapProjection`

## 设计决策

### Decision: 按官方字段顺序分段渲染

- requirements：`渲染字段与顺序`
- choice：只读取 `items`、`name`、`optional`，按该顺序逐字段完成取值、校验与输出，字段生效时才调用渲染入口。
- rationale：draft 明确要求官方字段定义与顺序；处理顺序与输出顺序一致，无需收集中间片段，其他输入键按工程规则静默忽略。

### Decision: items 委托与结果收敛

- requirements：`items 委托、去重与去空`
- choice：`items` 经 `base.get` 取值并用 `fromYamlArray` 恢复；每个原生 map 条目委托 `definitions.keyToPath`，对输出做 YAML 错误保护，空结果剔除，非空结果按渲染内容 `mustUniq` 去重；最终为空时省略 `items`。
- rationale：draft 要求逐项委托、回收结果去重去空；子模板已具备 KeyToPath 字段校验，父模板不重复实现其内部结构。

### Decision: name 必填与 RFC1123 Subdomain 校验

- requirements：`name 必填且为合法 ConfigMap 名称`
- choice：`base.string.normalize` 与 trim 判空后，经 `base.rfc` 的 `1123sub` 模式校验，并以 `quote` 渲染。
- rationale：draft 要求 `name` 必填且字段按官方定义；与既有 `definitions.configMapEnvSource` 的 ConfigMap 名称处理保持一致。

### Decision: optional 布尔归一化

- requirements：`optional 布尔`
- choice：剥离 YAML 外层引号后仅在结果非空时交给 `base.bool`，显式 `false` 保留输出。
- rationale：draft 要求 `optional` 可选且按官方 boolean；沿用既有布尔字段的归一化方式。

### Decision: 统一字段渲染入口

- requirements：`渲染字段与顺序`、`items 委托、去重与去空`
- choice：`name` 使用 `base.field` 的 `quote` 模式；`items` 使用 `base.field` 的 `base.slice` 渲染模板。
- rationale：工程规则要求统一使用 `base.field` 并按字段真实类型选择渲染模板。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, 点分路径]`
- output：YAML 字符串；无命中时为空输出，不抛出类型错误
- ownership：数据源与别名回溯由依赖负责；本模板只负责字段归一化、存在性判定与校验

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 返回的 YAML 标量文本
- output：解码后的 string；空输入返回空字符串；非法 YAML 或非 string 时中断
- ownership：YAML 标量解码由依赖负责；字段路径错误与 trim 由本模板负责

### Dependency: `base.rfc`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：`list [名称, "1123sub"]`
- output：校验通过的 string；格式或长度非法时中断
- ownership：RFC1123 Subdomain 与 253 字符上限校验由依赖负责；必填判定由本模板负责

### Dependency: `base.bool`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：bool，或字面量字符串 `"true"` / `"false"`
- output：`true` 或 `false` 字面量；其他类型或值中断
- ownership：布尔归一化与校验由依赖负责；字段存在性判断由本模板负责

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 值, 渲染模板]`，渲染模板为 `quote` 或 `base.slice`
- output：YAML 键值片段；渲染结果为空时不输出
- ownership：引号、缩进与渲染模板分派由依赖负责；字段生效条件由本模板负责

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 返回值
- output：布尔字符串；仅识别解析错误形态
- ownership：数组解析错误识别由依赖负责；失败消息由本模板构造

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值
- output：布尔字符串；仅对含 `Error` 键的 map 返回 `true`
- ownership：错误形态识别由依赖负责；失败消息由本模板构造

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`
- output：YAML 常量 Map；读取 `SYS.YAML_QUOTED`
- ownership：常量定义由依赖负责；本模板不新增或改写常量

### Dependency: `definitions.keyToPath`

- availability：`existing`
- source：`templates/api-resources/Definitions/_KeyToPath.tpl`
- operation：`consume`
- input：原生 KeyToPath map，`key` 与 `path` 必填，`mode` 可选
- output：KeyToPath YAML 字段片段；非法输入中断
- ownership：key、mode、path 的取值、归一化与校验由依赖负责；本模板只负责数组解析、逐项委托、空结果剔除、去重与片段嵌入

## 代码边界

### `templates/api-resources/Definitions/_ConfigMapProjection.tpl`

- access：`write`
- operations：`add` `define "definitions.configMapProjection"` 及紧邻中文契约注释
- writable-scopes：`define "definitions.configMapProjection"` 整个定义块

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume` `base.get`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` `base.string.normalize`、`base.isFromYamlError`、`base.isFromYamlArrayError`

### `templates/base/_k8s.tpl`

- access：`read`
- operations：`consume` `base.rfc`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.bool`、`base.slice`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field`

### `templates/base/_env.tpl`

- access：`read`
- operations：`consume` `base.env`

### `templates/api-resources/Definitions/_KeyToPath.tpl`

- access：`read`
- operations：`consume` `definitions.keyToPath`

## 验证设计

- 最小有效输入：`{name: "app-config"}`，预期仅输出合法且带引号的 `name`。
- 较完整有效输入：`{name: "app-config", items: [{key: "LOG_LEVEL", path: "app/config.conf"}, {key: "LOG_LEVEL", path: "app/config.conf"}], optional: false}`，预期 `items` 去重后仅一个条目，并输出 `optional: false`，顺序为 `items`、`name`、`optional`。
- 关键失败：缺失或空白 `name`、非法 `name`、`items` 非 array、条目非 map、条目缺少 `key`/`path`、`path` 为绝对路径或逃逸路径、`optional` 非法值。
- 空结果剔除：真实 `definitions.keyToPath` 对合法输入不产生空输出，该分支按父模板容错实现，不单独作为真实依赖集成场景。
- 依赖边界：全部依赖为真实模板，在 `/tmp/sd-kube-chart/` 最小 Chart 中加载真实实现，不使用同名 fixture。
