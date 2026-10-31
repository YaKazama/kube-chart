# 任务规则

## 任务权威

- `tasks.md` 是当前 change 的实施顺序和验证工作的唯一来源，只把 design 转换为可执行步骤，不创建新的行为、设计选择、依赖或文件边界。
- task 文本只由 `/opsx:spec` 创建或校对，或由 `/opsx:sync` 经确认后同步；`/opsx:code` 和 `/opsx:verify` 只能更新具有当前事实证据的 checkbox。

## tasks.md 结构

```markdown
# <变更名称>任务

## 实施

- [ ] T1 `<write boundary 路径>`：<精确实施结果>；对应 `<Decision 或 Requirement 名称>`。

## 验证

- [ ] V1 `<验证边界>`：<实际命令或场景及预期结果>。
```

## 任务闭包

- 每项 write operation 至少映射到一个实施 task；read boundary 不得产生修改任务。
- 每项实施 task 必须引用 design 中唯一的 write boundary 和 writable scope，不得使用目录、glob、候选路径或自然语言文件占位符。
- task 按依赖顺序排列；共享常量或基础能力的写入先于消费者，消费者实现先于对应验证。
- 每项验证设计至少映射到一个验证 task，明确真实依赖或 `/tmp/` fixture 边界；不得把轻量验证表述为完整发布检查。
- `/opsx:code` 只有在 task 的代码结果已生成且明显静态错误检查通过后才能勾选对应实施 task；失败、跳过或仅推断完成不得勾选。
- `/opsx:verify` 只有在 `/tmp/` 最小 application Chart 中实际执行对应 `helm template` 场景并获得预期结果后，才能勾选验证 task。
- 全部 task 勾选只表示任务具有当前证据，不替代 `/opsx:archive` 的轻量核对或 `/opsx:ck:publish` 的发布检查。
