# core.podSpec affinity 别名取值设计

## 技术目标

- capability：`core.podSpec`
- artifact-type：命名模板内部取值修正
- target：`templates/api-resources/Core/_PodSpec.tpl` 中 `define "core.podSpec"` 的 `affinity` 字段处理段

## 设计决策

### Decision: affinity 内部逐键 base.get 归一化

- requirements：`affinity 合并与委托`
- choice：从 `affinity` 取值解析出 map 后，以该 map 为上下文，对 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 逐键调用 `base.get`，由 `base.get` 完成内部 `*Alias` 优先与回退；把非空的解析结果以规范键写入 `$affinity`。不再使用 `pick` 白名单。
- rationale：`pick` 是纯键名筛选、不经过 `base.get`，无法完成别名识别；`base.get` 已具备同级 `<叶子>Alias` 能力，逐键调用可复用既有能力而不在本层重复实现别名优先逻辑。该写法与同文件第 88–96 行处理同级别名的方式对称。

### Decision: 别名归一化在 core.podSpec 内完成

- requirements：`affinity 合并与委托`
- choice：不把 `*Alias` 键加入 `pick` 白名单向下游透传，`definitions.affinity` 收到的对象只含 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 三个规范键。
- rationale：`definitions.affinity` 当前为 `unavailable`，其是否处理 `*Alias` 无契约保证；将归一化留在本层可保证委托上下文的键集合稳定，且与 `core.podSpec` 其他字段一致。

### Decision: 保持合并顺序与 affinity 优先

- requirements：`affinity 合并与委托`
- choice：先用内部归一化结果初始化 `$affinity`，再用 `mustMerge` 把同级字段补入；`mustMerge` 的补缺语义保证 `affinity` 内已有同名键不被同级覆盖。
- rationale：合并语义与修复前完全一致，本次只替换内部取键方式，不改合并算法。

### Decision: 内部键非 map 时中断

- requirements：`affinity 合并与委托`
- choice：逐键 `base.get` 取值经 `fromYaml` 恢复且通过 `base.isFromYamlError` 排除解析错误后，若结果非空却为标量，则 `fail` 并输出固定消息 `[core.podSpec] affinity.<字段名>: must be map type`。
- rationale：修复前 `pick` 对内部键不做类型校验，非 map 值被静默丢弃；改后取键路径会真正读取该值，必须给出可定位的失败边界，不能静默忽略或输出非法结构。

### Decision: 不识别短键

- requirements：`affinity 合并与委托`
- choice：逐键调用的键名清单固定为三个官方键，不扩充 `node`、`pod`、`podAnti`。
- rationale：逐键 `base.get` 只可能读取清单内的键，短键自然不参与合并，无需额外判断。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <affinity 解析后的 map> <点分路径>`，不传强制类型与额外可选参数，保持别名默认开启。
- output：可 `fromYaml` 解析的 YAML 字符串；路径全部缺失或为空值时返回空输出。
- ownership：别名派生、别名优先与回退由 `base.get` 负责；本层负责逐键遍历、非空判断与写入 `$affinity`。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值。
- output：布尔值，指示是否为解析错误形态。
- ownership：本层负责在排除解析错误后决定是否采用该键。

### Dependency: `definitions.affinity`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：合并后的 Affinity 对象，只含 `nodeAffinity`、`podAffinity`、`podAntiAffinity`。
- output：可 `fromYaml` 解析的 YAML 字符串；无有效内容时为空输出。
- ownership：合并、内部别名归一化与生效判断由本层负责；字段级结构由依赖层负责。规格已锁定调用契约，本 change 不实现。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list "affinity" <已归一化 map> "base.map"`。
- output：YAML 键值片段；渲染结果为空时不输出。
- ownership：本层负责决定字段是否生效；输出格式由依赖负责。

## 代码边界

### `templates/api-resources/Core/_PodSpec.tpl`

- access：`write`
- operations：`update` `define "core.podSpec"` 中 `affinity` 字段的内部取值段，把 `pick` 白名单改为逐键 `base.get` 归一化。
- writable-scopes：`define "core.podSpec"` 中 `affinity` 字段处理块的内部取键语句与其循环结构。

### `templates/base/_get.tpl`

- access：`read`
- operations：读取 `base.get` 的别名识别、数据源优先级与空输出约定。

### `templates/base/_convert.tpl`

- access：`read`
- operations：读取 `base.isFromYamlError` 的解析错误识别契约。

### `templates/base/_field.tpl`

- access：`read`
- operations：读取 `base.field` 的参数契约与空结果省略行为。

## 验证设计

- 内部别名命中：`/tmp/` 最小 application Chart 中只提供 `affinity.nodeAffinityAlias`，验证输出为 `affinity.nodeAffinity` 且内容一致。
- 三个键等价：分别以 `nodeAffinityAlias`、`podAffinityAlias`、`podAntiAffinityAlias` 提供，验证结果与对应规范键一致。
- 别名优先：`affinity` 内同时提供别名与规范键，验证取别名。
- 别名回退：只提供规范键，验证与修复前输出一致。
- 委托上下文：fixture 输出收到的键名集合，验证不含任何 `*Alias` 键。
- 合并优先级：`affinity` 内已有 `nodeAffinity` 且同级也存在 `nodeAffinity`，验证取 `affinity` 内值。
- 短键不生效：只提供 `node`、`pod`、`podAnti`，验证不输出 `affinity`。
- fixture 边界：`definitions.affinity` 为 `unavailable`，使用 `/tmp/` 同名最小 fixture，结论只证明 `core.podSpec` 自身行为。
