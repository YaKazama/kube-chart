---
updated_at: "2026-11-18T16:27:47Z"
---

# definitions.execAction 规格

## Purpose

为 Kubernetes ExecAction 的 `command` 字段提供统一渲染入口。

## ADDED Requirements

### Requirement: command 输入与校验

系统 MUST 以 map 作为上下文，并 MUST 将 `command` 视为必填的 string array。

#### Scenario: 有效 command

- **WHEN** 输入提供非空 string array 作为 `command`
- **THEN** 系统按输入顺序接受全部元素
- **AND** 系统 MUST NOT 拆分或改写任何元素

#### Scenario: command 缺失

- **WHEN** 输入无法提供 `command`
- **THEN** 系统 MUST 中断渲染

#### Scenario: command 类型无效

- **WHEN** `command` 的值不是 array
- **THEN** 系统 MUST 中断渲染

#### Scenario: 元素类型无效

- **WHEN** `command` 数组包含非 string 元素
- **THEN** 系统 MUST 中断渲染

### Requirement: command 输出

系统 MUST 仅输出 `command` 字段，并 MUST 在 `command` 整体为空时不产生输出。

#### Scenario: 非空 command

- **WHEN** `command` 是非空 string array
- **THEN** 系统输出仅包含 `command` 的 YAML 字段片段
- **AND** 元素顺序与字符串内容 MUST 保持不变

#### Scenario: 空 command

- **WHEN** `command` 是空 array
- **THEN** 系统 MUST 不产生输出

## 非目标

- 不处理 `exec`、`postStart`、`preStop` 或其他 LifecycleHandler 字段。
- 不新增其他动作模板。
- 不校验 `command` 内容在容器镜像中的可执行性。
