---
change-id: definitions-label-selector-requirement-fix
updated_at: "2026-11-04T05:55:16Z"
---

# 修正 LabelSelectorRequirement 模板

## 目标

- 修正 `templates/api-resources/Definitions/_LabelSelectorRequirement.tpl` 中 `definitions.labelSelectorRequirement` 的现有缺陷，使其行为符合约定的字段校验与渲染契约，并与其他 Definitions 模板一致地通过 `base.get` 取值。

## 需求

- `key`、`operator`、`values` 三个字段的取值统一使用 `base.get`，替换现有的 `hasKey` 与 `get` 直取。
- `base.get` 取值后可对字符串结果执行 `trim`，去除前后空白；`operator` 带首尾空白时去除后按合法取值渲染。
- `keyAlias`、`operatorAlias`、`valuesAlias` 由 `base.get` 内置识别，本模板不额外处理，只在模板注释的入参表中补充说明。
- 父级 `definitions.labelSelector` 在原生 map 分支（`_LabelSelector.tpl` 中 `kindIs "map"` 处）改用 `base.get` 分别取 `key`、`operator`、`values`，由 `base.get` 内置识别 `*Alias`；父级只校验取到的 `key` 与 `operator` 非空及 `operator` 枚举，`key` 的标签键语法交由子模板校验；取到的值为空或不符合约束时中断渲染。
- `In`、`NotIn` 必须提供非空 `values`；缺失或空数组时中断渲染。
- `Exists`、`DoesNotExist` 不接受 `values`：`values` 非空时中断渲染，失败消息使用 `[definitions.labelSelector]` 前缀。
- 字符串简写分支不会产生 `*Alias` 入参。
- `key` 与 `operator` 的缺失、`null` 与空字符串复用 `base.get` 的必填校验及其失败消息。
- `key` 的标签键校验保持分段式：按 `/` 拆分，最多两段，分别校验名称段与前缀段的正则规则，并校验前缀段总长不超过 253 字符。
- 名称段与前缀段的正则校验各自委托 `base.string.verify` 与 `base.env` 既有常量，失败消息保留 `base.string.verify` 自身前缀，不修改公共模板的报错信息。
- 分段数量超限由本模板报错，使用 `[definitions.labelSelectorRequirement]` 前缀。
- 子模板内 `values` 保持可选；缺失与显式空数组均不输出该字段，非数组时中断渲染。
- `values` 元素不逐个校验类型，输出时统一转为字符串，例如数字与布尔值按字符串渲染。
- `key` 非字符串时中断渲染；`base.get` 输出为 YAML 文本，需还原真实类型后才能判定。
- `values` 去除空元素后为空时按空处理，不输出该字段；`[nil]` 视为空值，避免 Helm 与 Kubernetes 对 `nil` 字符串语义误判。
- `base.slice.cleanup` 的元素类型白名单增加 bool，与 int、int64、float64 同组放行。
- 父级已有 `base.slice.cleanup` 清洗，不再重复校验 `values` 元素类型。
- `values` 的适用性由父级按 `operator` 判定，子模板不重复该判定。
- 保持字段输出顺序与既有失败消息前缀不变，不改变父级调用方式。

## 期望输入格式

<!-- 只填写用户明确指定的本次特殊限制。 -->

## 约束

- 复用公共模板与 Helm/Sprig 内置能力完成校验，不自行编写重复的正则或临时状态代码。
- 只校验 `key` 时复用 `base.env` 既有的名称段与前缀段常量，不新增共享常量，也不修改既有常量。
- `base.get` 调用不得过度填写入参：不传强制类型、别名开关和调试参数；必填校验仅 `key` 与 `operator` 使用，为抵达该参数所需的中间位置传空字符串。
- 单路径取值不使用 `base.getWithAlias`。

## 非目标

- 不重构 `base.field`、`base.slice` 等 `base/` 层模板。
- 不涉及 `values` 与 `operator` 的适用性校验归属，该职责仍由父级承担。

## 验收

- 三个字段均可由 `base.get` 取值，别名与多层数据源优先级按 `base.get` 默认规则生效。
- `key` 或 `operator` 缺失、为 `null` 或空字符串时，中断消息来自 `base.get` 的必填校验。
- 父级以 map 形式传入 `keyAlias`、`operatorAlias`、`valuesAlias` 时，子模板按别名取到值并正常渲染；既有合法入参输出保持不变。
- 标签键校验覆盖范围与既有判定一致：含可选前缀与 `/` 的合法键正常渲染；多个 `/`、名称段或前缀段不合规、前缀总长超过 253 字符时中断并给出可定位的失败消息。
- `values` 的适用性按 `operator` 判定：`In`、`NotIn` 正常渲染非空 `values`；`Exists`、`DoesNotExist` 携带非空 `values` 时中断。
- `values` 元素含数字或布尔值时输出为对应字符串，与直接传入字符串的输出结构一致。
- `key` 为非字符串类型时中断渲染，失败消息指明 `key` 类型非法。
- `values` 仅含 `nil` 元素时按空数组处理，不输出该字段；父级不因 `nil` 元素崩溃。
- `operator` 为 `Exists ` 等带首尾空白时正常渲染 `operator: Exists`，其他非法取值仍中断并给出合法范围。
