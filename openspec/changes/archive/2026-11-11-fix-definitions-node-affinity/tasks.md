# nodeAffinity weight 类型门禁收敛任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_NodeAffinity.tpl`：删除 `preferredDuringSchedulingIgnoredDuringExecution` 条目 `weight` 的 `fromYaml (printf "v: %s" ...)` 解码、`base.isFromYamlError` 检查与 `kindIs "map"`、`kindIs "slice"` 两个 `fail` 分支，保留存在性判断并把 `base.get` 原始文本直接写入待渲染条目；同步文件头契约注释中 `weight` 相关行为与边界；对应 `校验 preferredDuringSchedulingIgnoredDuringExecution 的 weight`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart 加载真实 `templates/base/*.tpl` 与 `templates/api-resources/Definitions/*.tpl`，调用 `definitions.nodeAffinity`，覆盖 `weight` 为 `50`、int64 `50`、`50.0` 且 `preference` 含单个 `matchExpressions`，预期输出 `weight: 50` 与 `preference.matchExpressions`，并覆盖两条元素的顺序输出。
- [x] V2 同一 fixture 覆盖 `weight: "50"`、`weight: {a: b}`、`weight: [1, 2]`、`weight: abc`、`weight: 1.5`、`weight: true`、`weight: 0`、`weight: 101`、`weight: {}`、`weight: []`，预期全部中断渲染，`[base.int]`、`[base.int.range]` 与空集合的失败消息前缀符合 `校验 preferredDuringSchedulingIgnoredDuringExecution 的 weight`。
- [x] V3 同一 fixture 覆盖 `weight` 缺失、为 `null`、为空字符串，预期在 `definitions.nodeAffinity` 层中断，失败消息包含条目下标与 `weight`；同时确认 `requiredDuringSchedulingIgnoredDuringExecution` 分支未被触发，避免命中仓库缺失的 `definitions.nodeSelector`。
