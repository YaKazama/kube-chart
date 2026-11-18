---
change-id: fix-definitions-container-env-from
updated_at: "2026-11-18T04:37:47Z"
---

# 修复 envFrom 上下文

## 目标

- 修复 `definitions.container` 模板中 `envFrom` 上下文只接受单一输入形态的问题，使其同时接受原生 `EnvFromSource` array 或 string array。

## 需求

- `envFrom` 仅接受 array 类型；传入单个 string 等非 array 时中断报错。
- `envFrom` 接受原生 `EnvFromSource` array；原生 array 中的 map 元素原样向下传递。
- `envFrom` 接受 string array；每个元素按“期望输入格式”解析为 `EnvFromSource` 支持的键。
- string 元素解析结果形如 `{configMapRef: <string>, prefix: <string>}` 或 `{secretRef: <string>, prefix: <string>}`。
- string 元素的第 1 段关键字不区分大小写，其余字段区分大小写。
- 关键字映射：`configMap` 或 `cm` -> `configMapRef`；`secret` -> `secretRef`。
- `configMapRef` 与 `secretRef` 互斥且至少出现一个。
- string 元素转 map 的解析在调用 `definitions.container.array` 之前完成，因此 `definitions.container.array` 的入参始终是全 map 数组。
- 段位固定：第 1 段为关键字，第 2 段为 `name`，第 3 段为 `prefix`，第 4 段为 `optional`；3 段输入的第三段就是 `prefix`，不参与 `optional` 判定。
- 解析由正则捕获和 Helm 函数配合完成：正则提供捕获组，Helm 函数按捕获组取值；取不到值时应修正正则，不增加兼容分支。
- 段数少于 2 或超过 4、关键字不在映射表时中断渲染并报错。
- `prefix` 可选；未提供时不向下传递该键，捕获为空即视为未提供。
- `optional` 本层不校验也不归一化，按原 token 作为 string 向下传递；布尔语义由下游模板经 `base.bool` 在渲染时校验。
- `optional` 必须伴随 `prefix`：只有 4 段输入同时包含 `prefix` 与 `optional`；3 段输入的第 3 段一律按 `prefix` 解析，即使取值为 `true` 或 `false`。
- `name`、`prefix`、`optional` 的合法性校验不在本层进行，交给子模板。
- `name` 与 `optional` 解析后仍以 string 形式向下传递。
- 同一 `envFrom` 数组允许 string 与 map 元素混用；每个元素最终向下传递的上下文必须是 map。

## 期望输入格式

```text
<configMap | cm> <name> [prefix] [optional]
或
<secret> <name> [prefix] [optional]
```

- 字段分隔符为空白与逗号，由 `templates/base/_env.tpl` 中新增的 `base.env` 常量 `K8S.ENV_FROM` 内置；段落之间可为一或多段空白或逗号。
- `prefix` 不允许包含逗号、空白等分隔字符或违规字符。

## 非目标

- 不改动 `env` 或容器其他字段的解析行为。
- 不修改 `definitions.envFromSource` 及其他 change 已确认的范围。

## 验收

- `envFrom` 传入原生 `EnvFromSource` array 时，map 元素原样向下传递。
- `envFrom` 传入 string array 时，`configMap`、`cm`、`secret` 关键字（含大小写变体）分别解析为 `configMapRef` 或 `secretRef`。
- 同一元素解析结果不会同时包含 `configMapRef` 与 `secretRef`。
- string 元素缺少 `prefix` 或 `optional` 时仍可解析出对应引用，且输出中不出现对应键。
- 3 段输入按第 3 段为 `prefix` 解析，不产生 `optional` 键。
- `optional` 原样向下传递，本层不做布尔校验。
- string 与 map 元素混用时，每个元素都以 map 上下文向下传递。
- string 元素格式非法（段数越界、关键字无法映射）时渲染中断并报错。
- `envFrom` 传入非 array 类型时渲染中断并报错。
- `name` 与 `prefix` 的字符集违规由子模板中断报错，本层不重复校验。

## 开放问题

- 无。
