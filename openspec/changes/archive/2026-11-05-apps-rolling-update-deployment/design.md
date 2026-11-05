# RollingUpdateDeployment 设计

## 技术目标

- capability：`apps.rollingUpdateDeployment`
- artifact-type：Helm 命名模板（library Chart）
- target：`templates/api-resources/Apps/_RollingUpdateDeployment.tpl` 中的 `apps.rollingUpdateDeployment`

## 设计决策

### Decision: 入参形态与字段读取

- requirements：`滚动更新参数渲染`
- choice：把传入上下文直接作为 `base.get` 的上下文，用 `list <上下文> "maxSurge"` 与 `list <上下文> "maxUnavailable"` 取值，使用默认参数，保留 `base.get` 的 `*Alias` 自动识别；不对入口上下文加 `kindIs "map"` 门禁。
- rationale：父级 `apps.deploymentStrategy` 已把恢复后的 map 原样透传，本层只读取两个已知键；未声明字段不参与渲染，无需入口类型门禁。

### Decision: 取值归一化与空值判据

- requirements：`滚动更新参数渲染`
- choice：每个字段的原始文本先经 `SYS.YAML_QUOTED` 剥离外层引号并 `trim`，归一化结果保存在 `$maxSurge`、`$maxUnavailable`；赋值包在 `with include "base.get" (list . "<字段>") | trim` 内，空输出时整体跳过，两个字段的校验与渲染都用 `with` 收敛空值分支。
- rationale：`base.get` 对缺失键、显式 `null` 与空字符串标量都不产生有效文本，`with` 的空值语义可以直接兼作字段生效判据，避免单独的 `if` 嵌套与 `null` 文本比较。

### Decision: base.get 将显式 null 归并为空值

- requirements：`滚动更新参数渲染`
- choice：在 `base.get` 的“处理第一个有效值”分支把 `kindIs "invalid"` 与空字符串一并视为未命中并继续回溯，同时在契约注释中补充“显式 null 视为空”。本模板不增加 `null` 文本判断。
- rationale：修复前 `base.get` 把显式 `null` 序列化为文本 `null`，使调用方需自行比较 `"null"` 才能实现“为空则省略”，与工程规则“空值处理由字段生效条件决定”相背；在共享取值层统一归并后，所有调用方一致获得空输出。实测 `null`、`~`、空值键均为 `kindIs "invalid"`，`'null'` 引号字符串仍为 string 并继续被本模板正则拦截，形态区分保持正确。

### Decision: 独立正则集中定义

- requirements：`取值形态校验`
- choice：在 `base.env` 的 `APPS` 下新增 `ROLLING_UPDATE.MAX_SURGE` 与 `ROLLING_UPDATE.MAX_UNAVAILABLE` 两个键。`MAX_SURGE` 为 `^\d+(?:%)?$`，接受任意非负整数与任意非负百分比。`MAX_UNAVAILABLE` 为 `^(?:\d+|0*(?:100|\d{1,2})%)$`，整数分支不设上限，百分比分支限定 `0%` 至 `100%` 并允许前导零。
- rationale：两个字段上限规则不同，必须使用独立表达式；工程规则禁止业务模板内联正则，集中定义才能保持单一来源；整数分支与百分比分支并列可以在不做数值解析的前提下同时满足“整数无上限、百分比不超 `100%`”。

### Decision: 零值判定用 trimAll 折叠前导零

- requirements：`两个字段同时为 0 时省略`
- choice：不保存独立的数字归一化变量，也不使用 `hasPrefix`/`trimPrefix` 循环；直接以 `empty (trimAll "0" (trimSuffix "%" $<字段>))` 判定该字段数值等价于 0。
- rationale：前导零写法仍是合法整数，不构成新的失败边界；`trimAll` 一次完成全部前导零与尾部零的剔除，对 `0`、`00`、`0%`、`00%` 都得到空串，对 `007`、`150`、`100%` 均非空，与循环写法结果等价且消除重复状态变量；渲染仍使用含 `%` 的原值，百分比不会退化为整数。

### Decision: 小数与非法形态失败

- requirements：`取值形态校验`
- choice：正则只接受十进制数字或“数字+`%`”，不含小数点、正负号与其他字符；不匹配时立即 `fail`，失败消息为 `[apps.rollingUpdateDeployment] <字段>: does not match <正则>, got '<值>'`。
- rationale：`base.rollingUpdate` 会把 `float64` 截断为整数，若先委托它会静默把 `1.5` 变成 `1`；先由独立正则拒绝小数才能满足“小数一律非法”。失败消息直接回显命中失败的正则，便于定位是形态错误还是百分比上限错误。

### Decision: 原生浮点 1.0 不单独判定

- requirements：`取值形态校验`
- choice：不对入参做 `kindIs "float64"` 判定，也不绕过 `base.get` 直读原始 map。
- rationale：实测在 `/tmp/` 最小 Chart 中，`fromYaml "maxSurge: 1.0"` 得到 `float64`，而 `base.get` 序列化后输出 `1`，与整数 `1` 完全同形；`1.5` 则保留为 `1.5`。因此先经 `base.get` 归一化后，正则能拦截全部非零小数，已满足规格；若拦截 `1.0` 必须在 `base.get` 之前额外读取原始类型，这与本层统一取值方式冲突，规格已明确不承担该判定。

### Decision: base.rollingUpdate 作为渲染模板完成二次格式校验

- requirements：`取值形态校验`
- choice：两个字段的 `base.field` 调用都把渲染模板指定为 `base.rollingUpdate`，即 `list "<字段>" <归一化值> "base.rollingUpdate"`，由其在校验通过后返回原值。
- rationale：`base.rollingUpdate` 是当前 Chart 真实存在且符合 IntOrString 入参的命名模板，作为 `base.field` 的渲染模板可以在最终渲染环节完成规格要求的二次格式校验，避免额外的独立调用；整数与百分比共用同一渲染路径保持 DRY，且其原值返回使得百分比 `25%` 与整数 `3` 都以不加引号的形态输出。

