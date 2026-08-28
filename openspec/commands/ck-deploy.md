# `/ck-deploy`

## 职责

对整个 Chart 执行只读发布检查；不创建、修改、修复或归档 change。

```text
/ck-deploy
```

## 上下文

使用 `Chart.yaml`、正式模板、values、Schema、用户文档、稳定样例、既有稳定能力规格、适用工程规则和仓库已有发布命令。只读取检查项或失败直接涉及的文件。

可以列出活动 change 的实际文件，以确认是否存在 `status: spec | code` 的未 Review 实现；不读取活动 draft 正文、其他 change 规格正文或归档内容补充发布契约。

## 检查范围

- Chart 类型及 Kubernetes、Helm 版本基线满足声明要求。
- 不存在影响本次发布但仍处于 `spec` 或 `code` 状态的活动 change；仅有 draft 的意图不视为正式代码变化。
- 正式模板、values、Schema、稳定样例和用户文档一致。
- 按 [`../rules/helm-templates.md`](../rules/helm-templates.md) 执行完整 Chart lint 和真实 Helm 渲染，不复用 `/opsx-code` 或 `/opsx-fix` 的当前文件隔离检查代替。
- 使用仓库真实存在的项目命令确认核心样例可渲染，关键异常输入按适用规格失败。
- 无敏感信息硬编码，安全默认值符合项目规则。
- 发布涉及 values 时，`values.yaml`、Schema、`docs/` 和稳定样例一致。
- `/opsx-review` 的轻量结论、会话摘要或历史记录未被用作发布验证替代品。

## 输出

只在会话中输出实际命令、退出码、通过项、失败项、证据和发布结论。不得臆造仓库不存在的命令或校验器、用静态推断代替实际结果，或在失败后修改文件掩盖问题。
