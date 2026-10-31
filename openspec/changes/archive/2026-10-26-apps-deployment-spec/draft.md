---
change-id: apps-deployment-spec
updated_at: "2026-08-28T08:38:39Z"
---

# Apps DeploymentSpec 模板

> 用户初始意图入口。
> 只需编辑下面的“目标、需求、约束、非目标、验收”。

## 目标

- 新增名为 `apps.deploymentSpec` 的模板。
- 模板目标路径为 `templates/api-resources/Apps/_DeploymentSpec.tpl`。

## 需求

- 字段：`minReadySeconds`,`paused`,`progressDeadlineSeconds`,`replicas`,`revisionHistoryLimit`,`selector`,`strategy`,`template`。

## 约束

- `selector`、`template` 必填，其他可选。
- 所有 `integer` 类型字段：非负数，负数不渲染。
- 默认值作为建议值，用户可选择是否覆盖。上限值为强约束。
  - 默认值：
    - `minReadySeconds` 为 `0`。
    - `paused` 为 `false`。
    - `progressDeadlineSeconds` 为 `600`。
    - `replicas` 为 `1`。
    - `revisionHistoryLimit` 为 `10`。
  - 上限值：`minReadySeconds`,`progressDeadlineSeconds`,`replicas`,`revisionHistoryLimit` 均为 `2147483647`。超过该值报错中断。
- `selector`：最多包含 `matchLabels`、`matchExpressions` 字段。子模板 `definitions.labelSelector`，向下传递清洗后的 `selector`。
  - 从 `base.labels` 中取值，左优合并，顺序： `selector.matchLabels` > `base.labels`。`base.labels` 透传上下文 `.`。
- `strategy`：允许支持 string、map 类型，类型互斥。子模板 `definitions.deploymentStrategy`。
  - map 类型。从 `strategy` 取 `type`、`rollingUpdate` 字段并向下传递。允许空 `strategy` 向下传递。
  - string 类型，正则表达式：`"^(Recreate|RollingUpdate)(?:\\s+(.*))?$"`，清洗为 map 后向下传递。map 包括 `type`、`rollingUpdate` 字段。正则过滤的结果中，第一个为 `type`、第二个为 `rollingUpdate`。此时的 `rollingUpdate` 是 string 类型。
- `template`：子模板 `core.podTemplateSpec`，透传上下文 `.`。

## 非目标

## 验收

- `templates/api-resources/Apps/_DeploymentSpec.tpl` 中存在可供调用的命名模板 `apps.deploymentSpec`。
