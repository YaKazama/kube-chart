# Sysctl 共享结构设计

## 技术目标

- capability：`definitions.sysctl`
- artifact-type：Kubernetes 共享结构命名模板
- target：`templates/api-resources/Definitions/_Sysctl.tpl` 中 `define "definitions.sysctl"`

## 设计决策

### Decision: 目标文件与命名模板归属

- requirements：`渲染 Sysctl 字段片段`
- choice：新增 `templates/api-resources/Definitions/_Sysctl.tpl`，文件内只定义 `definitions.sysctl`。
- rationale：`Sysctl` 是 Kubernetes 官方结构，v1.36 参考明确其 `Appears In` 为 `PodSecurityContext`，属可跨资源复用的同域共享结构，只能落在 `api-resources/Definitions`；该目录的 `_SeccompProfile.tpl`、`_SELinuxOptions.tpl` 沿用 `_<结构名>.tpl` 与 `definitions.<能力>` 命名。该 `define` 在全 Chart 不存在，属纯新增；既有调用点 `templates/api-resources/Definitions/_PodSecurityContext.tpl` 已在其 `sysctls` 分支以 `include "definitions.sysctl" $_item` 委托并逐条 `fromYaml` 回收，本 change 补齐该被委托能力。

### Decision: 使用 base.get 统一取值并隐式支持别名

- requirements：`渲染 Sysctl 字段片段`、`必填与类型校验`
- choice：两个字段均以 `include "base.get" (list . "<字段名>") | base.string.normalize | trim` 取值；别名由 `base.get` 默认开启的识别能力隐式处理，本模板不自行推导别名键名。
- rationale：规格要求同级 `<字段>Alias` 生效并优先于规范键，`base.get` 默认即为该语义，直接复用比自建取值逻辑更简短，也符合 [`helm-templates.md`](../rules/helm-templates.md) 的字段统一取值约束。`base.get` 返回 YAML 序列化文本，`base.string.normalize` 负责解码与 string 类型门禁（对数字、布尔与结构输入中断），两者串联即同时满足“取到归一化 string”与“非 string 中断”两条要求，无需额外 `kindIs`。`trim` 由本层负责，因为 `normalize` 明确不做 `trim`。
- 约束：`base.get` 对“键缺失”“值为 `null`”“值为空字符串”返回相同结果，无法自行区分三者；规格要求区分“缺失中断”与“`null` 输出 `""`”，因此必填判定无法完全交由 `base.get`，见下一项决策。

### Decision: value 必填判定覆盖规范键与别名键

- requirements：`必填与类型校验`
- choice：仅在 `value` 与 `valueAlias` 两个键均不存在时 `fail`；`name` 不单独做键存在判定，其余必填判定统一交给归一后的空值判断。
- rationale：`base.get` 不暴露“键是否存在”的信息，而规格要求「`value` 缺失中断」同时要求「仅提供 `valueAlias` 不算缺失」，两条同时成立时必须由本层做一次键存在判定。`hasKey . "value"` 或 `hasKey . "valueAlias"` 只靠两个字面量键名，不重复 `base.get` 的别名推导（它还会处理 `<叶子>Alias` 结尾不派生等边界，本模板用不到）。`name` 不需要这一步：规格对 `name` 的失败条件是「缺失、`null`、空字符串或只含空白」，这四者在归一后都表现为空字符串，一条 `if not $name` 已全覆盖。

### Decision: name 恒加双引号

- requirements：`取值与输出形态`
- choice：`name` 归一后以 `quote` 包裹再交给 `base.rawString` 输出。
- rationale：规格要求 `name` 恒带引号，防止极端取名（形如 `on`、`true`、`007`）在父级 `fromYaml` 回收时被解析成非 string。恒加引号无需逐例判断，也不影响常规名称的可读性。

### Decision: value 按 YAML 回读结果决定引号

- requirements：`取值与输出形态`
- choice：以 `fromYaml (printf "v: %s" $value)` 回读后判断 `.v` 的 `kindOf`：不是 `string` 时用 `quote` 包裹，是 `string` 时保持原样；两种情况都以 `base.rawString` 输出。
- rationale：规格要求「不加引号会被 YAML 解析为非 string 时加引号」，该判定只能由 YAML 回读得到。回读一次即覆盖 `0`、`8080`、`007`、`true`、`on`、`null`、`1.5` 等全部字面量形态，无需枚举取值集合。空串与只含空白经 `trim` 后为空，回读 `v: ` 得到 `null`，同样落入「需要加引号」分支，因此空串输出 `value: ""` 无需额外分支。回读失败（例如取值含 `: `）得到错误 map，`.v` 为 `invalid`，同样判为需要加引号，属于安全方向的过度加引号，不改变取值。

