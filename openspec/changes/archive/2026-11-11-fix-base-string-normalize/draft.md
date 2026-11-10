---
change-id: fix-base-string-normalize
updated_at: "2026-11-10T16:23:55Z"
---

# base.string.normalize 存量调用点批量改造

## 目标

- 检索 `templates/**/*.tpl`，找出与 `base.string.normalize` 等价的既有 string 字段清洗实现，并统一改为调用该模板。
- 消除 `templates/api-resources/` 中重复的引号剥离、类型判定与逐字符校验逻辑，收敛为单一入口。

## 需求

- 以 `TODO.md` 中「`base.string.normalize` 存量调用点批量改造」条目为改造清单与分组依据，覆盖其列出的全部 string 类调用点：第一组 17 处、第二组 15 处，共 32 处。
- 改造点统一改为直接输出 `base.string.normalize` 的结果，删除内联的 `SYS.YAML_QUOTED` 引号剥离、`kindIs "string" (fromYaml ...)` 类型判定与重复的空值分支。
- 传给 `base.string.normalize` 的入参必须是 `base.get` 的原始输出文本，调用方不得预先 `trim`、`fromYaml` 或拼接。
- 每个 string 改造点在 `base.string.normalize` 之后保留 `| trim`：现有实现均对去引号结果 trim（两处委托 `base.labelKey` 的调用点由下游 trim），保留后首尾空白剥离与「仅空白等同未设置」行为不变。
- `Apps/_DeploymentSpec.tpl` 的 4 个整数字段统一重构为「`base.get` 原始文本 → `base.int` 校验整数形态 → `base.int.range` 校验字段自定义上下限」，删除逐字符校验与 `base.int` 重复链：
  - 只接受序列化后为十进制整数形态的取值，含原生整数与整数值浮点；`base.get` 序列化后带引号的纯数字字符串视为非法并中断。
  - `minReadySeconds`、`progressDeadlineSeconds`、`revisionHistoryLimit`：大于 0 时渲染，`0` 视为 0 值且不渲染。
  - `replicas`：允许 `0` 并渲染 0。
  - `revisionHistoryLimit: 0` 保持不渲染，即使该字段在 Kubernetes API 中是 pointer；与 `minReadySeconds`、`progressDeadlineSeconds` 的零值处理保持一致，也避免与 `replicas` 的例外扩散。
  - 负数、带非零小数部分的浮点、非数字文本、布尔、map 与 list 一律中断，不再静默抑制输出。
  - Helm 把 `values.yaml` 的数值统一解析为 `float64`，`3` 与 `3.0` 运行时不可区分，整数值浮点与同值整数等价并照常输出。
  - 缺失或为空时一律不渲染，由 Kubernetes 集群自身默认值生效；模板不再内置任何默认值。
  - 上下限为字段自定义的 int32 非负区间 `0 - 2147483647`。
- `Core/_PodSpec.tpl` 的 2 个整数字段删除 `TYPES.POSITIVE_INT` 正则、`atoi` 与引号剥离，改用同一条 `base.int` + `base.int.range` 链路：
  - `activeDeadlineSeconds`：大于 0 时渲染，`0` 不渲染。
  - `terminationGracePeriodSeconds`：大于等于 0 时渲染，`0` 输出 0。
  - 两个字段的上下限为 `0 - +∞`。
- `Definitions/_WeightedPodAffinityTerm.tpl` 与 `Definitions/_PreferredSchedulingTerm.tpl` 的 `weight` 已委托 `base.int` 与 `base.int.range`，纯数字字符串可隐式通过，本次仅复核，不改变行为。
- bool 字段（`Core/_PodSpec.tpl` 的 7 个开关，1 处调用）与 `IntOrString` 字段（`maxSurge`、`maxUnavailable`，2 处）保持现状，不套用 `base.string.normalize`。
- `Apps/_DeploymentStrategy.tpl` 的 `type` 只有 Recreate、RollingUpdate 两个合法值：缺失与 YAML null 沿用现有行为视为未设置，字面字符串 `"null"` 与其他取值一律中断，删除把 `"null"` 归一化为空的分支。
- `Apps/_DeploymentSpec.tpl` 的 `selector` 不再单独判断 `"null"`，按 map 类型校验；缺失、null 与非 map 输入均中断。
- `Apps/_DeploymentSpec.tpl` 的 `strategy` 不对显式 null 做父级特判，透传给 `apps.deploymentStrategy` 处理。
- `Apps/_DeploymentSpec.tpl` 的 `strategy` 字符串简写分支先对 `strategy` 的 `base.get` 原始输出调用 `base.string.normalize`，再匹配策略简写格式；经 normalize 后已是真实 string，`type`、`maxSurge`、`maxUnavailable` 三处捕获结果不再使用 `SYS.YAML_QUOTED`，改用 `trimAll "\"'"` 折叠简写内的 `""`、`''` 空占位符。
  - 简写字符串内的 `""`、`''` 仍作为跳过 maxSurge 或 maxUnavailable 的空占位符生效，与改造前一致。
- 接受改造引入的新失败边界：非 string 输入到 string 字段、非整数文本到数值字段由静默输出改为中断渲染。
- 接受引号内容解码差异：`"\n"` 解码为换行、`'it''s'` 解码为 `it's`，不再保留引号原文。
- 接受失败消息变化：统一使用 `base.string.normalize` 前缀，不再携带调用方模板名与字段路径。
- 引号标量的零折叠由既有渲染器决定：`base.string.normalize` 正确解码 `"007"` 为 `007`，随后 `base.field` 的 `quote` 路由到 `base.string`，由 `TYPES.ZERO` 折叠为 `07`；该行为改造前后一致，本次不改变。
- `values.yaml` 来源的数值会被 Helm 解析为 `float64`，`base.get` 对 7 位以上整数使用科学计数法（`1000000` → `1e+06`），无法通过整数正则；有效整数上限为 `999999`。直接以 int 传入上下文时不触发该限制，可达到 int32 上限。
- 改造后在相同有效输入下的渲染结果与当前实现保持一致，并以归档 change 中已通过的有效输入场景作为回归基准。

