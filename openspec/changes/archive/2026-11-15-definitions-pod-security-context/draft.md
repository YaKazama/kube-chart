---
change-id: definitions-pod-security-context
updated_at: "2026-11-15T14:13:24Z"
---

# definitions.podSecurityContext

## 目标

- 新建公共模板 `definitions.podSecurityContext`，按带 `os` 的原生 map 结构渲染 Pod 级安全上下文。
- 字段语义参考 Kubernetes v1.36 官方文档。

## 需求

- 上下文为带 `os` 的原生 map，字段范围与“期望输入格式”一致。
- `appArmorProfile` 使用占位子模板 `definitions.appArmorProfile`。
- `seLinuxOptions` 使用占位子模板 `definitions.seLinuxOptions`。
- `seccompProfile` 使用占位子模板 `definitions.seccompProfile`。
- `sysctls` 使用占位子模板 `definitions.sysctl`；回收的内容需要去重、去空。
- `windowsOptions` 使用占位子模板 `definitions.windowsSecurityContextOptions`。
- 占位子模板在本 change 只使用名称，不创建 `define`；调用前由本模板完成必要的数据清洗，传递给子模板的上下文为 map。
- 除 `windowsOptions` 和 `runAsNonRoot` 外的字段用于 `os=linux` 情况；`windowsOptions` 用于 `os=windows` 情况。
- `runAsNonRoot` 不受 `os` 限制，`os=linux` 与 `os=windows` 两种情况都渲染。
- `os=windows` 时，除 `windowsOptions` 和 `runAsNonRoot` 外的字段被中断报错。
- `os=linux`、`os` 缺省或 `os.name` 不是 `linux` / `windows` 时，`windowsOptions` 被中断报错。
- 字段适用性按键是否存在判定，与取值是否为假值无关：空 map（如 `seLinuxOptions: {}`）与整数 `0` 均视为存在并参与中断报错。
- `os` 缺省或 `os.name` 不是 `linux` / `windows` 时按 `linux` 处理。
- `sysctls` 中完全相同的条目由 Helm 去重函数处理，不按 `name` 合并。
- `sysctls` 回收值去重后仍存在的同名不同值条目同样合法，由 Kubernetes 侧后出现的同名项覆盖前值。
- `sysctls` 去空：移除 `name` 或 `value` 为空字符串的条目；`"0"` 是合法值，不参与去空。
- `fsGroupChangePolicy` 枚举校验值为 `Always`、`OnRootMismatch`。
- `seLinuxChangePolicy` 枚举校验值为 `MountOption`、`Recursive`。
- `supplementalGroupsPolicy` 枚举校验值为 `Merge`、`Strict`。
- 枚举校验失败时使用 `fail` 终止渲染。
- 所有字段均为可选渲染，仅在输入中存在时输出。
- 所有 integer 类型数据均可显式设置 `0`，`0` 值视为有效值，不得按假值跳过。
- `supplementalGroups` 需要去重、去空，`0` 值合法并保留。
- `supplementalGroups` 去重后保持首次出现的输入顺序；空字符串与 null 元素视为空被移除，其余无法归一化为 integer 的元素中断渲染。
- `os` 只参与分支判断，不出现在输出中（`PodSecurityContext` 没有 `os` 字段）。
- `os.name` 比较前统一转小写；无法按 string 归一化的 `os.name` 按非 `linux` / `windows` 处理。
- `sysctls` 条目清洗为只含 `name`、`value` 的 map，标量先归一化为 string 再 trim。
- `sysctls` 清洗后为空时不输出该字段。
- `sysctls` 中非 map 条目或无法归一化为 string 的 `name`、`value` 视为类型非法并中断渲染。
- 委托结构解析后为空 map（如 `seLinuxOptions: {}`）时，在 `os` 匹配的前提下不调用子模板、不输出该字段。
- 字段值为 `null` 或字段缺失视为不存在，不触发 `os` 适用性报错。
- `runAsNonRoot` 显式 `false` 时仍输出该字段。

## 期望输入格式

```yaml
os:
  name: string # linux / windows
appArmorProfile:
  localhostProfile: string
  type: string
fsGroup: integer
fsGroupChangePolicy: string
runAsGroup: integer
runAsNonRoot: boolean
runAsUser: integer
seLinuxChangePolicy: string
seLinuxOptions:
  level: string
  role: string
  type: string
  user: string
seccompProfile:
  localhostProfile: string
  type: string
supplementalGroups: integer array
supplementalGroupsPolicy: string
sysctls:
  - name: string
    value: string
windowsOptions:
  gmsaCredentialSpec: string
  gmsaCredentialSpecName: string
  hostProcess: boolean
  runAsUserName: string
```

## 约束

- 字段结构以用户给出的上下文格式为准，字段语义以 Kubernetes v1.36 官方文档为准。
- `sysctls` 子模板的输入需要先完成去空、清洗和去重，再参与渲染。
- 枚举校验只在对应字段存在时执行。
- 本 change 不创建占位子模板的 `define`；依赖实现前，输入中出现被委托字段会因未定义模板中断渲染。

## 非目标

- 不创建 `definitions.appArmorProfile`、`definitions.seLinuxOptions`、`definitions.seccompProfile`、`definitions.sysctl`、`definitions.windowsSecurityContextOptions` 的 `define`。
- `[AI 推断]` 不实现与 `definitions.podSecurityContext` 无关的模板或字段。

## 验收

- 按 `os` 分别提供该 `os` 适用的完整输入时，输出字段结构与 Kubernetes v1.36 `PodSecurityContext` 一致。
- 字段缺省时不渲染；integer 字段显式设置为 `0` 时渲染 `0`。
- 非法枚举值被拒绝并给出合法范围，渲染中断；合法枚举值正常渲染。
- `os=linux`、`os` 缺省或 `os.name` 非法时渲染除 `windowsOptions` 外的字段；`os=windows` 时渲染 `windowsOptions`。
- `os=windows` 时输入除 `windowsOptions` 和 `runAsNonRoot` 外的任一字段，渲染中断并给出字段名与所属 `os`。
- `os=linux`、`os` 缺省或 `os.name` 非法时输入 `windowsOptions`，渲染中断并给出字段名与所属 `os`。
- `os` 不适用的字段以空 map 或 `0` 形式出现时，同样渲染中断。
- `runAsNonRoot` 在 `os=linux` 和 `os=windows` 下均渲染。
- `sysctls` 输入中的重复条目和空条目不会进入最终输出。
- `sysctls` 中 `value: "0"` 的条目正常进入最终输出。
- `sysctls` 中同名不同值的条目都保留，Kubernetes 侧以后值覆盖前值。
- `supplementalGroups` 中的重复值和空值不会进入最终输出，`0` 值保留。

## 开放问题

- 无。
