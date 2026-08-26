> 需求修改入口：[draft.md](../draft.md)

# Apps Deployment 设计

## 设计范围

- 目标文件只围绕主模板 `apps.deployment` 组织。
- 当前 change 只实现 Deployment 资源层模板，不实现 `metadata` 与 `spec` 子模板。
- 不新增 values、Schema、父 Chart 编排、Helm Hooks、二级资源或跨资源组合。

## Kubernetes API 字段

| 顺序 | 字段 | Kubernetes API 类型 | 当前层职责 |
|---|---|---|---|
| 1 | `apiVersion` | `string` | 固定渲染为 `apps/v1`，标识 Deployment 使用的版本化 API schema。 |
| 2 | `kind` | `string` | 固定渲染为 `Deployment`，标识 REST 资源类型。 |
| 3 | `metadata` | `ObjectMeta` | 委托 `metadata` 子模板生成，只在恢复并验证为 map 后渲染。 |
| 4 | `spec` | `DeploymentSpec` | 委托 `spec` 子模板生成，只在恢复并验证为 map 后渲染。 |

模板不处理 `status`。每个字段的中文注释在 `define` 块内紧邻对应处理闭环，整体契约中文注释紧邻 `define` 之前，说明功能、边界、入参、返回值与最小示例。

## 直接依赖与调用位置

| 依赖 | 状态 | 调用位置 | 传入上下文 | 最小返回边界 |
|---|---|---|---|---|
| `definitions.objectMeta` | 外部直接依赖；当前尚未实现 | `metadata` 字段处理闭环起点 | 父模板当前上下文 `.` | `include` 返回非空、有效且可恢复为 map 的 `ObjectMeta` YAML 字符串；允许空 map。 |
| `apps.deploymentSpec` | 外部直接依赖；当前尚未实现 | `spec` 字段处理闭环起点 | 父模板当前上下文 `.` | `include` 返回非空、有效且可恢复为 map 的 `DeploymentSpec` YAML 字符串；允许空 map。 |
| `base.isFromYamlError` | 已存在的直接依赖 | 两个子模板结果放入 envelope 并执行 `fromYaml` 后 | `fromYaml` 的解析结果 | 返回字符串布尔值；`"true"` 表示解析错误。 |
| `base.field` | 已存在的直接依赖 | `metadata`、`spec` 完成解析和类型校验后 | 分别传入 `list "metadata" $metadata "base.map"` 与 `list "spec" $spec "base.map"` | 调用指定渲染模板并返回对应字段的 YAML。 |
| `base.map` | 已存在的显式渲染依赖，由 `base.field` 调用 | `metadata`、`spec` 的字段渲染阶段 | 已验证为 map 的 `$metadata` 或 `$spec` | 返回 `toYamlPretty` 格式的 map YAML；空 map 返回 `{}`。 |

`definitions.objectMeta` 与 `apps.deploymentSpec` 的实现不属于当前 change；不得在当前 change 中创建对应占位 `define` 或实现。

## 上下文、顺序与字段闭环

1. 依赖父 Chart 以可写 map 构造的局部资源上下文 `.` 调用顶层资源模板；不在 `apps.deployment` 中重复执行入口 map 类型门禁。
2. 使用 `set . "_kind" "Deployment"` 原地写入控制键并以 `$_` 显式丢弃 `set` 返回值；无论 `_kind` 是否已存在，后续值均为字符串 `Deployment`。
3. 按 API 顺序直接渲染固定的 `apiVersion` 和 `kind`。
4. 调用 `metadata` 子模板；检查原始字符串非空，再把输出放入单键 envelope 后执行 `fromYaml`，依次用 `base.isFromYamlError`、envelope map 类型和取出的 `value` map 类型保护解析结果，最后使用 `base.field` 和 `base.map` 渲染。空 map 是合法的 map 返回值，不在父模板中拒绝。
5. 对 `spec` 按相同闭环处理，随后结束单资源输出。

任何字段失败都立即终止，不处理后续字段。当前模板自身发起的错误消息统一为 `[apps.deployment] 字段路径: 错误原因`；依赖模板直接失败时保留 Helm 传播的依赖错误。

## 类型与隔离边界

- 入参 `.` 的可写 map 类型由顶层资源调用契约保证；`_kind` 是字符串控制键。
- `include` 的子模板结果是字符串；只有经原始空字符串检查、YAML 错误保护和 map 类型检查后，才赋给具有业务语义的 `$metadata` 或 `$spec`。
- `apps.deployment` 是当前资源的拥有者，且需求明确要求设置 `_kind: Deployment`；按资源上下文规则可以原地覆盖已有 `_kind` 并将同一个 `.` 传给两个子模板，因此不对父上下文执行 `mustDeepCopy`。模板只允许写入 `_kind`，不得修改 `.Values` 或其他上下文键。
- 两个字段子模板属于直接依赖，应把传入上下文视为只读输入；其内部行为和实现不在当前 change 范围内。
- `metadata` 与 `spec` 的临时解析变量分别限制在对应字段闭环内，不跨字段复用。

## 失败与验证边界

- `definitions.objectMeta` 与 `apps.deploymentSpec` 尚未实现，因此当前 change 可以用 `/tmp/` 测试 Chart 中的同名最小 fixture 隔离验证调用方，但该结果不能证明真实依赖已经集成。
- 任一外部子模板在自身执行期间失败时，Helm 直接传播该依赖的错误；当前模板只负责检查成功返回后的空字符串、YAML 解析结果与 map 类型。
- 根 Chart 的 lint、目标模板隔离渲染及关键失败输入必须通过；外部依赖集成留给对应能力实现后的独立变更与验证，不在当前 change 中伪造通过结论。

## 输出与排版边界

- 使用 `{{- define "apps.deployment" -}}` 和 `{{- end }}`，2 空格缩进，并用显式换行避免字段粘连。
- library Chart 模板首尾不输出 `---`，不通过 `range` 拼接多个资源。
- 除目标资源字段、必要注释及处理逻辑外，不引入无关辅助模板。
