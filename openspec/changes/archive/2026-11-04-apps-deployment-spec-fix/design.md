# Deployment strategy 解析修复设计

## 技术目标

- capability：`apps.deploymentSpec` 的 `strategy` 字段解析与归一化
- artifact-type：Helm 命名模板（library Chart）
- target：`templates/api-resources/Apps/_DeploymentSpec.tpl` 中的 `apps.deploymentSpec` strategy 段

## 设计决策

### Decision: string 简写单次全量匹配三槽捕获

- requirements：`strategy 多类型归一化`
- choice：分支判据为有效 map 与其余输入两路；有效 map 走 map 分支，其余输入（含 string 与原生标量文本）统一进入 string 分支，不单独区分标量来源，也不再保留按 `null` 文本判定为独立失败形态的分支。匹配前先用 `fromYaml (printf "v: %s" <文本>)` 把文本还原为 YAML 标量，取 `v` 后 `toString | trim`，得到用于匹配的原始字符串。string 分支只执行一次 `APPS.DEPLOYMENT.STRATEGY` 全量匹配，捕获组 1/2/3 依次作为 `type`、`maxSurge`、`maxUnavailable`；不匹配立即 `fail`，不再按位置二次拆分。
- rationale：三槽独立可空要求由单条正则一次性表达，避免分段匹配产生部分命中；非法长度、小数和未知类型统一表现为整体不匹配，满足规格的单一失败边界；标量与 string 在 `base.get` 输出层同为文本，单独区分类别只会增加无行为差异的分支。`base.get` 内部用 `toYamlPretty` 序列化，对以 `'` 开头的字符串改用单引号引用并双写内部引号，`SYS.YAML_QUOTED` 的单层剥离无法还原，因此改用 YAML 标量解析还原，使 `""` 与 `''` 两种空槽写法等价。

### Decision: 捕获值剥离引号后归一化

- requirements：`strategy 多类型归一化`
- choice：每个捕获组分别用 `SYS.YAML_QUOTED` 剥离外层引号并 `trim`，得到空字符串时视为空；`type` 为空则取 `RollingUpdate`，非空时按 `lower` 比较后写回官方拼写 `RollingUpdate` / `Recreate`；`maxSurge`、`maxUnavailable` 非空时写入 `rollingUpdate`，为空时不写该键；`type` 为 `Recreate` 时整体丢弃 `rollingUpdate`。
- rationale：显式 `""`、`''` 与省略在正则中同为可空槽，剥离引号后统一为空，避免在模板内为两种引号重复分支；`type` 默认值与 `Recreate` 抑制滚动参数是规格规定的可观察结果，均在归一化终点完成。

### Decision: map 分支只做容器级校验

- requirements：`strategy 多类型归一化`
- choice：map 分支用 `base.get` 分别取 `type`、`rollingUpdate`；`type` 经 `SYS.YAML_QUOTED` 剥离引号后，空或 `null` 时补充 `RollingUpdate`，非空时按大小写不敏感归并为官方拼写，其他取值原样保留；`rollingUpdate` 仅在 `type` 非 `Recreate` 时读取，非空时经 `fromYaml` 恢复后要求 `kindIs "map"`，否则 `fail`，空 map 时丢弃该键；`rollingUpdate` 内部字段以 `mustDeepCopy` 复制后原样透传。
- rationale：`rollingUpdate` 的字段语义归属孙模板，本层只承担容器类型与生效条件；大小写归并与 string 分支共用同一可观察结果，避免两条输入路径产生不同的 `type` 拼写。

### Decision: 归一化结果为空时不渲染字段

- requirements：`strategy 多类型归一化`
- choice：`strategy` 原始值缺失或为空字符串时不进入处理；string 分支归一化后 `type` 与两个滚动参数都是空字符串时，不调用子模板也不渲染 `strategy`；其余情况把归一化 map 交给 `apps.deploymentStrategy`，对返回字符串直接 `fromYaml` 恢复，仅保留空输出和 YAML 解析错误检查，最终 map 类型门禁由 `base.field` 的 `base.map` 渲染模板执行。map 分支因 `type` 恒有值，不走该抑制判定。
- rationale：规格要求全空输入复用 Kubernetes 内部默认，不输出 `strategy` 字段；判定在归一化之后执行，使三类空来源共用同一判据。

### Decision: 委托目标切换为 apps.deploymentStrategy

- requirements：`strategy 多类型归一化`
- choice：把 `include "definitions.deploymentStrategy"` 改为 `include "apps.deploymentStrategy"`，入参仍为只含 `type`、可选 `rollingUpdate` 的 map；返回边界保留空输出与 YAML 解析错误检查，失败消息前缀 `[apps.deploymentSpec]` 保持不变。
- rationale：DeploymentStrategy 属于 `apps` API 组的嵌套结构，按分层规则应由同组模板承接；该模板在本 change 中只作为 unavailable 依赖引用。

### Decision: 常量合并且移除失效键

