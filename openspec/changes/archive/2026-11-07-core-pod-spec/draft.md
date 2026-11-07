---
change-id: core-pod-spec
updated_at: "2026-11-06T10:02:53Z"
---

# 新增 core.podSpec 命名模板

## 目标

- 新增命名模板 `core.podSpec`，为 Pod 模板提供统一的 PodSpec 字段片段构造能力。

## 需求

### 通用

- 模板名称为 `core.podSpec`。
- 接收的数据是父级模板透传的上下文 `.`，不使用 `dict` 重新包装。
- 字段类型与说明以 Kubernetes API 官方文档为准；取值统一经 `base.get` 读取。
- 每个字段均允许 `base.get` 默认的 `<字段名>Alias` 别名，取值时由 `base.get` 隐式识别，本模板不额外实现别名逻辑。
- 长字段名不提供额外的短别名。
- 字符串枚举字段使用枚举校验，越界值中断渲染。
- 数组字段回收结果去重、去空。
- 数组字段支持对子结构模板的委托渲染，父模板负责取值、清洗与解析保护，子模板只消费归一化后的上下文。
- 本 change 只为下列子模板建立调用点，不创建其实现，也不创建占位 `define`。
- 输出字段顺序遵循官方文档标注的 API 字段顺序。
- 模板文件位于 `templates/api-resources/Core/_PodSpec.tpl`，命名空间维持 `core.*`。

### activeDeadlineSeconds

- `integer`，可选。
- 为空或 0 不渲染。
- 只接受正整数，非正整数中断渲染。

### affinity

- `Affinity`，可选，期望输入为 object。
- 委托子模板 `definitions.affinity`，向其传递处理后的 map。
- 同级的 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 需要合并到 `affinity` 内的同名键中。
- `affinity` 优先：`affinity` 内已有的同名键不被同级字段覆盖。
- `nodeAffinity`、`podAffinity`、`podAntiAffinity` 可以与 `affinity` 同级。
- 原生类型一律使用官方定义的键名，不识别 `node`、`pod`、`podAnti` 短键。

### automountServiceAccountToken

- `boolean`，可选。
- 为空或 `false` 不渲染，仅 `true` 渲染。

### containers

- `Container array`，必填，期望输入为 map 或 array。
- 委托子模板 `definitions.container`。
- 需要同时兼容 map 与 array 输入形态。
- map 输入形态表示单个容器，其键均为 `definitions.container`（Container）定义的字段，清洗后按单元素数组处理。
- 向子模板传递的上下文只能是 `containers`、`os`、`Files`、`Values`、`Context` 组成的 map，建议使用 `pick` 取值。
- 需在模板注释中说明 `os` 是 `securityContext` 需要用到的。
- 回收结果去重、去空。
- 必填字段：缺失或清洗后为空时中断渲染并报错。

### initContainers

- `Container array`，可选，期望输入为 map 或 array。
- 取值、清洗、map 与 array 兼容、子模板委托和向下传递上下文均与 `containers` 相同。
- 与 `containers` 的唯一差异是可选性：为空不渲染，不中断渲染。

### dnsPolicy

- `string`，可选。
- 为空不渲染。
- 枚举校验 `ClusterFirstWithHostNet`、`ClusterFirst`、`Default`、`None`。

### hostAliases

- `HostAlias array`，可选，期望输入为 string array 或原生类型。
- 委托子模板 `definitions.hostAlias`。
- 回收结果去重、去空。
- string array 输入形态为 `<ip><分隔符><hostname><分隔符>[hostnameN]`，其中 hostname 部分需要解析为 string array。
- 分隔符只使用空格与逗号，不做其他扩展。
- 向下传递的上下文为清洗后包含 `ip`（string）与 `hostnames`（string array）的 map。

### hostIPC

- `boolean`，可选。
- 为空或 `false` 不渲染。

### hostNetwork

- `boolean`，可选。
- 为空或 `false` 不渲染。

### hostPID

- `boolean`，可选。
- 为空或 `false` 不渲染。
- 与 `shareProcessNamespace` 互斥，不能同时为 `true`。

### hostUsers

- `boolean`，可选。
- 为空不渲染；有效布尔值（`true` / `false`）均渲染。

### hostname

- `string`，可选。
- 为空不渲染。
- 基于 RFC 1035 校验。

### hostnameOverride

