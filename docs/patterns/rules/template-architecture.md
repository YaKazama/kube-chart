# 模板架构与命名规则

## 分层与依赖

```text
base → Definitions → api-resources / cloud / extensions
```

- `base`：取值、校验、字符串、路径、错误等通用原子能力；不得依赖上层。
- `Definitions`：可复用 Kubernetes 结构；不得包含资源编排。
- `api-resources`：Kubernetes 原生资源，字段对齐官方 API。
- `cloud`：云厂商适配，禁止跨厂商依赖。
- `extensions`：第三方 CRD，必须声明 CRD 版本。

## 命名与语法

- `templates/` 下除 `NOTES.txt` 外的文件必须以 `_` 开头。
- `templates/base/` 下的文件使用 `_<小写>.tpl`；`templates/` 下其余子目录中的文件使用 `_<大驼峰>.tpl`。
- 模板名称使用末级目录前缀加小驼峰，例如 `apps.deployment`。
- 每个 `define` 块使用中文注释说明功能、边界、入参、返回值与示例。
- 使用 2 空格缩进，必要时用 `{{- nindent 0 "" -}}` 优化 YAML 排版；库 Chart 模板首尾不得输出 `---`。
- 模板定义统一使用 `{{- define "x.y" -}}` 与 `{{- end }}`；禁止一行定义语法。
- 模板实现必须兼顾执行效率、性能与人类可读性。
- 局部变量使用 `$var`；临时变量使用 `$_` 或 `$__` 前缀。`base.get` 的临时结果通常使用同名 `$_` 或 `$__` 变量保存。
- 父 Chart 负责跨资源编排与 Hooks；嵌套资源必须重构独立上下文并隔离状态。
