# resources 支持从文件读取配置设计

## 技术目标

- capability：`base.fileRefs`、`base.map.dig` 与 `core.podSpec` 的 `resources` 文件来源
- artifact-type：Helm 命名模板（library Chart）
- target：`templates/base/_fileRefs.tpl` 中的 `base.fileRefs`、`templates/base/_collection.tpl` 中的 `base.map.dig`，以及 `templates/api-resources/Core/_PodSpec.tpl` 中的 `resources` 区段

## 设计决策

### Decision: 文件读取与合并集中在 base.fileRefs

- requirements：`按字段路径从文件读取内容`、`合并规则`、`读取失败边界`
- choice：新增 `base.fileRefs`，一个模板内完成 fileRefs 形态归一、路径校验、文件读取、路径取值与顺序累加合并；`core.podSpec` 只负责取值、调用与回退
- rationale：`*FileRefs` 是按字段前缀扩展的公共族，形态归一与失败边界必须一致；把这部分留在资源层会导致后续每个字段重复实现

### Decision: 路径取值复用 base.map.dig

- requirements：`按字段路径从文件读取内容`
- choice：`base.map.dig` 的分隔符由 `base.env` 的 `SPLIT.ALL` 改为 `splitList "."`，`base.fileRefs` 直接调用它并按输出是否为空判定未命中
- rationale：该模板契约本就声明为点分路径；原实现用 `SPLIT.ALL` 会把 `-`、`/` 等字符一并当作分隔符，导致 `ephemeral-storage` 类键无法取值。改为 `.` 后契约与实现一致，且本模板在 `templates/` 内无其他调用方，既有渲染结果不受影响；`SPLIT.ALL` 常量保留，`base.slice.cleanup` 语义不变

### Decision: 路径校验使用 base.path rel 模式并补充根目录逃逸检查

- requirements：`读取失败边界`
- choice：先调用 `base.path` 的 `rel` 模式归一化，再显式拒绝归一化结果为 `..` 或以 `../` 开头的路径
- rationale：`base.path` 的 `rel` 模式只排除绝对路径，不拒绝 `..` 逃逸；该组合满足「绝对路径与根目录逃逸均中断」

### Decision: map 递归合并，其他类型整体覆盖

- requirements：`合并规则`
- choice：首条结果直接采用；此后两侧均为 map 时调用 `mustMergeOverwrite`，否则用后命中结果整体覆盖；不校验跨项类型一致性
- rationale：Helm 底层合并语义即 `mustMergeOverwrite`（mergo `WithOverride`），map 递归合并、slice 与标量整体覆盖，后出现者优先；`fieldPaths` 与 array 元素均按列表顺序递增优先级，保持同一方向即可，无需额外的类型门禁

### Decision: 扩展名剥离不使用正则

- requirements：`按字段路径从文件读取内容`
- choice：用 `base` 取文件名后以 `splitList "."` 去掉最后一段；只剩一段时保留整段
- rationale：不引入新的固定正则常量，避免改动共享的 `base.env`

### Decision: 空输出表示无有效项

- requirements：`未生效时回退到 inline resources`
- choice：`base.fileRefs` 用 `$hasResult` 标记是否取到有效项，无有效项时输出空字符串；`core.podSpec` 按输出是否为空决定回退到 `resources`
- rationale：与既有 `include` + `fromYaml` 的调用约定一致，回退判断留在拥有 `resources` 字段的层；用独立布尔标记而不是对结果取值判空，避免合法的 `""`、`0`、`false` 被误判为无有效项

## 依赖契约

### Dependency: `base.fileRefs`

- availability：`unavailable`
- source：无
- operation：`add`
- input：`list [上下文 map, fileRefs 原始 YAML 字符串]`；上下文需含 `Files`
- output：累加结果的 YAML 字符串，类型与读取结果一致，可为 map、slice、string 或其他 YAML 值；无有效项时为空字符串；任一边界失败时中断
- ownership：本 change 新增该模板，负责形态归一、路径校验、文件读取、路径取值与顺序累加合并；`core.podSpec` 不重复实现以上任何一项

### Dependency: `base.map.dig`

