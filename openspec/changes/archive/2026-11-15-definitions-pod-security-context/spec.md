---
updated_at: "2026-11-15T14:35:04Z"
---

# PodSecurityContext 共享结构规格

## Purpose

提供可复用的 `definitions.podSecurityContext` 模板，把带 `os` 的 Pod 级安全上下文输入渲染为 Kubernetes v1.36 `PodSecurityContext` 字段片段。

## ADDED Requirements

### Requirement: 渲染 PodSecurityContext 字段片段

系统 MUST 按 Kubernetes `PodSecurityContext` 字段顺序输出 `appArmorProfile`、`fsGroup`、`fsGroupChangePolicy`、`runAsGroup`、`runAsNonRoot`、`runAsUser`、`seLinuxChangePolicy`、`seLinuxOptions`、`seccompProfile`、`supplementalGroups`、`supplementalGroupsPolicy`、`sysctls`、`windowsOptions`。

系统 MUST 只在字段存在且适用于当前 `os` 时输出该字段；没有任何可输出字段时 MUST 返回空内容而不失败。

系统 MUST NOT 输出 `os`。

integer 字段 MUST 接受显式 `0`，`0` MUST NOT 被当作未设置；boolean 字段 MUST 接受显式 `false`。

输入中除上述字段与 `os` 以外的键 MUST 静默忽略。

#### Scenario: 完整 linux 输入

- **WHEN** 输入包含 `os.name: linux` 以及全部 linux 适用字段的有效值
- **THEN** 输出按字段顺序包含 `appArmorProfile`、`fsGroup`、`fsGroupChangePolicy`、`runAsGroup`、`runAsNonRoot`、`runAsUser`、`seLinuxChangePolicy`、`seLinuxOptions`、`seccompProfile`、`supplementalGroups`、`supplementalGroupsPolicy`、`sysctls`，且不包含 `windowsOptions` 与 `os`

#### Scenario: 完整 windows 输入

- **WHEN** 输入包含 `os.name: windows`、`windowsOptions` 与 `runAsNonRoot`
- **THEN** 输出只包含 `runAsNonRoot` 与 `windowsOptions`

#### Scenario: 无有效字段

- **WHEN** 输入只包含 `os.name: linux`
- **THEN** 输出为空内容且渲染成功

#### Scenario: 整数字段显式 0

- **WHEN** 输入包含 `os.name: linux` 与 `fsGroup: 0`
- **THEN** 输出包含 `fsGroup: 0`

#### Scenario: 布尔字段显式 false

- **WHEN** 输入包含 `runAsNonRoot: false`
- **THEN** 输出包含 `runAsNonRoot: false`

#### Scenario: 忽略范围外键

- **WHEN** 输入包含 `os.name: linux`、`fsGroup: 1000` 与范围外的键 `foo`
- **THEN** 输出只包含 `fsGroup: 1000`

### Requirement: 按 os 校验字段适用性

系统 MUST 把下列情况按 `linux` 处理：`os` 缺省、从 `os` 中取不到 `name`、`os.name` 无法归一化为 string，以及 `os.name` 归一化后既不是 `linux` 也不是 `windows`。

系统 MUST 在比较前把 `os.name` 转小写。

`runAsNonRoot` MUST 同时适用于 `linux` 与 `windows`。

`os` 为 `windows` 时，系统 MUST 拒绝除 `windowsOptions` 与 `runAsNonRoot` 以外的字段；按 `linux` 处理时，系统 MUST 拒绝 `windowsOptions`。

适用性判定 MUST 基于字段是否存在且不为 `null`，MUST NOT 依赖取值真假：空 map、空 array、空字符串与整数 `0` MUST 视为存在；字段缺失或值为 `null` MUST 视为不存在。

被拒绝字段 MUST 中断渲染，失败信息 MUST 同时包含字段名与当前 `os`。

适用性校验 MUST 在任何字段输出前完成。

#### Scenario: windows 下使用 linux 专属字段

