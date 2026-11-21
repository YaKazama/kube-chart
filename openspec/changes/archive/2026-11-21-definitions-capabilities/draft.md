---
change-id: definitions-capabilities
updated_at: "2026-11-21T14:29:50Z"
---

# definitions.capabilities

## 目标

- 新增 `definitions.capabilities`，渲染 Kubernetes `Capabilities` 字段片段，供 `definitions.securityContext` 的 `capabilities` 字段委托调用。

## 需求

- 入参为 map，可包含 `add` 与 `drop`，两者均为 string array 且均可选。
- 按 Kubernetes 官方文档字段顺序渲染：`add` 在前，`drop` 在后。
- `add`、`drop` 的元素按 Linux capability 名称正则校验：`CAP_` 前缀可选、大小写不敏感；不做具体名称项校验。
- 校验后统一以大写输出；输入含 `CAP_` 前缀时保留，不含前缀时不补充。
- 未提供的字段不渲染；两者皆空时输出空内容。

## 期望输入格式

```yaml
add: [<string>, ...]
drop: [<string>, ...]
```

## 约束

- `add`、`drop` 的数组清洗使用 `base.slice.cleanup`，拆分正则使用分号、逗号、空格；结果以 YAML 列表输出。

## 非目标

- 不修改 `definitions.securityContext` 的委托逻辑。
- 不修改 `base.slice.cleanup` 的清洗行为。
- 不做 capability 名称白名单或存在性校验，不拦截符合正则的拼写错误（如 `NET_ADMN`）。

## 验收

- 同时提供 `add` 与 `drop` 时，输出顺序为 `add`、`drop`。
- 仅提供其中一个字段时，只输出该字段。
- 含分号、逗号或空格的字符串元素被拆分为多个列表项。
- 小写与带 `CAP_` 前缀的名称通过校验。
- `cap_net_admin` 输出为 `CAP_NET_ADMIN`，`net_admin` 输出为 `NET_ADMIN`。
- 不符合名称正则的输入（如 `NET-ADMIN`）中断渲染。
