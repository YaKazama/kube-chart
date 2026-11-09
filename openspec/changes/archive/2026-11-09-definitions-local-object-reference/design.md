# LocalObjectReference 共享结构设计

## 技术目标

- capability：`definitions.localObjectReference`
- artifact-type：Kubernetes 共享结构命名模板
- target：`templates/api-resources/Definitions/_LocalObjectReference.tpl` 中 `define "definitions.localObjectReference"`

## 设计决策

### Decision: 目标文件与命名模板归属

- requirements：`渲染 LocalObjectReference 字段片段`
- choice：新增 `templates/api-resources/Definitions/_LocalObjectReference.tpl`，文件内只定义 `definitions.localObjectReference`，文件名与结构名对齐并以 `_` 开头。
- rationale：`LocalObjectReference` 是 Kubernetes 官方结构，`PodSpec.imagePullSecrets`、`ServiceAccount.imagePullSecrets` 与多个 VolumeSource 复用，属可跨资源复用的同域共享结构，只能落在 `api-resources/Definitions`；该目录现有 `_ObjectMeta.tpl`、`_PodAffinityTerm.tpl` 等均沿用 `_<结构名>.tpl` 与 `definitions.<能力>` 命名，新增文件与之保持一致。当前该 `define` 在全 Chart 不存在，属纯新增。

### Decision: name 取值、去引号与空值跳过

- requirements：`name 为空时跳过渲染`
- choice：以 `base.get` 的 `list [上下文, "name"]` 非必填取值并保留默认别名识别，结果先 `trim`，再经 `base.env` 的 `SYS.YAML_QUOTED` 剥离 YAML 标量引号并再次 `trim`；剥离后为空时整段跳过，输出空内容。
- rationale：缺失、`null`、空字符串与只含空白必须统一按“不输出”处理，而 `base.get` 对标量返回 `toYamlPretty` 文本，字符串 `" on "` 会被自动加引号，因此必须先剥离引号再判空。`base.get` 的非必填语义已覆盖缺失与 `null`，调用方不重复 `hasKey`。空输出由调用方按“该项不生效”跳过，与 `templates/api-resources/Core/_PodSpec.tpl` 现有 `include ... | fromYaml` 后判空丢弃的处理一致。

### Decision: name 类型判定

- requirements：`校验 name 的 RFC 1035 语法`
- choice：剥离引号前先用 `fromYaml (printf "v: %s" $原始取值)` 恢复标量类型，再以 `kindIs "string"` 判定；不是 string 时以本模板前缀中断。
- rationale：`base.get` 会把布尔 `true`、整数 `123` 序列化为同形文本，而 `true` 恰好满足 RFC 1035 字符集，若不判定类型会被静默接受为合法名称。`printf "v: %s"` 包装保留原始引号，使字符串 `"on"` 仍恢复为 string，避免被 YAML 1.1 布尔规则误判。判定失败消息归属本模板，符合“类型判定失败使用本层前缀”的约定。

### Decision: RFC 1035 校验委托 base.rfc

- requirements：`校验 name 的 RFC 1035 语法`
- choice：把非空 `name` 以 `list [名称, "1035"]` 委托 `base.rfc`，直接使用其返回值作为输出值。
- rationale：`base.rfc` 已集中维护 `base.env` 的 `RFC.RFC1035`（1 - 63 字符、首字符小写字母、末字符小写字母或数字）与长度上限，本层不再复制正则常量或比较分支，满足正则契约与 DRY。其失败已覆盖空字符串、格式不符与超长三种边界，本层不重复实现同义校验；失败消息保留 `[base.rfc]` 前缀，符合规格的错误归属。

### Decision: 返回值形态与引号输出

- requirements：`渲染 LocalObjectReference 字段片段`
- choice：以 `base.field` 的 `list ["name", 校验后的名称, "quote"]` 输出单个字段，整体返回可 `fromYaml` 回收为 map 的 YAML 片段；`name` 为空时返回空内容。
- rationale：`base.field` 承担键值序列化与空值跳过，`quote` 保证 `on`、`no`、`y` 等同时满足 RFC 1035 与 YAML 1.1 布尔样式的名称保持 string 语义，避免父级二次解析把名称变成布尔值；此选择与 `definitions.hostAlias` 对 `ip` 使用 `quote` 的既有做法一致。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, "name"]`，非必填并保持别名默认开启以识别 `nameAlias`。
- output：可 `fromYaml` 解析的 YAML 字符串；标量经 `toYamlPretty` 序列化，字符串可能带 YAML 引号；路径缺失、为 `null` 或为空字符串时为空输出。
- ownership：数据源优先级、别名识别、标量序列化由依赖层负责；取值形式选择、去引号、判空与后续失败消息由本层负责。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`
- output：可由 `fromYaml` 解析的常量 Map，本模板读取 `SYS.YAML_QUOTED`。
- ownership：正则常量集中定义由依赖层负责；常量键选择与去引号决策由本层负责。

### Dependency: `base.rfc`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：`list [name, "1035"]`，`name` 为剥离引号并 `trim` 后的非空 string。
- output：校验通过时返回原字符串；空字符串、不匹配 `RFC.RFC1035` 或超过 63 字符时以 `[base.rfc]` 前缀中断渲染。
- ownership：RFC 1035 正则、长度上限与失败消息由依赖层负责；调用时机、去引号前置处理与类型判定由本层负责。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list ["name", 校验后的名称, "quote"]`。
- output：`name: "<值>"` 单行字段片段；值为空时不输出。
- ownership：键值序列化、引号处理与空值跳过由依赖层负责；字段生效条件、键名与渲染参数选择由本层负责。

### Dependency: `fromYaml` 与 `kindIs`

- availability：`existing`
- source：Helm 内置函数
- operation：`consume`
- input：`fromYaml (printf "v: %s" $原始取值)`；`kindIs "string"` 作用于恢复出的 `.v`。
- output：恢复为 map 后读取 `.v`；解析失败时 `.v` 为空值，判定为不是 string。
- ownership：YAML 解析与类型判定语义由 Helm 负责；包装格式、判定时机与失败消息由本层负责。

## 代码边界

### `templates/api-resources/Definitions/_LocalObjectReference.tpl`

- access：`write`
- operations：`add define "definitions.localObjectReference"`、`add 紧邻 define 之前的中文整体契约注释`、`add name 字段的中文注释`
- writable-scopes：文件内 `definitions.localObjectReference` 的契约注释与 `define` 块

## 验证设计

- `/tmp/` 最小 application Chart 直接加载本 change 的目标模板与真实 `base` 依赖，不提供同名 fixture：最小有效输入 `name: web`，断言输出 `name: "web"` 且不含其他键。
- 较完整有效输入：`nameAlias` 覆盖 `name`、空 `nameAlias` 回退 `name`、名称含首尾空白、1 字符与 63 字符边界、`"on"` 等 YAML 1.1 布尔样式名称，断言输出为带引号的 string 并可被 `fromYaml` 回收为 map。
- 关键失败输入：64 字符名称、大写、下划线、首尾 `-`、以数字开头，断言以 `[base.rfc]` 中断；布尔值、整数、map、list 的 `name`，断言以 `[definitions.localObjectReference] name` 中断；缺失、`null`、`""`、只含空白，断言输出为空且渲染成功。
