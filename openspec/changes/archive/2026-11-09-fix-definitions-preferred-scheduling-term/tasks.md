# PreferredSchedulingTerm preference 必填任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_PreferredSchedulingTerm.tpl`：在 `writable-scopes` 内把 `preference` 的 `base.get` 调用改为 `list [上下文, "preference", "", "", true]` 必填取值，必填校验与必填失败消息交由该能力完成，不在本层重复判空；`fromYaml` 与 `base.isFromYamlError` 后用 `kindIs "map"` 拒绝非 map，删除“空内容跳过”分支并在子模板渲染结果为空时 `fail`；同步更新整体契约注释与字段注释中 `preference` 的“可选”表述、“只输出 weight”表述与消息归属表述；对应 `Decision: preference 必填取值与 map 门禁`、`Decision: 子模板返回空内容改为中断`、`Decision: 保留 weight 与字段顺序不动`。
- [x] T2 `templates/api-resources/Definitions/_NodeAffinity.tpl`：在 `writable-scopes` 内于 preferred 段 `matchExpressions` 与 `matchFields` 归一化之后新增 `$preference` 空 map 中断判定，消息为 `[definitions.nodeAffinity] preferredDuringSchedulingIgnoredDuringExecution[<下标>].preference: required field is missing or empty`；同步更新该段字段注释与整体契约注释中“空匹配条件仍委托”的表述；对应 `Decision: nodeAffinity preferred 段新增空匹配条件中断`、`Decision: nodeAffinity 其余分支不动`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（`definitions.nodeSelector` 为同名回显 fixture，`definitions.nodeSelectorTerm` 与 `definitions.preferredSchedulingTerm` 为真实实现）：提供 `weight: 1` 与含 `matchExpressions`、`matchFields` 的 `preference`，验证输出顺序为 `weight` 在前、`preference` 在后；另验证 `weightAlias` 覆盖 `weight`、空 `preferenceAlias` 回退 `preference`。
- [x] V2 `/tmp/` 最小 application Chart（真实依赖）：`preference` 分别为缺失、`null`、空字符串、空 map、字符串、list，逐一验证渲染中断；缺失、`null`、空字符串与空 map 断言 `[base.get]` 与 `preference`，字符串与 list 断言 `[definitions.preferredSchedulingTerm]` 与 `preference`；再用 fixture 返回空内容与非法 YAML，验证两条子模板边界均中断并断言本模板前缀。
- [x] V3 `/tmp/` 最小 application Chart（真实依赖）：`weight` 分别为缺失、`null`、空字符串、`abc`、`true`、map、list、`1.5`、`0`、`-1`、`101`，结合合法 `preference`，验证失败边界与消息与改造前一致。
- [x] V4 `/tmp/` 最小 application Chart（真实依赖）：`definitions.nodeAffinity` 的 preferred 元素分别只含 `weight`、`matchExpressions: []` 与 `matchFields: []` 同时为空，验证中断且错误信息含 `preferredDuringSchedulingIgnoredDuringExecution[<下标>]`；再验证只提供 `matchFields`、只提供 `matchExpressions`、两者都提供、多项顺序、`weight: 101` 仍委托、`weightAlias` 优先、required 分支包裹 `nodeSelectorTerms`、长键非 array 中断、元素非 map 中断。
- [x] V5 静态检查：两个写入文件无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行；`grep` 确认 `_PreferredSchedulingTerm.tpl` 中不再出现 `preference（NodeSelectorTerm, 可选）` 与“只输出 weight”表述。
