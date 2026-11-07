# core.podSpec affinity 别名取值任务

## 实施

- [x] T1 `templates/api-resources/Core/_PodSpec.tpl`：把 `affinity` 字段的 `pick $_affinityParsed "nodeAffinity" "podAffinity" "podAntiAffinity"` 改为对 `affinity` 解析结果逐键调用 `base.get` 取三个官方键，用 `base.isFromYamlError` 排除解析错误后把非空结果以规范键写入 `$affinity`，保留 `mustDeepCopy` 隔离；对应 `Decision: affinity 内部逐键 base.get 归一化`、`Decision: 别名归一化在 core.podSpec 内完成`、`Decision: 不识别短键`。
- [x] T2 `templates/api-resources/Core/_PodSpec.tpl`：确认 `affinity` 内部值初始化后仍以 `mustMerge` 补入同级字段，保持 `affinity` 内同名键优先与后续 `definitions.affinity` 委托不变；对应 `Decision: 保持合并顺序与 affinity 优先`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（`definitions.affinity` 为同名 fixture）：只提供 `affinity.nodeAffinityAlias` 时输出 `affinity.nodeAffinity`，内容与别名一致。
- [x] V2 `/tmp/` 最小 application Chart（fixture）：分别以 `nodeAffinityAlias`、`podAffinityAlias`、`podAntiAffinityAlias` 提供，验证三者与对应规范键输出等价。
- [x] V3 `/tmp/` 最小 application Chart（fixture）：`affinity` 内同时提供别名与规范键时取别名；只提供规范键时输出与修复前一致。
- [x] V4 `/tmp/` 最小 application Chart（fixture）：fixture 输出收到的键名集合，验证传给 `definitions.affinity` 的对象不含任何 `*Alias` 键。
- [x] V5 `/tmp/` 最小 application Chart（fixture）：`affinity` 内已有 `nodeAffinity` 且同级也存在 `nodeAffinity` 时取 `affinity` 内值；只提供 `node`、`pod`、`podAnti` 短键时不输出 `affinity`。
- [x] V7 `/tmp/` 最小 application Chart（fixture）：`affinity.nodeAffinity` 取值为非 map 时渲染中断，错误信息包含 `affinity.nodeAffinity`。
- [x] V6 静态检查：修改文件无冲突标记、无行尾空白、末尾单换行。
