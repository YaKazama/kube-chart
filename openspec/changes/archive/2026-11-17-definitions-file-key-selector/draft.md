---
change-id: definitions-file-key-selector
updated_at: "2026-11-17T16:20:45Z"
---

# definitions.fileKeySelector

## 目标

- 新增命名模板 `definitions.fileKeySelector`，把 map 上下文渲染为 Kubernetes `FileKeySelector` 字段片段。
- 供 `definitions.envVarSource` 的 `fileKeyRef` 分支调用。

## 需求

- 入参上下文为 map。
- `volumeName`、`path`、`key` 均为必填字段；任一缺失或为空时中断渲染。
- `path` 为相对路径，其清洗归一化由 `base.path` 的 `rel` 模式完成，输出清洗后的结果而非原始输入。
- `path` 清洗后等于 `..` 或以 `../` 开头时中断渲染。
- `path` 清洗后等于 `.` 时中断渲染，因该结果指向卷根目录而非文件。
- `path` 为绝对路径时由 `base.path` 中断，失败消息保留其自身 `[base.path]` 前缀。
- `path` 原文含内部 `..` 段（如 `a/../b`）时，接受清洗阶段的消解结果，不做原文检查；但消解为 `.` 时按上一条中断。
- 按官方文档字段顺序渲染：`key`、`optional`、`path`、`volumeName`。
- 字段类型按官方定义：`key` 为 string，`optional` 为 boolean，`path` 为 string，`volumeName` 为 string。
- `optional` 只接受原生 boolean；字符串 `"true"` / `"false"` 视为类型错误并中断。
- `optional` 为可选字段，缺省时不输出。
- 取值使用 `base.get`。
- 只渲染官方文档约定的四个字段；入参中的其他键静默忽略。
- `templates/api-resources/Definitions/_EnvVarSource.tpl` 中 `fileKeyRef` 的必需段数同步修正，与新增的必填字段一致。

## 期望输入格式

- `definitions.fileKeySelector` 的入参为单个 `FileKeySelector` map，键为 `key`、`optional`、`path`、`volumeName`。

## 约束

- 三个必填字段为空或缺失即中断，不使用默认值掩盖缺失。
- 输出为单层字段片段，不包含 `fileKeyRef` 父键。
- `_EnvVarSource.tpl` 中 `fileKeyRef` 的必需段数由 2 改为 3：`required` 决定「切分后的段数是否足够组装」，与 `key` 必填一致后，`file VOL PATH`（两段）将不再组装，只输出空内容；合法字符串形式为 `file VOL PATH KEY` 或 `file VOL PATH KEY OPTIONAL`。
- 段数收紧已确认接受。
- `path` 只在清洗后校验相对性与根目录逃逸，不另建路径能力。

## 非目标

- 不渲染 `EnvVarSource` 的其他字段。
- 不实现 `definitions.envVarSource` 的分发逻辑。
- 不校验 `path` 清洗后指向的卷内文件是否真实存在。
- 不校验 `key` 的字符集与 128 字符上限。
- 不处理 `EnvFiles` 特性门禁。

## 验收

- 三个必填字段齐全时能渲染出合法的 `FileKeySelector` 字段片段。
- 四个字段齐全时按 `key`、`optional`、`path`、`volumeName` 顺序输出。
- `path` 输出的是清洗后的相对路径，例如 `logs/./app` 输出为 `logs/app`，`a/../b` 输出为 `b`。
- 绝对 `path` 及清洗后等于 `..` 或以 `../` 开头的 `path` 中断渲染。
- 清洗后等于 `.` 的 `path`（如 `.`、`a/..`）中断渲染。
- `optional` 缺省时只输出三个必填字段；`optional` 为字符串时中断。
- `volumeName`、`path`、`key` 任一缺失或为空时中断渲染。
- 入参中的额外键不产生输出。
- `_EnvVarSource.tpl` 的 `fileKeyRef` 字符串在少于三段时不再组装。

## 开放问题

- 无。
