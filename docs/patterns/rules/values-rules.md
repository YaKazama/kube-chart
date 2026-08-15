# Values、Schema 与用户文档规则

## 当前探索期

- 每个已实现字段必须在正式 SDD 中记录类型、必填性、默认行为与关键约束。
- 保留最小有效输入、较完整有效输入和关键失败输入作为验证证据。
- 不要求每个模板立即维护完整的 `values.yaml`、`values.schema.yaml` 与用户文档。

## 后期收敛与发布

- 基于稳定的正式 SDD 和已验证样例汇总 `values.yaml`、`values.schema.yaml`、`guide/` 与 README。
- `values.schema.yaml` 是 Schema 单一来源；所有顶层字段声明类型，必填字段进入 `required`，枚举与依赖关系显式表达。
- `values.yaml` 字段说明包含类型、含义、是否必填与默认值。
- 禁止在 values、样例和文档中硬编码密钥、令牌、证书等敏感信息。
