# 设计规则

## 设计权威

- `design.md` 是当前 change 的技术目标、实现决策、依赖契约、代码边界和验证设计的唯一来源；它不得创建或改变用户可见行为。
- 每项设计必须映射到当前 `spec.md` 的 Requirement、Scenario、失败边界，或映射到适用工程规则；正式代码只能确认当前事实，不能反向生成行为需求。
- design 与 spec 冲突时停止；不得用实现便利覆盖行为契约。

## design.md 结构

```markdown
# <变更名称>设计

## 技术目标

- capability：`<能力>`
- artifact-type：`<产物类型>`
- target：`<唯一目标路径或标识符>`

## 设计决策

### Decision: <名称>

- requirements：`<Requirement 名称>`
- choice：<唯一实现选择>
- rationale：<选择依据；只引用当前规格、工程规则或当前事实>

## 依赖契约

### Dependency: `<命名模板或能力>`

- availability：`existing | unavailable`
- source：`<工作区相对精确路径；unavailable 时写“无”>`
- operation：`consume | add | update | remove | rename`
- input：<精确入参边界>
- output：<最小返回类型、空值和错误边界>
- ownership：<本层与依赖层各自负责的行为>

## 代码边界

### `<工作区相对精确文件路径>`

- access：`read | write`
- operations：`<作用于精确符号、字段或文档区段的 operation>`
- writable-scopes：`<仅 access: write；精确符号或区段>`

## 验证设计

- <最小有效、较完整有效和关键失败场景及真实依赖或 fixture 边界>
```

## 设计闭包

- 技术目标必须唯一确定 capability、产物类型和 target；存在会改变行为或文件边界的未决项时不得创建设计。
- 每个直接依赖必须记录 availability、source、operation、input、output 和 ownership。`existing` 必须对应真实精确 source；`unavailable` 必须由 spec 已锁定调用契约且明确不在本 change 实现。
- operation 由当前事实与目标状态比较得到：既有能力完全一致时为 `consume`；缺失且当前 change 明确负责新增时为 `add`；现状与目标不同但用户未授权共享行为变化时停止，不自行选择 `update` 或新键。
- 代码边界按文件聚合。同一文件只有 `consume` 时为 `access: read`；存在 `add | update | remove | rename` 时为 `access: write`。write 文件仍只能修改 writable scope，其他内容视为只读。
- 同一文件不得重复列为 read 和 write。read/write 是当前 change 的权限，不是文件的永久属性。
- design 只记录实现决策和边界，不复制 Requirement 或 Scenario 正文，不写任务进度或验证结论。
- 验证设计必须区分真实依赖与 fixture；当前未实现依赖的 fixture 只证明调用方自身行为。
