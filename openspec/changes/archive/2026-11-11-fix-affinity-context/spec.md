---
updated_at: "2026-11-11T13:16:24Z"
---

# 清理 Definitions 模板顶层 `$` 上下文引用规格

## NO SPEC DELTA

本 change 只把 `define` 顶层作用域中 `include` / `base.get` 参数里的 `$` 替换为等价写法 `.`，属于纯内部表达收敛。

受影响能力为 `definitions.affinity`、`definitions.nodeAffinity`、`definitions.podAffinity`、`definitions.podAntiAffinity`、`definitions.podAffinityTerm`、`definitions.nodeSelectorTerm`、`definitions.nodeSelector`。

理由：

- `$` 在 `define` 顶层与 `.` 指向同一个入参 map，替换后两者的取值、类型与作用域语义完全一致。
- 各模板的输入契约、输出字段与顺序、失败消息文本、失败时机都没有变化。
- 不新增、删除或改名任何命名模板，也不改变任何字段的生效条件或类型门禁。

因此本 change 不产生可观察行为变化，不写入 ADDED、MODIFIED、REMOVED 或 RENAMED Requirement。

## 非目标

- 不改变任何模板的可观察行为、失败消息文本、输出字段顺序或类型门禁。
- 不调整 `$.Values`、`$.Release` 等真正依赖 `$` 根上下文语义的引用。
- 不重构 `range`、`with` 结构，也不合并或拆分既有模板。
- 不新增、改名或删除命名模板。
