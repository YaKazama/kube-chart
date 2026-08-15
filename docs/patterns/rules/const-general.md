# 通用开发约束

## 取值与渲染

- 必填缺失或类型非法时，必须通过 `required` 或 `fail` 尽早中断渲染。
- 报错格式统一为 `[模板名] 字段路径: 错误原因`，例：`{{- fail "[apps.deployment] image.repository: 必填" -}}`。。
- 多层字段统一使用 `base.get`；使用别名时调用 `base.getWithAlias`，别名优先。
- 同一 values 字段类型唯一；字段渲染使用对应的基础模板。
- bool 字段直接使用 `base.get`；map 使用 `fromYaml`，list 使用 `fromYamlArray`，并遵守 `const-boundary.md` 的兼容性规则。
- 模板入参最小化：单值传标量，同构集合传 list，多维状态传 dict；禁止无意义透传 `.`。
- 需要修改字典、列表、上下文或进行合并时，必须 `mustDeepCopy` 隔离，严禁污染 `.Values`。

## 模板与正则

- 字段按 Kubernetes API 顺序形成“处理—渲染”闭环；仅关联字段可集中处理后按 API 顺序输出。
- 多类型字段必须在上层完成类型归一化，再以 dict 传递给委托模板。
- 禁止创建未定义或仅占位的模板；模板名称使用末级目录前缀加小驼峰，`API` 等专有缩写可保留大写。
- 正则统一定义在 `templates/base/_env.tpl`；键名采用全大写下划线的嵌套结构。
- 简单正则可在父模板解析；复杂正则必须逐级解析。捕获结果使用 `mustRegexReplaceAll` 后必须 `trim`。
- 优先使用 Helm 提供的 `must*` 函数。包括 `mustToJson`、`mustToPrettyJson`、`mustToRawJson`、`mustToToml`、`mustRegexMatch`、`mustRegexFindAll`、`mustRegexFind`、`mustRegexReplaceAll`、`mustRegexReplaceAllLiteral`、`mustRegexSplit`、`mustDateModify`、`mustToDate`、`mustMerge`、`mustMergeOverwrite`、`mustDeepCopy`、`mustFirst`、`mustRest`、`mustLast`、`mustInitial`、`mustAppend`、`mustPrepend`、`mustReverse`、`mustUniq`、`mustWithout`、`mustHas`、`mustCompact`、`mustSlice`。

## 编码与验证

- 禁止输出 `status` 字段及相关逻辑。
- 代码按功能模块以空行分隔；`{{- else if }}` 与 `{{- else }}` 前保留空行。
- 验证临时文件仅可创建于 `/tmp/`，完成后必须清理。
- 所有模板修改必须执行 `helm lint`；未通过不得正式化。
- 模板分层、命名、注释和依赖方向遵守 `template-architecture.md`。
- 默认启用 `runAsNonRoot: true` 与 `readOnlyRootFilesystem: true`；默认禁用 `privileged` 与 `hostNetwork` 等高危权限。
