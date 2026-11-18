# definitions.lifecycleHandler 设计

## 技术目标

- capability：`definitions.lifecycleHandler`
- artifact-type：Helm library 命名模板
- target：`templates/api-resources/Definitions/_LifecycleHandler.tpl` 中的 `definitions.lifecycleHandler`

## 设计决策

### Decision: 单动作检测与分派

- requirements：`单动作输入与动作选择`
- choice：按 `exec`、`httpGet`、`sleep`、`tcpSocket` 的固定顺序检查 `hasKey`，收集存在的动作键；仅当数量为 1 时继续，并使用同一动作键映射到对应子模板名。
- rationale：动作按 key 是否存在判定，能保留 `0`、空字符串、空数组和空 map；数量不为 1 时立即中断，避免多动作歧义。

### Decision: 原生与抽象按运行时类型分支

- requirements：`原生 map 直接委托`、`抽象 exec 与 sleep 解析`、`抽象 httpGet 解析`、`抽象 tcpSocket 解析`
- choice：动作值为 map 时按原生结构原样传递；`exec` 的 slice 视为抽象 string array；`httpGet` 与 `tcpSocket` 的 string 视为抽象简写；`sleep` 的整数视为抽象 integer；其余类型中断。
- rationale：同一动作键的 map 与简写值可由类型唯一区分，无需额外模式开关。

### Decision: 抽象字段解析

- requirements：`抽象 exec 与 sleep 解析`、`抽象 httpGet 解析`、`抽象 tcpSocket 解析`
- choice：在 `base.env` 的 `K8S.LIFECYCLE_HANDLER` 下新增 `HTTP_GET` 与 `TCP_SOCKET` 两个位置捕获正则；先整体匹配，再以 `$1` 起的捕获组取值，未匹配组为空字符串。`exec` 生成 `command`，`sleep` 生成 `seconds`；`httpGet` 将 `schema` 映射为 `scheme`，并将 `headers` 括号内容先用 `SPLIT.COMMA` 分成逗号组，再在每个逗号组内用 `SPLIT.SPACE_COMMA` 分词，每两个 token 组成一个 `name value` 字符串放入 `httpHeaders`；`tcpSocket` 生成 `host` 与 `port`。
- rationale：与现有正则集中管理和位置捕获模式一致；`headers` 只拆成 string array，不侵入孙模板职责。

### Decision: 子模板委托与错误保护

- requirements：`子模板上下文与输出`
- choice：以构造后的 map 调用子模板，使用 `fromYaml` 恢复返回结果，并以 `base.isFromYamlError` 排除解析错误；非空结果通过 `base.field` 与 `base.map` 以动作键输出。四个动作类型的官方字段顺序均为字母序，与 `base.map` 的序列化顺序一致，不另建排序逻辑。
- rationale：保持所有子模板上下文为 map，并复用现有 YAML 解析保护和 map 渲染边界。

### Decision: 未实现子模板的验证边界

- requirements：`子模板上下文与输出`
- choice：四个动作子模板在当前 Chart 中不存在且不在本 change 创建；验证 fixture 提供同名 stub，只证明本模板的解析、分派和调用契约。
- rationale：draft 明确要求子模板只占位、不创建；fixture 结果不得表述为真实子模板集成通过。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`update`
- input：空字符串 `""`
- output：经 `fromYaml` 恢复的常量 map；复用现有 `SPLIT.COMMA` 与 `SPLIT.SPACE_COMMA`，新增 `K8S.LIFECYCLE_HANDLER.HTTP_GET` 与 `K8S.LIFECYCLE_HANDLER.TCP_SOCKET` 两个 string 正则。
- ownership：`base.env` 负责常量定义；`definitions.lifecycleHandler` 只读取并使用这些常量。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值
- output：字符串 `"true"` 或 `"false"`
- ownership：基础模板负责识别 Helm YAML 解析错误；调用方负责在错误时终止。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [动作键, 子模板输出 map, "base.map"]`
- output：YAML 字段片段；值为空时不输出
- ownership：基础模板负责单字段渲染；调用方负责键名、值和渲染模板选择。

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：map
- output：YAML map 文本；非 map 中断
- ownership：基础模板负责 map 类型门禁与序列化；调用方负责传入已恢复的 map。

### Dependency: `definitions.execAction`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：map；原生输入原样传递，抽象输入至少包含 `command` string array
- output：可解析为 map 的 YAML 字段片段
- ownership：子模板负责 `command` 渲染；本模板只负责动作分派与抽象值解析。

### Dependency: `definitions.httpGetAction`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：map；原生输入原样传递，抽象输入包含 `host`、`httpHeaders`、`path`、`port`、`scheme`，缺少 headers 时不设置 `httpHeaders`
- output：可解析为 map 的 YAML 字段片段
- ownership：子模板负责字段渲染及 `httpHeaders` 到 `definitions.httpHeader` 的进一步解析；本模板只负责位置解析和 string array 构造。

### Dependency: `definitions.sleepAction`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：map；原生输入原样传递，抽象输入至少包含 `seconds` integer
- output：可解析为 map 的 YAML 字段片段
- ownership：子模板负责 `seconds` 渲染；本模板只负责动作分派与抽象值映射。

### Dependency: `definitions.tcpSocketAction`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：map；原生输入原样传递，抽象输入包含 `host` 与 `port`
- output：可解析为 map 的 YAML 字段片段
- ownership：子模板负责 `host`、`port` 渲染；本模板只负责位置解析和 map 构造。

## 代码边界

### `templates/base/_env.tpl`

- access：`write`
- operations：`add` `K8S.LIFECYCLE_HANDLER.HTTP_GET` 与 `K8S.LIFECYCLE_HANDLER.TCP_SOCKET`
- writable-scopes：`K8S.LIFECYCLE_HANDLER` 子树

### `templates/api-resources/Definitions/_LifecycleHandler.tpl`

- access：`write`
- operations：`add` `definitions.lifecycleHandler`
- writable-scopes：整个新文件

### `templates/api-resources/Definitions/_Lifecycle.tpl`

- access：`read`
- operations：`consume` 既有 `definitions.lifecycleHandler` 调用边界

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` `base.isFromYamlError`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.map`

## 验证设计

- fixture：在 `/tmp/` 最小 application Chart 中加载 `_env.tpl` 与 `_LifecycleHandler.tpl`，并以同名 stub 提供四个 unavailable 子模板；fixture 只证明本模板行为和调用边界。
- 最小有效：分别渲染单个原生 `sleep` 与 host 缺省的抽象 `tcpSocket`，确认动作键、map 上下文和空字符串位置。
- 较完整有效：覆盖原生四动作、抽象 `exec`、完整 `httpGet`、完整 `tcpSocket`、空格与逗号混合的 headers、尾部位置缺省、`httpHeaders` 直传与构造、`sleep: 0`。
- 关键失败：零动作、多动作、错误值类型、逗号组内奇数 header token、子模板返回非法 YAML，均须使 `helm template` 非零退出。
