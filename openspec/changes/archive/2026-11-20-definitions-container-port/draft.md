---
change-id: definitions-container-port
updated_at: "2026-11-19T15:59:23Z"
---

# definitions.containerPort

## 目标

- 新增 `definitions.containerPort` 模板，用单行字符串或原生 `ContainerPort` map 描述一个 Kubernetes `ContainerPort` 条目。

## 需求

- 上下文支持 string 与原生 map 两种形态；string 形态的格式为 `[hostIP,][hostPort,]<containerPort>[/protocol][#name]`。
- string 形态按正则捕获组位置取值；`hostIP`、`hostPort`、`containerPort` 的位置分隔符为 `,`，`protocol` 由 `/` 引导，`name` 由 `#` 引导。
- map 形态的键为 `containerPort`（必填）与 `hostIP`、`hostPort`、`name`、`protocol`（可选），未声明的键静默忽略；两种形态的校验与输出完全一致。
- `hostIP` 捕获组只接受含 `.` 或 `:` 的 IP 形态 token，因此纯数字段落在第二个位置被识别为 `hostPort`：`8080,80` 为 `hostPort` + `containerPort`，`127.0.0.1,80` 为 `hostIP` + `containerPort`。
- `hostIP` 不要求与 `hostPort` 同时出现。
- `hostIP` 校验只接受 IPv4 与 IPv6，不接受域名、CIDR 或其他地址形式。
- 按 `containerPort`、`hostIP`、`hostPort`、`name`、`protocol` 的字母序渲染，与官方 `ContainerPort` 字段顺序一致。
- 端口号（`hostPort`、`containerPort`）必须落在 0 与 65536 之间且不等于 0 和 65536，即取值 1–65535。
- `protocol` 正则匹配不区分大小写，强制大写后按官方枚举 `SCTP`、`TCP`、`UDP` 校验。
- `name` 按既有命名端口规则校验：不超过 15 字符、符合 `K8S.IANA_SVC_NAME` 且至少包含一个字母。
- 未提供的可选字段（`hostIP`、`hostPort`、`protocol`、`name`）为空时跳过输出。
- 未提供 `protocol` 时不渲染该字段，交由 API 默认值 `TCP` 生效。
- 位置分隔符 `,` 两侧不允许空白；本简写的分隔符语义与既有允许空白混写的简写（如 `SPLIT.SPACE_COMMA`、`ENV_FROM`）不同，不得混用同一分隔符常量。
- `<containerPort>` 缺失、不符合格式、含空白或端口号越界时渲染中断。

## 期望输入格式

- `[hostIP,][hostPort,]<containerPort>[/protocol][#name]`
  - `hostIP`：可选，以 `,` 结尾，接受 IPv4 与 IPv6。
  - `hostPort`：可选，以 `,` 结尾。
  - `containerPort`：必填。
  - `protocol`：可选，以 `/` 引导。
  - `name`：可选，以 `#` 引导。
- 示例：`80`、`8080,80`、`127.0.0.1,80`、`127.0.0.1,8080,80/tcp#http`、`::1,8080,80/UDP#dns`。
- 原生 map：键为 `containerPort`（必填）与 `hostIP`、`hostPort`、`name`、`protocol`（可选）。
  - 示例：`{containerPort: 8080}`、`{containerPort: 80, hostIP: "::1", hostPort: 8080, name: dns, protocol: udp}`。

## 约束

- 端口号取值 1–65535，`0` 与 `65536` 均非法。
- `protocol` 大小写不敏感匹配，输出强制大写。
- `protocol` 枚举为官方文档标示的 `SCTP`、`TCP`、`UDP`。
- 位置分隔符只使用 `,`，不接受 `:` 作为兼容分隔符。
- `,` 两侧不忽略空白，不复用 `SPLIT.SPACE_COMMA` 等允许空白的分隔符常量。
- 实现采用逐字段直白写法，不使用 range 循环。
- 两种上下文形态只做取值差异，归一为同一组字段后共用同一套校验与渲染逻辑。
- `name` 不超过 15 字符，符合 `K8S.IANA_SVC_NAME` 且至少包含一个字母。
- `hostIP` 复用既有 IPv6 能力：`base.env` 的 `NET.IPV4`、`NET.IPV6`，与 `definitions.hostAlias` 的既有内联写法一致。
- `ports` 的 string 元素支持通过在 `definitions.container.array` 增加可选开关参数实现，开关默认关闭，仅 `definitions.container` 的 `ports` 调用处开启。
- 简写正则常量放入 `base.env` 的 `K8S` 命名空间，由模板用捕获组按位置取值。

## 非目标

- 不新增 `definitions.containerPort` 以外的 `definitions.*` 模板。
- 不校验 `name` 在 Pod 内的唯一性；该约束涉及跨条目的完整集合，单模板无法判定。

## 验收

- `127.0.0.1,8080,80/tcp#http` 解析出五个字段，按 `containerPort`、`hostIP`、`hostPort`、`name`、`protocol` 的顺序渲染。
- `::1,8080,80/udp#dns` 的 IPv6 `hostIP` 正确解析，`protocol` 输出为大写。
- `8080,80` 渲染 `hostPort` 与 `containerPort`，不输出其余字段。
- `127.0.0.1,80` 渲染 `hostIP` 与 `containerPort`，不输出 `hostPort`。
- `8080` 仅渲染 `containerPort: 8080`，不输出其余字段。
- 端口号为 `0`、`65536`、`65537` 时渲染中断。
- `8080/Sctp` 与 `8080/SCTP` 输出一致的大写 `protocol`。
- `protocol` 取官方枚举以外的值时渲染中断。
- `hostIP` 取域名（如 `example.com,80`）时渲染中断。
- `name` 超过 15 字符、含大写或首尾连字符时渲染中断。
- `8080, 80`、`127.0.0.1 ,8080,80` 等 `,` 两侧含空白的输入渲染中断。
- `{containerPort: 8080}` 仅渲染 `containerPort: 8080`；五字段 map 按相同顺序渲染且 `protocol` 大写。
- map 缺少 `containerPort`、`containerPort` 为 null 或空串、`hostPort` 为 `0`、`hostIP` 为域名、`name` 非法、`protocol` 非枚举时渲染中断。
- map 中未声明的键静默忽略；既非 string 也非 map 的上下文渲染中断。
- `definitions.container` 的 `ports` 可接受 string 简写元素与 map 元素，均渲染为完整 `ContainerPort` 字段片段。

## 开放问题

- 无。
