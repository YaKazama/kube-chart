# definitions.resourceClaim 模板设计

## 技术目标

- capability：`definitions.resourceClaim`
- artifact-type：Helm 命名模板（library Chart）
- target：`templates/api-resources/Definitions/_ResourceClaim.tpl` 中的 `definitions.resourceClaim`

## 设计决策

### Decision: 单文件单模板，按 API 字段顺序直接渲染

- requirements：`渲染单个 ResourceClaim 片段`
- choice：在新建 `_ResourceClaim.tpl` 中定义单一模板，依次渲染 `name`、`request` 两个标量字段，不拆分辅助模板
- rationale：Kubernetes v1.36 `core/v1 ResourceClaim` 只有这两个标量字段；同域文件以一个文件对应一个主模板组织，无复用子结构可拆

### Decision: 关闭 base.get 别名识别

- requirements：`渲染单个 ResourceClaim 片段`（额外键不影响输出）
- choice：调用 `base.get` 时显式传 `alias=false`
- rationale：规格要求 `name`、`request` 之外的键不改变渲染结果，别名识别会读取 `nameAlias`、`requestAlias` 而违反该边界；入参已由父级清洗，别名解析属于上游职责

### Decision: name 走必填取值，request 走可选取值

- requirements：`name 必填与失败边界`
- choice：`name` 使用 `base.get` 的必填参数，再经 `base.string.normalize` 解码并 trim 后判空；`request` 使用非必填参数，解码并 trim 后为空即跳过渲染
- rationale：必填缺失由 `base.get` 直接中断，与 `definitions.podResourceClaim` 的既有处理一致；规格要求空 `request` 视为未设置

### Decision: 两个字段以带引号标量输出

- requirements：`渲染单个 ResourceClaim 片段`（输出可被按 map 解析）
- choice：调用 `base.field` 时使用 `quote` 渲染模板
- rationale：`on`、`yes` 等名称经 YAML 解析后会变为布尔值，引用名必须以字符串形式保持；`definitions.podResourceClaim` 与 `definitions.localObjectReference` 采用同一形式

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文 map> "name" "" "" true false` 与 `list <上下文 map> "request" "" "" false false`
- output：可 `fromYaml` 解析的 YAML 字符串；必填路径缺失时中断渲染
- ownership：`base.get` 负责取值、必填校验与序列化；本模板负责标量解码、空值判定与字段渲染

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`include "base.get"` 的原始输出文本
- output：解码后的 string；空字符串与 `null` 解码结果返回空串；非 string 标量中断
- ownership：解码与类型门禁由依赖承担；本模板只做 `trim` 与空值判断，不重复类型校验

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list "name" <已归一化值> "quote"` 与 `list "request" <已归一化值> "quote"`
- output：单行 YAML 键值对；值为空时不输出该字段
- ownership：键值渲染与引号处理由依赖承担；本模板保证仅在字段生效时调用

## 代码边界

### `templates/api-resources/Definitions/_ResourceClaim.tpl`

- access：`write`
- operations：`add` `definitions.resourceClaim`
- writable-scopes：新建文件的全部内容

### `templates/api-resources/Definitions/_ResourceRequirements.tpl`

- access：`read`
- operations：`consume` 既有 `include "definitions.resourceClaim"` 调用契约

## 验证设计

- 真实依赖边界：验证 Chart 加载真实 `templates/base/` 模板与真实 `templates/api-resources/Definitions/_ResourceRequirements.tpl`
- fixture 边界：仅 `_ResourceClaim.tpl` 由当前 change 提供；其余模板均为仓库真实文件，不提供同名 fixture
- 最小有效：仅 `name`
- 较完整有效：`name` 与 `request` 同时设置；`request` 为 `null`、空字符串、仅空白；含 `nameAlias` 等额外键；`name` 含非 DNS 字符
- 关键失败：`name` 缺失、`name` 为空白、`name` 或 `request` 为非字符串标量
- 集成：通过真实 `definitions.resourceRequirements` 的容器 `claims` 简写与 map 项，确认委派结果与空结果剔除行为
