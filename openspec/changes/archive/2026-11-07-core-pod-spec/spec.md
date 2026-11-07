---
updated_at: "2026-11-07T05:51:25Z"
---

# core.podSpec 规格

## Purpose

为 Pod 模板提供统一的 `PodSpec` 字段片段构造能力，使 `PodTemplateSpec` 及其上层工作负载资源复用同一条 PodSpec 渲染路径，并对输入形态、字段生效条件、枚举边界和互斥约束给出稳定的可观察契约。

## ADDED Requirements

### Requirement: 调用上下文与字段取值优先级

系统 MUST 以父级模板通过 `include` 透传的上下文 `.` 作为唯一调用上下文，MUST NOT 要求 `dict` 等额外包装。

系统 MUST 对每个已支持字段同时识别 `<字段名>Alias` 与 `<字段名>`，并在同一数据源内优先使用非空的 `<字段名>Alias`，别名缺失或为空时回退规范键。

系统 MUST NOT 为任何字段引入 `<字段名>Alias` 之外的短别名。

系统 MUST 只输出本规格列出的字段；MUST NOT 输出 `dnsConfig`、`enableServiceLinks`、`ephemeralContainers`、`overhead`、`priority`、`schedulingGates`、`serviceAccount` 等未列出的 PodSpec 字段。

#### Scenario: 别名优先于规范键

- **WHEN** 上下文同时包含 `dnsPolicyAlias: Default` 与 `dnsPolicy: ClusterFirst`
- **THEN** 输出为 `dnsPolicy: Default`

#### Scenario: 别名缺失时回退规范键

- **WHEN** 上下文只包含 `dnsPolicy: ClusterFirst`
- **THEN** 输出为 `dnsPolicy: ClusterFirst`

#### Scenario: 未列出的字段不进入输出

- **WHEN** 上下文包含 `enableServiceLinks: false`
- **THEN** 输出不包含 `enableServiceLinks`

### Requirement: 字段输出顺序

系统 MUST 按 Kubernetes API 文档标注的 PodSpec 字段顺序输出，顺序为：`activeDeadlineSeconds`、`affinity`、`automountServiceAccountToken`、`containers`、`dnsPolicy`、`hostAliases`、`hostIPC`、`hostNetwork`、`hostPID`、`hostUsers`、`hostname`、`hostnameOverride`、`imagePullSecrets`、`initContainers`、`nodeName`、`nodeSelector`、`os`、`preemptionPolicy`、`priorityClassName`、`readinessGates`、`resourceClaims`、`resources`、`restartPolicy`、`runtimeClassName`、`schedulerName`、`securityContext`、`serviceAccountName`、`setHostnameAsFQDN`、`shareProcessNamespace`、`subdomain`、`terminationGracePeriodSeconds`、`tolerations`、`topologySpreadConstraints`、`volumes`。

#### Scenario: 多字段同时生效

- **WHEN** 上下文中 `restartPolicy`、`dnsPolicy`、`serviceAccountName` 均有效
- **THEN** 输出顺序为 `dnsPolicy`、`restartPolicy`、`serviceAccountName`

### Requirement: 无枚举约束的字符串字段

`nodeName`、`priorityClassName`、`runtimeClassName`、`schedulerName`、`serviceAccountName`、`subdomain` MUST 在取值非空时渲染原字符串；为空或缺失时不渲染。

`priorityClassName` MUST NOT 施加枚举限制，任意非空取值均渲染。

#### Scenario: 任意 PriorityClass 名称

- **WHEN** `priorityClassName` 为 `high-priority`
- **THEN** 输出为 `priorityClassName: high-priority`

#### Scenario: 空字符串不渲染

- **WHEN** `subdomain` 为 `""`
- **THEN** 输出不包含 `subdomain`

#### Scenario: 字符串 false 属于有效取值

- **WHEN** `subdomain` 为字符串 `"false"`
- **THEN** 输出为 `subdomain: "false"`

### Requirement: 枚举字符串字段

`dnsPolicy` MUST 只接受 `ClusterFirstWithHostNet`、`ClusterFirst`、`Default`、`None`。

`preemptionPolicy` MUST 只接受 `Never`、`PreemptLowerPriority`。

`restartPolicy` MUST 只接受 `Always`、`Never`、`OnFailure`。

三个字段为空或缺失时不渲染；取值不在允许集合内时中断渲染并给出可定位的字段错误信息。

#### Scenario: 合法枚举渲染