- `string`，可选。
- 为空不渲染。
- 基于 `base.rfc` 的 `1123` 模式校验。
- 以 `base.rfc` 为准：只校验单段 DNS 标签且上限 63 字符，不额外实现官方文档的 64 字符上限；该 1 字符收束无实际影响。
- 指定时 `hostNetwork` 必须为 `false`。
- 与 `setHostnameAsFQDN` 互斥：指定时 `setHostnameAsFQDN` 必须为空或 `false`，否则中断渲染。

### imagePullSecrets

- `LocalObjectReference array`，可选，期望输入为 string array 或原生类型。
- 委托子模板 `definitions.localObjectReference`。
- 回收结果去重、去空。
- 向子模板传递的上下文为包含 `name` 字段的 map。

### nodeName

- `string`，可选。
- 为空不渲染。

### nodeSelector

- `object`，可选。
- 为空不渲染。

### os

- `PodOS`（object），可选，期望输入为 string 或原生类型。
- 委托子模板 `definitions.podOS`。
- string 输入形态为操作系统名称。
- 向子模板传递的上下文为包含 `name` 字段的 map。

### preemptionPolicy

- `string`，可选。
- 为空不渲染。
- 枚举校验 `Never`、`PreemptLowerPriority`。

### priorityClassName

- `string`，可选。
- 为空不渲染。
- 以官方文档为准，接受任意 PriorityClass 名称，不做枚举限制。

### readinessGates

- `PodReadinessGate array`，可选，期望输入为 string array 或原生类型。
- 委托子模板 `definitions.podReadinessGate`。
- 回收结果去重、去空。
- 向子模板传递的上下文为包含 `conditionType` 的 map。

### resourceClaims

- `PodResourceClaim array`，可选，期望输入为 string array 或原生类型。
- 委托子模板 `definitions.podResourceClaim`。
- 回收结果去重、去空。
- string array 输入形态为 `<name><分隔符>[resourceClaimName]<分隔符>[resourceClaimTemplateName]`。
- 分隔符只使用空格与逗号，不做其他扩展。
- 向子模板传递的上下文为包含 `name`、`resourceClaimName`、`resourceClaimTemplateName` 的 map。
- 本 change 不处理 `resourceClaimName` 与 `resourceClaimTemplateName` 的互斥及二选一问题，只清洗所需上下文。

### resources

- `ResourceRequirements`，可选，object。
- 为空不渲染。
- 委托子模板 `definitions.resourceRequirements`。
- 向子模板传递的上下文为包含 `claims`、`limits`、`requests` 的 map。

### restartPolicy

- `string`，可选。
- 为空不渲染。
- 枚举校验 `Always`、`Never`、`OnFailure`。

### runtimeClassName

- `string`，可选。
- 为空不渲染。

### schedulerName

- `string`，可选。
- 为空不渲染。

### securityContext

- `PodSecurityContext`，可选，原生类型（object）。
- 为空不渲染。
- 委托子模板 `definitions.podSecurityContext`。
- 向子模板传递的上下文为包含 `os` 及 `securityContext` 原生字段的内容。

### serviceAccountName

- `string`，可选。
- 为空不渲染。

### setHostnameAsFQDN

- `boolean`，可选。
- 为空或 `false` 不渲染。

### shareProcessNamespace

- `boolean`，可选。
- 为空或 `false` 不渲染。

### subdomain

- `string`，可选。
- 为空不渲染。

### terminationGracePeriodSeconds

- `integer`，可选。
- 为空不渲染；允许显式 0 值。
- 必须为非负整数。

### tolerations

- `Toleration array`，可选，原生类型。
- 回收结果去重、去空。
- 委托子模板 `definitions.toleration`。

### topologySpreadConstraints

- `TopologySpreadConstraint array`，可选，原生类型。
- 回收结果去重、去空。
- 委托子模板 `definitions.topologySpreadConstraint`。

### volumes

