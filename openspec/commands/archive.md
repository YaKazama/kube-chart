# `/opsx:archive`

## 职责

对当前 change 执行轻量文件核对，生成归档摘要并移动到归档目录；不修复代码、不同步制品、不生成用户文档，也不执行完整发布检查。

```text
/opsx:archive <change-id>
```

## 上下文

本动作只使用文件上下文，不使用聊天历史。读取当前 draft、spec、design、tasks、design 代码边界内的当前文件和版本控制事实、相关测试与文档事实、[`../rules/change-documents.md`](../rules/change-documents.md)，以及完成轻量核对直接需要的工程规则。

不得用聊天历史、旧会话摘要或未重新取得的验证输出补充归档证据。

## 轻量核对

- `openspec/changes/<change-id>/` 是否存在，归档目标是否不存在。
- spec、design、tasks 是否完整，frontmatter 是否有效，`confirmed` 是否为 `true`，四向闭包是否成立。
- tasks 是否全部完成且 checkbox 具有当前文件事实支撑。
- 当前代码、spec、design 和 tasks 是否同步，write boundary 是否存在越界修改。
- `docs/` 与根 `README.md` 是否需要更新；需要时是否已完成或已明确记录为归档后的文档动作。
- draft 或笔记中是否存在会阻塞归档的未关闭问题。
- 是否建议先运行 `/opsx:docs <change-id>`、`/opsx:verify <change-id>` 或在归档后运行 `/opsx:ck:publish`。

文档或发布检查不是默认的隐式阶段门禁；只有当前 spec、design 或 tasks 明确要求且尚未完成时才阻塞归档。阻塞性开放问题、缺失制品、未完成任务、代码与制品不一致或越界修改必须阻塞。

## 输出

- 核对失败时不修改文件，按“缺失项、风险项、建议动作”输出归档检查结果。
- 核对通过时输出变更目标、关键行为、设计边界、修改文件、验证事实、文档状态、已知风险和后续发布建议组成的归档摘要。
- 把完整目录移动到 `openspec/changes/archive/YYYY-MM-DD-<change-id>/`；目标存在时不覆盖，移动失败时保留活动目录并报告实际位置。
- 不新增状态字段或归档记录文件，不把轻量核对表述为完整发布检查通过。
