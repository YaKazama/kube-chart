---
updated_at: "2026-11-21T13:31:03Z"
---

# SecurityContext 共享结构规格

## Purpose

提供可复用的 `definitions.securityContext` 模板，把带 `os` 的容器级 `securityContext` 输入渲染为 Kubernetes v1.36 `SecurityContext` 字段片段。

## ADDED Requirements

### Requirement: 渲染 SecurityContext 字段片段

输入上下文 MUST 为原生 map，字段与 `os` 控制键位于同一 map。

系统 MUST 按 Kubernetes `SecurityContext` 字段顺序输出 `allowPrivilegeEscalation`、`appArmorProfile`、`capabilities`、`privileged`、`procMount`、`readOnlyRootFilesystem`、`runAsGroup`、`runAsNonRoot`、`runAsUser`、`seLinuxOptions`、`seccompProfile`、`windowsOptions`。

系统 MUST 只输出存在、适用于当前 `os` 且归一化后生效的字段；没有任何生效字段时 MUST 返回空内容而不失败。

系统 MUST NOT 输出 `os`、`securityContext` 父键、`apiVersion` 或 `kind`。

标量字段取值 MUST 去除首尾空白后用于判空、校验与输出。

integer 字段 MUST 接受显式 `0`，`0` MUST NOT 被当作未设置；boolean 字段 MUST 接受显式 `false`。

输入中除上述字段与 `os` 以外的键 MUST 静默忽略。

#### Scenario: linux 可渲染字段

- **WHEN** 输入包含 `os.name: linux` 以及 `allowPrivilegeEscalation`、`appArmorProfile`、`privileged`、`procMount`、`readOnlyRootFilesystem`、`runAsGroup`、`runAsNonRoot`、`runAsUser`、`seLinuxOptions`、`seccompProfile` 的有效值
- **THEN** 输出按官方字段顺序包含这些字段，且不包含 `windowsOptions`、`os` 与 `securityContext`

#### Scenario: 完整 windows 输入

- **WHEN** 输入包含 `os.name: windows`、`windowsOptions: {runAsUserName: ContainerUser}` 与 `runAsNonRoot: true`
- **THEN** 输出只包含 `runAsNonRoot` 与 `windowsOptions`

#### Scenario: 无有效字段

- **WHEN** 输入只包含 `os.name: linux`
- **THEN** 输出为空内容且渲染成功

#### Scenario: 整数字段显式 0

- **WHEN** 输入包含 `os.name: linux` 与 `runAsGroup: 0`
- **THEN** 输出包含 `runAsGroup: 0`

#### Scenario: 布尔字段显式 false

- **WHEN** 输入包含 `allowPrivilegeEscalation: false`
- **THEN** 输出包含 `allowPrivilegeEscalation: false`

#### Scenario: 忽略范围外键

- **WHEN** 输入包含 `os.name: linux`、`privileged: true` 与范围外的键 `foo`
- **THEN** 输出只包含 `privileged: true`

#### Scenario: 标量首尾空白

- **WHEN** 输入包含 `os.name: linux` 与 `procMount: " Default "`
- **THEN** 输出为 `procMount: Default`

### Requirement: 按 os 校验字段适用性

系统 MUST 把下列情况按 `linux` 处理：`os` 缺省、从 `os` 中取不到 `name`、`os.name` 无法归一化为 string，以及 `os.name` 归一化后既不是 `linux` 也不是 `windows`。

系统 MUST 在比较前把 `os.name` 转小写。

`runAsNonRoot` MUST 同时适用于 `linux` 与 `windows`。

`os` 为 `windows` 时，系统 MUST 拒绝除 `windowsOptions` 与 `runAsNonRoot` 以外的字段；按 `linux` 处理时，系统 MUST 拒绝 `windowsOptions`。

适用性判定 MUST 基于字段是否存在且不为 `null`，MUST NOT 依赖取值真假：空 map、空 array、空字符串与整数 `0` MUST 视为存在；字段缺失或值为 `null` MUST 视为不存在。

被拒绝字段 MUST 中断渲染，失败信息 MUST 同时包含字段名与当前 `os`。

适用性校验 MUST 在任何字段输出前完成。

#### Scenario: windows 下使用 linux 专属字段

- **WHEN** 输入包含 `os.name: windows` 与 `privileged`
- **THEN** 渲染中断，失败信息包含 `privileged` 与 `windows`

#### Scenario: 大写 os 名称

- **WHEN** 输入包含 `os.name: Windows` 与 `windowsOptions: {runAsUserName: ContainerUser}`
- **THEN** `os` 归一化为 `windows`，`windowsOptions` 正常渲染

#### Scenario: os 缺省时拒绝 windowsOptions

- **WHEN** 输入不包含 `os` 但包含 `windowsOptions`
- **THEN** 渲染中断，失败信息包含 `windowsOptions` 与 `linux`

#### Scenario: 未知 os 名称按 linux 处理

- **WHEN** 输入包含 `os.name: darwin` 与 `allowPrivilegeEscalation: true`
- **THEN** `allowPrivilegeEscalation` 正常渲染，不因 `os` 非法而失败

#### Scenario: runAsNonRoot 跨 os 生效

