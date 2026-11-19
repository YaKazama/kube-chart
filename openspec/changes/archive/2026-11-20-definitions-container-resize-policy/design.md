# definitions.containerResizePolicy 设计

## 技术目标

- capability：`definitions.containerResizePolicy`
- artifact-type：`Helm named template`
- target：`definitions.containerResizePolicy`

## 设计决策

### Decision: 上下文双形态分派与字段归一化

- requirements：`输入形态与位置解析`、`map 上下文`
- choice：入参先按 `kindOf` 分派：`string` 进入位置拆分，`map` 进入逐字段取值，其他类型以 `[definitions.containerResizePolicy] input: must be string or object type` 中断。map 分支用 `base.get` 取 `resourceName` 与 `restartPolicy`，再经 `base.string.normalize` 解码并 `trim`；只读取这两个键，其他键自然不参与。两个分支归一为同一组 `$resourceName`、`$restartPolicy`，共用单一校验与渲染块。
- rationale：`_Container.tpl` 的 `resizePolicy` 一直声明逐项委托本模板，`definitions.container.array` 的 map 元素以该 map 作为子模板上下文，map 形态是该调用契约的必要能力；两分支只做取值差异，校验与输出不重复实现。map 分支不遍历键，因此「接受任意键」无需额外逻辑。

### Decision: 位置拆分复用 SPLIT.SPACE_COMMA

- requirements：`输入形态与位置解析`
- choice：string 分支用 `mustRegexSplit $const.SPLIT.SPACE_COMMA (trim .) -1` 拆分，不剔除空段；段数多于 2 时以 `[definitions.containerResizePolicy] input: …` 中断；否则按索引取第 1 段为 `$resourceName`、第 2 段（存在时）为 `$restartPolicy`。
- rationale：`SPLIT.SPACE_COMMA` 的运行时表达式 `\s*[,\s]+\s*` 已表达「逗号与空白混用、连续分隔符视作一个」，与 spec 的分隔符语义完全一致，直接复用避免新增常量；`trim` 只消除整串两端空白，避免边界空白产生额外空段，与 `_EnvFromSource.tpl` 的既有写法一致。数组级去重与空项剔除属父模板职责，本模板不引入 `mustWithout`，空段按位置参与必填与可选项判断。

### Decision: 枚举校验复用 base.field

- requirements：`字段类型与枚举校验`
- choice：`resourceName` 以 `base.field (list "resourceName" $resourceName "quote" (list "cpu" "memory"))` 输出，`restartPolicy` 以 `base.field (list "restartPolicy" $restartPolicy "quote" (list "NotRequired" "RestartContainer"))` 输出；非枚举值由 `base.field` 中断。
- rationale：`base.field` 的允许值列表与 `quote` 可共存，一次调用同时完成大小写敏感的枚举校验与带引号输出；与 `_Container.tpl` 中 `restartPolicy`、`imagePullPolicy` 的既有写法一致。类型门禁由 `base.string.normalize` 在 map 分支完成，string 分支的段本身即 string。

### Decision: 固定顺序与逐字段直白写法

- requirements：`输出字段与顺序`
- choice：按 `resourceName`、`restartPolicy` 顺序各写一段独立闭环，不使用 `range`；`restartPolicy` 为空时跳过输出。
- rationale：该顺序与官方 `ContainerResizePolicy` 字段表一致；两个字段形态不同（必填/可选），直白展开比循环更少配置点。

### Decision: resizePolicy 调用开启 allowString