- `Volume array`，可选，期望输入为 string array 或原生类型。
- 回收结果去重、去空。
- 委托子模板 `definitions.Volume`，向其传递包含 `volumeType`、`volumeName`、`volumeData` 的 map；其中 `volumeType`、`volumeName` 为 string，`volumeData` 期望为 string 或 map，`volumeName` 在子模板中输出为 `name`。
- 原生类型输入也必须拆分为包含 `volumeType`、`volumeName`、`volumeData` 的 map 再向下传递。
- 原生类型输入的拆分规则：字典第一层的键名（如 `configMap`、`nfs`、`emptyDir`）作为 `volumeType`，对应值（通常为 map）作为 `volumeData`；`name` 是特殊键，作为 `volumeName`，不进入 `volumeType` 与 `volumeData`。
- 原生类型输入的每一项中，`name` 与非 `name` 键具备互斥性和唯一性：只能有一个 `name` 和一个非 `name` 键；出现多个非 `name` 键或无法确定唯一非 `name` 键时中断报错。
- string array 参考正则：`^(cm|configMap|secret|pvc|persistentVolumeClaim|emptyDir|hostPath|nfs|image|fc|iscsi)(?:\s+(.*?))(?:\s+(.*?))?$`，第 1 组不区分大小写。第 1 组指向 `volumeType`，第 2 组指向 `volumeName`，第 3 组指向 `volumeData`。
- `volumeType` 需要转换为官方文档中对应的键名后再向下传递。`volumeType` 与 `definitions.Volume` 中键的对应关系：
  - `cm` / `configMap` → `configMap`
  - `secret` → `secret`
  - `pvc` / `persistentVolumeClaim` → `persistentVolumeClaim`
  - `emptyDir` → `emptyDir`
  - `hostPath` → `hostPath`
  - `nfs` → `nfs`
  - `image` → `image`
  - `fc` → `fc`
  - `iscsi` → `iscsi`

## 期望输入格式

```text
containers:
  - name: xxx
    image: xxx
    ...

containers:
  name: xxx
  image: xxx
  ...
```

```text
hostAliases:
  - 1.1.1.1 a.example.com b.example.com
  - 1.1.1.2 a.example.com b.example.com
```

```text
imagePullSecrets:
  - secret-1
  - secret-2
```

```text
os: linux
```

```text
readinessGates:
  - xxx-1
  - xxx-2
```

```text
resourceClaims:
  - name-1 resourceClaimName-1 resourceClaimTemplateName-1
```

## 约束

- 只使用 Helm 内置函数、Go Template、Sprig 与 Chart 既有的 `base.*` 能力，不得臆造函数。
- 字段取值统一使用 `base.get`，不自行遍历 `.Context` / `.Values` / `.Values.global`。
- map 与 list 的读取和合并不得修改输入上下文、`.Values` 或共享集合。
- 委托子模板的返回值必须完成解析保护；解析错误不得当作有效输出。
- 占位子模板不创建 `define`，也不在本 change 建立其能力规格。

## 非目标

- 不实现本 change 中作为占位引用的任何 `definitions.*` 子模板。
- 不处理和校验 `os` 与 `securityContext` 的字段互斥，该约束交由子模板处理。
- 不实现 `core.podSpec` 未列出的 PodSpec 字段，例如 `dnsConfig`、`enableServiceLinks`、`ephemeralContainers`、`overhead`、`priority`、`schedulingGates`、`serviceAccount` 等。
- 不处理 `resourceClaims` 中 `resourceClaimName` 与 `resourceClaimTemplateName` 的互斥与二选一校验。
- 不改造现有工作负载模板的既有调用方式。

## 验收

- 所有已列出字段按各自生效条件渲染；未生效字段不输出。
- 枚举字段的越界值中断渲染，并给出可定位的字段错误信息。
- `<字段名>Alias` 别名在取值时被 `base.get` 隐式识别并生效。
- `affinity` 的同级 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 与 `affinity` 原生字段最终合并为同一 map 并传递给 `definitions.affinity`。
- `affinity` 优先：合并时 `affinity` 内已有的同名键不被同级字段覆盖。
- `hostnameOverride` 按 `base.rfc` 的 `1123` 模式校验，长度上限为 63 字符。
- `containers`、`initContainers` 的 map 与 array 两种输入形态均产生相同的数组输出，并只向子模板传递 `containers`、`os`、`Files`、`Values`、`Context` 组成的 map。
- `hostAliases`、`resourceClaims`、`volumes` 的 string array 形态被正确解析为对应子模板所需的 map 结构，且分隔符只识别空格与逗号。
- `volumes` 的 `volumeType` 被转换为官方文档中对应的键名，其中 `secret` 渲染为 `secret`。
- `volumes` 原生类型输入按第一层键名识别 `volumeType`、按 `name` 识别 `volumeName`、按对应值识别 `volumeData`。
- `volumes` 原生类型输入的单个项出现多个非 `name` 键或无法确定唯一非 `name` 键时中断报错。
- `containers` 缺失或清洗后为空时中断渲染并报错。
- 数组字段回收结果去重、去空。
- 互斥约束（`hostPID` 与 `shareProcessNamespace`、`hostnameOverride` 与 `hostNetwork`、`hostnameOverride` 与 `setHostnameAsFQDN`）被违反时中断渲染。

## 开放问题

- 当前无未决事项。
