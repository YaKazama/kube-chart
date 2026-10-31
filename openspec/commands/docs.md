# `/opsx:docs`

## 职责

独立生成和维护 `docs/` 最终用户文档并更新根 `README.md`，把指定活动 change 或全部归档内容中已经由正式代码支持的行为提炼为用户可见文档。不修改 change 制品或正式代码。

```text
/opsx:docs [change-id]
```

## 上下文

本动作只使用文件上下文，不使用聊天历史。

带 change-id 时读取：

- `openspec/changes/<change-id>/*.md`；
- 这些制品明确涉及的代码命令、配置和接口定义；
- 已有 `docs/`、根 `README.md`、稳定样例；
- [`../rules/documentation.md`](../rules/documentation.md) 和按目标文件类型适用的规则。

不带 change-id 时读取：

- `openspec/changes/archive/*/*.md` 中全部归档根目录 Markdown 制品；
- 归档内容明确涉及的代码命令、配置和接口定义；
- 已有 `docs/`、根 `README.md`、稳定样例；
- [`../rules/documentation.md`](../rules/documentation.md) 和按目标文件类型适用的规则。

文件清单只用于解析上述真实路径。归档陈述与当前代码不一致时以当前正式接口事实过滤过时内容，但不得从代码独自推导新的用户契约。

## 门禁

- 带 change-id 时，确切活动 change 必须存在；不得自动改为读取同名归档。
- 带 change-id 时，spec、design 和 tasks 必须完整闭包，`spec.md` 必须为 `confirmed: true`，且相关行为已有正式实现证据。
- 某项行为缺少明确规格来源、正式实现或必要验证依据时，跳过该项并报告证据缺口，不以推断补全。
- 未确认 `[AI 推断]`、开放问题、未实现规格或仅存在于 fixture 的能力不得写成已支持功能。

## 输出

- 仅更新 `docs/` 下最终用户文档和工作区根 `README.md`。
- 根 README 保持安装或导入方式、核心原则、可用模板清单、最小示例、常见问题和迁移说明；详细内容放入 `docs/` 并使用真实存在的相对链接。
- 带 change-id 时只修改能精确归属于该 change 的内容；不带时处理全部归档对当前用户文档的累积影响。
- 删除或改写已不再反映正式实现的内容前，必须能从所选 change 范围和当前接口事实确认归属；无法确认时保留并报告风险。
- 不修改 `openspec/changes/`、正式模板、values、Schema、稳定样例或其他代码文件。
- 会话输出修改文件、文档覆盖范围、跳过项和证据；不声明发布检查通过。
