---
change-id: definitions-secret-key-selector
updated_at: "2026-11-17T17:43:59Z"
---

# definitions.secretKeySelector

## 目标

- 新增命名模板 `definitions.secretKeySelector`，把 map 上下文渲染为 Kubernetes `SecretKeySelector` 字段片段。
- 供 `definitions.envVarSource` 的 `secretKeyRef` 分支调用。

## 需求

- 入参上下文为 map。
- `name` 与 `key` 均为必填字段；缺失或为空时中断渲染。
- 按官方文档字段顺序渲染：`key`、`name`、`optional`。
- 字段类型按官方定义：`key` 为 string，`name` 为 string，`optional` 为 boolean。
- `optional` 为可选字段，缺省时不输出。
- 取值使用 `base.get`。
- 父级 `definitions.envVarSource` 的 `secretKeyRef` 字符串简写必需段数由 1 调整为 2，与 `configMapKeyRef` 对齐。
- 只渲染官方文档约定的三个字段；入参中的其他键静默忽略。
- `optional` 接受原生布尔值以及字符串 `true`／`false`，显式 false 也输出；数字、map、list 与其他字符串视为类型错误。`definitions.configMapKeySelector` 与 `definitions.fileKeySelector` 同步采用相同取值规则。
- `name` 必须是合法的 Secret 名称，即 RFC1123 Subdomain：总长不超过 253 字符，仅小写字母数字与 `-`、`.`，每段不超过 63 字符且首尾为字母数字；不采用 RFC1035 或 RFC1123 Label 规则。
- `key` 必须匹配 Secret data key 字符集 `[-._a-zA-Z0-9]+`：允许大小写字母、数字、`-`、`_`、`.`，不限制首尾字符与最大长度；空值与不匹配时中断渲染。
- `definitions.configMapKeySelector` 的 `key` 同步采用同一字符集校验，两个选择器行为保持一致。

## 期望输入格式

- `definitions.secretKeySelector` 的入参为单个 `SecretKeySelector` map，键为 `key`、`name`、`optional`。

## 约束

- `name` 与 `key` 为空或缺失即中断，不使用默认值掩盖缺失。
- `key` 的字符集正则集中定义在 `templates/base/_env.tpl` 的 `base.env`，由两个选择器共用，不在业务模板内联。
- `definitions.configMapKeySelector` 的 `key` 从「仅非空」变为字符集校验，属既有能力的可观察行为变化，随本 change 一并交付。
- 输出为单层字段片段，不包含 `secretKeyRef` 父键。

## 非目标

- 不渲染 `EnvVarSource` 的其他字段。
- 不实现 `definitions.envVarSource` 的分发与互斥逻辑。
- 不校验 `name` 指向的 Secret 是否存在，也不校验 `key` 是否存在于该 Secret。

## 验收

- 最小输入 `name` 与 `key` 能渲染出合法的 `SecretKeySelector` 字段片段。
- 三个字段齐全时按 `key`、`name`、`optional` 顺序输出。
- `optional` 缺省时只输出 `key` 与 `name`。
- `name` 或 `key` 缺失、为空白时中断渲染。
- `name` 为 `my-secret`、`app.config`、`1secret` 或 63 字符单段时渲染成功；为大写字母、含 `_`、首尾为 `-` 或 `.`、含连续点、单段超过 63 字符或总长超过 253 字符时中断渲染。
- `key` 为 `LOG_LEVEL`、`app.key`、`db-password`、`a_b.c-d`、`.key`、`key.`、`_key`、`-key` 时渲染成功；含空格、`/`、`:` 等非字符集字符时中断渲染。
- `definitions.configMapKeySelector` 与 `definitions.secretKeySelector` 对同一 `key` 输入给出相同的成功或失败结果。
- 入参中的额外键不产生输出。
- `definitions.envVarSource` 的 `secretKeyRef` 字符串简写少于 2 段时不组装该字段；达到 2 段时按 `name`、`key`、`optional` 位次组装，第三段的 `true`／`false` 正常生效，超出部分忽略。

## 开放问题

- 无。
