---
change-id: definitions-exec-action
updated_at: "2026-11-18T16:25:48Z"
---

# definitions.execAction

## 目标

- 新增命名模板 `definitions.execAction`，处理 `command` 上下文。

## 需求

- 上下文为 map，包含 `command` 字段。
- `command` 为 string array。
- `command` 必填；缺失时必须中断渲染。
- `command` 中的 string 不能拆分，元素必须按原值保留。
- `command` 元素不是 string 时必须中断渲染。
- `command` 整体为空时不渲染。
- 输出仅包含 `command`，不包含其他字段。

## 期望输入格式

```yaml
command:
  - <string array>
```

## 约束

- 上下文以 map 传入。
- `command` 的值形态为 string array。
- 使用 `base.slice` 处理 `command`，不使用会拆分字符串的切片清洗能力。

## 非目标

- 不新增其他动作模板。
- 不处理 `definitions.lifecycleHandler` 的动作分派或其他动作字段解析。

## 验收

- `definitions.execAction` 可由 Helm 加载，并能以包含 `command` string array 的 map 上下文调用。
- `command` 的 string array 内容按输入顺序保留，各元素不被拆分或改写。
- 缺失 `command` 时渲染中断。
- `command` 整体为空时不产生输出。
- `command` 元素不是 string 时渲染中断。
- 模板输出 map 仅包含 `command`。

## 开放问题

- 无。