### Decision: 双零取值整体省略

- requirements：`两个字段同时为 0 时省略`
- choice：两个字段都生效且各自满足上文 `trimAll` 零值判定时，直接返回空输出，不调用任何 `base.field`。
- rationale：Kubernetes API 明确 `maxSurge` 与 `maxUnavailable` 不可同时为 0，省略后由 API 隐式默认值 `25%` 生效，比中断渲染更符合规格“不渲染且不失败”；折叠前导零后的空串判据可以统一识别 `0`、`00`、`0%`、`00%`，不需要单独的数值解析分支。

### Decision: 按 API 字段顺序输出

- requirements：`滚动更新参数渲染`
- choice：先渲染 `maxSurge`，再渲染 `maxUnavailable`。
- rationale：`RollingUpdateDeployment` 官方字段表顺序为 `maxSurge`、`maxUnavailable`。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`add`
- input：空 string `""`
- output：可由 `fromYaml` 恢复的非空 YAML map；本模板读取新增的 `APPS.ROLLING_UPDATE.MAX_SURGE`、`APPS.ROLLING_UPDATE.MAX_UNAVAILABLE` 与既有 `SYS.YAML_QUOTED`
- ownership：提供集中常量；本模板负责按字段选择表达式与剥离外层引号

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`update`
- input：`list <当前上下文> "maxSurge"` 与 `list <当前上下文> "maxUnavailable"`
- output：YAML 文本；缺失、显式 `null` 与空字符串标量时为空输出
- ownership：提供多层取值、别名默认语义、空值归并与序列化；本模板负责字段生效判断，不再自行处理 `null` 文本

### Dependency: `base.rollingUpdate`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：归一化后的非空 string 值
- output：合法时返回原字符串；非法时 `fail`
- ownership：作为 `base.field` 的渲染模板完成 IntOrString 形态的二次格式校验；上限、小数与双零判断由本模板负责

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list "maxSurge" <值> "base.rollingUpdate"` 与 `list "maxUnavailable" <值> "base.rollingUpdate"`
- output：字段 YAML；渲染为空时不输出
- ownership：负责字段序列化与渲染路由；本模板负责字段生效条件与是否调用

## 代码边界

### `templates/base/_env.tpl`

- access：`write`
- operations：add `base.env` 输出中的 `APPS.ROLLING_UPDATE.MAX_SURGE` 与 `APPS.ROLLING_UPDATE.MAX_UNAVAILABLE` 两个键
- writable-scopes：`APPS` 映射下新增的 `ROLLING_UPDATE` 映射及其两个子键

### `templates/api-resources/Apps/_RollingUpdateDeployment.tpl`

- access：`write`
- operations：add `apps.rollingUpdateDeployment` 命名模板及其整体契约注释；add `maxSurge`、`maxUnavailable` 两个字段功能块、紧邻字段注释、双零判定与委托校验
- writable-scopes：新建文件的全部内容

### `templates/base/_get.tpl`

- access：`write`
- operations：update `base.get` 的“处理第一个有效值”分支，将 `kindIs "invalid"` 与空字符串一并视为未命中并 `continue`；update 整体契约注释中“标量取首个非空值”条目，补充“显式 null 视为空”
- writable-scopes：`base.get` 定义体内 `处理第一个有效值` 分支的空值判定条件，以及整体契约注释中该行为条目

### `templates/base/_k8s.tpl`

- access：`read`
- operations：consume `base.rollingUpdate`

### `templates/base/_field.tpl`

- access：`read`
- operations：consume `base.field`

## 验证设计

- 在 `/tmp/` 最小 application Chart 中加载真实 `_RollingUpdateDeployment.tpl`、真实 `_env.tpl`、真实 `_get.tpl`、真实 `_k8s.tpl`、真实 `_field.tpl` 与真实 `_DeploymentStrategy.tpl`，通过 `apps.deploymentStrategy` 渲染，确认真实调用链集成。
- 最小有效场景覆盖 `{maxSurge: 1}`、`{maxUnavailable: "25%"}` 与空 map。
- 空值场景覆盖 `{maxSurge: null}`、`{maxSurge: ~}`、空值键 `maxSurge:`、`{maxUnavailable: null}` 与 `{maxSurgeAlias: null, maxSurge: 5}`，预期均不中断渲染；空别名场景预期输出 `maxSurge: 5`。
- 较完整有效场景覆盖 `{maxSurge: 3, maxUnavailable: "30%"}` 的字段顺序、`{maxSurge: "150%"}` 的百分比无上限、`{maxUnavailable: 150}` 的整数无上限、`{maxSurge: 0}` 的单侧 0 渲染。
- 关键失败场景覆盖 `{maxUnavailable: "101%"}`、`{maxSurge: 1.5}`、`{maxSurge: "-1"}`、`{maxSurge: "abc"}`；并覆盖 `{maxSurge: 1.0}` 按整数渲染 `maxSurge: 1`。
- `base.get` 的 `null` 归并属于共享基础能力变更，验证必须加载真实 `_get.tpl` 并按 V0 独立覆盖 `null`、`~`、空值键、引号字符串与空别名回退，不得用 fixture 替代。
- 双零场景覆盖 `{maxSurge: 0, maxUnavailable: 0}`、`{maxSurge: "0%", maxUnavailable: "0%"}`、`{maxSurge: 0, maxUnavailable: "0%"}`，预期 `strategy` 不含 `rollingUpdate`。