- **WHEN** 输入包含 `os.name: windows` 与 `runAsNonRoot: true`
- **THEN** 输出包含 `runAsNonRoot: true`

#### Scenario: 假值形式的不适用字段

- **WHEN** 输入包含 `os.name: windows` 与 `seLinuxOptions: {}`
- **THEN** 渲染中断，失败信息包含 `seLinuxOptions` 与 `windows`

#### Scenario: 整数 0 形式的不适用字段

- **WHEN** 输入包含 `os.name: windows` 与 `runAsUser: 0`
- **THEN** 渲染中断，失败信息包含 `runAsUser` 与 `windows`

### Requirement: 委托已实现的结构字段

系统 MUST 以 map 作为上下文，把 `appArmorProfile` 委托 `definitions.appArmorProfile`、`seLinuxOptions` 委托 `definitions.seLinuxOptions`、`seccompProfile` 委托 `definitions.seccompProfile`、`windowsOptions` 委托 `definitions.windowsSecurityContextOptions`。

四个字段的输入 MUST 是 map；不是 map 时 MUST 中断渲染。

输入为空 map 时系统 MUST NOT 调用对应子模板，也 MUST NOT 输出该字段。

子模板返回空内容时系统 MUST NOT 输出该字段；子模板返回不可解析内容时系统 MUST 中断渲染。

#### Scenario: 委托成功

- **WHEN** 输入包含 `os.name: linux` 与 `seLinuxOptions: {level: s0}`
- **THEN** 输出包含 `seLinuxOptions`，其内容来自 `definitions.seLinuxOptions` 的渲染结果

#### Scenario: 空结构不输出

- **WHEN** 输入包含 `os.name: linux` 与 `seccompProfile: {}`
- **THEN** 渲染成功且输出不包含 `seccompProfile`

#### Scenario: 子模板结果为空

- **WHEN** 输入包含 `os.name: linux` 与 `seLinuxOptions: {foo: bar}`
- **THEN** 渲染成功且输出不包含 `seLinuxOptions`

#### Scenario: 结构输入类型非法

- **WHEN** 输入包含 `os.name: linux` 与 `seccompProfile: RuntimeDefault`
- **THEN** 渲染中断，失败信息包含 `seccompProfile` 与 `definitions.securityContext`

### Requirement: capabilities 占位委托

`capabilities` MUST 作为 map 委托 `definitions.capabilities`。

`definitions.capabilities` 不在本 change 实现；本 change MUST NOT 创建该命名模板。

输入为空 map 时系统 MUST NOT 调用该子模板，也 MUST NOT 输出 `capabilities`。

输入不是 map 时 MUST 中断渲染。

输入为非空 map 时，系统 MUST 调用当前不存在的 `definitions.capabilities`，渲染 MUST 中断。

#### Scenario: 空 capabilities 跳过

- **WHEN** 输入包含 `os.name: linux` 与 `capabilities: {}`
- **THEN** 渲染成功且输出不包含 `capabilities`

#### Scenario: 非空 capabilities 中断

- **WHEN** 输入包含 `os.name: linux` 与 `capabilities: {add: [NET_ADMIN]}`
- **THEN** 渲染中断

#### Scenario: capabilities 类型非法

- **WHEN** 输入包含 `os.name: linux` 与 `capabilities: NET_ADMIN`
- **THEN** 渲染中断

### Requirement: 枚举与类型校验

`procMount` MUST 只接受 string，取值 MUST 为 `Default` 或 `Unmasked`；不是 string 或不在枚举内 MUST 中断渲染，且错误信息 MUST 给出合法取值。

`allowPrivilegeEscalation`、`privileged`、`readOnlyRootFilesystem`、`runAsNonRoot` MUST 只接受布尔值或 `"true"`、`"false"` 字面量；不满足时 MUST 中断渲染。

`runAsGroup`、`runAsUser` MUST 只接受可归一化为 integer 的输入；不满足时 MUST 中断渲染。

#### Scenario: 合法 procMount

- **WHEN** 输入包含 `os.name: linux` 与 `procMount: Unmasked`
- **THEN** 输出包含 `procMount: Unmasked`

#### Scenario: 非法 procMount 枚举

- **WHEN** 输入包含 `os.name: linux` 与 `procMount: Unconfined`
- **THEN** 渲染中断，失败信息包含 `procMount`、`Default` 与 `Unmasked`

#### Scenario: procMount 类型非法

- **WHEN** 输入包含 `os.name: linux` 与 `procMount: true`
- **THEN** 渲染中断

#### Scenario: 布尔字符串字面量

- **WHEN** 输入包含 `os.name: linux` 与 `privileged: "false"`
- **THEN** 输出包含 `privileged: false`

#### Scenario: 布尔值非法

- **WHEN** 输入包含 `os.name: linux` 与 `readOnlyRootFilesystem: "yes"`
- **THEN** 渲染中断

#### Scenario: 整数字段类型非法

- **WHEN** 输入包含 `os.name: linux` 与 `runAsUser: abc`
- **THEN** 渲染中断

## 非目标

- 不实现 `definitions.capabilities` 子模板。
- 不实现 `SecurityContext` 以外的 Kubernetes 安全上下文结构或字段。
- 不校验容器运行时或节点是否支持某个安全配置。
