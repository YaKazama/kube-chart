# 新增 definitions.sleepAction 设计

## 技术目标

- capability：`definitions.sleepAction`
- artifact-type：Kubernetes 共享结构模板
- target：`templates/api-resources/Definitions/_SleepAction.tpl`

## 设计决策

### Decision: 以 base.get 取值并经 fromYaml 回读归一

- requirements：`SleepAction 片段渲染`
- choice：使用 `base.get` 取得 `seconds`，用 `fromYaml` 包装回读恢复原生类型后再做类型、整值与范围判断。
- rationale：`helm-templates.md` 要求多层字段统一使用 `base.get`，取值入口不得绕开。实测 Helm 4.3.2 下 `base.get` 会把 float64 序列化为 `1.2345678e+07`、`9.007199254740991e+15` 等科学计数法文本，直接交给 `base.int` 会中断，因此瓶颈在归一而非取值：包装回读是仓库既有的原生类型恢复手法，同目录 `_Sysctl.tpl` 亦按此处理。

### Decision: 在 float64 域完成整值与闭区间校验

- requirements：`非法输入中断`
- choice：先用 `kindOf` 把入参限定为 int、int64、float64，再统一转为 float64，依次执行整值校验与 `[1, 9007199254740991]` 闭区间校验，闭区间校验的返回值显式丢弃，通过后用 `int` 归一渲染。
- rationale：数值比较必须在同一类型下进行（实测 int 与 float64 直接比较会报 incompatible types），故先统一为 float64；`base.int.range` 的返回值是十进制文本，对 `9.007199254740991e+15` 这类取值再转 int 会得到 0，因此只取它的校验副作用；上限以内的整值在 float64 下可精确表示，超出上限的取值不会因舍入跌破上限。`base.int` 对 float64 四舍五入、`base.int.positive` 会截断小数并接受字符串，均不能用作本字段的类型门禁。

### Decision: 缺失、null 与空字符串统一为空输出

- requirements：`缺失与空值不渲染`
- choice：取值经缺失、`null`、空字符串判定后直接结束本模板，不产生任何输出，也不触发类型或范围校验。
- rationale：规格要求这三种输入等价且不中断；三者都不属于整数语义输入，跳过校验可避免把“未设置”误报为类型错误。

## 依赖契约

### Dependency: `base.get`

- availability：existing
- source：`templates/base/_get.tpl`
- operation：consume
- input：`list [上下文, "seconds"]`，使用默认别名识别与默认合并模式。
- output：可由 `fromYaml` 解析的 YAML 字符串；缺失、`null` 与空字符串均返回空输出，float64 可能以科学计数法文本呈现。
- ownership：`base.get` 负责取值、数据源优先级与同级 `secondsAlias` 识别；本模板负责把返回文本回读为原生类型，并承担后续类型、整值与范围判断。

### Dependency: `base.isFromYamlError`

- availability：existing
- source：`templates/base/_convert.tpl`
- operation：consume
- input：`fromYaml` 的恢复结果，任意类型。
- output：布尔字符串；仅当结果为包含 `Error` 键的 map 时返回 `true`。
- ownership：`base.isFromYamlError` 负责识别 Helm 的 YAML 解析错误形态；本模板负责在识别到错误时中断渲染。

### Dependency: `base.field`

- availability：existing
- source：`templates/base/_field.tpl`
- operation：consume
- input：`list [key, value, render template]`，key 为 `seconds`，value 为已归一化的 int，render template 为 `base.int`。
- output：单行 YAML 键值对；value 渲染为空时不输出字段。
- ownership：`base.field` 负责键名拼接与最终渲染；本模板负责调用前的存在性、类型、整值与范围校验，只在字段生效时调用。

### Dependency: `base.int`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：int、int64、float64 或整数格式字符串。
- output：十进制数字字符串；非法类型中断。
- ownership：`base.int` 负责数值到十进制文本的格式化与类型门禁；本模板已保证入参为 int，故不再依赖其浮点与字符串分支语义。

### Dependency: `base.int.range`

- availability：existing
- source：`templates/base/_validate.tpl`
- operation：consume
- input：`list [num, min, max]`，三值形式按闭区间校验，三个元素均为数值类型；本模板统一传入 float64。
- output：校验通过的数值文本；越界时以 `[base.int.range]` 前缀中断。
- ownership：`base.int.range` 负责闭区间比较与越界中断；本模板只使用其校验副作用并显式丢弃返回值，渲染值由自身归一结果提供。

## 代码边界

### `templates/api-resources/Definitions/_SleepAction.tpl`

- access：`write`
- operations：`add`
- writable-scopes：整个新增文件，包括 `definitions.sleepAction` 的命名模板契约注释与 `define` 块。

### `templates/api-resources/Definitions/_LifecycleHandler.tpl`

- access：`read`
- operations：`consume`

## 验证设计

- 最小有效场景：`/tmp/` fixture Chart 加载 `definitions.sleepAction` 与 `base/`，以 `seconds: 30` 渲染出 `seconds: 30`。
- 较完整有效场景：int64 入参、`30.0`、取值 12345678 的 float64 与上限 9007199254740991 均按 integer 输出。
- 静默场景：`seconds` 缺失、为 `null`、为空字符串时模板输出为空内容且不中断。
- 关键失败场景：0、-1、9007199254740992、`"30"`、true、list、map 与 3.7 均在 `/tmp/` fixture 中中断。
- 集成场景：经 `definitions.lifecycleHandler` 的 `sleep` 委托时输出 `sleep` 字段片段。
