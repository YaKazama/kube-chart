# `/opsx:verify`

## 职责

在 `/tmp/` 创建最小 application Chart，加载当前 change 已变更 Helm 模板及其必要依赖，并实际执行 `helm template`；不生成或修复正式代码，不执行完整 Chart 发布检查。

```text
/opsx:verify <change-id>
```

## 门禁

- 当前 change 的 spec、design 和 tasks 必须完整，验证设计和模板代码边界必须能够唯一确定。
- 验证目标由 design 的模板 write boundary、tasks 和当前文件事实共同确定；版本控制差异存在时作为变更证据，但不得因代码已经提交而丢失明确验证目标。没有可验证模板时停止并报告。
- Helm 可执行文件不存在、版本不满足项目基线或必要依赖契约无法构造时停止，不以静态推断替代实际渲染。

## 上下文

本动作只使用文件上下文，不使用聊天历史。读取当前 spec、design、tasks、design 中与验证直接相关的 write/read boundary、必要依赖、目标模板当前内容、可用的版本控制差异、[`../rules/helm-templates.md`](../rules/helm-templates.md) 和其他直接适用规则。

当前未实现依赖只能按 design 已锁定的最小契约在 `/tmp/` 提供同名 fixture；不得读取无关实现或把 fixture 结果表述为真实依赖集成通过。

## 输出

- 仅在 `/tmp/` 创建最小 `type: application` Chart；验证完成后按项目规则保留临时目录供用户检查。
- 最小 Chart 只装载当前已变更模板和渲染所需的直接依赖，覆盖最小有效输入、较完整有效输入和关键失败输入。
- 对每个场景实际执行 `/opt/homebrew/bin/helm template`，记录命令、退出码、关键输出和预期是否满足。
- 只有相关场景全部获得预期结果时，才勾选 tasks 中精确对应的验证 checkbox；失败、跳过或 fixture 边界不清时不勾选。
- 不修改 draft、spec 正文、design、task 文本、正式代码或用户文档，不改变 `confirmed`。
- 会话报告临时 Chart 路径、真实依赖与 fixture 边界、通过项、失败项、未覆盖项和验证结论；不声明完整发布检查通过。
