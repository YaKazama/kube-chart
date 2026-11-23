# definitions.keyToPath 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_KeyToPath.tpl`：新增 `definitions.keyToPath` 命名模板、契约注释与错误消息前缀，实现字段顺序、`key` 校验、`path` 归一化与前导 `..` 防护、`mode` 归一化及失败分支；对应 `Decision: 字段取值与输出顺序`、`Decision: key 校验`、`Decision: path 归一化与逃逸防护`、`Decision: mode 归一化`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小与完整渲染：加载真实 `_KeyToPath.tpl` 与 base 依赖，验证 `{key, path}` 的输出顺序，以及 `mode: "0400"` → 256、`493` → 493、`"0777"` → 511；同时验证 `a/../b` → `b`、`./app//config.conf` → `app/config.conf`；对应 `验证设计` 的最小有效、较完整有效与 path 归一化项。
- [x] V2 `/tmp/sd-kube-chart/` 关键失败：覆盖 `key` 缺失/空/含空格、`path` 绝对路径/`../x`/`..`/空字符串、`mode` 为 `"0778"`/数值 `512`、非 map 上下文及字段错误类型；对应 `验证设计` 的关键失败项。
- [x] V3 `/tmp/sd-kube-chart/` 集成：用真实 `definitions.configMapVolumeSource` 接收 `items: ["key path", "key1 path1 0400"]`，确认调用真实 `definitions.keyToPath` 且不再使用 fixture；对应 `验证设计` 的集成边界项。
