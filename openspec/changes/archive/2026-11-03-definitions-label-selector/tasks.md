# definitions.labelSelector 任务

## 实施

- [x] T1 `templates/base/_env.tpl`：将 `K8S.SELECTOR` 的 `EQUALITY0`、`SET0`、`SET_EXISTS` 重命名为 `EQUALITY_FOR_APPS`、`SET_FOR_APPS`、`EXISTS_FOR_APPS`，正则内容保持不变；对应 `Decision: 正则常量重命名但内容不变`。
- [x] T2 `templates/api-resources/Definitions/_LabelSelector.tpl`：新增 `definitions.labelSelector`，通过 `base.get` 使用内置别名，归一化 string/map 表达式，按大小写不敏感输入归一化 operator，清洗并恢复 values 为 string，非法字符串和空集合均失败，归一化项 `include` `definitions.labelSelectorRequirement` 并校验收返回非空 map，最后按 `matchExpressions` → `matchLabels` 渲染；本 change 不创建占位模板；对应 `Decision: 表达式归一化后委托占位模板`、`Decision: 非法字符串和空集合均失败`、`Decision: operator 输入大小写不敏感、输出规范大小写`、`Decision: 仅使用 base.get 内置别名`、`Decision: values 统一清洗并恢复为字符串`、`Decision: matchLabels 保持必填和直接渲染`。
- [x] T3 `templates/api-resources/Apps/_DeploymentSpec.tpl`：在 selector 的 `pick` 列表中加入 `matchExpressionsAlias`、`matchLabelsAlias` 并原样传给 `definitions.labelSelector`，不改变现有 `matchLabels` 与 `base.labels` 合并逻辑；对应 `Decision: apps.deploymentSpec 仅透传内置别名`。

## 验证

- [x] V1 `/tmp/` 最小 Chart 加载真实 `_env.tpl`、base 模板和 `_LabelSelector.tpl`，并提供同名 `definitions.labelSelectorRequirement` fixture，执行 `helm template`：仅 `matchLabels`、以及覆盖 `=`、`==`、`!=`、`in`、`notin`、裸 key、`!key`、原生 `in`、原生 `NOTIN`、原生 `Exists` 的完整输入，输出顺序为 `matchExpressions` 后 `matchLabels`，values 为清洗并转为 string 的列表。
- [x] V2 `/tmp/` 最小 Chart 加载同名 `definitions.labelSelectorRequirement` fixture，执行 `helm template` 验证关键失败：`matchLabels` 缺失或非 map、标签值非 string、`matchExpressions` 非 array、未知元素类型、非法字符串、空 `in`/`notin` 列表、未知 operator、`In`/`NotIn` values 缺失或为空、`Exists`/`DoesNotExist` 携带非空 values，均失败并中断。
- [x] V3 `/tmp/` 最小 Chart 加载同名 `definitions.labelSelectorRequirement` fixture，执行 `helm template` 验证内置别名和正则边界：`matchLabelsAlias`、`matchExpressionsAlias` 生效且优先于规范键，`mExprs`、`mLabels` 不被读取；覆盖 `.`、`_`、`-` 和大小写不敏感的 `in`/`notin`。
- [x] V4 `/tmp/` fixture 加载 `apps.deploymentSpec` 及 selector 依赖，使用同名 fixture 补齐 `definitions.deploymentStrategy`、`core.podTemplateSpec`、`definitions.labelSelectorRequirement`，执行 `helm template`：`pick` 保留 `matchLabelsAlias`、`matchExpressionsAlias` 并原样传入 `definitions.labelSelector`；仅提供 `matchLabels` 时行为保持不变。只视为调用方局部验证，不作为完整资源集成证据。
- [x] V5 `/tmp/` fixture 分别让 `definitions.labelSelectorRequirement` 返回空、无效 YAML 和非 map，执行 `helm template`，确认 `definitions.labelSelector` 失败并中断；只证明调用方行为，不代表占位模板实现已验证。
- [x] V6 `/tmp/` 最小 Chart 加载同名 `definitions.labelSelectorRequirement` fixture，执行 `helm template`：`matchLabels` 为空 object 时失败并中断；`matchExpressions` 为 `null` 时按缺失处理，输出不包含 `matchExpressions`。
