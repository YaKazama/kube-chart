# 核心模板能力

## `base.get`

`base.get` 是统一取值能力，返回 YAML 字符串；按结果类型配合 `fromYaml` 或 `fromYamlArray` 使用。

- 入参：`list <上下文> <点分路径> [强制类型] [合并模式] [必填校验布尔] [调试布尔]`。
- 强制类型：`int`、`int64`、`float64`、`atoi`、`toString`、`toStrings`、`toDecimal`、`quote`、`squote`。
- 优先级：CLI 覆盖参数 > 模板内部上下文 > `.Context` > `.Values` > `.Values.global`。
- dict 默认左优合并，`right` 为右优覆盖；list 默认 concat、去空、去重，`replace` 为全量替换。
- 合并 `.Values` 嵌套 dict 时必须使用 `mustDeepCopy`，不得污染原始上下文。
- 非必填字段不存在时返回对应类型零值；必填字段缺失时立即报错。

## `base.field`

`base.field` 安全渲染 YAML 键值对，负责引号、枚举和特殊类型的字段输出。

- 入参：`list <key> <value> [渲染模板/quote] [允许值列表枚举]`。
- 默认使用 `base.string`；数值分别使用 `base.int`、`base.int64`、`base.float64`；强制字符串使用 `quote`；容器环境变量使用 `containers.env`。
- 必填字段不得用默认值掩盖缺失；字段类型与渲染模板必须与正式 SDD 一致。

## Kubernetes 通用能力

- 元数据名称优先级：`fullname` > `name`；名称超过 63 个字符必须报错。
- `helmLabels`、`justNameLabel` 和自定义 `labels` 按既定互斥与合并规则处理；`justNameLabel` 为 true 时只保留 name 标签，用户标签可覆盖默认标签。
- 镜像优先级：内联 `image` 字符串 > `imageRef`。`imageRef.repository` 必填；按 `registry/namespace/repository:tag@digest` 拼接，空 namespace 省略。
- `*FieldRefs` 优先级：`*FileRefs` > 结构化字段 > 内联字段。`filePath` 必须为通过 base 层校验的相对路径。
- 容器级引用可使用 `fieldPaths` 点分取值；配置级引用可指定 `key`，为空时使用文件名。

## 资源与父 Chart 边界

- 库 Chart 负责资源模板渲染与嵌套资源上下文重构；模板首尾不得输出 `---`，不得自行通过 `range` 拼接多个独立资源。
- 库 Chart 不处理 Helm Hooks；父 Chart 负责跨资源编排与 Hooks。
- 二级嵌套资源必须在子模板入口使用 `mustDeepCopy` 与 `mustMergeOverwrite` 构造隔离上下文。
- 父 Chart 必须构造局部 `$ctx` 注入业务配置，禁止直接篡改全局上下文。