- requirements：`definitions.container 的 resizePolicy 集成`
- choice：`definitions.container` 的 `resizePolicy` 调用在既有 `definitions.container.array` 入参上追加 `"allowString" true`，并同步该字段注释；不修改 `definitions.container.array` 的实现。
- rationale：`definitions.container.array` 已具备 `allowString`（默认 `false`），`ports` 已在同一文件以相同方式开启；本 change 只需在调用处开启并更新注释。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：空字符串 `""`
- output：可由 `fromYaml` 恢复的常量 Map；使用既有 `SPLIT.SPACE_COMMA`，键值保持不变
- ownership：依赖层负责常量集中声明；本模板负责读取常量并拆分 string 上下文

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [map 上下文, 点分路径]`；路径仅为 `resourceName`、`restartPolicy`
- output：YAML 字符串；字段缺失与 `null` 返回空输出，因此本模板对必填 `resourceName` 自行判空中断
- ownership：依赖层负责上下文优先级与别名识别；本模板负责字段业务校验

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 输出的 YAML 标量文本
- output：string；非 string 标量或非法 YAML 中断
- ownership：依赖层负责标量解码与类型门禁；本模板负责 `trim` 与业务校验

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 已归一化值, "quote", 允许值列表]`
- output：YAML 键值片段；枚举参数与 `quote` 可共存，非枚举值中断
- ownership：依赖层负责最终渲染与枚举校验；本模板负责生效条件与归一化

### Dependency: `definitions.container.array`

- availability：`existing`
- source：`templates/api-resources/Definitions/_Container.tpl`
- operation：`consume`
- input：`list` 形式的 `dict`，含 `key`、`define`、`raw` 与可选 `allowString`
- output：与既有相同；`allowString=true` 时 string 元素放行，非 map 非 string 元素中断
- ownership：依赖层负责数组恢复、逐项委托、空项剔除与 `base.slice` 渲染；本模板只消费其 string 放行能力，不修改该能力

### Dependency: `definitions.container`

- availability：`existing`
- source：`templates/api-resources/Definitions/_Container.tpl`
- operation：`update`
- input：上下文 map 不变
- output：与既有相同；`resizePolicy` 元素可为 string 或 map
- ownership：依赖层负责字段取值与渲染顺序；本模板只调整 `resizePolicy` 的委托参数与契约注释

## 代码边界

### `templates/api-resources/Definitions/_ContainerResizePolicy.tpl`

- access：`write`
- operations：`add definitions.containerResizePolicy`
- writable-scopes：新文件的完整内容

### `templates/api-resources/Definitions/_Container.tpl`

- access：`write`
- operations：`update definitions.container 的 resizePolicy 注释与调用参数`、`update definitions.container 整体契约注释中的数组元素类型边界描述`
- writable-scopes：`definitions.container` 中 `resizePolicy` 字段的注释与 `include` 调用行、整体契约注释中对应的 `resizePolicy` 字段说明，以及「数组字段非 array 或元素非对象时中断」一句的元素类型描述

### `templates/base/_env.tpl`

- access：`read`
- operations：`base.env`
- writable-scopes：无

### `templates/base/_get.tpl`

- access：`read`
- operations：`base.get`
- writable-scopes：无

### `templates/base/_convert.tpl`

- access：`read`
- operations：`base.string.normalize`
- writable-scopes：无

### `templates/base/_field.tpl`

- access：`read`
- operations：`base.field`
- writable-scopes：无

### `templates/base/_types.tpl`

- access：`read`
- operations：`base.string`
- writable-scopes：无

## 验证设计

- 最小有效：string `cpu` 与 map `{resourceName: cpu}`，输出只含 `resourceName`。
- 较完整有效：`cpu,NotRequired`、`memory RestartContainer`、`  cpu,, NotRequired  ` 三种分隔形态，验证连续分隔符与两侧空白；map 五键含额外 `note` 时只输出两个规范字段。
- 空段边界：`cpu,` 第 2 段为空，按未提供处理只输出 `resourceName`；`,cpu` 第 1 段为空，必填校验中断。
- 关键失败：空 string、`cpu NotRequired extra` 三段、`CPU`、`gpu`、`storage`、`notrequired`、`Always`、非 string 的 `resourceName`/`restartPolicy`、缺少 `resourceName` 的 map、非 string 非 map 上下文，均中断渲染。
- 集成：加载真实 `_Container.tpl`，验证 `resizePolicy` 的 string 简写、简写与 map 混用，以及元素为其他类型时中断。
- 依赖边界：`base.*` 与 `_Container.tpl` 均为真实实现，直接在 `/tmp/` 最小 application Chart 中加载并执行 `helm template`，不使用同名 fixture。
