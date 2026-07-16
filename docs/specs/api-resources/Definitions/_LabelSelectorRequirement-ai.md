# definitions.LabelSelectorRequirement

## 目标与交付约定

新增命名模板 `definitions.labelSelectorRequirement`，写入 `templates/api-resources/Definitions/_LabelSelectorRequirement.tpl`。入参为 dict（由上层 `definitions.labelSelector` 透传），按 K8s 官方 API 字段顺序（`key` → `operator` → `values`）渲染 `LabelSelectorRequirement` 资源，不渲染 `status` 字段。

## 字段级功能需求

### key（string，必填）

独立字段，单字段闭环（取-校验-渲染）。

- 必填项，缺失或 `base.get` 返回 `"null"` 时立即 fail。
- 必须为 string 类型，非 string 立即 fail。
- 通过 `base.field` 渲染为 `base.string`。

### operator（string，必填）

仅允许 `In`、`NotIn`、`Exists`、`DoesNotExist` 四种取值；与 `values` 强关联（`In`/`NotIn` 必须有非空 values；`Exists`/`DoesNotExist` 必须 values 为空），属例外场景，集中处理后按 API 顺序渲染。

- 必填项，缺失或 `base.get` 返回 `"null"` 时立即 fail。
- 通过 `mustHas` 进行枚举校验，非法值立即 fail 并输出合法范围。
- 通过 `base.field` 渲染为 `base.string`。

### values（[]string，条件必填）

与 `operator` 强关联，集中处理后按 `operator` 条件渲染。

- 未提供或 `base.get` 返回 `"null"` 时按空数组处理。
- 入参必须为 array 类型，类型非法立即 fail。
- 通过 `base.isFromYamlArrayError` 兼容 Helm 4.2.2 `fromYamlArray` 对非列表输入返回错误切片的 BUG。
- 每个元素必须为 string 且非空，违反任一约束立即 fail。
- **与 operator 关联规则**：
  - `operator = In` 或 `NotIn` → `values` 必须非空，违反立即 fail。
  - `operator = Exists` 或 `DoesNotExist` → `values` 必须为空，违反立即 fail。
- 满足关联规则时通过 `base.field` 渲染为 `base.slice`；不满足时不渲染（按 operator 决定是否输出 `values` 字段）。

## 专属边界行为

- **必填项缺失**：`key` / `operator` 缺失或 `base.get` 返回 `"null"` 时立即 fail。
- **类型非法**：
  - `key` 非 string → 立即 fail。
  - `values` 非 array → 立即 fail。
  - `values` 元素非 string 或为空 → 立即 fail。
- **枚举非法**：`operator` 不在 `In` / `NotIn` / `Exists` / `DoesNotExist` 范围内 → 立即 fail 并输出合法枚举。
- **关联冲突**：
  - `In` / `NotIn` + values 空 → 立即 fail。
  - `Exists` / `DoesNotExist` + values 非空 → 立即 fail。
- **list 类型 BUG 兼容**：`values` 通过 `base.isFromYamlArrayError` 兼容 Helm 4.2.2 `fromYamlArray` 对非列表输入返回错误切片的 BUG。

通用边界场景（必填缺失统一处理、非法枚举值报错等）复用 `docs/rules/const-boundary.md`。

## 约束说明

通用约束复用 `docs/rules/const-general.md`，包括：

- 字段处理和渲染顺序严格对齐 K8s 官方 API（`key` → `operator` → `values`），形成"处理-渲染"单字段闭环；例外情况（`operator` 与 `values` 强关联）允许关联字段集中处理后按 API 顺序渲染。
- 必须使用 `base.get` 取值、`base.field` 渲染，禁止绕开。
- 优先使用 `must` 系列函数。
- 错误格式：`[definitions.labelSelectorRequirement] 字段路径: 错误原因`。
- 禁止实现 `status` 字段及相关逻辑。

专属约束：

- `key` 独立无关联，必须单字段闭环（取-校验-渲染），禁止延迟到末尾渲染。
- `operator` 与 `values` 强关联，集中处理（取值+校验）后按 K8s API 顺序渲染：`operator` 先于 `values` 输出。
- `values` 仅在 `operator` 为 `In` / `NotIn` 时输出；`Exists` / `DoesNotExist` 时不输出 `values` 字段。
- `operator` 渲染值使用归一化大写（K8s API 仅接受 `In` / `NotIn` / `Exists` / `DoesNotExist`），上游 `definitions.labelSelector` 已完成归一化。
- 禁止创建新模板（本模板为 `definitions.labelSelector` 的委托模板）。

## 参考资料

- API：
  - https://kubernetes.io/docs/reference/kubernetes-api/definitions/label-selector-requirement-v1-meta/#LabelSelectorRequirement
  - https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#labelselectorrequirement-v1-meta
- 委托调用方：
  - `templates/api-resources/Definitions/_LabelSelector.tpl`：`matchExpressions` 元素规整为 dict 后委托本模板
  - `docs/specs/api-resources/Definitions/_LabelSelector.md`：上层 spec
- 实现参考：
  - `docs/rules/const-general.md`：通用约束（含字段顺序与"处理-渲染"单字段闭环）
  - `docs/rules/const-boundary.md`：通用边界
  - `docs/rules/const-example-code.md`：模板语法示例
  - `templates/base/_get.tpl`：`base.get` 取值机制
  - `templates/base/_field.tpl`：`base.field` 渲染机制