- **WHEN** `dnsPolicy` 为 `ClusterFirstWithHostNet`
- **THEN** 输出为 `dnsPolicy: ClusterFirstWithHostNet`

#### Scenario: 越界枚举中断

- **WHEN** `restartPolicy` 为 `Sometimes`
- **THEN** 渲染中断，错误信息包含字段名 `restartPolicy`

### Requirement: 主机名字段校验

`hostname` MUST 在非空时按 RFC 1035 单段名称校验，校验失败时中断渲染。

`hostnameOverride` MUST 在非空时按项目既定 RFC 1123 单段名称语义校验，长度上限为 63 字符；该字符上限以项目既定校验能力为准，不额外实现 64 字符上限。

两个字段为空或缺失时不渲染。

#### Scenario: hostname 校验失败

- **WHEN** `hostname` 为 `Bad_Name`
- **THEN** 渲染中断

#### Scenario: hostnameOverride 超出 63 字符

- **WHEN** `hostnameOverride` 为 64 个合法小写字符
- **THEN** 渲染中断

### Requirement: 数值字段

`activeDeadlineSeconds` MUST 在取值缺失或为 `0` 时不渲染；MUST 只接受正整数，接受负数、非整数或非法字符串时中断渲染。

`terminationGracePeriodSeconds` MUST 在取值缺失时不渲染；MUST 接受非负整数，其中显式 `0` MUST 渲染为 `terminationGracePeriodSeconds: 0`；接受负数或非整数时中断渲染。

#### Scenario: activeDeadlineSeconds 为 0

- **WHEN** `activeDeadlineSeconds` 为 `0`
- **THEN** 输出不包含 `activeDeadlineSeconds`

#### Scenario: activeDeadlineSeconds 为负数

- **WHEN** `activeDeadlineSeconds` 为 `-1`
- **THEN** 渲染中断

#### Scenario: terminationGracePeriodSeconds 显式 0

- **WHEN** `terminationGracePeriodSeconds` 为 `0`
- **THEN** 输出为 `terminationGracePeriodSeconds: 0`

### Requirement: 布尔字段生效条件

`automountServiceAccountToken`、`hostIPC`、`hostNetwork`、`hostPID`、`setHostnameAsFQDN`、`shareProcessNamespace` MUST 只在取值为 `true` 时渲染；取值为空、缺失或 `false` 时不渲染。

`hostUsers` MUST 在取值为布尔 `true` 或 `false` 时均渲染；取值为空或缺失时不渲染。

所有布尔字段 MUST 只接受布尔类型或字面量字符串 `"true"` / `"false"`，其他取值中断渲染。

#### Scenario: 布尔 true 渲染

- **WHEN** `hostNetwork` 为 `true`
- **THEN** 输出为 `hostNetwork: true`

#### Scenario: 布尔 false 不渲染

- **WHEN** `hostIPC` 为 `false`
- **THEN** 输出不包含 `hostIPC`

#### Scenario: hostUsers 的 false 也渲染

- **WHEN** `hostUsers` 为 `false`
- **THEN** 输出为 `hostUsers: false`

### Requirement: nodeSelector 渲染

`nodeSelector` MUST 在取值非空时按对象渲染，取值 MUST 为 map 类型；为非 map 类型时中断渲染。

`nodeSelector` 为空或缺失时不渲染。

#### Scenario: nodeSelector 非空

- **WHEN** `nodeSelector` 为 `{disktype: ssd}`
- **THEN** 输出为 `nodeSelector: {disktype: ssd}`

#### Scenario: nodeSelector 为空

- **WHEN** `nodeSelector` 缺失或为空对象
- **THEN** 输出不包含 `nodeSelector`

#### Scenario: nodeSelector 类型非法

- **WHEN** `nodeSelector` 为字符串
- **THEN** 渲染中断

### Requirement: 字段互斥约束

系统 MUST 在 `hostPID` 与 `shareProcessNamespace` 同时为 `true` 时中断渲染。

系统 MUST 在 `hostnameOverride` 非空且 `hostNetwork` 为 `true` 时中断渲染。

系统 MUST 在 `hostnameOverride` 非空且 `setHostnameAsFQDN` 为 `true` 时中断渲染。

#### Scenario: hostPID 与 shareProcessNamespace 冲突

- **WHEN** `hostPID` 与 `shareProcessNamespace` 均为 `true`
- **THEN** 渲染中断

#### Scenario: hostnameOverride 与 hostNetwork 冲突

