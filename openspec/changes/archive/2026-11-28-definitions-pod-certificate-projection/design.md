# definitions.podCertificateProjection 设计

## 技术目标

- capability：`definitions.podCertificateProjection`
- artifact-type：Helm 命名模板
- target：`definitions.podCertificateProjection`

## 设计决策

### Decision: 路径组与文件布局校验

- requirements：`文件布局与相对路径`
- choice：经 `base.get`、`base.string.normalize` 与 trim 读取三个路径字段；以非空值判定是否配置；校验 `keyPath` 与 `certificateChainPath` 成对出现，并校验至少配置一种文件布局；随后按官方顺序对已生效路径经 `base.path` 的 `rel` 模式校验并以 `quote` 渲染。
- rationale：draft 要求相对路径与布局约束；三个路径字段存在相互依赖，集中读取与校验避免重复分支。

### Decision: signerName 与 keyType 必填

- requirements：`signerName 与 keyType 必填`
- choice：两者经 `base.string.normalize` 解码与 trim 后判空；`keyType` 通过 `base.field` 的允许值列表校验枚举，`signerName` 以 `quote` 渲染。
- rationale：draft 明确两者必填与 `keyType` 枚举范围；统一标量解码并尽早报错。

### Decision: maxExpirationSeconds 归一化与范围

- requirements：`maxExpirationSeconds 范围`
- choice：剥离 YAML 外层引号后交给 `base.int` 校验整数，再经 `base.int.range` 校验 3600–7862400 闭区间，以 `base.int` 渲染；空值省略。
- rationale：draft 明确整数秒与范围；沿用既有数值归一化与范围校验能力。

### Decision: userAnnotations 键校验

- requirements：`userAnnotations 键校验`
- choice：`base.get` 取值后以 `fromYaml` 恢复 map 并做解析错误保护；逐项校验值为 string，键经 `base.labelKey` 校验语法并要求包含 `/` 前缀，使用其返回值重建注解 map；最终以 `base.map` 渲染，空 map 省略。
- rationale：draft 要求键为带域名前缀的限定名、值为 string；复用标签键语法校验并补足注解键必须带前缀的差异。

### Decision: 官方顺序直接渲染

- requirements：`渲染字段与顺序`
- choice：按 `certificateChainPath`、`credentialBundlePath`、`keyPath`、`keyType`、`maxExpirationSeconds`、`signerName`、`userAnnotations` 顺序逐字段校验并直接输出，不保留片段变量。
- rationale：处理顺序与官方输出顺序一致，直接渲染最简；其他输入键按工程规则静默忽略。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, 点分路径]`
- output：YAML 字符串；无命中时为空输出，不抛出类型错误
- ownership：数据源与别名回溯由依赖负责；本模板负责归一化、存在性判定与校验

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
- ownership：trim 与 `.`/`..` 段归一化由依赖负责；路径字段的必填与布局判定由本模板负责

### Dependency: `base.int`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：int、int64、float64 或整数字符串
- output：十进制整数字符串；非法输入中断
- ownership：整数格式归一化由依赖负责；范围校验由 `base.int.range` 负责

### Dependency: `base.int.range`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：`list [整数, 3600, 7862400]`
- output：闭区间内的整数；越界时中断
- ownership：范围校验由依赖负责；字段存在性与渲染由本模板负责

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 值, 渲染模板, 允许值列表]`；渲染模板为 `quote`、`base.int` 或 `base.map`，允许值列表仅用于 `keyType`
- output：YAML 键值片段；渲染结果为空时不输出
- ownership：引号、缩进、枚举校验与渲染模板分派由依赖负责；字段生效条件由本模板负责

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

### Dependency: `base.labelKey`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：`list [键, 调用方模板名, 字段路径]`
- output：trim 后的键；键类型、段数、name 与 prefix 语法或 prefix 长度非法时中断
- ownership：键语法校验由依赖负责；注解键必须具备前缀的额外约束与 map 重建由本模板负责

## 代码边界

### `templates/api-resources/Definitions/_PodCertificateProjection.tpl`

- access：`write`
- operations：`add` `define "definitions.podCertificateProjection"` 及紧邻中文契约注释
- writable-scopes：`define "definitions.podCertificateProjection"` 整个定义块

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume` `base.get`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` `base.string.normalize`、`base.isFromYamlError`

### `templates/base/_validate.tpl`

- access：`read`
- operations：`consume` `base.path`、`base.int.range`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.int`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field`

### `templates/base/_env.tpl`

- access：`read`
- operations：`consume` `base.env`

### `templates/base/_k8s.tpl`

- access：`read`
- operations：`consume` `base.labelKey`

## 验证设计

- 最小有效输入：`{signerName: "example.com/signer", keyType: "RSA3072", credentialBundlePath: "credential-bundle.pem"}`，预期按 `credentialBundlePath`、`keyType`、`signerName` 输出。
- 仅双文件布局：`{signerName, keyType, keyPath: "key.pem", certificateChainPath: "chain.pem"}`，预期输出两个路径。
- 全量输入：两种布局、`maxExpirationSeconds` 边界值与合法 `userAnnotations`，预期全部字段按官方顺序输出。
- 关键失败：缺失 `signerName`/`keyType`、非法 `keyType`、双文件字段不成对、未配置任何布局、绝对路径、`maxExpirationSeconds` 越界或非整数、`userAnnotations` 非 map、值非 string、键缺少前缀或键语法非法。
- 依赖边界：全部依赖为真实模板，在 `/tmp/sd-kube-chart/` 最小 Chart 中加载真实实现，不使用同名 fixture。
