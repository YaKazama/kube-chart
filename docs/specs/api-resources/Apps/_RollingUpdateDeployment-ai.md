# apps.RollingUpdateDeployment

## 1. 目标与交付约定

`apps.rollingUpdateDeployment` 是 kube-chart 中负责渲染 Kubernetes `Deployment` 资源 `spec.strategy.rollingUpdate` 字段内容的命名模板。该模板由 `apps.deploymentStrategy` 调用，按 Kubernetes `RollingUpdateDeployment` API 定义的字段顺序输出 YAML 键值对。

- **模板名称**：`apps.rollingUpdateDeployment`
- **交付文件**：`templates/api-resources/Apps/_RollingUpdateDeployment.tpl`
- **入参来源**：唯一 dict，由 `apps.deploymentStrategy` 完成上层多类型归一化后传递。
- **整体渲染原则**：仅处理 `maxSurge` 与 `maxUnavailable` 两个字段；通过 `base.get` 读取、通过 `base.field` 渲染；直接保留传入的整数或百分比字符串，不在本层执行正则校验。

## 2. 字段级功能需求

严格按照 Kubernetes API 字段顺序排列。

### 2.1 maxSurge

| 属性 | 说明 |
|------|------|
| 类型 | 整数或百分比字符串 |
| 必填 | 否 |
| 默认 | Kubernetes 默认 `25%`；字段未提供时不显式渲染 |
| 渲染条件 | 值非空且非 `null` 时渲染；数值 `0` 视为有效值，必须渲染为 `0` |
| 处理逻辑 | 使用 `base.get` 读取，直接取值后使用 `base.field` 渲染 |
| 委托关系 | 无 |

### 2.2 maxUnavailable

| 属性 | 说明 |
|------|------|
| 类型 | 整数或百分比字符串 |
| 必填 | 否 |
| 默认 | Kubernetes 默认 `25%`；字段未提供时不显式渲染 |
| 渲染条件 | 值非空且非 `null` 时渲染；数值 `0` 视为有效值，必须渲染为 `0` |
| 处理逻辑 | 使用 `base.get` 读取，直接取值后使用 `base.field` 渲染 |
| 委托关系 | 无 |

### 2.3 返回值

返回 `RollingUpdateDeployment` YAML 键值对，不包含 `rollingUpdate` 父键；由 `apps.deploymentStrategy` 包入 `rollingUpdate` 块。示例：

```yaml
maxSurge: 25%
maxUnavailable: 0
```

## 3. 专属边界行为

通用边界行为统一遵循 `docs/rules/const-boundary.md`。

- **同时为空**：`maxSurge` 与 `maxUnavailable` 均为空值或未提供时，允许返回空内容，不渲染任一字段。
- **零值保留**：任一字段为数值 `0` 时，必须作为有效配置渲染为 `0`，不得按空值跳过。
- **双零冲突**：`maxSurge` 与 `maxUnavailable` 不能同时为 `0`；命中时必须立即失败。
- **类型归一化边界**：本模板仅接收 dict；由 `apps.deploymentStrategy` 负责上层 string/object 等多类型输入的识别与规整。

## 4. 约束说明

通用开发约束统一遵循 `docs/rules/const-general.md`。

- **取值与渲染**：字段取值必须使用 `base.get`，字段输出必须使用 `base.field`。
- **类型处理**：字段允许整数或百分比字符串，直接取值并渲染；本模板不新增正则校验逻辑。
- **字段范围**：仅实现 API 定义的 `maxSurge`、`maxUnavailable`；未定义输入字段静默忽略，不输出 `status` 相关内容。
- **字段顺序**：渲染顺序必须保持 `maxSurge` 在前、`maxUnavailable` 在后。

## 5. 参考资料

- API：
  - <https://kubernetes.io/docs/reference/kubernetes-api/apps/deployment-v1/#DeploymentSpec>
  - <https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#rollingupdatedeployment-v1-apps>
- 关联模板：
  - `templates/api-resources/Apps/_DeploymentStrategy.tpl`：上层调用与入参归一化
  - `templates/base/_get.tpl`：`base.get` 取值机制
  - `templates/base/_field.tpl`：`base.field` 字段渲染机制
- 规则引用：
  - `docs/rules/const-general.md`：通用开发约束
  - `docs/rules/const-boundary.md`：通用边界行为
  - `docs/rules/const-example-code.md`：模板示例代码规范