- **WHEN** `hostnameOverride` 非空且 `hostNetwork` 为 `true`
- **THEN** 渲染中断

#### Scenario: hostnameOverride 与 setHostnameAsFQDN 冲突

- **WHEN** `hostnameOverride` 非空且 `setHostnameAsFQDN` 为 `true`
- **THEN** 渲染中断

### Requirement: affinity 合并与委托

系统 MUST 把 `affinity` 自身字段与同级的 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 合并为同一个对象，同级字段 MUST 以对应同名键（`nodeAffinity`、`podAffinity`、`podAntiAffinity`）进入合并结果。

合并时 `affinity` 内已存在的同名键 MUST 保留，同级字段 MUST NOT 覆盖同名键。

系统 MUST NOT 识别 `affinity` 内的 `node`、`pod`、`podAnti` 短键，也 MUST NOT 允许这些短键与 `affinity` 同级生效。

合并结果为空时 MUST 不渲染 `affinity`；非空时 MUST 委托 `definitions.affinity` 渲染，并向其传入合并后的对象。

#### Scenario: 同级 nodeAffinity 合并

- **WHEN** `affinity` 包含 `podAntiAffinity`，同级 `nodeAffinity` 有效
- **THEN** 传给 `definitions.affinity` 的对象同时包含 `podAntiAffinity` 与 `nodeAffinity`

#### Scenario: affinity 优先

- **WHEN** `affinity` 内已有 `nodeAffinity`，同时存在同级 `nodeAffinity`
- **THEN** 合并结果中的 `nodeAffinity` 取 `affinity` 内的值

#### Scenario: 短键不生效

- **WHEN** `affinity` 内或同级只提供 `node`、`pod`、`podAnti`
- **THEN** 这些短键不参与合并，合并结果按其余有效内容渲染

#### Scenario: 合并结果为空

- **WHEN** `affinity` 与三个同级字段均缺失或为空
- **THEN** 输出不包含 `affinity`

### Requirement: containers 与 initContainers 委托

`containers` MUST 兼容数组与 map 两种输入形态；map 形态表示单个容器，其键均为 Container 定义的字段，清洗后按单元素数组处理。

每个容器 MUST 委托 `definitions.container` 渲染，向其传递的上下文 MUST 只由当前容器元素（键名 `containers`）、`os`、`Files`、`Values`、`Context` 组成；其中 `os` 透传用于容器 `securityContext`。

输出 MUST 为数组，并 MUST 去重、剔除空项。

`containers` 为必填：缺失、清洗后为空或最终数组为空时 MUST 中断渲染并报错。

`initContainers` MUST 与 `containers` 采用相同的取值、清洗、输入形态兼容、委托和上下文透传规则；唯一差异是可选性，为空或缺失时不渲染，MUST NOT 中断渲染。

#### Scenario: 数组形态

- **WHEN** `containers` 为包含两个容器对象的数组
- **THEN** 输出为两个元素的 `containers` 数组

#### Scenario: map 形态

- **WHEN** `containers` 为单个容器 map
- **THEN** 输出为单元素 `containers` 数组

#### Scenario: 容器上下文边界

- **WHEN** 渲染任一容器
- **THEN** `definitions.container` 收到的上下文只包含 `containers`、`os`、`Files`、`Values`、`Context` 五个键

#### Scenario: containers 缺失

- **WHEN** 上下文不包含 `containers`
- **THEN** 渲染中断并报错

#### Scenario: initContainers 为空

- **WHEN** `initContainers` 缺失或清洗后为空
- **THEN** 输出不包含 `initContainers`，渲染不中断

### Requirement: hostAliases 归一化与委托

`hostAliases` MUST 兼容字符串数组与原生结构数组。

字符串项 MUST 按 `<ip><分隔符><hostname><分隔符>[hostnameN]` 解析为 `ip`（string）与 `hostnames`（string array）；分隔符只识别空格与逗号。

归一化后的每一项 MUST 委托 `definitions.hostAlias` 渲染，传入的上下文 MUST 为包含 `ip` 与 `hostnames` 的 map。

输出 MUST 为数组，并 MUST 去重、剔除空项。

#### Scenario: 字符串项解析

- **WHEN** `hostAliases` 为 `["1.1.1.1 a.example.com,b.example.com"]`
- **THEN** 传给 `definitions.hostAlias` 的上下文为 `ip: 1.1.1.1` 与 `hostnames: [a.example.com, b.example.com]`

#### Scenario: 字符串项格式非法

