# PodOS 共享结构设计

## 技术目标

- capability：`definitions.podOS`
- artifact-type：Kubernetes 共享结构命名模板
- target：`templates/api-resources/Definitions/_PodOS.tpl` 中 `define "definitions.podOS"`

## 设计决策

### Decision: 目标文件与命名模板归属

- requirements：`渲染 PodOS 字段片段`
- choice：新增 `templates/api-resources/Definitions/_PodOS.tpl`，文件内只定义 `definitions.podOS`，文件名与结构名对齐并以 `_` 开头。
- rationale：`PodOS` 是 Kubernetes 官方结构，`PodSpec.os`、容器 `os` 与 `PodSecurityContext` 复用，属可跨资源复用的同域共享结构，只能落在 `api-resources/Definitions`；该目录现有 `_ObjectMeta.tpl`、`_LocalObjectReference.tpl` 等均沿用 `_<结构名>.tpl` 与 `definitions.<能力>` 命名，新增文件与之保持一致。当前该 `define` 在全 Chart 不存在，属纯新增。

### Decision: name 取值、去引号与空值跳过

- requirements：`name 为空时跳过渲染`
- choice：以 `base.get` 的 `list [上下文, "name"]` 非必填取值并保留默认别名识别，结果先 `trim`，再经 `base.env` 的 `SYS.YAML_QUOTED` 剥离 YAML 标量引号并再次 `trim`；剥离后为空时输出空内容。
- rationale：缺失、`null`、空字符串与只含空白必须统一按“不输出”处理，而 `base.get` 对标量返回 `toYamlPretty` 文本，空白字符串会被加引号，因此必须先去引号再判空。`base.get` 的非必填语义已覆盖缺失与 `null`，调用方不重复 `hasKey`。空输出由调用方按“`os` 不生效”跳过，与 `templates/api-resources/Core/_PodSpec.tpl` 现有 `include ... | fromYaml` 后判空丢弃的处理一致。

### Decision: 小写归一

- requirements：`小写归一`
- choice：去引号并 `trim` 后立即用 Helm/Sprig 内置 `lower` 转为小写，后续校验与输出统一使用该结果。
- rationale：用户要求大小写不敏感匹配，归一化必须在枚举校验之前完成，否则 `Linux` 会被判为非法。使用内置 `lower` 而非新增正则常量，满足“优先使用既有函数、不复制能力”的约束；项目内已有 `definitions.labelSelector`、`definitions.nodeSelectorTerm` 等使用 `lower` 的先例。

### Decision: 枚举校验委托 base.field

- requirements：`校验 name 枚举`
- choice：以 `base.field` 的 `list ["name", 归一化后的取值, "base.string", (list "linux" "windows")]` 完成枚举校验与字段输出；本模板不实现枚举比较分支，也不自定义枚举失败消息。
- rationale：`base.field` 的允许值列表已在渲染前完成枚举校验，命中时按 `base.string` 输出 `name: linux`，未命中时以 `[base.field]` 前缀中断并输出字段名与允许值列表，正好满足“失败由 `base.field` 持有”的共识。委托后非 string 输入同样自然失败：布尔、整数、map 与 list 经 `toString` 后均不在允许值内，因此本模板无需额外的 `kindIs` 类型门禁，避免与 `definitions.localObjectReference` 中因枚举无法覆盖才保留的类型判定形成重复逻辑。

### Decision: 返回值形态

- requirements：`渲染 PodOS 字段片段`
- choice：模板只输出 `name` 单行字段片段，返回可 `fromYaml` 回收为 map 的 YAML 字符串；`name` 为空时返回空内容。
- rationale：既有调用方 `core.podSpec` 以 `include "definitions.podOS" | fromYaml` 消费并按“解析错误或空值则跳过”处理，字段片段形态与其契约一致。`linux`、`windows` 不是 YAML 1.1 布尔或数值样式，因此不需要强制加引号，`base.field` 的默认 `base.string` 渲染即可。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, "name"]`，非必填并保持别名默认开启以识别 `nameAlias`。
- output：可 `fromYaml` 解析的 YAML 字符串；标量经 `toYamlPretty` 序列化，字符串可能带 YAML 引号；路径缺失、为 `null` 或为空字符串时为空输出。
- ownership：数据源优先级、别名识别、标量序列化由依赖层负责；取值形式选择、去引号、判空与归一化由本层负责。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`
- output：可由 `fromYaml` 解析的常量 Map，本模板读取 `SYS.YAML_QUOTED`。
- ownership：正则常量集中定义由依赖层负责；常量键选择与去引号决策由本层负责。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list ["name", 归一化后的 string, "base.string", (list "linux" "windows")]`。
- output：命中允许值时输出 `name: <值>` 单行字段片段，空值时不输出；未命中时以 `[base.field] name: value '<值>' not in allowed list '<列表>'` 中断渲染。
- ownership：允许值比较、枚举失败消息与 `base.string` 渲染路由由依赖层负责；键名、归一化结果与允许值列表选择由本层负责。

### Dependency: `lower`

- availability：`existing`
- source：Helm/Sprig 内置字符串函数
- operation：`consume`
- input：剥离引号并 `trim` 后的非空 string。
- output：全小写 string。
- ownership：大小写转换语义由 Helm/Sprig 负责；调用时机与归一化边界由本层负责。

## 代码边界

### `templates/api-resources/Definitions/_PodOS.tpl`

- access：`write`
- operations：`add define "definitions.podOS"`、`add 紧邻 define 之前的中文整体契约注释`、`add name 字段的中文注释`
- writable-scopes：文件内 `definitions.podOS` 的契约注释与 `define` 块

## 验证设计

- `/tmp/` 最小 application Chart 直接加载本 change 的目标模板与真实 `base` 依赖，不提供同名 fixture：最小有效输入 `name: linux`，断言输出 `name: linux` 且不含其他键，并可被 `fromYaml` 回收为 map。
- 较完整有效输入：`nameAlias: windows` 覆盖 `name: linux`、空 `nameAlias` 回退 `name`、`Linux`、`WINDOWS`、`"  Linux  "`、附加无关键，断言输出为归一化后的小写取值。
- 关键失败输入：`darwin`、`linux2`、`true`、`123`、map、list，断言以 `[base.field]` 中断且错误信息包含 `name` 与 `linux`、`windows`；缺失、`null`、`""`、只含空白，断言输出为空且渲染成功。
