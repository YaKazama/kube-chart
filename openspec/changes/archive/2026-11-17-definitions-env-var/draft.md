---
change-id: definitions-env-var
updated_at: "2026-11-17T15:05:07Z"
---

# definitions.envVar

## 目标

- 新增命名模板 `definitions.envVar`，把单个环境变量上下文渲染为 Kubernetes `EnvVar` 结构。
- 把 `valueFrom` 的抽象字符串语法第一层拆解为 `EnvVarSource` 的目标字段，并统一经由占位子模板 `definitions.envVarSource` 完成第二层渲染。

## 需求

- 入参为父级传入的单个环境变量 map，含 `name` 以及 `value` 或 `valueFrom` 之一；取值从当前作用域读取。
- 支持以下输入上下文形态：
  - `name: string`、`value: string`
  - `name: string`、`value: 非 string 标量`
  - `name: string`、`valueFrom: string`
  - `name: string`、`valueFrom: 原生 map`
- `name` 必填；`value` 与 `valueFrom` 互斥且各自可选；两者同时出现时中断报错。
- 只渲染官方文档约定的 `EnvVar` 字段；入参中的其他键静默忽略。
- `name` 缺失或为空时中断报错。
- `value` 与 `valueFrom` 同时缺省时不渲染该字段，仅输出 `name`。
- `value` 为非 string 标量时强制以双引号字符串输出，不中断渲染；`value` 为 string 时同样以双引号字符串输出。
- `value` 为 map 或 list 时中断渲染，因其无法构成合法的 `EnvVar.value` 字符串。
- `valueFrom` 为原生 map 时原样向下透传，不做正则解析；该 map 的字段名需与 `EnvVarSource` 及后续模板所需的字段完全一致，本模板不做校验和转换。
- `valueFrom` 为抽象字符串时采用正则匹配，关键字大小写不敏感；分隔符使用 `templates/base/_env.tpl` 中 `base.env` 的 `SPLIT.SPACE_COMMA`，逗号与空白等价。
- 字符串形态只切分两段：第 1 段为关键字，第 2 段为孙模板所需的值原串；本 change 不处理第二层拆分。
- 关键字不匹配或段数不足时无法构成 `{<EnvVarSource 字段>: <第 2 段原串>}`，此时不渲染 `valueFrom` 字段，仅输出 `name`，不报错。
- 第 1 段关键字与 `EnvVarSource` 字段的对应关系：
  - `configMap`、`cm` → `configMapKeyRef`
  - `field` → `fieldRef`
  - `file` → `fileKeyRef`
  - `resource` → `resourceFieldRef`
  - `secret` → `secretKeyRef`
- `valueFrom` 的子模板为 `definitions.envVarSource`，本 change 仅占位调用，不创建该模板，也不新增占位 `define`。
- 验收阶段以子模板返回值正确为前提；`/opsx:verify` 在 `/tmp/` 最小 Chart 中以同名最小 fixture 代替它，该结果只证明本模板自身的分支与调用，不代表真实依赖集成通过。
- 传给 `definitions.envVarSource` 的上下文：原生 map 直接向下传递；字符串则组装为 `{<EnvVarSource 字段>: <第 2 段原串>}`，例如 `{configMapKeyRef: "cm-name key optional"}`，该字符串的正则解析由子模板完成。
- 孙模板所需的字段拆分、校验与缺省处理由 `definitions.envVarSource` 负责，不在本 change 实现范围。
- 可选段缺省时参考原生字段语义，通常缺省时不渲染对应字段。
- 本模板不负责渲染结果的回收、去重与去空；这些由父级 `definitions.container.array` 完成。
- `templates/api-resources/Definitions/_Container.tpl` 的三处 `definitions.enVar` 引用在本 change 内一并修正为 `definitions.envVar`。

## 期望输入格式

- `definitions.envVar` 的入参为单个环境变量的 map，键为 `name`、`value`、`valueFrom`。
- `valueFrom` 的字符串形态使用下列语法，第 1 段为关键字，后续段为孙模板所需的值。
- 段之间可混用逗号或空格作为分隔符；方括号表示该段可选。

  ```text
  # ConfigMapKeySelector
  <configMap|cm> <name> [key] [optional]
  # fieldRef
  <field> <fieldPath> [apiVersion]
  # fileKeyRef
  <file> <volumeName> <path> [key] [optional]
  # resourceFieldRef
  <resource> <resource> [containerName] [divisor]
  # secretKeyRef
  <secret> <name> [key] [optional]
  ```

## 约束

- 取值使用 `base.get`。
- 第一层解析只产出 `{<EnvVarSource 字段>: <剩余原串>}`，不展开选择器对象内部结构。

## 非目标

- 不创建 `definitions.envVarSource` 子模板本体。
- 不实现 `definitions.envVarSource` 内部逐字段映射（`configMapKeyRef`、`fieldRef`、`fileKeyRef`、`resourceFieldRef`、`secretKeyRef` 的对象细节）。
- 不对齐第二层语法与参考正则 `k8s.container.envVar*` 的差异（`envVarSecret` 的 `key` 是否必填、`envVarFile` 是否含 `key` 段），由后续子模板 change 处理。
- 不处理容器级 `env` 列表的聚合、去重与去空逻辑。

## 验收

- 三种输入形态分别渲染出结构正确的 `EnvVar` 结果。
- `value` 为 string 或非 string 标量时均输出带双引号的字符串，不出现数字或布尔类型。
- 抽象字符串的每个关键字都映射到对应的 `EnvVarSource` 字段，关键字大小写不敏感，`configMap` 与 `cm` 等价。
- 关键字不匹配或段数不足时，不渲染 `valueFrom` 字段，仅输出 `name`，不产生渲染错误。
- 原生 map 形态的 `valueFrom` 原样透传；字符串形态按 `{<EnvVarSource 字段>: <第 2 段原串>}` 传给子模板。
- `name` 缺失时中断报错；`value` 与 `valueFrom` 同时出现时中断报错；两者同时缺省时仅输出 `name`。
- `_Container.tpl` 不再出现 `definitions.enVar`。
- 子模板仅占位，不引入本 change 之外的实现。

## 开放问题

- 无。