- **WHEN** `hostAliases` 项无法按 `<ip><分隔符><hostname><分隔符>[hostnameN]` 解析出 `ip` 与至少一个 `hostname`
- **THEN** 渲染中断并报错

#### Scenario: 原生结构项

- **WHEN** `hostAliases` 项为包含 `ip` 与 `hostnames` 的 map
- **THEN** 该 map 直接作为 `definitions.hostAlias` 的上下文

### Requirement: 名称类数组字段归一化与委托

`imagePullSecrets` MUST 兼容字符串数组与原生结构数组；字符串项 MUST 归一化为包含 `name` 的 map，原生项按原结构透传；每项 MUST 委托 `definitions.localObjectReference` 渲染。

`os` MUST 兼容字符串与原生结构；字符串 MUST 归一化为包含 `name` 的 map，原生结构按原结构透传；结果 MUST 委托 `definitions.podOS` 渲染。

`readinessGates` MUST 兼容字符串数组与原生结构数组；字符串项 MUST 归一化为包含 `conditionType` 的 map，原生项按原结构透传；每项 MUST 委托 `definitions.podReadinessGate` 渲染。

`resourceClaims` MUST 兼容字符串数组与原生结构数组；字符串项 MUST 按 `<name><分隔符>[resourceClaimName]<分隔符>[resourceClaimTemplateName]` 解析为包含 `name`、`resourceClaimName`、`resourceClaimTemplateName` 的 map，分隔符只识别空格与逗号，缺省部分 MUST 不输出；每项 MUST 委托 `definitions.podResourceClaim` 渲染。

上述字段的输出 MUST 为数组（`os` 为单个对象），并 MUST 去重、剔除空项。

#### Scenario: imagePullSecrets 字符串项

- **WHEN** `imagePullSecrets` 为 `["secret-1", "secret-2"]`
- **THEN** 传给 `definitions.localObjectReference` 的上下文依次为 `name: secret-1`、`name: secret-2`

#### Scenario: os 字符串项

- **WHEN** `os` 为 `linux`
- **THEN** 输出为 `os: {name: linux}` 结构，`name` 由 `definitions.podOS` 渲染

#### Scenario: readinessGates 字符串项

- **WHEN** `readinessGates` 为 `["g1"]`
- **THEN** 传给 `definitions.podReadinessGate` 的上下文为 `conditionType: g1`

#### Scenario: resourceClaims 单段字符串项

- **WHEN** `resourceClaims` 为 `["claim-1"]`
- **THEN** 传给 `definitions.podResourceClaim` 的上下文只包含 `name: claim-1`

#### Scenario: resourceClaims 三段字符串项

- **WHEN** `resourceClaims` 为 `["claim-1,rc-1,tpl-1"]`
- **THEN** 传给 `definitions.podResourceClaim` 的上下文包含 `name: claim-1`、`resourceClaimName: rc-1`、`resourceClaimTemplateName: tpl-1`

### Requirement: resources 与 securityContext 委托

`resources` MUST 在非空时委托 `definitions.resourceRequirements` 渲染，传入的上下文 MUST 为包含 `claims`、`limits`、`requests` 的 map；为空或缺失时不渲染。

`securityContext` MUST 在非空时委托 `definitions.podSecurityContext` 渲染，传入的上下文 MUST 包含原生 `securityContext` 字段与 `os`；为空或缺失时不渲染。

#### Scenario: resources 非空

- **WHEN** `resources` 包含 `limits` 与 `requests`
- **THEN** `definitions.resourceRequirements` 收到的上下文包含 `limits` 与 `requests`

#### Scenario: securityContext 携带 os

- **WHEN** `securityContext` 非空且 `os` 为 `linux`
- **THEN** `definitions.podSecurityContext` 收到的上下文同时包含原生 `securityContext` 字段与 `os`

### Requirement: tolerations 与 topologySpreadConstraints 委托

`tolerations` MUST 接受原生结构数组，每个元素 MUST 委托 `definitions.toleration` 渲染，并以其自身作为上下文。

`topologySpreadConstraints` MUST 接受原生结构数组，每个元素 MUST 委托 `definitions.topologySpreadConstraint` 渲染，并以其自身作为上下文。

两个字段的输出 MUST 为数组，并 MUST 去重、剔除空项；为空或缺失时不渲染。

#### Scenario: tolerations 逐项委托

- **WHEN** `tolerations` 包含两个元素
- **THEN** `definitions.toleration` 被调用两次，每次上下文为对应元素

