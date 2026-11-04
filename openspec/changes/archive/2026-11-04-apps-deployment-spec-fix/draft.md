---
change-id: apps-deployment-spec-fix
updated_at: "2026-11-04T09:01:59Z"
---

# Deployment strategy 解析修复

## 目标

- 修复 `apps.deploymentSpec` 中 `strategy` 字段的解析缺陷：现有 string 简写无法表达 `type`、`maxSurge`、`maxUnavailable` 三者任意为空。
- 把 `strategy` 的委托目标从占位的 `definitions.deploymentStrategy` 改为 `apps.deploymentStrategy`；该子模板本 change 只占位，不创建。

## 需求

- `strategy` 支持 string 简写和原生 map 两种格式，二者互斥；其他类型中断渲染。
- string 由单个正则一次性全量匹配，匹配失败即中断渲染；首槽可省略或为显式空字符串。
- 正则固定 3 个位置槽（`type`、`maxSurge`、`maxUnavailable`），超出即匹配失败。
- `maxSurge`、`maxUnavailable` 的数值部分只能是整数，小数如 `1.5` 不属于合法形态，匹配失败并中断渲染。
- 原生标量输入不单独区分：`base.get` 取值结果统一按 string 处理。
- `type`、`maxSurge`、`maxUnavailable` 三者可以任意为空，均为合法输入。
- `type` 为空时使用内置默认值 `RollingUpdate`，并在渲染结果中显式输出 `type: RollingUpdate`；Kubernetes 文档已注明 `Default is RollingUpdate.`。
- `type` 为 `Recreate` 时省略 `rollingUpdate` 的全部内容；输入中的 `maxSurge`、`maxUnavailable` 静默忽略，不视为非法。
- string 分支的 `maxSurge`、`maxUnavailable` 只能是整数或百分比，不允许小数；map 分支的对应字段原样透传，由 Kubernetes 底层判断。
- map 分支的 `type` 与 string 分支一样按大小写不敏感归并为官方拼写 `RollingUpdate` / `Recreate`。
- map 分支的 `type` 为 `null`、空字符串或缺失时等同于空，补充 `RollingUpdate`。
- map 分支只做容器级校验：`rollingUpdate` 必须是 map，`type` 为 `Recreate` 或 `rollingUpdate` 为空时丢弃 `rollingUpdate`；`rollingUpdate` 内部字段原样透传，其归一化、`*Alias` 处理与类型判断均由孙模板负责，本层不涉及。
- `strategy` 为空时（缺失、空字符串或 string 简写归一化后三项全空）不渲染该字段，复用 Kubernetes 内部默认设置。
- type 枚举门禁是子模板的工作，本层不实现枚举判断逻辑。正则匹配时才按大小写不敏感限定为两个枚举字面量，因此未知 type 在 string 分支表现为不匹配；匹配成功后本层只把 type 归一化为官方拼写 `RollingUpdate` / `Recreate`。
- 无论输入是 string 还是 map，最终渲染出的 `strategy` 都必须是 map，且只含 `type` 与可选 `rollingUpdate`。
- 非法输入失败消息的字段路径前缀沿用 `apps.deploymentSpec`。

## 期望输入格式

### string 形式

`[type][分隔符][maxSurge][分隔符][maxUnavailable]`，首槽只决定 `type`，其余两个位置值始终依次填入 `maxSurge`、`maxUnavailable`：

- 首槽可以是 `Recreate`、`RollingUpdate`（大小写不敏感）、显式空字符串（`""` 或 `''`）或完全省略。
- 分隔符为 `SPLIT.ALL` 去掉 `.` 与 `-` 后的字符集 `[\s:,/|*^@#]`，也可省略。

因此 `RollingUpdate 20%` 表示 `maxSurge=20%`，`1 30%` 表示 `type` 取默认值、两个参数依次填入，只给 `maxUnavailable` 时须写作 `RollingUpdate "" 30%`。

`base.env` 的 `APPS.DEPLOYMENT.STRATEGY` 为单个全量匹配常量，捕获组 1/2/3 依次为 `type`、`maxSurge`、`maxUnavailable`（`_env.tpl` 中按 YAML 双引号转义：`\s` 写为 `\\s`、`\d` 写为 `\\d`、`""` 写为 `\"\"`）：

```text
^(?:((?i:recreate|rollingupdate)|""|''))?(?:\s*[\s:,/|*^@#]+\s*|\s*)(""|''|\d+%?)?(?:\s*[\s:,/|*^@#]+\s*|\s*)(""|''|\d+%?)?$
```

