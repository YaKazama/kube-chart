---
change-id: definitions-resource-field-selector
updated_at: "2026-11-17T17:08:27Z"
---

# definitions.resourceFieldSelector

## 目标

- 新增命名模板 `definitions.resourceFieldSelector`，把 map 上下文渲染为 Kubernetes `ResourceFieldSelector` 字段片段。
- 供 `definitions.envVarSource` 的 `resourceFieldRef` 分支调用。

## 需求

- 入参上下文为 map。
- `resource` 为必填字段；缺失或为空时中断渲染。
- `resource` 必须是 `EnvVarSource.resourceFieldRef` 官方支持的资源名之一：`limits.cpu`、`limits.memory`、`limits.ephemeral-storage`、`requests.cpu`、`requests.memory`、`requests.ephemeral-storage`。
- `resource` 不在支持列表内时中断渲染。
- 按官方文档字段顺序渲染：`containerName`、`divisor`、`resource`。
- 字段类型按官方定义：`containerName` 为 string，`divisor` 为 Quantity，`resource` 为 string。
- `containerName` 与 `divisor` 均为可选字段，缺省时不输出；`divisor` 不补官方默认值 `1`。
- `divisor` 的取值先剥离 YAML 外层引号并 `trim`，经单位白名单校验后再逐次经 `base.quantity` 校验。
- `divisor` 输出形态：cpu 的无单位整数按不加引号的数字标量输出（如 `1`、`2`）；cpu 的小数核值与毫核、内存类字节单位取值按字符串标量输出（如 `1.5` → `1500m`、`500m`、`2Mi`）。
- `divisor` 按 `resource` 类型限制**形态**，量级不受限制：
  - 以 `.cpu` 结尾的资源：只允许无单位整数、无单位小数或整数毫核，如 `1`、`2`、`1.5`、`500m`、`1000m`；小数毫核如 `1.5m` 不合法。
  - 以 `.memory` 或 `.ephemeral-storage` 结尾的资源：必须带字节单位，如 `2Mi`、`128Mi`、`1Gi`、`1Ti`、`1k`、`1M`、`1G`、`1E`；无单位取值不合法。
  - 形态与资源类型不匹配时中断渲染，如 `.cpu` 下的 `1Ki`、`.memory` 下的 `1` 与 `1m`。
- 取值使用 `base.get`。
- 只渲染官方文档约定的三个字段；入参中的其他键静默忽略。

## 期望输入格式

- `definitions.resourceFieldSelector` 的入参为单个 `ResourceFieldSelector` map，键为 `containerName`、`divisor`、`resource`。

## 约束

- `resource` 为空或缺失即中断，不使用默认值掩盖缺失。
- `resource` 与 `divisor` 的允许值校验需要固定正则，统一放入 `templates/base/_env.tpl` 的 `base.env`。
- `divisor` 的允许集合本身均为合法 Quantity：`K8S.DIVISOR_CPU` 与 `K8S.DIVISOR_SIZE` 的匹配集均为 `K8S.QUANTITY` 的真子集。
- `divisor` 的输出经 `base.quantity` 作为 `base.field` 的渲染模板一次性完成，不另做独立校验调用；因白名单匹配集为其真子集，该调用不会产生新的失败边界。
- `divisor` 只约束形态与资源类型匹配，不限制量级；`2Mi`、`1000m` 等均为合法输入。
- cpu 的无单位整数与带单位取值分别按数字与字符串标量输出，不需要额外的无单位判定正则。
- 十进制单位按 Kubernetes Quantity 规则使用小写 `k`，大写 `K` 不合法；`1M`、`1G` 为大写。
- 输出为单层字段片段，不包含 `resourceFieldRef` 父键。

## 非目标

- 不渲染 `EnvVarSource` 的其他字段。
- 不实现 `definitions.envVarSource` 的分发逻辑。
- 不兼容 `DownwardAPIVolumeFile` 的资源名扩展。

## 验收

- 最小输入 `resource` 能渲染出合法的 `ResourceFieldSelector` 字段片段。
- 三个字段齐全时按 `containerName`、`divisor`、`resource` 顺序输出。
- `containerName` 与 `divisor` 缺省时只输出 `resource`，不补默认值 `1`。
- `resource` 缺失或为空时中断渲染。
- `resource` 为六个官方资源名之一时渲染成功，不在列表内（如 `metadata.name`、`limits.gpu`）时中断。
- `divisor` 为 `1`、`2`、`1.5`、`500m`、`1000m` 时在 `.cpu` 资源下渲染成功，其中 `1.5` 输出 `1500m`；为 `2Mi`、`128Mi`、`1Gi`、`1.5Gi`、`1Ti`、`1k`、`1M`、`1G` 时在 `.memory` 与 `.ephemeral-storage` 下渲染成功。
- `divisor` 形态与资源类型不匹配时中断，如 `.cpu` 下的 `1Ki` 与 `1.5m`、`.memory` 下的 `1` 与 `1m`。
- `divisor` 为无单位整数时输出为数字标量（`1` 与 `"1"` 均输出 `1`）；为小数核值时输出为整数毫核字符串；为毫核或字节单位时输出为字符串标量。
- 入参中的额外键不产生输出。

## 开放问题

- 无。
