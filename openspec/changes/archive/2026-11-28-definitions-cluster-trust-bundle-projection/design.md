# definitions.clusterTrustBundleProjection 设计

## 技术目标

- capability：`definitions.clusterTrustBundleProjection`
- artifact-type：Helm 命名模板
- target：`definitions.clusterTrustBundleProjection`

## 设计决策

### Decision: 按官方字段顺序分段渲染

- requirements：`渲染字段与顺序`
- choice：只读取上述五个字段，先完成取值与校验，再按 `labelSelector`、`name`、`optional`、`path`、`signerName` 逐段构建并顺序输出已生效字段。
- rationale：draft 明确要求官方顺序；分段输出避免条件分支改变字段顺序，其他输入键按工程规则静默忽略。

### Decision: name 与 signerName 的非空存在性判定

- requirements：`name 与 signerName 二选一`
- choice：分别以 `base.get` 取值并经 `base.string.normalize` 解码与 trim；以非空结果判定生效；两者都为空或都非空时立即 `fail`。
- rationale：draft 的互斥与二选一约束；统一 YAML 标量解码并尽早报错。

### Decision: path 归一化与逃逸拒绝

- requirements：`path 必填相对路径`
- choice：`base.string.normalize` 与 trim 判空后，经 `base.path` 的 `rel` 模式归一化；归一化结果为 `..` 或以 `../` 开头时 `fail`；以 `quote` 渲染。
- rationale：draft 要求相对路径；与既有 `definitions.keyToPath`、`definitions.downwardAPIVolumeFile` 的路径边界一致。

### Decision: labelSelector 空值与整体委托

- requirements：`labelSelector 委托与伴随约束`
- choice：`labelSelector` 为空（缺失、null、空字符串或空 map）时按未设置处理，不渲染也不校验 `signerName`；非空 map 才要求 `signerName` 非空，并整体传给 `definitions.labelSelector`，对其输出做 YAML 错误与空输出保护后以 `base.map` 渲染。
- rationale：draft 要求空 selector 视同父模板未传递；子模板已具备 `matchLabels` 必填与结构校验能力，父模板不重复实现其内部结构。

### Decision: optional 布尔归一化

- requirements：`optional 布尔`
- choice：剥离 YAML 外层引号后仅在结果非空时交给 `base.bool`，显式 `false` 保留输出。
- rationale：draft 要求 `optional` 可选且按官方 boolean；沿用既有布尔字段的归一化方式。

### Decision: 统一字段渲染入口

- requirements：`渲染字段与顺序`、`path 必填相对路径`
- choice：字符串字段使用 `base.field` 的 `quote` 模式；`labelSelector` 使用 `base.field` 的 `base.map` 渲染模板。
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

### Dependency: `base.path`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：`list [路径, "rel"]`
- output：归一化后的相对路径 string；绝对路径或未知模式时中断
- ownership：trim 与 `.`/`..` 段归一化由依赖负责；前导 `..` 逃逸拒绝由本模板负责

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
- input：`list [键名, 值, 渲染模板]`，渲染模板为 `quote` 或 `base.map`
- output：YAML 键值片段；渲染结果为空时不输出
- ownership：引号、缩进与渲染模板分派由依赖负责；字段生效条件由本模板负责

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

### Dependency: `definitions.labelSelector`

- availability：`existing`
- source：`templates/api-resources/Definitions/_LabelSelector.tpl`
- operation：`consume`
- input：原生非空 map，`matchLabels` 必填，`matchExpressions` 可选
- output：LabelSelector YAML 字段片段；非法输入中断
- ownership：selector 内部结构、校验与渲染由依赖负责；本模板只负责空值判定、伴随约束与片段嵌入

## 代码边界

### `templates/api-resources/Definitions/_ClusterTrustBundleProjection.tpl`

- access：`write`
- operations：`add` `define "definitions.clusterTrustBundleProjection"` 及紧邻中文契约注释
- writable-scopes：`define "definitions.clusterTrustBundleProjection"` 整个定义块

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume` `base.get`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` `base.string.normalize`、`base.isFromYamlError`

### `templates/base/_validate.tpl`

- access：`read`
- operations：`consume` `base.path`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.bool`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field`

### `templates/base/_env.tpl`

- access：`read`
- operations：`consume` `base.env`

### `templates/api-resources/Definitions/_LabelSelector.tpl`

- access：`read`
- operations：`consume` `definitions.labelSelector`

## 验证设计

- 最小有效输入：`{name: "trust-bundle", path: "ca.crt"}`，预期仅输出 `name`、`path` 且顺序正确。
- 较完整有效输入：`{signerName: "example.com/signer", labelSelector: {matchLabels: {app: "web"}}, optional: false, path: "ca.crt"}`，预期输出 `labelSelector`、`optional: false`、`path`、`signerName`。
- 空 labelSelector 有效输入：`{name: "trust-bundle", path: "ca.crt", labelSelector: {}}` 与 `{signerName: "example.com/signer", path: "ca.crt", labelSelector: {}}`，预期省略 `labelSelector` 且不中断；null 与空字符串等同未传递。
- 关键失败：缺失或空白 `path`、绝对路径、`../` 逃逸、`name` 与 `signerName` 同时或同时缺失、非空 `labelSelector` 缺少 `signerName`、`name` 与非空 `labelSelector` 并存、非空 `labelSelector` 非 map 或缺少 `matchLabels`、`optional` 非法值。
- 依赖边界：全部依赖为真实模板，在 `/tmp/sd-kube-chart/` 最小 Chart 中加载真实实现，不使用同名 fixture。
