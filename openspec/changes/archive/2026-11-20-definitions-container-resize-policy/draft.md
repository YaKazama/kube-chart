---
change-id: definitions-container-resize-policy
updated_at: "2026-11-19T16:26:56Z"
---

# definitions.containerResizePolicy

## 目标

- 新增 `definitions.containerResizePolicy` 模板，用原生 map 或单行字符串描述一条 Kubernetes `ContainerResizePolicy` 条目。

## 需求

- 上下文支持原生 map 与 string 两种形态。
- string 形态的格式为 `resourceName [restartPolicy]`，分隔符为空格和逗号，复用既有 `SPLIT.SPACE_COMMA` 语义。
- string 形态按位置取值：第 1 段为 `resourceName`，第 2 段为 `restartPolicy`；出现第 3 段及以后时格式不合法，按正则不匹配中断报错。
- `resourceName` 必填，可用值为 `cpu`、`memory`，必须全小写；非法取值中断报错。
- `restartPolicy` 可选，可用值为 `NotRequired`、`RestartContainer`，大小写敏感；非法取值中断报错。
- `restartPolicy` 未提供时不输出该字段，交由 API 默认值 `NotRequired` 生效。
- 两个字段只接受 string 类型，非 string 类型中断报错。
- map 形态可包含任意键，只处理 `resourceName` 与 `restartPolicy`，其余键不处理。
- 按官方字段顺序渲染：`resourceName` 在前，`restartPolicy` 在后。

## 期望输入格式

- string：`resourceName [restartPolicy]`
  - 分隔符为空格和逗号，两侧空白与连续分隔符按 `SPLIT.SPACE_COMMA` 语义处理。
  - 示例：`cpu`、`cpu, NotRequired`、`memory RestartContainer`。
- 原生 map：可包含任意键，只处理 `resourceName`（必填）与 `restartPolicy`（可选）。
  - 示例：`{resourceName: cpu, restartPolicy: RestartContainer}`、`{resourceName: memory, note: anything}`。

## 约束

- `resourceName` 仅 `cpu`、`memory`，全小写，大小写敏感。
- `restartPolicy` 仅 `NotRequired`、`RestartContainer`，大小写敏感。
- 两个字段只接受 string 类型。
- string 形态的分隔符复用既有 `SPLIT.SPACE_COMMA`，不新增独立分隔符常量。
- `definitions.container` 的 `resizePolicy` 调用改为开启 string 简写支持。
- `templates/api-resources/Definitions/_Container.tpl` 的整体契约需随本模板内容同步调整，包括数组元素类型的通用边界描述；调整后必须同步修改注释。
- 数组级去重与空项剔除属于父模板职责，本模板不处理。

## 非目标

- 不新增 `definitions.containerResizePolicy` 以外的 `definitions.*` 模板。
- 不校验 `resourceName` 在容器内是否重复。

## 验收

- `cpu` 仅渲染 `resourceName: "cpu"`，不输出 `restartPolicy`。
- `cpu, NotRequired` 与 `memory RestartContainer` 按同一分隔符语义解析出两个字段，并按 `resourceName`、`restartPolicy` 顺序渲染。
- `{resourceName: memory, restartPolicy: RestartContainer}` 与等价 string 输出一致。
- map 中额外的键（如 `note`）不处理、不报错。
- `resourceName` 缺失、取 `CPU`、`gpu` 或非 string 类型时渲染中断。
- `restartPolicy` 取 `notrequired`、`Always` 或非 string 类型时渲染中断。
- `definitions.container` 的 `resizePolicy` 可接受 string 简写元素与 map 元素。
- `cpu NotRequired extra` 出现第 3 段，格式不合法，渲染中断。

## 开放问题

- 无。
