# definitions.execAction 设计

## 技术目标

- capability：`definitions.execAction`
- artifact-type：Helm library 命名模板
- target：`templates/api-resources/Definitions/_ExecAction.tpl` 中的 `definitions.execAction`

## 设计决策

### Decision: command 取值与必填校验

- requirements：`command 输入与校验`
- choice：通过 `base.get` 的默认别名模式读取 `command`；不使用 `required` 模式，以便区分缺失与空 array。原始结果 trim 后为空时中断，非空时用 `fromYamlArray` 恢复并以 `base.isFromYamlArrayError` 排除解析错误。
- rationale：`base.get` 的 required 模式会把空 array 视为缺失，无法满足“空 command 不渲染”；别名行为沿用 `base.get` 的默认契约。

### Decision: command 元素校验与渲染

- requirements：`command 输入与校验`、`command 输出`
- choice：逐项检查恢复后的 array，任一元素不是 string 时中断；array 为空时不调用 `base.field`，非空时仅以 `base.field` 和 `base.slice` 输出 `command`。
- rationale：`base.slice` 只序列化 array，不拆分或清洗元素，能够保持 string 原值和顺序。

### Decision: 单字段输出边界

- requirements：`command 输出`
- choice：模板只调用一次 `base.field` 输出 `command`，不输出任何其他字段。
- rationale：ExecAction 在本 change 中只负责 `command`，其他 LifecycleHandler 结构由上层模板处理。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, "command", "", "", false]`
- output：YAML 字符串；缺失时为空字符串，空 array 时返回可解析的空 array
- ownership：`base.get` 负责取值和 YAML 序列化；调用方负责区分缺失与空 array，并执行中断判断。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 返回值
- output：字符串 `"true"` 或 `"false"`
- ownership：基础模板负责识别 array 解析错误；调用方负责在错误时终止。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list ["command", 已验证的 string array, "base.slice"]`
- output：YAML 字段片段；渲染结果为空时不输出
- ownership：基础模板负责字段渲染；调用方负责字段生效判断和元素校验。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：string array
- output：YAML array；非 array 输入中断
- ownership：基础模板负责 array 序列化；调用方负责以 `base.field` 选择该渲染模板。

## 代码边界

### `templates/api-resources/Definitions/_ExecAction.tpl`

- access：`write`
- operations：`add` `definitions.execAction`
- writable-scopes：整个新文件

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume` `base.get`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` `base.isFromYamlArrayError`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.slice`

### `templates/api-resources/Definitions/_LifecycleHandler.tpl`

- access：`read`
- operations：`consume` 既有 `definitions.execAction` 调用边界

## 验证设计

- 在 `/tmp/` 最小 application Chart 中加载 `_ExecAction.tpl` 及上述真实基础依赖，不提供未实现子模板 stub。
- 最小有效：单个字符串 `command` 成功渲染，输出仅包含 `command`。
- 较完整有效：多元素 `command` 包含空格、逗号与空字符串，确认元素不拆分、顺序和内容保持不变；空 array 不产生输出。
- 关键失败：`command` 缺失、`command` 不是 array、存在非 string 元素时均须使 `helm template` 非零退出。