- **WHEN** 输入包含 `os.name: windows` 与 `sysctls`
- **THEN** 渲染中断，失败信息包含 `sysctls` 与 `windows`

#### Scenario: 大写 os 名称

- **WHEN** 输入包含 `os.name: Windows` 与 `windowsOptions`
- **THEN** `os` 归一化为 `windows`，`windowsOptions` 正常渲染

#### Scenario: os 缺省时拒绝 windowsOptions

- **WHEN** 输入不包含 `os` 但包含 `windowsOptions`
- **THEN** 渲染中断，失败信息包含 `windowsOptions` 与 `linux`

#### Scenario: 未知 os 名称按 linux 处理

- **WHEN** 输入包含 `os.name: darwin` 与 `fsGroup: 1000`
- **THEN** `fsGroup` 正常渲染，不因 `os` 非法而失败

#### Scenario: runAsNonRoot 跨 os 生效

- **WHEN** 输入包含 `os.name: windows` 与 `runAsNonRoot: true`
- **THEN** 输出包含 `runAsNonRoot: true`

#### Scenario: 假值形式的不适用字段

- **WHEN** 输入包含 `os.name: windows` 与 `seLinuxOptions: {}`
- **THEN** 渲染中断，失败信息包含 `seLinuxOptions` 与 `windows`

#### Scenario: 整数 0 形式的不适用字段

- **WHEN** 输入包含 `os.name: windows` 与 `runAsUser: 0`
- **THEN** 渲染中断，失败信息包含 `runAsUser` 与 `windows`

### Requirement: 委托结构字段

系统 MUST 以 map 作为上下文，把 `appArmorProfile` 委托 `definitions.appArmorProfile`、`seLinuxOptions` 委托 `definitions.seLinuxOptions`、`seccompProfile` 委托 `definitions.seccompProfile`、`windowsOptions` 委托 `definitions.windowsSecurityContextOptions`。

四个字段的输入 MUST 是 map；不是 map 时 MUST 中断渲染。

输入为空 map 时系统 MUST NOT 调用对应子模板，也 MUST NOT 输出该字段。

子模板返回空内容时系统 MUST NOT 输出该字段；子模板返回不可解析内容时系统 MUST 中断渲染。

#### Scenario: 委托成功

- **WHEN** 输入包含 `os.name: linux` 与 `seLinuxOptions: {level: s0}`
- **THEN** 输出包含 `seLinuxOptions`，其内容来自 `definitions.seLinuxOptions` 的渲染结果

#### Scenario: 空结构不输出

- **WHEN** 输入包含 `os.name: linux` 与 `seLinuxOptions: {}`
- **THEN** 渲染成功且输出不包含 `seLinuxOptions`

#### Scenario: 结构输入类型非法

- **WHEN** 输入包含 `os.name: linux` 与 `seccompProfile: RuntimeDefault`
- **THEN** 渲染中断，失败信息包含 `seccompProfile` 与 `definitions.podSecurityContext`

### Requirement: sysctls 清洗与委托

系统 MUST 逐条处理 `sysctls`；条目不是 map 时 MUST 中断渲染。

条目 MUST 只读取 `name` 与 `value`，其他键 MUST 忽略。

`name` 与 `value` MUST 归一化为 string 并 `trim`：缺失或 `null` MUST 视为空字符串；值为 map 或 array 时 MUST 中断渲染。

`name` 或 `value` 归一化后为空字符串的条目 MUST 被移除。

剩余条目 MUST 投影为只包含 `name` 与 `value` 的 map，并按完整条目去重且保留首次出现顺序；同名不同值的条目 MUST 全部保留。

清洗后没有剩余条目时系统 MUST NOT 输出 `sysctls`。

系统 MUST 逐条以 map 作为上下文委托 `definitions.sysctl`，并回收非空结果；清洗结果非空但回收结果为空时 MUST NOT 输出 `sysctls`。

#### Scenario: 去重与去空

