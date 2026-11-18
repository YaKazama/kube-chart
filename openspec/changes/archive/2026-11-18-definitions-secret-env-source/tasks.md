# definitions.secretEnvSource任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_SecretEnvSource.tpl`：仅新增 `definitions.secretEnvSource` 命名模板，按 `name`、`optional` 顺序渲染字段片段并覆盖归一、失败与省略边界；对应 `独立 SecretEnvSource 片段模板`、`名称归一、校验与引用输出复用基础能力`、`optional 空值省略与布尔校验`。

## 验证

- [x] V1 `/tmp/definitions-secret-env-source/name-only`：在最小 application Chart 中执行 `helm template` 调用 `definitions.secretEnvSource` 且仅传入 `name: app-secret`，预期输出仅含 `name: "app-secret"`。
- [x] V2 `/tmp/definitions-secret-env-source/normalization`：执行 `helm template`，分别以带首尾空白的 `name` 和原生 `false`、字符串 `"true"` 的 `optional` 调用，预期 `name` 已去除空白，`optional` 依次输出 `false`、`true`，字段顺序为 `name`、`optional`。
- [x] V3 `/tmp/definitions-secret-env-source/failures`：分别以缺失或空白的 `name`、非字符串 `name`、非法或超长 `name`、非法 `optional` 执行 `helm template`，预期每次渲染中断。
- [x] V4 `/tmp/definitions-secret-env-source/optional-empty`：分别以 `optional` 缺失、显式 `null`、空字符串和仅空白字符串执行 `helm template`，预期输出均不包含 `optional`。
