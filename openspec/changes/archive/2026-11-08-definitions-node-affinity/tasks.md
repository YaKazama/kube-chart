# NodeAffinity 共享结构任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_NodeAffinity.tpl`：新建文件并在 `writable-scopes` 内 `add` 紧邻 `define` 之前的中文整体契约注释与 `define "definitions.nodeAffinity"` 骨架，注释覆盖入参两个规范长键、字段输出顺序、失败边界与返回值；对应 `Decision: 目标文件与命名模板归属`、`Decision: 只读两个规范长键并关闭别名识别`。
- [x] T2 `templates/api-resources/Definitions/_NodeAffinity.tpl`：在 `writable-scopes` 内实现 `preferredDuringSchedulingIgnoredDuringExecution` 闭环：`base.get` 关闭别名取值、空输出跳过、`fromYamlArray` 恢复与 `base.isFromYamlArrayError` 判定、元素 `kindIs "map"` 门禁、`weight` 空输出中断与 `v:` 容器标量还原、`matchExpressions` 与 `matchFields` 别名归一化后写入 `$preference`、委托 `definitions.preferredSchedulingTerm`、返回值 `fromYaml` 与 `base.isFromYamlError` 保护后顺序累加，最后以 `base.field` 搭配 `base.slice` 输出；对应 `Decision: 两字段按 array 恢复并按字段闭环`、`Decision: preferred 逐项归一化后委托`、`Decision: weight 只判存在性并按标量传递`、`Decision: matchExpressions 与 matchFields 归一化后写入目标容器`、`Decision: 子模板返回值的错误边界`。
- [x] T3 `templates/api-resources/Definitions/_NodeAffinity.tpl`：在 `writable-scopes` 内实现 `requiredDuringSchedulingIgnoredDuringExecution` 闭环：同规则取值与元素门禁、逐项清洗后包裹为 `dict "nodeSelectorTerms" $terms`、委托 `definitions.nodeSelector`、返回值 `fromYaml` 与 `base.isFromYamlError` 保护，非空时以 `base.field` 搭配 `base.map` 输出；对应 `Decision: 两字段按 array 恢复并按字段闭环`、`Decision: matchExpressions 与 matchFields 归一化后写入目标容器`、`Decision: required 包裹为 nodeSelectorTerms 并整体委托`、`Decision: 子模板返回值的错误边界`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（`definitions.preferredSchedulingTerm`、`definitions.nodeSelector` 为同名回显 fixture）：只提供一项 `preferredDuringSchedulingIgnoredDuringExecution`（含 `weight: 1`、`matchExpressions`、`matchFields`），输出只含该字段且为一项，fixture 收到的 `weight` 为整数、`preference` 含两个匹配字段。
- [x] V2 `/tmp/` 最小 application Chart（fixture）：两字段同时提供且各含多项，验证输出顺序为 `preferredDuringSchedulingIgnoredDuringExecution` 在前、项数一致、`definitions.nodeSelector` 收到的 map 只含 `nodeSelectorTerms` 且元素顺序一致。
- [x] V3 `/tmp/` 最小 application Chart（fixture）：分别提供 `preferredAlias`、`matchExpressionsAlias`、`matchFieldsAlias` 与同名规范键并取值不同，验证别名生效；别名置空时验证回退规范键；`matchExpressions` 与 `matchFields` 都为空时验证该项仍被委托。
- [x] V4 `/tmp/` 最小 application Chart（fixture）：两个规范长键均为空 array、只提供 `preferred`／`required` 短键、只提供 `preferredDuringSchedulingIgnoredDuringExecutionAlias` 三种输入均输出空结果。
- [x] V5 `/tmp/` 最小 application Chart（fixture）：`preferredDuringSchedulingIgnoredDuringExecution` 为 map、`requiredDuringSchedulingIgnoredDuringExecution` 元素为字符串、`weight` 缺失、`weight` 为空字符串、`weight` 为 map、`matchExpressions` 为 map、fixture 返回非 YAML 文本，分别验证渲染中断且错误信息包含 `[definitions.nodeAffinity]` 与对应字段路径。
- [x] V6 静态检查：`templates/api-resources/Definitions/_NodeAffinity.tpl` 无冲突标记、无行尾空白、`define` 与 `end` 配平、文件末尾单换行。