### Requirement: volumes 归一化与委托

`volumes` MUST 兼容字符串数组与原生结构数组。

原生结构项的归一化规则：字典第一层的非 `name` 键名作为 `volumeType`，其对应值作为 `volumeData`，`name` 键作为 `volumeName` 且 MUST NOT 进入 `volumeType` 或 `volumeData`。

原生结构项的每一项 MUST 有且仅有一个非 `name` 键；出现多个非 `name` 键时 MUST 中断渲染并报错。

字符串项 MUST 按 `^(cm|configMap|secret|pvc|persistentVolumeClaim|emptyDir|hostPath|nfs|image|fc|iscsi)(?:\s+(.*?))(?:\s+(.*?))?$` 解析（第 1 组不区分大小写）：第 1 组为 `volumeType`，第 2 组为 `volumeName`，第 3 组为 `volumeData`。

`volumeType` MUST 归一化为官方键名：`cm` 与 `configMap` → `configMap`，`secret` → `secret`，`pvc` 与 `persistentVolumeClaim` → `persistentVolumeClaim`，`emptyDir`、`hostPath`、`nfs`、`image`、`fc`、`iscsi` 保持同名。

每项 MUST 委托 `definitions.Volume` 渲染，传入的上下文 MUST 为包含 `volumeType`（string）、`volumeName`（string）、`volumeData`（string 或 map）的 map；`volumeName` MUST 作为子模板输出中的 `name`。

输出 MUST 为数组，并 MUST 去重、剔除空项。

#### Scenario: 原生项拆分

- **WHEN** `volumes` 项为 `{name: data, hostPath: {path: /var/lib/data}}`
- **THEN** 传给 `definitions.Volume` 的上下文为 `volumeType: hostPath`、`volumeName: data`、`volumeData: {path: /var/lib/data}`

#### Scenario: 原生项多个非 name 键

- **WHEN** `volumes` 项同时包含 `configMap` 与 `nfs`
- **THEN** 渲染中断并报错

#### Scenario: 字符串项

- **WHEN** `volumes` 为 `["cm,config-name"]`
- **THEN** 传给 `definitions.Volume` 的上下文为 `volumeType: configMap`、`volumeName: config-name`

#### Scenario: secret 归一化

- **WHEN** `volumes` 为 `["secret,secret-name"]`
- **THEN** 传给 `definitions.Volume` 的 `volumeType` 为 `secret`

#### Scenario: volumes 字符串项格式非法

- **WHEN** `volumes` 字符串项无法匹配规定正则
- **THEN** 渲染中断并报错

### Requirement: 委托输出保护与数组回收

系统 MUST 在委托子模板输出为空、无有效 YAML 或无法解析为有效结构时，把该元素或该字段视为无有效输出并省略，MUST NOT 把解析错误当作有效内容输出。

系统 MUST 对每个数组字段的最终结果去重并剔除空项。

系统 MUST NOT 通过省略掩盖 `containers` 的必填事实：`containers` 排除无效输出后为空时 MUST 中断渲染。

#### Scenario: 单个元素无有效输出

- **WHEN** `imagePullSecrets` 中的一个元素经委托后输出为空
- **THEN** 该元素被剔除，其余元素正常渲染

#### Scenario: 重复元素去重

- **WHEN** `imagePullSecrets` 为 `["secret-1", "secret-1"]`
- **THEN** 输出只包含一个元素

#### Scenario: containers 全部无效

- **WHEN** `containers` 的所有元素经委托后输出均为空
- **THEN** 渲染中断并报错

## 非目标

- 不实现 `definitions.affinity`、`definitions.container`、`definitions.hostAlias`、`definitions.localObjectReference`、`definitions.podOS`、`definitions.podReadinessGate`、`definitions.podResourceClaim`、`definitions.resourceRequirements`、`definitions.podSecurityContext`、`definitions.toleration`、`definitions.topologySpreadConstraint`、`definitions.Volume` 中任何一个子模板。
- 不处理和校验 `os` 与 `securityContext` 的字段互斥。
- 不实现 `dnsConfig`、`enableServiceLinks`、`ephemeralContainers`、`overhead`、`priority`、`schedulingGates`、`serviceAccount` 等未列出的 PodSpec 字段。
- 不处理 `resourceClaims` 中 `resourceClaimName` 与 `resourceClaimTemplateName` 的互斥与二选一校验。
- 不改造现有工作负载模板的既有调用方式。