- **WHEN** 输入 `sysctls` 为 `[{name: a, value: "1"}, {name: a, value: "1"}, {name: b, value: ""}, {name: "", value: "2"}]`
- **THEN** 只保留一条 `{name: a, value: "1"}` 并输出

#### Scenario: 同名不同值保留

- **WHEN** 输入 `sysctls` 为 `[{name: a, value: "1"}, {name: a, value: "2"}]`
- **THEN** 两条条目都进入输出，顺序与输入一致

#### Scenario: value 为字符串 0

- **WHEN** 输入 `sysctls` 为 `[{name: net.ipv4.ip_forward, value: "0"}]`
- **THEN** 该条目保留并输出

#### Scenario: 清洗后为空

- **WHEN** 输入 `sysctls` 为 `[{name: a, value: ""}]`
- **THEN** 渲染成功且输出不包含 `sysctls`

#### Scenario: 条目类型非法

- **WHEN** 输入 `sysctls` 为 `[a]`
- **THEN** 渲染中断，失败信息包含 `sysctls`

### Requirement: supplementalGroups 清洗

系统 MUST 按输入顺序处理 `supplementalGroups` 元素。

`null` 元素与空字符串元素 MUST 被移除。

其余元素 MUST 归一化为 integer；无法归一化为 integer 的元素 MUST 中断渲染。

清洗结果 MUST 去重并保留首次出现顺序；整数 `0` MUST 保留。

清洗后没有剩余元素时系统 MUST NOT 输出 `supplementalGroups`。

#### Scenario: 去重与去空

- **WHEN** 输入 `supplementalGroups` 为 `[1000, 0, 1000, "", null, 1001]`
- **THEN** 输出为 `[1000, 0, 1001]`

#### Scenario: 非法元素

- **WHEN** 输入 `supplementalGroups` 为 `[1000, abc]`
- **THEN** 渲染中断

#### Scenario: 清洗后为空

- **WHEN** 输入 `supplementalGroups` 为 `["", null]`
- **THEN** 渲染成功且输出不包含 `supplementalGroups`

### Requirement: 枚举与类型校验

系统 MUST 校验 `fsGroupChangePolicy` 的取值为 `Always` 或 `OnRootMismatch`，`seLinuxChangePolicy` 的取值为 `MountOption` 或 `Recursive`，`supplementalGroupsPolicy` 的取值为 `Merge` 或 `Strict`。

枚举校验 MUST 只在对应字段存在时执行；非法取值 MUST 中断渲染并给出合法范围。

`fsGroup`、`runAsGroup`、`runAsUser` MUST 只接受整数；`runAsNonRoot` MUST 只接受布尔值或 `true`、`false` 字面量；不满足时 MUST 中断渲染。

#### Scenario: 合法枚举

- **WHEN** 输入包含 `fsGroupChangePolicy: OnRootMismatch` 与 `os.name: linux`
- **THEN** 输出包含 `fsGroupChangePolicy: OnRootMismatch`

#### Scenario: 非法枚举

- **WHEN** 输入包含 `supplementalGroupsPolicy: MergeAll` 与 `os.name: linux`
- **THEN** 渲染中断，失败信息包含 `supplementalGroupsPolicy`、`Merge` 与 `Strict`

#### Scenario: 字段缺省时跳过枚举校验

- **WHEN** 输入只包含 `os.name: linux` 与 `fsGroup: 1000`
- **THEN** 渲染成功，不因枚举字段缺省而失败

#### Scenario: 整数字段类型非法

- **WHEN** 输入包含 `fsGroup: abc` 与 `os.name: linux`
- **THEN** 渲染中断

## 非目标

- 不实现 `definitions.appArmorProfile`、`definitions.seLinuxOptions`、`definitions.seccompProfile`、`definitions.sysctl`、`definitions.windowsSecurityContextOptions` 中的任何一个子模板。
- 不渲染“期望输入格式”所列字段与 `os` 控制键以外的内容。
