# definitions.downwardAPIProjection 设计

## 技术目标

- capability：`definitions.downwardAPIProjection`
- artifact-type：Helm 命名模板
- target：`definitions.downwardAPIProjection`

## 设计决策

### Decision: 单字段直接渲染

- requirements：`渲染 items 字段`
- choice：只读取 `items`，完成数组解析与委托后直接调用渲染入口，不保留片段变量；其他输入键静默忽略。
- rationale：官方仅定义 `items` 一个字段，处理顺序与输出顺序一致，无需中间片段。

### Decision: items 委托与结果收敛

- requirements：`items 委托、去重与去空`
- choice：`items` 经 `base.get` 取值并用 `fromYamlArray` 恢复；每个原生 map 条目委托 `definitions.downwardAPIVolumeFile`，对输出做 YAML 错误保护，空结果剔除，非空结果按渲染内容 `mustUniq` 去重；最终为空时省略。
- rationale：draft 要求逐项委托、回收结果去重去空；子模板已具备 DownwardAPIVolumeFile 字段校验，父模板不重复实现其内部结构。

### Decision: 统一字段渲染入口

- requirements：`渲染 items 字段`
- choice：`items` 使用 `base.field` 的 `base.slice` 渲染模板。
- rationale：工程规则要求统一使用 `base.field` 并按字段真实类型选择渲染模板。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, 点分路径]`
- output：YAML 字符串；无命中时为空输出，不抛出类型错误
- ownership：数据源与别名回溯由依赖负责；本模板只负责数组解析、条目判定与输出

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

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 值, "base.slice"]`
- output：YAML 键值片段；渲染结果为空时不输出
- ownership：缩进与渲染模板分派由依赖负责；字段生效条件由本模板负责

### Dependency: `definitions.downwardAPIVolumeFile`

- availability：`existing`
- source：`templates/api-resources/Definitions/_DownwardAPIVolumeFile.tpl`
- operation：`consume`
- input：原生 DownwardAPIVolumeFile map，`path` 必填，`fieldRef` 与 `resourceFieldRef` 二选一
- output：DownwardAPIVolumeFile YAML 字段片段；非法输入中断
- ownership：`fieldRef`、`resourceFieldRef`、`mode`、`path` 的取值、归一化与校验由依赖负责；本模板只负责数组解析、逐项委托、空结果剔除、去重与片段嵌入

## 代码边界

### `templates/api-resources/Definitions/_DownwardAPIProjection.tpl`

- access：`write`
- operations：`add` `define "definitions.downwardAPIProjection"` 及紧邻中文契约注释
- writable-scopes：`define "definitions.downwardAPIProjection"` 整个定义块

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume` `base.get`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` `base.isFromYamlError`、`base.isFromYamlArrayError`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.slice`

### `templates/api-resources/Definitions/_DownwardAPIVolumeFile.tpl`

- access：`read`
- operations：`consume` `definitions.downwardAPIVolumeFile`

## 验证设计

- 空输入：`{}` 与 `{items: []}`，预期模板输出为空。
- 最小有效输入：`{items: [{path: "meta/name", fieldRef: "metadata.name"}]}`，预期输出一个 `items` 条目。
- 较完整有效输入：`{items: [{path: "meta/name", fieldRef: "metadata.name"}, {path: "meta/name", fieldRef: "metadata.name"}]}`，预期 `items` 去重后仅一个条目。
- 关键失败：`items` 非 array、条目非 map、条目缺少 `fieldRef`/`resourceFieldRef`、`path` 为绝对路径或逃逸路径、`fieldRef` 类型非法。
- 空结果剔除：真实 `definitions.downwardAPIVolumeFile` 对合法输入不产生空输出，该分支按父模板容错实现，不单独作为真实依赖集成场景。
- 依赖边界：全部依赖为真实模板，在 `/tmp/sd-kube-chart/` 最小 Chart 中加载真实实现，不使用同名 fixture。
