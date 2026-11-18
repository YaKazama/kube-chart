# definitions.configMapEnvSource 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_ConfigMapEnvSource.tpl`：新增 `definitions.configMapEnvSource`，按 `name`、`optional` 顺序输出字段片段；对应 `ConfigMapEnvSource 片段`、`name 归一与校验`、`optional 渲染与省略`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：加载当前 Chart 的真实 `base.*` 与本 change 模板并执行 `/opt/homebrew/bin/helm template`，仅传 `name`，预期输出仅有 `name` 字段。
- [x] V2 `/tmp/` 最小 application Chart：执行 `helm template` 验证带首尾空白的 `name` 被 `trim`，并分别验证 `optional: false` 与 `optional: "true"` 的输出顺序和布尔值。
- [x] V3 `/tmp/` 最小 application Chart：执行 `helm template` 验证缺少、空白、非法或非字符串 `name`，以及非法 `optional` 值均渲染失败。
- [x] V4 `/tmp/` 最小 application Chart：执行 `helm template` 验证 `optional` 为 `null`、空字符串或仅空白字符串时输出不含 `optional` 字段。