- availability：`existing`
- source：`templates/base/_collection.tpl`
- operation：`update`
- input：`list [map, 点分路径, 默认值]`；`base.fileRefs` 传入 `list $_document $_fieldPath ""`
- output：命中时返回该值的 YAML 字符串（可为 map、slice 或标量）；未命中或中间节点不是 map 时返回空字符串
- ownership：`base.map.dig` 负责按 `.` 拆分与递归取值；`base.fileRefs` 负责按空输出判定未命中并中断，不重复实现路径遍历

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文> "resourcesFileRefs"` 与 `list <上下文> "resources"`
- output：可 `fromYaml` 解析的 YAML 字符串；路径未命中时为空输出
- ownership：`base.get` 负责取值与别名识别；`core.podSpec` 负责空值判定与回退

### Dependency: `base.path`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：`list <filePath> "rel"`
- output：归一化后的相对路径字符串；绝对路径时中断
- ownership：`base.path` 只做相对路径校验与归一化；根目录逃逸检查由 `base.fileRefs` 补充

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`include "base.get"` 或 fileRefs 元素的原始标量文本
- output：解码后的 string；空值与 `null` 返回空串；非 string 标量中断
- ownership：解码与类型门禁由依赖承担；`base.fileRefs` 只做 `trim` 与空值判断

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的结果
- output：`"true"` 表示解析错误
- ownership：解析保护由依赖承担；`base.fileRefs` 依此中断非法 YAML

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 的结果
- output：`"true"` 表示解析错误
- ownership：数组形态解析保护由依赖承担；`base.fileRefs` 依此区分 array 与 map 形态

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list "resources" <合并后内容 map> "base.map"`
- output：`resources` 字段 YAML 片段；值为空时不输出
- ownership：字段渲染由依赖承担；`core.podSpec` 保证仅在内容生效时调用

### Dependency: `definitions.resourceRequirements`

- availability：`existing`
- source：`templates/api-resources/Definitions/_ResourceRequirements.tpl`
- operation：`consume`
- input：合并后内容 map，附加 `_kind=PodSpec`
- output：`ResourceRequirements` YAML 片段；无有效内容时为空
- ownership：字段白名单、量值校验与渲染由依赖承担，本 change 不改其边界

### Dependency: `core.podSpec`

- availability：`existing`
- source：`templates/api-resources/Core/_PodSpec.tpl`
- operation：`update`
- input：父 Chart 透传的上下文 map，含 PodSpec 字段与 `Files`
- output：PodSpec YAML 片段
- ownership：本 change 只改 `resources` 区段，加入 `resourcesFileRefs` 取值、`base.fileRefs` 调用、回退与渲染；其他字段保持原样

## 代码边界

### `templates/base/_fileRefs.tpl`

- access：`write`
- operations：`add` `base.fileRefs`
- writable-scopes：新建文件的全部内容

### `templates/base/_collection.tpl`

- access：`write`
- operations：`update` `base.map.dig`
- writable-scopes：`base.map.dig` 中的路径拆分语句与对应契约注释

### `templates/api-resources/Core/_PodSpec.tpl`

- access：`write`
- operations：`update` `resources` 区段
- writable-scopes：`core.podSpec` 中 `resources` 字段的取值、回退与渲染闭环

### `templates/api-resources/Definitions/_ResourceRequirements.tpl`

- access：`read`
- operations：`consume` 既有渲染契约

## 验证设计

- 真实依赖边界：验证 Chart 加载真实 `templates/base/` 模板、真实 `_PodSpec.tpl` 与真实 `_ResourceRequirements.tpl`
- fixture 边界：仅 `_fileRefs.tpl` 与验证用 `_configs/` 文件由当前 change 提供；其余模板为仓库真实文件
- 最小有效：map 形态 + 单个 `fieldPaths`
- 较完整有效：array 多元素；省略 `fieldPaths`；多 `fieldPaths`；map 递归合并；slice 与标量整体覆盖；文件名无扩展名；含 `-` 的键名路径
- 关键失败：`filePath` 缺失、空白、绝对路径、含 `..`、文件不存在、文件为空、非法 YAML、路径未命中、`resources` 最终结果不是 map
- 回归：`base.map.dig` 改为 `.` 分隔后，`base.slice.cleanup` 的 `SPLIT.ALL` 默认拆分行为不变
- 集成：`core.podSpec` 中 array 与 map 两种形态的输出，以及 `resourcesFileRefs` 缺失、为 `null`、无有效项时的回退结果
