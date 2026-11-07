# fix-kindis-check 设计

## 技术目标

- capability：`apps.deploymentSpec`、`base.labels`
- artifact-type：命名模板内部判断修正
- target：`templates/api-resources/Apps/_DeploymentSpec.tpl` 的 `apps.deploymentSpec` 与 `templates/base/_k8s.tpl` 的 `base.labels`

## 设计决策

### Decision: strategy 分支删除重复类型判断

- requirements：`NO SPEC DELTA`（受影响能力 `apps.deploymentSpec`）
- choice：`apps.deploymentSpec` 中保留 `$_strategyIsError := eq (include "base.isFromYamlError" $_strategyParsed) "true"`，把 `if and (not $_strategyIsError) (kindIs "map" $_strategyParsed)` 改为 `if not $_strategyIsError`；`else` 分支与后续归一化逻辑不变。
- rationale：`fromYaml` 成功即保证结果是 map，`$_strategyIsError` 为假时 `kindIs "map"` 恒真；删除后分支可达性与字符串简写回退完全不变。

### Decision: rollingUpdate 分支保留类型门禁

- requirements：`NO SPEC DELTA`（受影响能力 `apps.deploymentSpec`）
- choice：`rollingUpdate` 分支的 `if or (eq (include "base.isFromYamlError" $strategyRollingUpdate) "true") (not (kindIs "map" $strategyRollingUpdate))` 保持原样。
- rationale：该 `kindIs` 与错误 helper 同处一个 `or` 并共同触发同一 `fail`，表达的是“解析失败或结构非 map 即失败”的单一目标类型门禁，删除会改变失败路径的表达方式且不属于本次声明的重复判断模式。

### Decision: base.labels 删除两处重复类型判断

- requirements：`NO SPEC DELTA`（受影响能力 `base.labels`）
- choice：`base.labels` 中的 `customLabels` 与 `helmLabels` 两处 `if and $parsed (eq (include "base.isFromYamlError" $parsed) "false") (kindIs "map" $parsed)` 改为 `if and $parsed (eq (include "base.isFromYamlError" $parsed) "false")`，保留非空判断与错误 helper 判定。
- rationale：与 `strategy` 分支同理，错误 helper 为假时恢复结果必为 map；保留 `$parsed` 非空判断以免把空 map 并入标签集合的既有行为发生变化。

### Decision: 保留 podSpec 的多类型分支

- requirements：`NO SPEC DELTA`（受影响能力 `core.podSpec`）
- choice：`core.podSpec` 中 `os` 字段的 `else if kindIs "map" $_osParsed` 保持不变。
- rationale：该判断位于 string 与 map 两种输入形态的分支选择位置，用于区分“字符串补齐 name”与“原生对象复制”，不是错误 helper 之后的同类重复检查。

## 依赖契约

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值。
- output：布尔值，指示是否为解析错误形态。
- ownership：本 change 只消费其判定结果，不修改该能力实现。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文> <点分路径>`。
- output：可 `fromYaml` 解析的 YAML 字符串。
- ownership：本 change 不修改该能力，只在 `base.labels` 与 `apps.deploymentSpec` 既有调用点保持入参不变。

### Dependency: `base.name`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：上下文 map。
- output：资源名称字符串。
- ownership：`base.labels` 内部继续调用，行为不变。

### Dependency: `base.helmLabels`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：上下文 map。
- output：可 `fromYaml` 解析的标签 YAML 字符串。
- ownership：`base.labels` 内部继续调用，输入与空值边界不变。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list <键名> <已归一化值> [渲染模板] [允许值列表]`。
- output：YAML 键值片段。
- ownership：本 change 不修改调用方式与传入值。

### Dependency: `apps.deploymentStrategy`

- availability：`existing`
- source：`templates/api-resources/Apps/_DeploymentStrategy.tpl`
- operation：`consume`
- input：已归一化的 DeploymentStrategy map。
- output：可 `fromYaml` 解析的 DeploymentStrategy YAML 片段。
- ownership：`apps.deploymentSpec` 的委托输入与空输出失败边界保持不变。

### Dependency: `core.podTemplateSpec`

- availability：`existing`
- source：`templates/api-resources/Core/_PodTemplateSpec.tpl`
- operation：`consume`
- input：父级透传的上下文 map。
- output：可 `fromYaml` 解析的 PodTemplateSpec YAML 片段。
- ownership：本 change 不修改其调用方式。

## 代码边界

### `templates/api-resources/Apps/_DeploymentSpec.tpl`

- access：`write`
- operations：`update` `define "apps.deploymentSpec"` 内 `strategy` 字段的 map 分支条件，删除与 `$_strategyIsError` 重复的 `kindIs "map"`。
- writable-scopes：`define "apps.deploymentSpec"` 中 `strategy` 字段处理的 `if and (not $_strategyIsError) ...` 单行条件。

### `templates/base/_k8s.tpl`

- access：`write`
- operations：`update` `define "base.labels"` 内 `customLabels` 与 `helmLabels` 两处条件，删除与错误 helper 重复的 `kindIs "map"`。
- writable-scopes：`define "base.labels"` 中 `$_clParsed` 与 `$_hlOutParsed` 两处 `if and ...` 单行条件。

### `templates/base/_convert.tpl`

- access：`read`
- operations：读取 `base.isFromYamlError` 的解析错误识别契约。

### `templates/base/_get.tpl`

- access：`read`
- operations：读取 `base.get` 的返回值形态与空输出约定。

### `templates/base/_field.tpl`

- access：`read`
- operations：读取 `base.field` 的参数契约与空结果省略行为。

### `templates/api-resources/Apps/_DeploymentStrategy.tpl`

- access：`read`
- operations：读取 `apps.deploymentStrategy` 的入参与返回边界。

### `templates/api-resources/Core/_PodTemplateSpec.tpl`

- access：`read`
- operations：读取 `core.podTemplateSpec` 的调用契约。

## 验证设计

- 基线对比：在 `/tmp/` 最小 application Chart 中，用同一组输入分别在修改前与修改后渲染 `apps.deploymentSpec` 与 `base.labels`，逐字段比对输出完全一致。
- `apps.deploymentSpec` 覆盖：`strategy` 为 map 形态、字符串简写形态、`null`、非法标量四类输入，验证输出与失败消息不变。
- `base.labels` 覆盖：仅自定义 `labels`、仅 `helmLabels`、两者同时存在、`justNameLabel=true`、`labels` 为非 map 标量五类输入，验证合并结果与保底 `name` 标签不变。
- 残留检查：对 `templates/` 下全部 `*.tpl` 重新执行错误 helper 之后的同类 `kindIs` 扫描，确认剩余命中为已声明保留项。
- 静态检查：修改文件无冲突标记、无行尾空白、末尾单换行。
- fixture 边界：`base.labels` 依赖 `base.name` 与 `base.helmLabels` 均为真实实现；`apps.deploymentSpec` 的 `core.podTemplateSpec` 与 `apps.deploymentStrategy` 若在测试 Chart 中不可用，使用同名最小 fixture，结论只证明本次改动不改变调用输入。
