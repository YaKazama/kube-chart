# base.string.normalize 存量调用点改造任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_LocalObjectReference.tpl`：`name` 改为 `base.string.normalize` 解码后 trim，删除 `SYS.YAML_QUOTED` 剥离与 `kindIs "string"` 判定；对应 `字符串字段按 YAML 标量语义解码`。
- [x] T2 `templates/api-resources/Definitions/_PodReadinessGate.tpl`：`conditionType` 改为 `base.string.normalize` 解码后 trim，删除 `SYS.YAML_QUOTED` 剥离与 `kindIs "string"` 判定；对应 `字符串字段按 YAML 标量语义解码`。
- [x] T3 `templates/api-resources/Definitions/_PodOS.tpl`：`name` 改为 `base.string.normalize` 解码后 trim 再转小写，删除 `SYS.YAML_QUOTED` 剥离；对应 `字符串字段按 YAML 标量语义解码`。
- [x] T4 `templates/api-resources/Definitions/_HostAlias.tpl`：`ip` 改为 `base.string.normalize` 解码后 trim，删除 `SYS.YAML_QUOTED` 剥离；对应 `字符串字段按 YAML 标量语义解码`。
- [x] T5 `templates/api-resources/Definitions/_PodResourceClaim.tpl`：`name`、`resourceClaimName`、`resourceClaimTemplateName` 改为 `base.string.normalize` 解码后 trim，删除 `SYS.YAML_QUOTED` 剥离与三处 `kindIs "string"` 判定，保留 `name` 归一化为空的中断；对应 `字符串字段按 YAML 标量语义解码`。
- [x] T6 `templates/api-resources/Definitions/_PodAffinityTerm.tpl`：`topologyKey` 改为 `base.string.normalize` 解码后 trim 再交 `base.labelKey`，删除 `SYS.YAML_QUOTED` 剥离与 `kindIs "string"` 判定；对应 `字符串字段按 YAML 标量语义解码`。
- [x] T7 `templates/api-resources/Definitions/_LabelSelectorRequirement.tpl`：`key` 与 `operator` 改为 `base.string.normalize` 解码后 trim，删除 `SYS.YAML_QUOTED` 剥离与 `key` 的 `kindIs "string"` 判定；对应 `字符串字段按 YAML 标量语义解码`。
- [x] T8 `templates/api-resources/Definitions/_LabelSelector.tpl`：原生 map 条目的 `key` 与 `operator` 改为 `base.string.normalize` 解码后 trim，删除 `SYS.YAML_QUOTED` 剥离与 `key` 的 `kindIs "string"` 判定；对应 `字符串字段按 YAML 标量语义解码`。
- [x] T9 `templates/api-resources/Definitions/_NodeSelectorRequirement.tpl`：`key` 与 `operator` 的循环取值改为 `base.string.normalize` 解码后 trim，删除 `SYS.YAML_QUOTED` 剥离与 `kindIs "string"` 判定，保留归一化为空的中断；对应 `字符串字段按 YAML 标量语义解码`。
- [x] T10 `templates/api-resources/Definitions/_NodeSelectorTerm.tpl`：原生 map 条目的 `key` 与 `operator` 改为 `base.string.normalize` 解码后 trim，删除 `SYS.YAML_QUOTED` 剥离与 `key` 的 `kindIs "string"` 判定；对应 `字符串字段按 YAML 标量语义解码`。
- [x] T11 `templates/api-resources/Apps/_DeploymentStrategy.tpl`：`type` 改为 `base.string.normalize` 解码后 trim，删除 `SYS.YAML_QUOTED` 剥离与 `"null"` 归一化分支；对应 `渲染 DeploymentStrategy type 字段`。
- [x] T12 `templates/api-resources/Apps/_DeploymentSpec.tpl`：`minReadySeconds`、`progressDeadlineSeconds`、`replicas`、`revisionHistoryLimit` 收敛为「取原始输出 → `base.int` → `base.int.range 0 2147483647`」并删除逐字符校验、去前导零、字典序上限比较、引号剥离与模板默认值；`selector` 删除不可达的 `"null"` 文本比较；`strategy` 的 map 分支 `type` 与字符串简写分支改用 `base.string.normalize`，简写捕获结果改用 `trimAll "\"'"`；对应 `渲染 DeploymentSpec 整数字段`、`渲染 DeploymentSpec selector 与 strategy`。
- [x] T13 `templates/api-resources/Core/_PodSpec.tpl`：`os` 字符串简写、`hostnameOverride`、`dnsPolicy`、`hostname`、`nodeName`、`preemptionPolicy`、`priorityClassName`、`restartPolicy`、`runtimeClassName`、`schedulerName`、`serviceAccountName`、`subdomain` 改为 `base.string.normalize` 解码后 trim；`activeDeadlineSeconds` 与 `terminationGracePeriodSeconds` 删除 `TYPES.POSITIVE_INT` 前置判断、`atoi` 与引号剥离，改用 `base.int` + `base.int.range 0`；对应 `字符串字段按 YAML 标量语义解码`、`渲染 PodSpec 整数字段`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart 加载真实 `templates/base/*.tpl` 与全部变更模板，渲染只提供 `selector` 的 Deployment，并覆盖带引号标量（含 `nodeName: "007"` 的零折叠）、首尾空白、多行标量与 `selector: {}`，预期与 `字符串字段按 YAML 标量语义解码` 及 `渲染 DeploymentSpec selector 与 strategy` 场景一致。
- [x] V2 同一 fixture 覆盖 `replicas: 3`、`replicas: 3.0`、`replicas: 0`、`minReadySeconds: 0`、`progressDeadlineSeconds: 0`、`revisionHistoryLimit: 0`、`activeDeadlineSeconds: 0`、`terminationGracePeriodSeconds: 0`、`replicas: 999999`、`replicas: 1000000` 以及四个整数字段全部省略的用例，预期零值语义、缺失不输出、整数形态与序列化上限边界符合 `渲染 DeploymentSpec 整数字段`、`渲染 PodSpec 整数字段`。
- [x] V3 同一 fixture 覆盖 `strategy: "RollingUpdate 25% 10%"`、`strategy: "RollingUpdate \"\" 10%"`、`strategy: "\"\""`、`strategy: null`、`type: "null"`，预期与 `渲染 DeploymentSpec selector 与 strategy`、`渲染 DeploymentStrategy type 字段` 场景一致。
- [x] V4 同一 fixture 覆盖 `nodeName: true`、`topologyKey: 5`、`conditionType: [a]`、`replicas: -1`、`replicas: "3"`、`activeDeadlineSeconds: 1.5`、`progressDeadlineSeconds: 2147483648`、`strategy: 5`、`selector: "null"`，预期全部中断渲染且失败消息前缀符合对应 Requirement。
- [x] V5 同一 fixture 复核 bool 字段、`maxSurge`、`maxUnavailable` 与两处 `weight` 的取值，预期接受范围与改造前一致，不发生未声明行为变化。
