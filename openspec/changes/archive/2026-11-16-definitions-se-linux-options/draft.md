---
change-id: definitions-se-linux-options
updated_at: "2026-11-15T15:48:35Z"
---

# definitions.seLinuxOptions

## 目标

- 新建公共模板 `definitions.seLinuxOptions`，渲染 Kubernetes 容器 SELinux 标签结构。

## 需求

- 上下文为 map，字段为 `level`、`role`、`type`、`user`，与“期望输入格式”一致。
- 四个字段均为 string 类型。
- 四个字段均为可选，缺失时跳过该字段。
- 输出字段顺序按 Kubernetes v1.36 官方字段表，即 `level`、`role`、`type`、`user`。
- 所有字段均缺失时返回空内容，不报错。
- 字段值为 string 时先 `trim`，随后判断与输出均使用 `trim` 结果。
- 字段值为空字符串或只含空白时不渲染该字段。
- 字段值非 string 类型（数字、布尔、map、array）时报错中断，不做类型归一化。
- 输出强制加引号，所有字段值均以双引号包裹的字符串形式输出。

## 期望输入格式

```yaml
level: string
role: string
type: string
user: string
```

## 约束

- 本 change 需确认既有调用点 `definitions.podSecurityContext` 以 `include "definitions.seLinuxOptions"` 委托时的上下文契约保持不变。

## 非目标

- 不实现 SELinuxOptions 结构以外的字段或其他安全上下文结构。

## 验收

- 完整输入时，输出按 `level`、`role`、`type`、`user` 顺序包含四个字段。
- 只提供部分字段时，只输出其中非空字段。
- 所有字段缺失、均为空字符串或均为空白时，渲染成功且返回空内容。
- 字段值首尾带空白时，输出取值为 `trim` 后的值。
- 任一字段为数字、布尔、map 或 array 时报错并中断渲染。
- 输出字段值均带双引号；取值为 `on`、`yes`、`true` 等 YAML 布尔字面量时，经父级 `fromYaml` 回收后仍为原字符串。

## 开放问题

- 无。
