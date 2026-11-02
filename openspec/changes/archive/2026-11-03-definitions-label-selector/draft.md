---
change-id: definitions-label-selector
updated_at: "2026-11-02T15:42:13Z"
---

# definitions.labelSelector

## 目标

- 新增模板 `definitions.labelSelector`。
- 输入使用 `apps.deploymentSpec` 模板中经过处理后的 `selector` 数据。

## 需求

- `definitions.labelSelector` 接收经过处理的 map；输入来源为 `apps.deploymentSpec` 模板处理后的 `selector` 数据。
- `matchLabels` 为必填项，不能省略；空 object 视为缺失并失败。
- `matchExpressions` 为可选 array；为 `null` 时按缺失处理并省略该字段。
- 字段和类型以 Kubernetes 官方 `LabelSelector` 定义为基准，不过度扩展或更改：
  - `matchLabels` 为 object（string → string），直接渲染。
  - `matchExpressions` 为 `LabelSelectorRequirement` array（slice）；每项包含 `key`（string）、`operator`（string）、`values`（string array）。
- `matchExpressions` 列表项支持以下输入形态：
  - 等值：`<key> = <value>` 或 `<key> == <value>`，归一化为 `In`。
  - 不等值：`<key> != <value>`，归一化为 `NotIn`。
  - 集合：`<key> in (<value>, ...)` 归一化为 `In`；`<key> notin (<value>, ...)` 归一化为 `NotIn`。
  - 仅 key：`<key>` 归一化为 `Exists`。
  - 取反仅 key：`"!<key>"` 归一化为 `DoesNotExist`。
  - 原生字典：`{key, operator, values}`。
- 字符串形态仅使用以下三条正则，不引入其他正则；常量名去掉数字、统一使用 `_FOR_APPS` 后缀，正则内容不变：
  - `EQUALITY_FOR_APPS`：`^([A-Za-z0-9._-]+)(?:\s+([=]{1,2}|!=))(?:\s+([A-Za-z0-9._-]+))$`
  - `SET_FOR_APPS`：`^([A-Za-z0-9._-]+)(?:\s+((?i)in|(?i)notin))(?:\s+\((.*?)\))$`
  - `EXISTS_FOR_APPS`：`^(!)?([A-Za-z0-9._-]+)$`
- 本 change 同步重命名 `templates/base/_env.tpl` 的 `K8S.SELECTOR` 常量：`EQUALITY0` → `EQUALITY_FOR_APPS`，`SET0` → `SET_FOR_APPS`，`SET_EXISTS` → `EXISTS_FOR_APPS`。
- `operator` 输入不区分大小写，输出必须为 `In`、`NotIn`、`Exists`、`DoesNotExist` 的规范大小写。
- `values` 按官方规则处理：`In` 和 `NotIn` 必须为非空 string array；`Exists` 和 `DoesNotExist` 的 values 必须缺失或为空，且不向下传递 values 字段；原生字典违反该规则时失败。
- 所有 values 均经过 `base.slice.cleanup` 清洗。该模板按其契约完成拆分、trim、纯数字字符串转 int、去重和去空，并返回 YAML 列表；集合清洗不负责 string 类型归一化。`definitions.labelSelector` 在 `fromYamlArray` 后逐项 `toString`，把清洗结果恢复为官方要求的 string array，因此纯数字值以规范化十进制字符串输出，前导零和显式 `+` 不保留。
- 字符串形态无法匹配三条正则之一时必须失败并中断渲染；`in` / `notin` 的列表经清洗后为空时同样必须失败并中断渲染，不跳过。
- `*Alias` 自动别名是内置默认功能；本 change 不提供显式别名 `mExprs`、`mLabels`。
- `apps.deploymentSpec` 的 selector 预处理只需在 `pick` 时保留 `matchExpressionsAlias`、`matchLabelsAlias` 并原样向下传递；`definitions.labelSelector` 内的 `base.get` 统一处理别名优先和缺失回退。`pick` 结果没有这两个字段时不需额外处理，不影响后续行为；现有 `matchLabels` 与 `base.labels` 合并逻辑保持不变。
- `definitions.labelSelector` 将归一化后的 `matchExpressions` 项传给占位模板 `definitions.labelSelectorRequirement`；本 change 不创建该模板、文件或 `define`。

## 期望输入格式

以下 map 直接传入 `definitions.labelSelector`，其中 `matchLabels` 必填。

```yaml
matchLabels:
  xxx: deploy-1
matchExpressions:
  # 基于等值 / 不等值
  - environment = production
  - environment1 == production1
  - tier != frontend
  # 基于集合
  - environment2 in (production2, qa2, xxx2)
  - tier2 notin (frontend2, backend2)
  - partition
  - "!partition1"
  # 原生字典
  - key: key
    operator: In
    values:
      - value1
      - value2
  - key: key2
    operator: Exists
```

内置别名形态与对应规范键等价：

```yaml
matchLabelsAlias:
  xxx: deploy-1
matchExpressionsAlias:
  - environment = production
```

## 约束

- 输入范围仅限 `apps.deploymentSpec` 模板处理后的 `selector` 数据。

## 验收

- 示例中各 `matchExpressions` 形态均能渲染为合法 LabelSelector：`=`、`==`、`in` 输出 `In`，`!=`、`notin` 输出 `NotIn`，裸 key 输出 `Exists`，`!key` 输出 `DoesNotExist`，原生字典的 `operator` 按大小写不敏感输入、规范大小写输出。
- `matchLabelsAlias`、`matchExpressionsAlias` 与对应规范键产生相同输出；`matchLabels` 原样输出，`values` 输出为经过 `base.slice.cleanup` 清洗并转为 string 的列表。
- 无法匹配正则的字符串和空 `in` / `notin` 列表均导致失败并中断渲染；`matchLabels` 缺失时失败并中断渲染。
- `apps.deploymentSpec` 在 `pick` 结果中保留 `matchExpressionsAlias`、`matchLabelsAlias` 并向下传递；缺失时由 `base.get` 回退规范键。
- `matchExpressions` 每项归一化后传给占位模板 `definitions.labelSelectorRequirement`，其返回 map 参与最终输出；本 change 不创建该模板。
