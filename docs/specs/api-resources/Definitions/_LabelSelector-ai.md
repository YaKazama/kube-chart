# definitions.LabelSelector

## 目标与交付约定

新增命名模板 `definitions.labelSelector`，写入 `templates/api-resources/Definitions/_LabelSelector.tpl`。入参为 dict（由上层 `selector` 调用方透传），按 K8s 官方 API 字段顺序（`matchExpressions` → `matchLabels`）处理并渲染 `LabelSelector` 资源，不渲染 `status` 字段。

## 字段级功能需求

### matchExpressions（array，可选）

列表元素支持 string / 原生 object 两种类型，向下传递前统一规整为 dict 形态（`key` / `operator` / `values`），委托 `definitions.labelSelectorRequirement` 渲染；回收时 `mustUniq | mustCompact` 去重去空。

#### 列表元素类型识别与规整

- **dict 类型**：通过 `pick` 提取 `key`、`operator`、`values` 三个字段后透传，未定义字段静默忽略。
- **string 类型**：通过 `K8S.SELECTOR` 系列正则解析为 dict 后透传，标签选择支持：
  - 基于等值：`key = value` / `key == value` / `key != value`
  - 基于集合：`key In (v1, v2, ...)` / `key NotIn (...)`，操作符大小写不敏感
  - 基于存在性：`key` / `!key`
  - 参考：https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors
- **正则定义**：集中存放在 `templates/base/_env.tpl` 的 `K8S.SELECTOR` 路径下：
  - `EQUALITY0`：等值选择器（`=` / `==` / `!=`），归一为 `In` / `NotIn`，values 为单值列表。
  - `SET0`：集合选择器（`In` / `NotIn`），操作符大小写不敏感，归一为 `In` / `NotIn`，values 通过 `SPLIT.COMMA` 拆分并去重去空。
  - `SET_EXISTS`：存在性选择器（`key` / `!key`），归一为 `Exists` / `DoesNotExist`，无 values 字段。

#### 回收处理

- 规整后的 dict 委托 `definitions.labelSelectorRequirement` 渲染，回收后逐项追加到结果列表。
- 元素渲染为空或非法时立即 fail。

#### 渲染条件

- 列表为空或未提供时不渲染（不输出 `matchExpressions` 字段）。
- 列表非空时通过 `base.field` 渲染为 `base.slice`。

### matchLabels（object，必填）

- 直接渲染为 map；上层调用方已通过 `base.labels` 等机制合并默认值（默认包含 `name` 标签）。
- 入参必须为 map 类型，缺失或非 map 类型立即 fail。
- 通过 `base.field` 渲染为 `base.map`。

## 专属边界行为

- **必填项缺失**：`matchLabels` 缺失或 `base.get` 返回 `"null"` 时立即 fail。
- **类型非法**：`matchLabels` 传入非 map 类型时立即 fail。
- **元素类型非法**：`matchExpressions` 元素不是 string 或 map 类型时立即 fail。
- **不支持的选择器**：string 类型元素无法匹配 `EQUALITY0` / `SET0` / `SET_EXISTS` 任一正则时立即 fail。
- **空值检查**：`SET0` 选择器拆分后的每个 value 必须非空，否则立即 fail。
- **回收校验**：每个元素经下层模板渲染后为空或非法时立即 fail。
- **list/map 类型 BUG 兼容**：
  - `matchExpressions` 通过 `base.isFromYamlArrayError` 兼容 Helm 4.2.2 `fromYamlArray` 对非列表输入返回错误切片的 BUG。
  - `matchLabels` 通过 `base.isFromYamlError` 兼容 Helm 4.2.2 `fromYaml` 对非 map 输入返回错误 map 的 BUG。

通用边界场景（必填缺失统一处理、非法枚举值报错等）复用 `docs/rules/const-boundary.md`。

## 约束说明

通用约束复用 `docs/rules/const-general.md`，包括：

- 字段处理和渲染顺序严格对齐 K8s 官方 API（`matchExpressions` → `matchLabels`），形成"处理-渲染"单字段闭环。
- 必须使用 `base.get` 取值、`base.field` 渲染，禁止绕开。
- 正则集中管理（`K8S.SELECTOR` 系列位于 `templates/base/_env.tpl`），禁止模板中直接使用字面量正则。
- 优先使用 `must` 系列函数。
- 错误格式：`[definitions.labelSelector] 字段路径: 错误原因`。

专属约束：

- `matchExpressions` 元素传递到 `definitions.labelSelectorRequirement` 前必须规整为 dict 类型；回收时必须 `mustUniq | mustCompact` 去重去空。
- string 类型元素按 K8s 标签选择器规则解析，统一映射到 `definitions.labelSelectorRequirement` 的标准 dict 形态（`key` / `operator` / `values`）。
- 选择器操作符归一化：
  - `=` / `==` → `In`
  - `!=` → `NotIn`
  - `In`（任意大小写）→ `In`
  - `NotIn`（任意大小写）→ `NotIn`
  - `!` 前缀 → `DoesNotExist`
  - 无前缀 → `Exists`
- `SET0` values 拆分保留 string 类型，禁止通过自动类型转换把数字字符串渲染为 int。
- 委托调用 `definitions.labelSelectorRequirement` 时上下文使用 dict 类型，下层不再区分 string / object。

## 参考资料

- API：
  - https://kubernetes.io/docs/reference/kubernetes-api/definitions/label-selector-v1-meta/#LabelSelector
  - https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#labelselector-v1-meta
  - https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
  - https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors
- 委托模板：
  - `templates/api-resources/Definitions/_LabelSelectorRequirement.tpl`
- 实现参考：
  - `docs/rules/const-general.md`：通用约束
  - `docs/rules/const-boundary.md`：通用边界
  - `docs/rules/const-example-code.md`：模板语法示例
  - `templates/base/_env.tpl`：正则常量定义（`K8S.SELECTOR` 路径）
  - `templates/base/_get.tpl`：`base.get` 取值机制
  - `templates/base/_field.tpl`：`base.field` 渲染机制
- 上层调用：
  - `templates/api-resources/Apps/_DeploymentSpec.tpl`：`selector` 字段委托本模板
  - `docs/specs/api-resources/Apps/_DeploymentSpec.md`：上层 spec