### 捕获后的归一化

每个捕获组先剔除外层引号并 `trim`，`""`、`''` 归为空字符串，再按位置处理：

1. `type` 为空时取 `RollingUpdate`，否则归一为官方拼写。
2. `maxSurge`、`maxUnavailable` 为空时不输出该键。
3. 三项均空时不渲染 `strategy`。

### map 形式

- `type`、`rollingUpdate` 两个可选键，其他键静默忽略。
- `type` 缺失、为 `null` 或为空字符串时补充 `RollingUpdate`；非空时按大小写不敏感归并为官方拼写。
- `type` 为 `Recreate` 时丢弃 `rollingUpdate`。
- `rollingUpdate` 必须是 map，否则中断渲染；为空时丢弃该键；内部字段原样透传给孙模板。
- `rollingUpdate` 内部字段的归一化、`*Alias` 处理与类型判断属于孙模板 `apps.rollingUpdateDeployment` 的职责，本层只做容器级校验与透传。

## 约束

- 本次只处理 `strategy` 字段，不涉及其他字段。
- 占位模板只占位，不实际创建：`apps.deploymentStrategy` 与 `apps.rollingUpdateDeployment` 均不在本 change 实现。
- `apps.rollingUpdateDeployment` 属于孙子模板，不处理。
- 本 change 是对 `apps-deployment-strategy` 的 BUG 修正。
- `base.env` 的 `APPS.DEPLOYMENT.STRATEGY` 改为单个全量匹配常量，首槽可省略且接受显式空字符串；`APPS.DEPLOYMENT.ROLLING_UPDATE` 已无引用，随本次调整移除。
- `openspec/references/template-snippets.md` 的「多类型字段规整」示例纳入本次修改范围。
- `apps.deploymentStrategy` 的占位阻断状态保持不变；验收时用同名 fixture 放行，不视为本 change 的模板缺失。

## 非目标

- 不涉及 `minReadySeconds`、`progressDeadlineSeconds`、`revisionHistoryLimit`、`paused` 等其他 `DeploymentSpec` 字段。
- 不创建 `apps.deploymentStrategy` 与 `apps.rollingUpdateDeployment` 模板。
- 不校验 `maxSurge`、`maxUnavailable` 的数值形态、百分比上限或二者联动约束。

## 验收

- `RollingUpdate 1 30%` 渲染为 `type: RollingUpdate`，`rollingUpdate` 含 `maxSurge` 与 `maxUnavailable`。
- `1 30%` 渲染为 `type: RollingUpdate` 加两个参数。
- `1` 渲染为 `type: RollingUpdate` 加 `rollingUpdate.maxSurge`。
- `RollingUpdate "" 30%` 渲染为 `type: RollingUpdate` 加 `rollingUpdate.maxUnavailable`。
- `rollingupdate` 渲染为 `type: RollingUpdate`。
- `RollingUpdate '' 30%` 与 `RollingUpdate "" 30%` 渲染结果一致，均只含 `rollingUpdate.maxUnavailable`。
- `'' 30%` 与 `"" 30%` 渲染结果一致，均只含 `rollingUpdate.maxSurge`。
- `'' 1 30%` 与 `"" 1 30%` 渲染结果一致，均含 `maxSurge` 与 `maxUnavailable` 两个参数。
- `RollingUpdate1` 与 `RollingUpdate 1` 渲染结果一致，分隔符可省略。
- 单独的 `""` 或 `''`、`"" ""`、`'' ''` 视为全空，不产生 `strategy` 字段。
- `RollingUpdate "" ""` 只输出 `type: RollingUpdate`，不输出 `rollingUpdate`。
- `Recreate 1 30%` 渲染结果只含 `type: Recreate`。
- map 输入 `{rollingUpdate: {maxSurge: 1}}` 渲染为 `type: RollingUpdate` 加原样 `rollingUpdate`。
- map 输入的 `rollingUpdate` 内部字段不被本层改写或校验，`{rollingUpdate: 1}` 中断渲染，`{rollingUpdate: {}}` 只输出 `type`。
- 空 `strategy` 不产生 `strategy` 字段，也不注入任何默认值。
- `BlueGreen`、`1 30% 5`、`1 30% 5 6`、`1.5`、`-1` 以及既非 string 也非 map 的输入中断渲染，失败消息前缀为 `apps.deploymentSpec`。
- 任意合法输入最终渲染出的 `strategy` 都是 map。

## 开放问题

- 无。
