---
change-id: definitions-sysctl
updated_at: "2026-11-15T17:16:37Z"
---

# definitions.sysctl

## 目标

- 新建公共模板 `definitions.sysctl`，渲染 Kubernetes 容器内核参数配置结构。

## 需求

- 上下文为 map，字段为 `name`、`value`，与“期望输入格式”一致。
- `name` 与 `value` 均为 string 类型。
- `value` 为数字、布尔、map 或 array 时中断渲染，不做类型归一化；调用方必须自己传入字符串形式，例如 `"0"`。
- `name` 必填，缺失、`null`、空字符串或只含空白时中断渲染。
- `value` 必填，缺失时中断渲染；`value` 为 `null` 时视为空值，与空字符串同等处理。
- `value` 的必填判定同时覆盖 `value` 与 `valueAlias`：两者均未提供时中断，只要其中一个提供且取值有效则视为已提供。
- `value` 取字符串 `"null"` 时是普通字符串，正常渲染为 `value: "null"`，不得当作空值。
- 两个字段取值均先去除首尾空白，必填判定、引号判定与输出均使用去除后的结果。
- `value` 去除首尾空白后为空或输入为 `null` 时，输出带双引号的 `value: ""`。
- 输出字段顺序按 Kubernetes v1.36 官方字段表，即 `name` 在 `value` 之前。
- `name` 输出时恒加双引号，防止极端取名被父级 YAML 回收为其他类型。
- `value` 不加引号会被 YAML 解析为非 string 时，输出时加双引号，例如 `8080` 输出为 `value: "8080"`。
- `value` 为普通 string（如 `abc`）时，不额外添加双引号。
- `value` 取 string `"0"` 时必须显式输出带引号的 `value: "0"`，不得因假值判断被跳过。
- 取值使用统一取值能力，同级 `<字段>Alias` 别名生效并优先于规范键，覆盖默认取值与类型门禁；别名视为合法输入而非范围外键。
- 除 `name`、`value` 及其同级别名以外的输入键静默忽略，不参与渲染也不触发失败。

## 期望输入格式

```yaml
name: string
value: string
```

`value` 必须写为字符串形式；写成 `0`、`true` 等非字符串字面量会中断渲染，写成 `null` 则按空值输出 `""`。

## 约束

- 当前调用点是 `templates/api-resources/Definitions/_PodSecurityContext.tpl`，其 `sysctls` 分支已在不存在的 `definitions.sysctl` 上委托：仅取 `name` 与 `value`、`toString` 归一、去空去重后逐条 `include` 并以 `fromYaml` 回收，最后以 `base.field` + `base.slice` 输出。本 change 补齐该被委托能力，并保持该调用链的上下文契约不变。
- 该调用点已先做 `toString` 与 `trim`，因此经它委托时 `value` 到达本模板一定是 string，数字会被上游悄悄转成字符串；仅直接调用本模板时数字与布尔才会触发中断。
- 该调用点以 `if and $sysctl.name $sysctl.value` 丢弃 `value` 为空的条目，因此经它委托时空串 `value` 永远不会到达本模板；本模板接受空串的行为仅在直接调用时可见。
- 统一取值能力对「键缺失」「值为 `null`」「值为空字符串」返回相同结果，无法自行区分三者，因此「`value` 缺失中断」与「`value` 为 `null` 输出 `""`」共存时需额外做键存在性判定。
- 键存在性判定若只检查规范键，仅提供 `valueAlias` 的输入会被误判为缺失（实测确认），因此必填判定需同时覆盖 `value` 与 `valueAlias` 两个键名；其余取值与类型门禁仍由统一取值能力完成。

## 非目标

- 不实现 sysctl 结构以外的字段或其他安全上下文结构。
- 不校验 `name` 的内核参数命名格式，也不校验 `value` 的取值范围。

## 验收

- `name` 与 `value` 均提供时，输出同时包含两个字段，顺序为 `name` 在前、`value` 在后。
- `name` 缺失、`null`、空字符串或去除空白后为空时报错并中断渲染。
- `value` 缺失时报错并中断渲染。
- `value` 取 `null` 时输出为 `value: ""`，不中断渲染。
- `value` 取字符串 `"null"` 时输出为 `value: "null"`，与 `null` 取值结果不同。
- 输入 `valueAlias` 时以别名为准，输出与直接提供 `value` 一致。
- 仅提供 `valueAlias` 而不提供 `value` 时，不得判为缺失。
- `value` 与 `valueAlias` 均未提供时报错并中断渲染。
- 同时提供 `value` 与 `valueAlias` 时，以 `valueAlias` 为准。
- 仅提供 `nameAlias` 而不提供 `name` 时，与直接提供 `name` 结果一致。
- `name` 取 `net.ipv4.ip_forward` 时输出为 `name: "net.ipv4.ip_forward"`。
- `value` 取 string `8080` 时输出为 `value: "8080"`，经父级 `fromYaml` 回收后仍为 string。
- `value` 取 map 或 array 时报错并中断渲染。
- `value` 取数字 `0` 或布尔 `true` 时报错并中断渲染。
- `value` 取 `abc` 时输出为 `value: abc`，不额外添加双引号。
- `value` 取 string `"0"` 时输出为 `value: "0"`，不得被假值判断跳过。
- `value` 取空字符串或只含空白时输出为 `value: ""`，不中断渲染。
- 输入含 `foo: bar` 等范围外键时静默忽略，输出与不含该键时一致。
- `definitions.podSecurityContext` 的 `sysctls` 分支可对新模板完成逐条回收，去重去空后正确输出数组。

## 开放问题

- 无。
