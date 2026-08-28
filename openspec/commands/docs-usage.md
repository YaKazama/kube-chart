# `/docs-usage`

## 职责

独立生成和维护面向最终用户的使用文档：更新 `docs/` 下的用户文档，并更新工作区根目录 `README.md`。不创建、修改、修复或归档 change。

```text
/docs-usage
```

## 前置条件

- 不存在 `status: spec` 或 `status: code` 的活动 change；仅有 draft 的意图不阻塞本命令。
- 文档只覆盖已完成 `/opsx-review` 并已归档的稳定能力，以及不依赖活动 change 的既有正式实现。
- 缺少支撑某项用户可见行为的已归档规格、正式代码或稳定样例时，停止该项文档生成并报告缺口；不得以推断补全。

## 上下文

读取 `Chart.yaml`、正式模板、values、Schema、现有 `docs/`、工作区根目录 `README.md`、稳定样例、已归档且 `status: reviewed` 的规格，以及 [`../rules/documentation.md`](../rules/documentation.md) 和按文件类型适用的工程规则。只读取生成或校验文档直接需要的文件。

可以列出活动 change 的实际文件，以确认是否存在 `status: spec | code` 的未 Review 实现；不读取活动 draft 正文、活动 spec 正文或其他无关归档内容。

## 输出

- 依据已完成 Review 的正式实现、规格与稳定样例，生成或更新 `docs/` 下的最终用户文档，并同步更新工作区根目录 `README.md`。
- 根 `README.md` 保持安装或导入方式、核心原则、可用模板清单、最小示例、常见问题和迁移说明；细节内容放入 `docs/` 并使用真实存在的相对链接。
- 删除或改写已不再反映稳定实现的用户文档内容；不得删除 `docs/` 中无法确认归属或影响范围的文件，并应报告该阻塞。
- 不修改 `openspec/changes/`、正式模板、values、Schema、稳定样例或其他代码文件。
- 在会话中输出修改文件、文档覆盖范围、未覆盖项及其证据；本动作不声明 Chart 发布验证通过。
