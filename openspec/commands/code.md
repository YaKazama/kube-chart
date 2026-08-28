# `/opsx-code`

## 职责

按已锁定的 `spec.md` 和代码锚点生成正式代码；不修订用户意图或行为契约，不生成其他 change 制品。

```text
/opsx-code <change-id>
```

## 门禁

- `spec.md` 不存在时中断并警告：必须先执行 `/opsx-spec <change-id>`。
- 只接受 `status: spec`；其他状态不修改文件。
- 技术目标、Requirement、Scenario 或代码锚点存在占位符、歧义、无效路径或相互冲突时停止。
- 用户执行本命令即确认已 Review 当前 spec 和手工调整后的代码锚点。

## 上下文

读取当前 `spec.md`、其中列出的代码锚点、[`../rules/change-documents.md`](../rules/change-documents.md) 以及按锚点文件类型路由的工程规则。

命令定义、工作流和规则属于控制上下文，不受代码锚点限制；正式代码、用户文档、样例、测试和依赖只允许读取 `## 代码锚点` 中列出的精确文件。不得读取 draft、其他 change、归档或锚点外实现。

## 输出

- 只修改代码锚点中的文件，以当前实现为基础幂等完成全部 Requirement 和 Scenario。
- 不允许用占位实现、fixture 或锚点外修改绕过缺失依赖；需要扩大锚点或改变契约时停止并报告。
- 本动作不声明 Review 或发布验证通过，不创建验证记录。
- 全部代码完成后，只把 `spec.md` frontmatter 更新为 `status: code` 和当前 `updated_at`；规格正文和代码锚点保持不变。
- 中途失败或存在未完成行为时保持 `status: spec`，报告已修改文件、未完成内容和阻塞原因，允许用户再次执行本命令续作。
