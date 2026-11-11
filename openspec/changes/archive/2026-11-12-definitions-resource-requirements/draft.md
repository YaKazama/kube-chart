---
change-id: definitions-resource-requirements
updated_at: "2026-11-11T16:07:18Z"
---

# 新增 definitions.resourceRequirements 模板

## 目标

- 新增命名模板 `definitions.resourceRequirements`，渲染 Kubernetes `ResourceRequirements` 片段。
- 让 `core.podSpec` 的 `resources` 直接透传上下文，不再用 `pick` 截取 `claims`、`limits`、`requests`，以规避遗漏 `*Alias`。

## 需求

- `claims`、`limits`、`requests` 均为可选。
- `limits` 和 `requests` 均为 object 类型；抽象 string 形式按 `期望输入格式` 段的位置顺序解析。
- `hugepages-size` 的值替换键 `hugepages-<size>` 中的 `<size>`，`hugepages-max` 作为该键的值。
- `hugepages-size` 与 `hugepages-max` 必须使用相同单位，如均为 `Ki`、`Mi` 或 `Gi`；单位不同时中断渲染。
- `hugepages-size` 与 `hugepages-max` 校验时统一换算为字节数，渲染时各自保持原样。
- `hugepages-size` 与 `hugepages-max` 为倍数关系且 `hugepages-max` 更大，即 `hugepages-max / hugepages-size` 是正整数且余 0；不满足时中断渲染。
- `hugepages` 处理逻辑必须显式注释说明：使用 `cat /proc/meminfo | grep -i huge` 查看宿主机的 `Hugepagesize` 与 `HugePages_Total`，据此决定 `size` 与 `max` 的值。
- `cpu` 接受小数（如 `0.5`），需转换为 `500m`；1 cpu = 1000m cpu。
- `cpu` 最多 3 位小数，超出时中断渲染；毫核只能是以 `m` 结尾的正整数，`1.5m` 不合法。
- `cpu` 换算后小于 `1m` 且不为 0 时中断渲染；`cpu: 0` 视为未设置，不渲染该键。
- `memory` 与 `ephemeral-storage` 的 0 值同样视为未设置，不渲染对应键。
- 占位标记 `""` 与 `''` 等价，两者均表示该位置未设置；用户可使用任一种 YAML 空字符串写法。
- `limits` 和 `requests` 渲染时使用公共模板 `base.quantity`；`cpu` 精度与毫核校验在 `base.quantity` 之外额外执行。
- `limits` 和 `requests` 只接受 `cpu`、`memory`、`ephemeral-storage`、`hugepages-<size>`；其他键（含扩展资源键）直接丢弃，不参与渲染也不报错。
- `_kind` 为 `PodSpec` 时资源键进一步收窄为 `cpu`、`memory`、`hugepages-<size>`；`ephemeral-storage` 与其他键静默丢弃，不参与渲染也不报错。
- `claims` 为 ResourceClaim 数组，接受 string array 或原生 array。
- string array 形式的 `claims` 每项为 `<name> [request]`，分隔符为空格和逗号，需先处理为 map 再向子模板传递。
- `claims` 委托子模板 `definitions.resourceClaim`，子模板上下文为 map。
- `claims` 逐项回收委托结果，结果全部为空或无效时视为空集合，不输出 `claims` 字段。
- `definitions.resourceClaim` 不在本 change 范围内：本 change 只在 `definitions.resourceRequirements` 内保留该子模板调用，不创建其实现。
- 父级 `core.podSpec` 在 `resources` 处向本模板传递时追加 `_kind="PodSpec"`，只写入传给本模板的子上下文，不修改父级上下文。
- `_kind` 为 `PodSpec` 时 `claims` 静默忽略，不处理该字段；`_kind` 缺省时保留容器允许 `claims` 的行为。
- 本模板统一使用 `base.get` 取值，隐式处理 `*Alias`。
- `claims` 按逐项类型判断，string 项按空格和逗号拆分，map 项按原生格式处理，同一数组允许混用。
- 仅小数形式的 `cpu` 需换算为毫核；已是整数 cpu 或整数毫核的输入原样输出。
- `hugepages` 的 `size` 与 `max` 只校验单位一致、倍数关系与大小关系，不额外校验页大小是否为硬件标准值。

