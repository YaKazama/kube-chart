# `/opsx:ck:publish`

## 职责

对整个 Chart 执行只读发布检查；不创建、修改、修复、同步或归档 change。

```text
/opsx:ck:publish
```

## 上下文

本动作只使用文件上下文，不使用聊天历史。读取 `Chart.yaml`、正式模板、values、Schema、用户文档、稳定样例、既有稳定能力规格、活动 change 的文件事实、适用工程规则和仓库已有发布命令。只读取检查项或失败直接涉及的内容，但检查范围覆盖整个 Chart。

活动 change 依据目录、制品完整性、确认标记、task checkbox、代码差异和开放问题判断发布风险，不读取或推断旧阶段状态。归档内容只在校验稳定用户契约或文档来源确有需要时读取。

## 检查范围

- Chart 类型及 Kubernetes、Helm 版本基线满足声明要求。
- 不存在已影响正式代码但制品不完整、未确认、任务未完成、代码未同步或有阻塞性开放问题的活动 change；只有 draft 且未影响正式代码的意图不阻塞。
- 正式模板、values、Schema、稳定样例和用户文档一致。
- 按 [`../rules/helm-templates.md`](../rules/helm-templates.md) 对整个 Chart 实际执行 `/opt/homebrew/bin/helm lint .`，并用仓库真实存在的 Helm 命令验证核心样例和关键失败输入。
- 无敏感信息硬编码，安全默认值符合项目规则。
- 发布涉及 values 时，`values.yaml`、Schema、`docs/` 和稳定样例一致。
- `/opsx:verify` 的最小 Chart 结果、`/opsx:archive` 摘要或历史会话没有被用作完整发布检查的替代品。

## 输出

只在会话中输出实际命令、退出码、通过项、失败项、证据和发布结论。不得臆造仓库不存在的命令或校验器、用静态推断代替实际结果，或在失败后修改文件掩盖问题。
