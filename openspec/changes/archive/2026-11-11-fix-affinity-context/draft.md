---
change-id: fix-affinity-context
updated_at: "2026-11-11T13:23:41Z"
---

# 清理 Definitions 模板中遗留的顶层 `$` 上下文引用

## 目标

- 清理 `fix: affinity 子模板改为逐字段直白写法`（`ee61370`）展开 `range` 派发后，在 `define` 顶层作用域中遗留的 `$` 上下文引用。

## 需求

- 把 `define` 顶层作用域中 `include` / `base.get` 调用里的 `$` 改为 `.`，消除已失去作用域区分意义的历史写法。
- 统一采用 `.`；不使用「保留 `$` 并补充说明性注释」的方案。
- 修改范围包含 `templates/api-resources/Definitions/_NodeSelector.tpl` 第 25 行；该文件的 `definitions-node-selector` change 已归档，不再占用活动写边界。
- 只处理 `$` 与 `.` 在顶层作用域完全等价的调用点；行为、失败消息与输出必须保持不变。
- 处于 `range`、`with` 等嵌套作用域内、`$` 仍承担外层上下文语义的调用点必须保持原样。
- 修改范围限定为 `templates/api-resources/Definitions/` 下的既有模板，不改变任何命名模板的入参、返回值和失败边界。

## 约束

- 该遗留来自 `53515ce` 首次实现时 `range $_name := $names` 内部的 `include "base.get" (list $ $_name)`；`ee61370` 删除外层 `range` 后未同步把 `$` 改为 `.`，两种写法在当前代码中完全等价。
- 已知受影响的顶层调用点共 18 处：

  | 文件 | 行 |
  |---|---|
  | `templates/api-resources/Definitions/_Affinity.tpl` | 27、56、85 |
  | `templates/api-resources/Definitions/_NodeAffinity.tpl` | 27、80 |
  | `templates/api-resources/Definitions/_PodAffinity.tpl` | 27、30 |
  | `templates/api-resources/Definitions/_PodAntiAffinity.tpl` | 29、32 |
  | `templates/api-resources/Definitions/_PodAffinityTerm.tpl` | 38、59、76、93、114、130 |
  | `templates/api-resources/Definitions/_NodeSelectorTerm.tpl` | 30、36 |
  | `templates/api-resources/Definitions/_NodeSelector.tpl` | 24 |

- 必须保持原样：`templates/api-resources/Definitions/_NodeSelectorRequirement.tpl` 第 37 行的 `(list $ $_name ...)` 位于 `range $_name := list "key" "operator"` 内，`$` 仍指向 `define` 顶层入参。
- 实施过程中 5 个文件的 `{{- define ... -}}` 之后紧邻空行被删除；该空行由 `-}}` 裁剪、不产生输出，属排版事实，本 change 接受现状并不再恢复。
- 本次为纯样式收敛但仍须做最小渲染验证，不能只做静态检查。
- 仅使用 Helm 内置函数、Go Template、Sprig 与 Helm 特有函数；本次不新增或删除任何函数调用。

## 非目标

- 不改变任何模板的可观察行为、失败消息文本、输出字段顺序或类型门禁。
- 不调整 `$.Values`、`$.Release` 等真正依赖 `$` 根上下文语义的引用。
- 不重构 `range`、`with` 结构，也不合并或拆分既有模板。
- 不新增、改名或删除命名模板。
- 不修改 `templates/base/`、`api-resources/Definitions/` 以外的模板。

## 验收

- `templates/api-resources/Definitions/` 下 `define` 顶层作用域的 `include` / `base.get` 调用不再出现 `(list $ ...)` 形式。
- `_NodeSelectorRequirement.tpl` 中 `range` 内部的 `$` 保持不变。
- 各模板的 `define` 名称、入参、返回值与失败消息文本与修改前逐字一致。
- `definitions.affinity`、`definitions.nodeAffinity`、`definitions.podAffinity`、`definitions.podAntiAffinity`、`definitions.podAffinityTerm`、`definitions.nodeSelectorTerm`、`definitions.nodeSelector` 的既有渲染结果不变。
- 在 `/tmp/` 最小 application Chart 中实际执行 `helm template`，至少覆盖 `definitions.affinity` 一条完整链路与 `definitions.nodeSelector` 一条链路，输出与修改前一致。

## 开放问题

- 无。