- requirements：`strategy 多类型归一化`
- choice：把 `base.env` 的 `APPS.DEPLOYMENT.STRATEGY` 改写为 3 个捕获组的单条全量表达式，并删除已无引用的 `APPS.DEPLOYMENT.ROLLING_UPDATE`。
- rationale：正则集中管理是工程规则要求；旧表达式只有 2 个捕获组，且 `ROLLING_UPDATE` 在当前正式模板中已无引用，保留会形成第二套失效契约。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`update`
- input：空 string `""`
- output：可由 `fromYaml` 恢复的非空 YAML map；`SYS.YAML_QUOTED` 保持不变，`APPS.DEPLOYMENT.STRATEGY` 为新的非空 string，`APPS.DEPLOYMENT.ROLLING_UPDATE` 不再存在
- ownership：提供集中常量；当前模板只读取 `SYS.YAML_QUOTED` 与 `APPS.DEPLOYMENT.STRATEGY`，负责匹配、捕获与字段失败消息。运行时表达式为 `^(?:((?i:recreate|rollingupdate)|""|''))?(?:\s*[\s:,/|*^@#]+\s*|\s*)(""|''|\d+%?)?(?:\s*[\s:,/|*^@#]+\s*|\s*)(""|''|\d+%?)?$`；`_env.tpl` 源码按 YAML 双引号转义，`\s` 写作 `\\s`、`\d` 写作 `\\d`、`""` 写作 `\"\"`

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <当前上下文> "strategy"`
- output：YAML 文本；缺失或空字符串时为空输出
- ownership：提供多层取值与别名识别；当前模板负责形态分支、归一化和失败边界

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list "strategy" <归一化 map> "base.map"`
- output：字段 YAML；渲染为空时不输出
- ownership：只负责字段序列化；当前模板负责字段生效条件

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：DeploymentStrategy 子模板返回并经 `fromYaml` 恢复的值
- output：map YAML；非 map 立即失败
- ownership：执行最终 map 类型门禁；当前模板负责空值与 YAML 解析错误边界。当子模板返回 YAML list 或标量时，`fromYaml` 产生错误 map，由 `base.isFromYamlError` 先行拦截，本门禁在该路径下不被触发。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：任意 `fromYaml` 返回值
- output：string boolean，仅错误 map 返回 `"true"`
- ownership：识别 Helm YAML 错误形态；当前模板负责形态分支与类型判断

### Dependency: `apps.deploymentStrategy`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：只含 `type` 与可选 `rollingUpdate` 的非空 map，`rollingUpdate` 为 map
- output：DeploymentStrategy YAML map；空值与非法 YAML 由当前模板失败，非 map 的 YAML 输出表现为 `fromYaml` 错误 map，同样由 `base.isFromYamlError` 拦截
- ownership：依赖负责 DeploymentStrategy 内部字段与 `rollingUpdate` 归一化；当前模板负责形态解析、默认值、`Recreate` 抑制与返回边界

## 代码边界

### `templates/api-resources/Apps/_DeploymentSpec.tpl`

- access：`write`
- operations：update strategy 段的 string 分支为 YAML 标量还原、单次三槽匹配与归一化，update map 分支为容器级校验与 `type` 归并，update 空结果不渲染判定，update 委托目标为 `apps.deploymentStrategy`；update 文件头契约注释中 strategy 的委托说明与字段注释
- writable-scopes：`apps.deploymentSpec` 定义体的 strategy 功能块，以及该文件头部整体契约注释中的 strategy 条目与紧邻 strategy 功能块的字段注释

### `templates/base/_env.tpl`

- access：`write`
- operations：update `APPS.DEPLOYMENT.STRATEGY` 表达式、remove `APPS.DEPLOYMENT.ROLLING_UPDATE`
- writable-scopes：`base.env` 定义体内 `APPS.DEPLOYMENT` 段

### `openspec/references/template-snippets.md`

- access：`write`
- operations：update 「多类型字段规整」示例中的捕获组数量与常量读取说明，使其与新表达式一致
- writable-scopes：`## 多类型字段规整` 章节的示例代码块与该章节末尾说明段

### `templates/base/_get.tpl`

- access：`read`
- operations：consume `base.get`

### `templates/base/_field.tpl`

- access：`read`
- operations：consume `base.field`

### `templates/base/_types.tpl`

- access：`read`
- operations：consume `base.map`

### `templates/base/_convert.tpl`

- access：`read`
- operations：consume `base.isFromYamlError`

## 验证设计

- 在 `/tmp/` 最小 application Chart 中加载真实 `_DeploymentSpec.tpl` 与真实 `_env.tpl`，`apps.deploymentStrategy` 用同名 fixture 放行；不宣称真实子模板集成通过。
- 最小有效场景覆盖 `RollingUpdate 1 30%`、`1 30%` 与单独 `1`，确认 `type` 默认值与 `rollingUpdate` 字段集合。
- 较完整有效场景覆盖三段齐全、首槽显式空字符串 `""` 与 `''`、中槽显式空字符串、`rollingupdate` 小写、分隔符省略、三项全空、`Recreate` 携带滚动参数，以及 map 分支的默认 `type`、大小写归并、`rollingUpdate` 透传与空 map。
- 关键失败场景覆盖 `BlueGreen`、`1 30% 5`、`1 30% 5 6`、`1.5`、`-1`、非 string 非 map 输入、map 分支 `rollingUpdate` 非 map，以及 fixture 返回空、`null`、无效 YAML 和非 map；子模板异常返回一律由当前模板的 YAML 错误或空输出检查中断，并输出 `[apps.deploymentSpec]` 前缀消息。
- 常量变更必须加载真实 `_env.tpl`，不得以同名 fixture 替代 `base.env`；静态检查只覆盖 write boundary 的空白、冲突标记和文件末尾单一换行。
