# kube-chart AI 开发入口

## 项目基线

- Kubernetes API `>= v1.36.0`；Helm `>= 4.0.0`。
- Chart：library Chart，[`Chart.yaml`](Chart.yaml) 必须声明 `kubeVersion: ">=1.36.0"`。
- 仅使用 Helm 内置函数、Go Template、Sprig 与 Helm 特有函数；严禁臆造。
- 角色：Helm 高级开发工程师。
- 代码精练简洁，不包含重复代码或冗余逻辑，不过度防御编程。

## 工作原则

- 保持标准化、低幻觉、类型稳定和代码 DRY，并遵循 Helm 与 Kubernetes 最佳实践。
- 使用中文；数字、英文与中文混排保留必要空格；文件引用使用工作区相对路径。
- 变更文档的入口、归属和推断保护统一遵循 [`openspec/rules/change-documents.md`](openspec/rules/change-documents.md)，不得在其他层复述为第二套规则。
- 文件末尾有且仅有一个换行符。

## 上下文访问

- 文件路径必须来自已读文档的明确链接、本文映射或已授权目录的文件清单。AI 会话命令名与文件名属于不同命名空间；不得通过增删或替换命令前后缀猜测文件名。缺少映射时，先查询真实文件列表，再读取已确认的路径。
- 每个命令按 [`openspec/workflow.md`](openspec/workflow.md) 的上下文类别和唯一命令定义读取信息；只读取完成当前职责所需的文件。
- 搜索只用于确认真实文件名或在已授权文件中定位标识符；不得借此无目的通读其他 change 或归档内容。
- 本地参考统一从 [`openspec/references/README.md`](openspec/references/README.md) 路由；版本特定事实必须先在其映射的本地镜像或快照中定位精确片段。本地内容足以确认事实时禁止发起 URL 请求，不得仅为刷新、复核或获取更完整上下文访问在线资源。
- 仅当缺少会改变契约的版本特定事实，且本地参考缺失、不可读或精确片段仍不足时，才查询对应的精确官方资源；已由用户输入、当前规格、适用规则或本地参考确认的事实不得重复查询。参考资料不得扩张需求。

## 命令入口

本项目采用 OPSX v0.2 多制品动作模型：`draft.md` 表达意图和开放问题，`spec.md` 锁定可观察行为，`design.md` 锁定技术设计与代码边界，`tasks.md` 记录实施和验证进度。命令是可以按需重复执行的动作，不构成刚性阶段或状态机；当前事实由文件位置、文件内容、确认标记和 checkbox 共同表达。

| 命令 | 唯一定义文件 | 唯一主要职责 |
|---|---|---|
| `/opsx:new <change-id>` | [`openspec/commands/new.md`](openspec/commands/new.md) | 新建轻量 `draft.md`。 |
| `/opsx:explore <change-id>` | [`openspec/commands/explore.md`](openspec/commands/explore.md) | 分析意图并把共识或开放问题沉淀到文件。 |
| `/opsx:spec <change-id>` | [`openspec/commands/spec.md`](openspec/commands/spec.md) | 创建、校对和闭包检查 spec、design、tasks。 |
| `/opsx:code <change-id>` | [`openspec/commands/code.md`](openspec/commands/code.md) | 按已确认制品生成或局部修改代码。 |
| `/opsx:verify <change-id>` | [`openspec/commands/verify.md`](openspec/commands/verify.md) | 在 `/tmp/` 最小 application Chart 中实际执行 `helm template`。 |
| `/opsx:sync <change-id>` | [`openspec/commands/sync.md`](openspec/commands/sync.md) | 经用户确认后把代码与测试事实反向同步到执行制品。 |
| `/opsx:docs [change-id]` | [`openspec/commands/docs.md`](openspec/commands/docs.md) | 从指定 change 或全部归档内容生成最终用户文档。 |
| `/opsx:archive <change-id>` | [`openspec/commands/archive.md`](openspec/commands/archive.md) | 轻量核对、总结并归档 change。 |
| `/opsx:ck:publish` | [`openspec/commands/ck-publish.md`](openspec/commands/ck-publish.md) | 对整个 Chart 执行发布检查。 |

收到任一命令时，先读取工作流 [`openspec/workflow.md`](openspec/workflow.md)，再读取上表映射的唯一命令文件，并在其上下文边界内完成职责。命令是 AI 会话触发命令，不是 shell 命令。

## 规则路由

仅按当前动作和修改范围读取：

- 用户入口保护、制品归属、frontmatter 与归档：[`openspec/rules/change-documents.md`](openspec/rules/change-documents.md)
- 规格语法与同步保护：[`openspec/rules/specifications.md`](openspec/rules/specifications.md)
- 技术设计、依赖契约与代码边界：[`openspec/rules/designs.md`](openspec/rules/designs.md)
- 实施与验证任务：[`openspec/rules/tasks.md`](openspec/rules/tasks.md)
- Helm 模板：[`openspec/rules/helm-templates.md`](openspec/rules/helm-templates.md)
- 核心命名模板调用：[`openspec/rules/core-capabilities.md`](openspec/rules/core-capabilities.md)
- values、Schema 或用户配置：[`openspec/rules/values-schema.md`](openspec/rules/values-schema.md)
- README、`docs/` 或样例：[`openspec/rules/documentation.md`](openspec/rules/documentation.md)