## 期望输入格式

```yaml
# 抽象格式
claims:
  - <name> [request]
limits: [cpu] [memory] [ephemeral-storage] ([hugepages-size] [hugepages-max])
requests: [cpu] [memory] [ephemeral-storage] ([hugepages-size] [hugepages-max])
```

```yaml
# 原生格式
claims:
  - name: string
    request: string
limits:
  cpu: IntOrString
  memory: IntOrString
  hugepages-<size>: IntOrString(hugepages-max)
  ephemeral-storage: IntOrString
```

- `limits` 和 `requests` 的 string 形式为 `[cpu] [memory] [ephemeral-storage] ([hugepages-size] [hugepages-max])`，`hugepages-size` 与 `hugepages-max` 位于括号内，分隔符统一为空格和逗号。
- string 形式按位置取值，每个分段都有值（可能为空）；省略中间位置时使用 `""`、`''` 或 `0` 占位，例如 `"" 512Mi 1Gi` 表示只设置 memory 与 ephemeral-storage。
- `""`、`''` 与 `0` 占位均视为该位置未设置，不参与渲染；两种引号写法等价，不得只识别其中一种；不提供占位时前面的位置按顺序占用。
- 括号内的 `hugepages-size` 与 `hugepages-max` 必须成对出现；只给一个或括号不完整时中断渲染。
- 原生格式中不在白名单内的键直接丢弃，不参与渲染也不报错。

## 约束

- 仅使用 Helm 内置函数、Go Template、Sprig 与 Helm 特有函数。
- 参考 Kubernetes 资源管理文档：<https://kubernetes.io/zh-cn/docs/concepts/configuration/manage-resources-containers/>。

## 非目标

- 不调整公共模板 `base.quantity` 的既有校验规则。
- 不改动 `core.podSpec` 中 `resources` 之外的字段。
- 不创建 `definitions.resourceClaim`，其实现由后续 change 提供。

## 验收

- 抽象 string 形式与原生形式输入均能渲染出合法的 `resources` 片段。
- `hugepages-size` 与 `hugepages-max` 生成 `hugepages-<size>: <hugepages-max>`；非整数倍或 `hugepages-max` 不大于 `hugepages-size` 时渲染失败。
- `hugepages-size=2Mi` 与 `hugepages-max=1024Mi` 渲染通过；`hugepages-size=2Mi` 与 `hugepages-max=1Gi` 因单位不同渲染失败。
- 括号内只给一个 hugepages 值或括号不完整时渲染失败。
- 模板注释包含 `cat /proc/meminfo | grep -i huge` 及 `Hugepagesize`、`HugePages_Total` 的取值说明。
- `cpu: 0.5` 渲染为 `500m`；`cpu: 0.005` 渲染为 `5m`；`cpu: 0.0005`、`cpu: 1.5m` 均渲染失败。
- `cpu: 0`、`memory: 0`、`ephemeral-storage: 0` 不产生对应输出。
- `limits` 或 `requests` 中的扩展资源键被丢弃，输出中不出现对应键，也不中断渲染。
- string 形式使用 `""`、`''` 或 `0` 占位时对应位置不产生输出，后续位置仍按顺序写入正确键。
- 省略 `claims`、`limits` 或 `requests` 时不产生对应输出；`claims` 委托结果全部为空时同样不输出 `claims`。
- `_kind: PodSpec` 且输入含 `claims` 时输出不含 `claims`，也不报错。
- `core.podSpec` 透传含 `*Alias` 的 `resources` 上下文时不再丢失字段，子上下文携带 `_kind: PodSpec`。
- 非空 `claims` 的委托链路只能用 `/tmp/` 同名 fixture 验证；`definitions.resourceClaim` 缺失时真实渲染会中断。

## 开放问题

- 无。
