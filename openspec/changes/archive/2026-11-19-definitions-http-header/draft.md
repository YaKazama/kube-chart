---
change-id: definitions-http-header
updated_at: "2026-11-18T17:32:43Z"
---

# definitions.httpHeader

## 目标

- 新增命名模板 `definitions.httpHeader`，渲染 HTTPHeader 的 `name` 与 `value` 字段片段。

## 需求

- 上下文为 map，字段为 `name: string` 与 `value: string`。
- `name` 与 `value` 必须成对出现；任意一个缺失时中断渲染并报错。
- `name` 或 `value` 去除首尾空白后为空字符串时，按缺失处理并中断渲染并报错；仅包含空白字符时同样如此。
- `name` 与 `value` 的类型必须为 string。
- 渲染前去除 `name`、`value` 的首尾空白。

## 期望输入格式

```yaml
name: string
value: string
```

## 验收

- `name` 与 `value` 均存在且均为 string 时，输出包含两者的 HTTPHeader 字段片段。
- `name` 或 `value` 任一缺失时中断渲染并报错。
- `name` 或 `value` 去除首尾空白后为空时按缺失处理并中断渲染报错，仅含空白字符时同样中断。
- `name` 或 `value` 不是 string 时中断渲染并报错。
- 输出的 `name` 与 `value` 已去除首尾空白。
