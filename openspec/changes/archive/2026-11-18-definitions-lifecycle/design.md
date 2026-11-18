# definitions.lifecycle 生命周期模板设计

## 技术目标

- capability：`definitions.lifecycle`
- artifact-type：Helm library Chart 命名模板
- target：`templates/api-resources/Definitions/_Lifecycle.tpl`

## 设计决策

### Decision: 独立 Lifecycle 模板

- requirements：`生命周期 Handler 委托`、`stopSignal 校验与渲染`
- choice：新增 `_Lifecycle.tpl`，只定义 `definitions.lifecycle`；不定义 `definitions.lifecycleHandler`。
- rationale：规格要求 Handler 由外部模板处理，本模板只负责当前层字段。

### Decision: Handler 统一委托

- requirements：`生命周期 Handler 委托`
- choice：用同一个有序循环处理 `postStart` 和 `preStop`；每项完成 YAML map 恢复与错误保护后，将 map 原样传给 `definitions.lifecycleHandler`，回收非空结果并以 `base.map` 渲染。
- rationale：规格要求两个字段复用同一子模板、不得复制处理逻辑，并保持原生 map 与抽象结构不归一化。

### Decision: stopSignal 本地校验

- requirements：`stopSignal 校验与渲染`
- choice：先归一化并去除 `stopSignal` 首尾空白；仅当 `stopSignal` 存在时再归一化并去除 `os.name` 首尾空白，要求其非空，再通过 `base.field` 的允许值列表执行大小写敏感校验并输出。
- rationale：规格要求 `stopSignal` 在本模板校验和渲染，且仅适用于非空 `.spec.os.name`。

### Decision: 父模板注入 os

- requirements：`stopSignal 校验与渲染`
- choice：为 `definitions.container.struct` 增加可选 `extra` map，将 `extra` 深拷贝后与解析出的子模板上下文合并且 `extra` 优先；`definitions.container` 调用该辅助模板渲染 lifecycle 时传入同源 `os`。
- rationale：规格要求 lifecycle 获取同一 Pod 的 `os`，同时复用既有对象字段的解析、错误保护和渲染闭环。

## 依赖契约

### Dependency: `definitions.lifecycleHandler`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：单个 lifecycle Handler map，可包含 `exec`、`httpGet`、`sleep`、`tcpSocket`。
- output：可解析为 map 的 YAML 字符串；无有效内容时为空字符串；失败时保留自身错误并中断。
- ownership：外部模板负责 Handler 内部结构、孙模板调用和结果渲染；本模板只原样传递 Handler map 并回收非空结果。当前 Chart 未定义该模板，本 change 不创建。

### Dependency: `definitions.container`

- availability：`existing`
- source：`templates/api-resources/Definitions/_Container.tpl`
- operation：`update`
- input：Container 字段 map，包含 lifecycle 原始字段与同源 `os`。
- output：Container YAML 字段片段。
- ownership：`definitions.container` 负责把同源 `os` 注入 lifecycle 上下文；`definitions.lifecycle` 负责 lifecycle 字段校验和输出。

### Dependency: `definitions.container.struct`

- availability：`existing`
- source：`templates/api-resources/Definitions/_Container.tpl`
- operation：`update`
- input：`key`、`define`、`raw`，以及可选的 `extra` map。
- output：单字段 YAML 片段；无有效内容时为空字符串。
- ownership：辅助模板负责解析、合并 `extra`、调用子模板和错误保护；调用方负责提供需要注入的 map。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list` 形式的上下文、点分路径及可选参数。
- output：YAML 字符串。
- ownership：只负责取值、别名识别与序列化，不定义 lifecycle 字段语义。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list` 形式的键名、值、渲染模板和允许值列表。
- output：YAML 键值片段；渲染结果为空时不输出。
- ownership：负责最终渲染与允许值校验，不负责取值和字段生效判断。

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：map。
- output：YAML map 字符串；非 map 时中断。
- ownership：只执行 map 类型校验与序列化。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：YAML 标量文本。
- output：解码后的 string；非 string 标量或非法文本时中断。
- ownership：只做标量解码，不执行字段枚举校验。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值。
- output：表示是否为解析错误的布尔字符串。
- ownership：只识别 Helm 的 YAML 错误 map，不解析错误内容。

## 代码边界

### `templates/api-resources/Definitions/_Lifecycle.tpl`

- access：`write`
- operations：`add definitions.lifecycle`
- writable-scopes：新文件全部内容

### `templates/api-resources/Definitions/_Container.tpl`

- access：`write`
- operations：`update definitions.container lifecycle delegation`、`update definitions.container.struct extra merging`、`update related contract comments`
- writable-scopes：`definitions.container` 的 lifecycle 委托区段；`definitions.container.struct` 的入参、合并逻辑、整体契约注释和示例；文件头部 lifecycle 相关行为与边界说明

### `templates/api-resources/Core/_PodSpec.tpl`

- access：`read`
- operations：`confirm core.podSpec injects os into definitions.container`

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume base.get`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume base.field`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume base.map`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume base.string.normalize`、`consume base.isFromYamlError`

## 验证设计

- 最小有效场景：在 `/tmp/` 最小 application Chart 中提供 `definitions.lifecycleHandler` fixture；直接渲染包含 `postStart` 和非空 `preStop` 的 lifecycle，并让 fixture 对 `preStop` 返回空结果，确认只输出 `postStart`。
- 较完整有效场景：通过真实 `core.podSpec` 和 `definitions.container` 渲染同时包含 `postStart`、`preStop` 和合法 `stopSignal` 的容器，PodSpec 提供 `os.name: linux`；确认三个字段均输出，证明父模板 `os` 注入有效。
- 关键失败场景：同一 fixture 下分别验证 `stopSignal` 缺少 `os.name`、`stopSignal` 大小写不匹配、`postStart` 不是 map；确认 `helm template` 非零退出。
- 依赖边界：`definitions.lifecycleHandler` 为 `/tmp/` fixture，只能证明 lifecycle 委托与回收行为；`definitions.container`、`base.*` 使用真实模板。
