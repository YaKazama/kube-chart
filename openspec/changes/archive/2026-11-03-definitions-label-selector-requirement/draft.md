---
change-id: definitions-label-selector-requirement
updated_at: "2026-11-03T09:36:16Z"
---

# Definitions LabelSelectorRequirement

## 目标

- 新建 `definitions.labelSelectorRequirement` 命名模板，承接父级 `definitions.labelSelector` 中 `matchExpressions` 解析为 map 后的单项数据，完成该 Kubernetes 结构的字段校验，并通过公共模板完成渲染。

## 需求

- 新建模板 `definitions.labelSelectorRequirement`。
- 入参是父级模板 `definitions.labelSelector` 中 `matchExpressions` 解析为 map 后的单项数据，类型为 object（map），包含 `key`、`operator` 和选填的 `values`；`In`/`NotIn` 的 `values` 前置处理由父级完成。
- 字段类型以官方文档约束为准：`key` 为 string，`operator` 为 string，`values` 为 string array。
- `operator` 取值范围按官方说明校验：`Valid operators are In, NotIn, Exists and DoesNotExist.`
- `operator` 在渲染时传入枚举列表进行二次校验，枚举列表大小写敏感，由渲染校验自动处理；只需保证传入的校验列表准确。
- `operator` 的允许值列表由本模板持有。
- `In`/`NotIn` 是否有 `values` 已在父级模板 `definitions.labelSelector` 中完成处理；本模板不重复判断 `values` 是否存在。
- `values` 的渲染委托 `base.field` 完成；序列化由 `toYamlPretty` 处理，强制转换由 `base.field` 的既有参数完成；本模板不自行实现转换或清理逻辑。
- 本模板输入中的 `values` 不应有空值；空数组不渲染，符合预期。
- 参考 Helm 官方源码，`fromYamlArray` 仅在解析无效 YAML 时返回错误形态（包含错误信息的单元素数组）；本模板链路不会产生此类输入，其解析错误结果不会出现，不设置对应错误处理。
- 父级模板保留字符串简写解析与构造 map；调用本模板后只回收生成的内容，在父级完成组装并恢复结果。本模板负责 `key`、`operator` 的业务校验和 `values` 的字段渲染，不重复承担父级已完成的 `values` 存在性及 `In`/`NotIn` 适用性处理。
- `key` 需要按 Kubernetes 标签键语法做格式校验：可选前缀与名称用斜杠分隔，名称为必填段，前缀为可选 DNS 子域。
- `key` 的名称段必须小于等于 63 个字符，以字母数字字符（`[a-z0-9A-Z]`）开头和结尾，中间允许破折号（`-`）、下划线（`_`）、点（`.`）和字母数字。
- `key` 的前缀可选；若指定，必须是 DNS 子域，即由点（`.`）分隔的一系列 DNS 标签，总共不超过 253 个字符，后跟斜杠（`/`）。
- 校验按前缀段与名称段分别进行，失败消息也分开。
- 标签键格式正则：

```yaml
K8S:
  SELECTOR:
    KEY_NAME_FOR_APPS: "^[A-Za-z0-9]([-A-Za-z0-9_.]{0,61}[A-Za-z0-9])?$"
    KEY_PREFIX_FOR_APPS: "^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?)*$"
```

- 名称段正则 `KEY_NAME_FOR_APPS` 已用真实 Chart 实测：`app`、`app.kubernetes.io` 通过；`app-`、`-app`、`a b`、64 个 `a` 全部不通过；63 个 `a` 通过。
- 前缀段正则 `KEY_PREFIX_FOR_APPS` 已用真实 Chart 实测：`app.kubernetes.io`、`example` 通过；`App.io`、`app..io`、单个 label 64 个 `a` 不通过。
- 前缀段总长 253 字符的上限无法由正则表达，使用 `len` 对前缀段单独判定。
- 前缀段与名称段使用 `splitList "/"` 拆分：长度为 2 时取首项为前缀、末项为名称；长度为 1 时只有名称段，无前缀。
- 多个 `/` 的失败消息归属整体 `key`；显式空前缀（如 `/name`）和空名称（如 `prefix/`）的失败消息分别归属前缀段和名称段。
- 本模板主动产生的失败消息统一使用 `[definitions.labelSelectorRequirement]` 前缀；委托公共模板执行校验时，保留公共模板自身的失败前缀。

## 期望输入格式

- object（map）类型，键为 `key`、`operator` 和选填的 `values`。

## 约束

- 字段类型、`operator` 枚举范围和 `values` 与 `operator` 的取值约束均以 Kubernetes API v1.36 官方字段表为准。
- `key` 的格式约束以官方[标签语法和字符集](https://kubernetes.io/zh-cn/docs/concepts/overview/working-with-objects/labels/#syntax-and-character-set)为准。
- 入参是上游已解析为 map 的数据，本模板不重复实现字符串简写解析；父级已完成 `values` 的存在性、数组类型及 `In`/`NotIn` 适用性处理。
- 官方字段顺序为 `key`、`operator`、`values`，输出顺序与之对齐。
- `operator` 的枚举校验通过渲染层的允许值列表完成，不在模板内自行维护枚举分支；枚举大小写敏感，大小写不一致时失败，不做归一化。
- 标签键格式正则作为项目固定正则新增到 `base.env` 的 `K8S.SELECTOR` 下；若后续出现更贴切的领域层级再迁移。
- 标签键格式正则的常量键名沿用现有 `<能力>_FOR_APPS` 命名风格。
- `definitions.labelSelector` 现有正则中的 key 匹配范围保持宽松，不复刻严格格式校验；严格校验只在本模板执行，避免过度或重复校验。

## 非目标

- 不将父级字符串简写解析或子模板返回结果的 YAML 恢复与错误保护迁入本模板。
- 不处理上述三个字段之外的其他字段，不输出 `status`。
- 不承担由 `matchLabels` 构造 requirement 的路径。
- 不为 `values` 中的空字符串项添加额外清理逻辑。

## 验收

- 输入合法 map 时，按 `key`、`operator`、`values` 顺序输出 `LabelSelectorRequirement` YAML 字段片段。
- `operator` 为 `In`、`NotIn` 且 `values` 非空时正常输出 `values`。
- `operator` 为 `Exists`、`DoesNotExist` 且 `values` 为空或缺失时不输出 `values`。
- `operator` 超出 `In`、`NotIn`、`Exists`、`DoesNotExist` 时中断渲染并给出合法范围。
- `operator` 与官方枚举大小写不一致时中断渲染，不做归一化。
- `values` 为空数组时不渲染 `values` 字段，符合预期。
- `key`、`operator` 类型非法时中断渲染。
- `key` 形如 `app`、`app.kubernetes.io/name` 时通过校验。
- `key` 不符合标签键语法（例如含空格、以非字母数字开头或结尾、前缀非法）时中断渲染。
- `key` 名称段超过 63 个字符时中断渲染，并给出名称段相关的失败消息。
- `key` 前缀段超过 253 个字符时中断渲染，并给出前缀段相关的失败消息。
- 本模板主动产生的失败消息使用 `[definitions.labelSelectorRequirement]` 前缀；公共依赖产生的失败消息保留其自身前缀。

## 开放问题

- 无。