### Decision: 使用 quote 加 base.rawString 而非 base.field 的 quote 渲染模板

- requirements：`取值与输出形态`
- choice：自行 `quote` 后交给 `base.field` 的 `base.rawString` 渲染模板，不使用 `base.field` 的 `quote` 关键字。
- rationale：`base.field` 的 `quote` 关键字会把渲染模板换成 `base.string`（`templates/base/_field.tpl` 的分支处理），而 `base.string` 对形如 `007`、`0000` 的取值按 `TYPES.ZERO` 折叠前导零，实测输出变为 `07`、`0`，与规格「输出使用去除首尾空白后的结果」冲突。`base.rawString` 只做类型门禁并原样返回，配合预先 `quote` 可同时满足引号与取值不变两个约束。

### Decision: 返回值形态

- requirements：`渲染 Sysctl 字段片段`
- choice：只输出字段片段，不输出父键、`---`、`apiVersion` 或 `kind`；两个字段必填，模板恒有非空输出。
- rationale：调用点 `_PodSecurityContext.tpl` 以 `include "definitions.sysctl" $_item | fromYaml` 回收，并仅在回收结果非空时追加到输出列表；恒有输出与该回收契约一致，不会出现条目被静默丢弃的情况。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, "<字段名>"]` 形式的非必填取值，键名取自 `name` 与 `value`；别名保持默认开启，因此同级 `nameAlias`、`valueAlias` 隐式生效。
- output：可由 `fromYaml` 解析的 YAML 字符串；标量经 `toYamlPretty` 序列化并带尾随换行，字符串可能带 YAML 引号；路径缺失、为 `null` 或为空字符串时为空输出。
- ownership：数据源优先级、别名识别与标量序列化由依赖层负责；必填的键存在性判定、`trim`、引号决策与输出由本层负责。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 返回的原始文本。
- output：解码后的 string；空输入返回空字符串；非 string 标量或非法 YAML 标量中断，且不做 `trim`。
- ownership：YAML 标量解码与 string 类型门禁（包括数字、布尔、map 与 array 的中断）由依赖层负责；`trim`、空值后的输出形态与引号决策由本层负责。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [<字段名>, 已处理好的字符串, "base.rawString"]`，不传允许值列表。
- output：值生效时输出单行字段片段 `key: value`；渲染结果为空时不输出；因传入已带引号的字符串，输出中的引号不受依赖层再加工。
- ownership：输出格式与多行/复杂类型分支由依赖层负责；取值归一、必填与类型判定、引号决策由本层负责。

### Dependency: `base.rawString`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：string 值。
- output：原样返回的 string；非 string 输入中断。
- ownership：string 类型门禁与原文保留由依赖层负责；取值归一与引号决策由本层负责。

## 代码边界

### `templates/api-resources/Definitions/_Sysctl.tpl`

- access：`write`
- operations：`add define "definitions.sysctl"`、`add 紧邻 define 之前的中文整体契约注释`、`add 字段级中文注释`
- writable-scopes：文件内 `definitions.sysctl` 的契约注释与 `define` 块

### `templates/api-resources/Definitions/_PodSecurityContext.tpl`

- access：`read`
- operations：`consume 既有委托调用 include "definitions.sysctl" $_item | fromYaml`、`consume 既有 name/value 投影与去空去重逻辑`

## 验证设计

- `/tmp/` 最小 application Chart 加载本 change 的目标模板与真实 `base` 依赖（`base.get`、`base.string.normalize`、`base.field`、`base.rawString` 及其传递依赖），不需要任何 fixture：本模板无 unavailable 依赖，全部场景都是真实依赖集成。
- 最小有效输入：`{name: net.ipv4.ip_forward, value: "0"}`，断言输出顺序为 `name`、`value`，`name` 恒带引号，`value` 输出 `"0"`，且可被 `fromYaml` 回收为 map。
- 较完整有效输入：`{value: abc}` 断言不加引号、`{value: "true"}` 与 `{value: "on"}` 断言加引号、`{value: "007"}` 与 `{value: "0000"}` 断言取值不被改写、`{value: ""}`、`{value: "   "}` 与 `{value: null}` 断言输出 `""`、`{value: "null"}` 断言输出 `"null"`、`{name: " kernel.x ", value: "  1  "}` 断言双 trim、`{foo: bar}` 断言范围外键忽略、`{valueAlias: "2"}` 与 `{nameAlias: kernel.x}` 断言别名生效、回收后 `value` 的 `kindOf` 为 `string`。
- 关键失败输入：`name` 缺失、`null`、空字符串、纯空白、`123`、`true`、map、array；`value` 与 `valueAlias` 均缺失、`0`、`true`、map、array。逐项断言渲染中断。
- 静态检查：目标模板无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
