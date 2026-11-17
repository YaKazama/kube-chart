# definitions.fileKeySelector 设计

## 技术目标

- capability：`definitions.fileKeySelector`
- artifact-type：Kubernetes 原生 API 同域共享结构模板（`FileKeySelector`）
- target：`templates/api-resources/Definitions/_FileKeySelector.tpl`

## 设计决策

### Decision: 单文件承载并按官方字段顺序渲染

- requirements：`字段渲染顺序与类型`、`三个必填字段校验`、`path 相对路径归一化`、`optional 只接受原生布尔值`
- choice：新建 `templates/api-resources/Definitions/_FileKeySelector.tpl`，只包含 `definitions.fileKeySelector` 一个 define，按 `key` → `optional` → `path` → `volumeName` 顺序处理。
- rationale：共享结构文件围绕与文件名对应的主模板组织；四个字段无共享中间状态，拆分没有复用收益；官方字段表顺序为 `key`、`optional`、`path`、`volumeName`。

### Decision: 三个必填字段统一自控判空

- requirements：`三个必填字段校验`
- choice：`volumeName`、`path`、`key` 均以 `base.get` 取值（不启用必填参数），经 `base.string.normalize` 解码并 `trim` 后自行判空；为空时以 `[definitions.fileKeySelector] <字段>: required field is missing or empty` 中断。
- rationale：`base.get` 的必填参数失败消息使用 `[base.get]` 前缀，无法满足失败消息统一为 `[模板名] 字段路径: 错误原因`；取值仍由 `base.get` 负责，判空与消息归本层；三字段处理完全同构，可用同一模式表达。

### Decision: path 用 base.path 的 rel 模式归一化并补充路径边界判断

- requirements：`path 相对路径归一化`
- choice：`path` 判空后 `include "base.path" (list $path "rel")`；随后若结果等于 `.`、等于 `..` 或以 `../` 开头则中断，失败消息携带归一化结果；绝对路径由 `base.path` 自行中断，本层不拦截。
- rationale：`base.path` 的 `rel` 模式已实现 `trim | clean` 与绝对路径拒绝，是项目现有唯一的路径归一化能力，`base.fileRefs` 的 `filePath` 校验也采用同一组合；`clean` 消解 `.` 与内部 `..`，但会保留前导 `..` 并把 `a/..` 归一为 `.`，因此逃逸与卷根目录两种结果必须由调用方补充判断。绝对路径保留 `base.path` 自身消息，与 `definitions.localObjectReference` 对 `base.rfc` 的用法一致。

### Decision: optional 用 base.get 原始输出的引号形态区分原生布尔与字符串

- requirements：`字段渲染顺序与类型`、`optional 只接受原生布尔值`
- choice：`optional` 以 `base.get` 取值并 `trim`；非空时，若 `SYS.YAML_QUOTED` 命中（说明原值是字符串）或值不是 `true`/`false`，则以 `[definitions.fileKeySelector] optional: must be boolean` 中断；否则交给 `base.bool` 并以 `base.bool` 渲染。
- rationale：`base.get` 返回 YAML 文本，原生布尔序列化为裸 `true`/`false`，字符串 `"true"` 会序列化为带引号形态，用既有 `SYS.YAML_QUOTED` 即可区分，无需绕过取值层直接读原生值；该模式与 `definitions.configMapKeySelector` 保持一致。

### Decision: 父级 fileKeyRef 必需段数改为 3

- requirements：`父级必需段数修正`
- choice：把 `templates/api-resources/Definitions/_EnvVarSource.tpl` 配置表中 `fileKeyRef` 的 `required` 从 `2` 改为 `3`。
- rationale：本能力要求 `volumeName`、`path`、`key` 同时非空，两段字符串必然产生缺 `key` 的上下文；在组装前拒绝比依赖子模板报错更符合「尽早报错」，且改动只涉及该配置项的一个数值。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, 点分路径]`；本能力使用 `key`、`optional`、`path`、`volumeName` 四条单层路径，不传强制类型与必填参数。
- output：YAML 字符串；路径缺失时为空输出。
- ownership：取值与别名识别由 `base.get` 负责；必填判空、类型判定与失败消息由本能力负责。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 的原始输出，不得预先 trim。
- output：解码后的 string；空输入返回空字符串；非 string 标量中断。
- ownership：YAML 标量还原与类型失败由该模板负责；本能力只消费结果并判空。

### Dependency: `base.path`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：`list [路径, "rel"]`。
- output：`trim | clean` 归一化后的相对路径；绝对路径中断。
- ownership：归一化与绝对路径拒绝由该模板负责；`.`、`..` 与 `../` 前缀三种结果的拒绝与最终输出由本能力负责。

### Dependency: `base.bool`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：原生 bool，或字面量字符串 `"true"` / `"false"`。
- output：布尔字符串；其他输入中断。
- ownership：布尔语义与输出由该模板负责；输入是否为原生布尔由本能力前置判定。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 值, 渲染模板]`；`key`、`path`、`volumeName` 使用 `quote`，`optional` 使用 `base.bool`。
- output：单字段 YAML 片段，空值不输出。
- ownership：渲染格式与引号由该模板负责；字段生效判断由本能力负责。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：占位空字符串，经 `fromYaml` 恢复常量 Map。
- output：常量 Map；本能力只读取 `SYS.YAML_QUOTED`。
- ownership：常量定义与结构有效性由该模板负责；本能力不得内联或改写该表达式。

## 代码边界

### `templates/api-resources/Definitions/_FileKeySelector.tpl`

- access：`write`
- operations：add `definitions.fileKeySelector`
- writable-scopes：整个新建文件

### `templates/api-resources/Definitions/_EnvVarSource.tpl`

- access：`write`
- operations：update `fileKeyRef` 配置项的 `required` 值 `2` → `3`
- writable-scopes：`$sources` 列表中 `fileKeyRef` 条目的 `required` 数值

## 验证设计

- 最小有效：真实 `templates/base/` 与 `_FileKeySelector.tpl` 加载到 `/tmp/` 最小 application Chart，输入 `key`、`path`、`volumeName`，断言三个字段均以双引号输出且无 `optional`。
- 较完整有效：四字段齐全时按 `key`、`optional`、`path`、`volumeName` 顺序输出；`optional: false` 仍输出；含额外键时只输出四个官方字段；`path` 为 `logs/./app.log` 输出 `logs/app.log`，`a/../b` 输出 `b`。
- 关键失败：`volumeName`、`path`、`key` 各自缺失与为空白、`path` 为 `/etc/app.log`、`path` 为 `../app.log`、`path` 为 `..`、`path` 为 `.`、`path` 为 `a/..`、`optional` 为字符串 `"true"`、`optional` 为数字，均中断；除绝对路径由 `base.path` 给出消息外，其余消息含对应字段名或归一化结果。
- 父级回归：加载真实 `_EnvVarSource.tpl`，`fileKeyRef` 为 `env-vol app.log` 时不组装该字段且输出为空，为 `env-vol app.log LOG_LEVEL` 时组装并委托本能力。
- fixture 边界：`definitions.envVarSource` 为真实实现，无需 fixture；本次不涉及未实现的其它选择器子模板。