## 期望输入格式

<!-- 只填写用户明确指定的本次特殊限制。 -->

## 约束

- 检索目录以工作区实际路径 `templates/` 为准。
- 仅使用 Helm 内置函数、Go Template、Sprig 与 Helm 特有函数。
- 保持代码 DRY，不引入重复逻辑，不为单点差异复制整套清洗链。
- 单个调用点若无法用 `base.string.normalize` 或底层数值模板等价表达，保留现状并在执行制品中说明理由。
- `base.string.normalize` 只接受解码后为 string 或 null 的标量；原生 bool、数值输入会中断渲染，因此不能用于 bool 与 `IntOrString` 字段。
- string 调用点在改造后不得残留 `SYS.YAML_QUOTED`；6 处整数字段同样不保留该常量。
- `strategy` 简写三处捕获结果不得使用 `SYS.YAML_QUOTED`，空占位符统一用 `trimAll "\"'"` 折叠；捕获字母表只有 `\d+`、`\d+%`、`""`、`''`，`trimAll` 不得影响数字与百分比。
- 2 处 `weight` 调用点保留 `SYS.YAML_QUOTED` 去引号：`base.get` 对标量输出 YAML 序列化文本，字符串数值带引号，而 `base.int` 只接受无引号数字；6 处整数字段不再剥离引号，改为拒绝带引号的纯数字字符串。
- 数值字段的上下限校验统一用 `base.int.range` 在 int 上执行，不恢复逐字符比较或字符串字典序比较。

## 非目标

- 不修改 `base.string.normalize` 自身的实现与失败边界。
- 不新增或修改其他 `base.*` 能力模板。
- 不处理 `TODO.md` 中 `base.slice.cleanup` 溢出与 affinity map 兼容条目。
- 不改动改造清单之外的 `SYS.YAML_QUOTED` 调用点。
- 不改动 `Definitions/_NodeAffinity.tpl` 中 `fromYaml (printf "v: %s" ...)` 的父级标量门禁：该处需同时接受原生数值，与 `base.string.normalize` 的 string 语义不同，且不在本次清单内，另开 change 处理。

## 验收

- 原 32 处 string 站点全部改造完成，对应位置不再残留 `kindIs "string" (fromYaml ...)` 类型判定与 `SYS.YAML_QUOTED`；`strategy` 的 `type` 与三个简写捕获共 4 个站点合并为 2 处调用，实际 `base.string.normalize` 调用数为 30。
- 6 处整数字段改用 `base.int` + `base.int.range`，不再保留逐字符校验、引号剥离与 `TYPES.POSITIVE_INT`、`atoi` 重复实现。
- `minReadySeconds`、`progressDeadlineSeconds`、`revisionHistoryLimit` 在 `0` 时不渲染，其余正整数渲染；`replicas` 在 `0` 时渲染 0。
- `revisionHistoryLimit: 0` 不渲染，最终对象采用 Kubernetes API 默认值 10。
- `replicas`、`progressDeadlineSeconds`、`revisionHistoryLimit` 缺失或为空时不渲染对应字段，模板不内置默认值。
- `activeDeadlineSeconds` 在 `0` 时不渲染；`terminationGracePeriodSeconds` 在 `0` 时渲染 0。
- 上述 6 个字段对 `-1`、`1.5`、`"3"`、`abc`、`true` 一律中断渲染；YAML 中 `+5` 与 `5` 同为整数 5、`3.0` 与 `3` 同为整数值 3，均照常输出。
- 4 个 int32 字段保留上限校验：`2147483647` 通过，`2147483648` 及更大值中断渲染。
- 引号标量经渲染器输出后遵循既有零折叠：输入 `"007"` 的 string 字段最终输出 `07`，与改造前一致。
- `values.yaml` 来源的整数字段在 `999999` 及以下正常输出，`1000000` 及以上因科学计数法中断；直接传入 int 时可达到 `2147483647`。
- 2 处 `weight` 保持 `base.int` 与 `base.int.range` 现有行为不变。
- `apps.deploymentStrategy` 的 `type: "null"` 字面字符串中断；缺失与 YAML null 仍按未设置取默认 RollingUpdate。
- `apps.deploymentSpec` 的 `selector` 对 null 与非 map 输入中断，`strategy` 的显式 null 交由 `apps.deploymentStrategy` 处理且结果与改造前一致。
- `apps.deploymentSpec` 的 `strategy: "RollingUpdate \"\" 10%"` 输出 `maxUnavailable: 10%` 且不含 `maxSurge`；`strategy: "RollingUpdate '' 10%"` 同。
- `apps.deploymentSpec` 的 `strategy: "\"\""` 与 `strategy: "''"` 不输出 `strategy`，与改造前一致。
- `apps.deploymentSpec` 的 `strategy: 5` 这类原生数值输入中断渲染，符合非 string 输入到 string 字段的新失败边界。
- bool 1 处与 `IntOrString` 2 处保持现有实现，不出现未声明的行为变化。
- 归档 change 中已通过的有效输入场景渲染输出保持不变。

## 开放问题

<!-- 当前无开放问题。 -->
