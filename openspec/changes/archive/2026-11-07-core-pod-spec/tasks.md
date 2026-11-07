# core.podSpec 任务

## 实施

- [x] T1 `templates/base/_env.tpl`：在 `define "base.env"` 的 `SPLIT` 下新增 `SPACE_COMMA` 常量，在 `K8S` 下新增 `VOLUME.SHORT` 常量；既有常量行不得修改；对应 `Decision: 字符串简写解析`。
- [x] T2 `templates/api-resources/Core/_PodSpec.tpl`：新建文件并定义 `core.podSpec`，写入模板注释（含字段顺序、`os` 用途、委托与必填边界说明）并按官方顺序组织字段渲染骨架；对应 `Decision: 目标文件与模板命名`、`Decision: 输出顺序与字段渲染`。
- [x] T3 `templates/api-resources/Core/_PodSpec.tpl`：在 `core.podSpec` 内实现字符串字段取值（`base.get` 默认别名）、无枚举字段渲染、`nodeSelector` 的 map 渲染与 `dnsPolicy`、`preemptionPolicy`、`restartPolicy` 的枚举渲染；对应 `Decision: 字段取值与别名`、`Decision: 枚举校验`、`Decision: 输出顺序与字段渲染`。
- [x] T4 `templates/api-resources/Core/_PodSpec.tpl`：在 `core.podSpec` 内实现 `hostname`、`hostnameOverride` 的 `base.rfc` 校验，以及 `activeDeadlineSeconds`、`terminationGracePeriodSeconds` 的正整数/非负整数渲染；对应 `Decision: 主机名字段校验`、`Decision: activeDeadlineSeconds 生效判断`、`Decision: terminationGracePeriodSeconds 生效判断`。
- [x] T5 `templates/api-resources/Core/_PodSpec.tpl`：在 `core.podSpec` 内实现布尔字段生效条件（六个仅 `true` 渲染的字段与 `hostUsers` 的差异）与三组互斥校验；对应 `Decision: 仅 true 渲染的布尔字段生效判断`、`Decision: hostUsers 生效判断`、`Decision: 互斥校验`。
- [x] T6 `templates/api-resources/Core/_PodSpec.tpl`：在 `core.podSpec` 内实现 `affinity` 的 `mustDeepCopy` + `mustMerge` 合并与 `definitions.affinity` 委托；对应 `Decision: affinity 合并`。
- [x] T7 `templates/api-resources/Core/_PodSpec.tpl`：在 `core.podSpec` 内实现 `containers`、`initContainers` 的 `fromYamlArray` 优先归一化、`fromYaml` 单元素包装、共用 `pick` 白名单上下文构造、`mustMerge` 上下文合并、`definitions.container` 委托与 `containers` 必填失败；对应 `Decision: containers 输入形态归一化`。
- [x] T8 `templates/api-resources/Core/_PodSpec.tpl`：在 `core.podSpec` 内实现 `hostAliases`、`imagePullSecrets`、`os`、`readinessGates`、`resourceClaims` 的字符串简写解析、归一化、去重与对应子模板委托；字符串简写分隔使用 `SPLIT.SPACE_COMMA`；对应 `Decision: 字符串简写解析`。
- [x] T9 `templates/api-resources/Core/_PodSpec.tpl`：在 `core.podSpec` 内实现 `volumes` 的原生项拆分、非 `name` 键唯一性校验、字符串项三组捕获与 `volumeType` 官方键名映射，并委托 `definitions.Volume`；字符串项使用 `K8S.VOLUME.SHORT`；对应 `Decision: volumes 原生项拆分与唯一性`、`Decision: 字符串简写解析`。
- [x] T10 `templates/api-resources/Core/_PodSpec.tpl`：在 `core.podSpec` 内实现 `resources`、`securityContext`、`tolerations`、`topologySpreadConstraints` 的取键白名单与子模板委托，并统一完成 `fromYaml`/`fromYamlArray` + `base.isFromYamlError`/`base.isFromYamlArrayError` 解析保护、`mustUniq` 去重与 `mustWithout` 去空；对应 `Decision: 逐项委托类字段的上下文构造`、`Decision: 委托输出解析保护与数组回收`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：加载真实 `templates/base/_env.tpl`，验证 `SPLIT.SPACE_COMMA` 与 `K8S.VOLUME.SHORT` 按 design 记录的运行时表达式生效，并覆盖既有常量未被破坏。
- [x] V2 `/tmp/` 最小 application Chart（`definitions.*` 全部为同名 fixture）：`containers` 缺失与 `containers` 为空数组两种输入均渲染中断并报错。
- [x] V3 `/tmp/` 最小 application Chart（fixture）：`restartPolicy: Sometimes`、`activeDeadlineSeconds: -1`、`nodeSelector` 为非 map 类型分别中断，`terminationGracePeriodSeconds: 0` 正常输出 `0`。
- [x] V4 `/tmp/` 最小 application Chart（fixture）：`hostPID` + `shareProcessNamespace`、`hostnameOverride` + `hostNetwork`、`hostnameOverride` + `setHostnameAsFQDN` 三组冲突均中断。
- [x] V5 `/tmp/` 最小 application Chart（fixture）：同一容器分别以数组与 map 提供，两次渲染结果一致；fixture 输出收到的上下文验证只含 `containers`、`os`、`Files`、`Values`、`Context`。
- [x] V6 `/tmp/` 最小 application Chart（fixture）：同时提供 `affinity.nodeAffinity` 与同级 `nodeAffinity`，验证合并结果取 `affinity` 内的值；只提供短键时不参与合并。
- [x] V7 `/tmp/` 最小 application Chart（fixture）：`volumes` 原生项、多非 `name` 键项（中断）、无法匹配正则的字符串项（中断）、字符串简写项、`secret` 项分别验证拆分结果与 `volumeType` 映射。
- [x] V8 `/tmp/` 最小 application Chart（fixture）：字符串简写解析验证 `hostAliases`、`resourceClaims` 的空格与逗号混合分隔、多余分隔符、缺省字段省略与无法解析时的中断，以及 `imagePullSecrets`、`readinessGates`、`os` 的归一化结果。
- [x] V9 `/tmp/` 最小 application Chart（fixture）：fixture 返回空内容与非法 YAML 时元素被剔除，重复 `imagePullSecrets` 去重后只剩一个元素。
