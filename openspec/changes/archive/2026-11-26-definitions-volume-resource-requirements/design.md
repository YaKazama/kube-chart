# definitions.volumeResourceRequirements 设计

## 技术目标

- capability：`definitions.volumeResourceRequirements`
- artifact-type：Helm 共享结构命名模板（library Chart）
- target：`templates/api-resources/Definitions/_VolumeResourceRequirements.tpl`
- supporting-capability：`base.quantity.ge`，新增于 `templates/base/_k8s.tpl`，operation 为 `add`

## 设计决策

### Decision: 字段顺序、空值省略与原值渲染

- requirements：`VolumeResourceRequirements 字段渲染`
- choice：按 `limits` → `requests` 顺序处理；字段缺失或为空 map 时跳过；非空字段经 `base.map.verify` 与 `K8S.QUANTITY` 校验后，使用恢复的原始值通过 `base.field` 的 `base.map` 模式输出。
- rationale：规格要求官方顺序、空 map 省略、值通过校验且按原值输出；工程规则要求 map 子模板先完成 YAML 恢复与错误保护。

### Decision: 共同键比较

- requirements：`VolumeResourceRequirements 字段渲染`
- choice：两个字段归一化后，遍历 `requests` 的资源键；仅当 `limits` 存在同名键时，以 `(list (toString 限制值) (toString 请求值))` 调用 `base.quantity.ge`，返回 `false` 时以 `[definitions.volumeResourceRequirements] requests.<key>: must not exceed limits` 中断。
- rationale：规格要求仅比较两侧同时存在的键，并校验 `requests` 不超过 `limits`；`base.quantity.ge` 的 `ge` 语义决定限制值作为第一个参数。

### Decision: base.quantity.ge 数值化比较

- requirements：`Quantity 数值比较`
- choice：接受 `list [left, right]` 两个 Quantity 字符串；先校验参数为 string，再委托 `base.quantity` 校验 Quantity 格式；按 `K8S.QUANTITY` 捕获组提取数值主体与后缀，结合 `-` 前缀确定符号，将二进制后缀换算为 1024 的幂、十进制后缀换算为 1000 的幂、`m` 换算为 0.001、`e`/`E` 指数形式换算为 10 的幂，统一转为 `float64` 后用 `ge` 比较，返回 `true` 或 `false`。
- rationale：draft 要求先转为数字再比较、首个 Quantity 大于或等于第二个时返回 `true`；复用 `base.quantity` 与 `K8S.QUANTITY` 避免重复实现格式校验与正则。

### Decision: 失败消息归属

- requirements：`VolumeResourceRequirements 字段渲染`、`Quantity 数值比较`
- choice：本模板的比较失败使用 `[definitions.volumeResourceRequirements]` 前缀；`base.quantity.ge` 的参数与类型失败使用 `[base.quantity.ge]` 前缀；委托 `base.quantity`、`base.map.verify` 的失败保留其自身前缀。
- rationale：draft 确认失败消息由本 change 持有；公共模板的既有失败消息无法拦截，沿用工程规则中委托保留前缀的约定。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文 map, 点分路径 string]`，使用默认别名识别与非必填行为。
- output：可取值的 YAML 字符串；路径全部缺失时为空输出。
- ownership：`base.get` 负责数据源优先级、同级别名识别与序列化；本模板负责字段存在性判断与失败消息。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值。
- output：`"true"` 表示解析错误，其他表示成功。
- ownership：`base.isFromYamlError` 负责解析错误识别；本模板负责错误发生后的中断。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`。
- output：可解析为常量 Map 的 YAML 字符串；本 change 使用 `K8S.QUANTITY`。
- ownership：`base.env` 负责正则常量的结构与内容；本模板与 `base.quantity.ge` 只读取该键。

### Dependency: `base.map.verify`

- availability：`existing`
- source：`templates/base/_collection.tpl`
- operation：`consume`
- input：`list [map, 正则 string]`，本 change 使用 `K8S.QUANTITY`。
- output：包含原键与校验通过原值的 YAML 字符串；非 map 或值不匹配时中断并保留其自身前缀。
- ownership：`base.map.verify` 负责 map 类型门禁与逐值校验；本模板负责字段生效判断、解析恢复与原值渲染。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [key string, value map, "base.map"]`。
- output：YAML 键值对；value 为空时为空输出。
- ownership：`base.field` 负责键值对与 map 渲染；本模板负责只在字段生效时调用。

### Dependency: `base.quantity`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：string、int 或 float64 形式的 Quantity 值。
- output：校验通过的原始值；不匹配 `K8S.QUANTITY` 时中断并保留其自身前缀。
- ownership：`base.quantity` 负责 Quantity 格式校验；`base.quantity.ge` 负责数值换算与比较。

### Dependency: `base.quantity.ge`

- availability：`unavailable`
- source：无
- operation：`add`
- input：`list [left Quantity string, right Quantity string]`。
- output：`"true"` 或 `"false"` 字符串；任一参数不是合法 Quantity 时中断。
- ownership：`base.quantity.ge` 负责两个 Quantity 的数值换算与大于或等于比较；调用方负责传入字符串形态的 Quantity。

## 代码边界

### `templates/base/_k8s.tpl`

- access：`write`
- operations：`add base.quantity.ge`
- writable-scopes：仅新增 `base.quantity.ge` 的整体契约注释与 `define` 块，紧邻现有 `base.quantity`。

### `templates/api-resources/Definitions/_VolumeResourceRequirements.tpl`

- access：`write`
- operations：`add definitions.volumeResourceRequirements`
- writable-scopes：新增文件的整体契约注释与 `define` 块。

### `templates/api-resources/Core/_PersistentVolumeClaimSpec.tpl`

- access：`read`
- operations：`consume resources 对 definitions.volumeResourceRequirements 的既有委托调用契约`

## 验证设计

- `base.quantity.ge` 直接场景：`1Gi` 与 `1024Mi` 返回 `true`；`2Gi` 与 `1Gi` 返回 `true`；`500m` 与 `1` 返回 `false`；非法 Quantity 中断。
- 定义模板最小有效输入：仅 `limits` 或仅 `requests` 非空时只输出该字段。
- 定义模板较完整有效输入：`limits` 与 `requests` 均含共同资源键且请求不超过限制，输出顺序为 `limits`、`requests`，值保持原值。
- 定义模板关键失败场景：共同键请求超过限制、非法 Quantity、非 map 类型均中断；非共同键不触发比较失败。
- 依赖边界：`/tmp/sd-kube-chart/` 最小 Chart 加载真实 `base.get`、`base.isFromYamlError`、`base.env`、`base.map.verify`、`base.field`、`base.quantity` 与本 change 新增的 `base.quantity.ge`，不提供同名 fixture。
