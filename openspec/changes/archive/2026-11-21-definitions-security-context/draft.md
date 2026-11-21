---
change-id: definitions-security-context
updated_at: "2026-11-21T13:30:11Z"
---

# 实现 definitions.securityContext

## 目标

- 新增 `definitions.securityContext` 模板，用于渲染容器 `securityContext` 字段片段。

## 需求

- 上下文为原生 map，包含 `os` 字段，不先做 YAML 解析。
- 字段清单与渲染顺序（按官方文档顺序）：

  | 字段 | 类型 / 子模板 | 适用 os |
  |---|---|---|
  | `allowPrivilegeEscalation` | boolean | linux |
  | `appArmorProfile` | `definitions.appArmorProfile` | linux |
  | `capabilities` | `definitions.capabilities` | linux |
  | `privileged` | boolean | linux |
  | `procMount` | string | linux |
  | `readOnlyRootFilesystem` | boolean | linux |
  | `runAsGroup` | integer | linux |
  | `runAsNonRoot` | boolean | linux、windows |
  | `runAsUser` | integer | linux |
  | `seLinuxOptions` | `definitions.seLinuxOptions` | linux |
  | `seccompProfile` | `definitions.seccompProfile` | linux |
  | `windowsOptions` | `definitions.windowsSecurityContextOptions` | windows |

  - 适用 os 依据官方文档中“cannot be set when spec.os.name is ...”的约束。
  - `procMount` 官方类型为 string，枚举为 `Default`、`Unmasked`；用户清单写作 boolean，按“类型以官方文档为准”处理。

- 结构字段的子模板上下文为 map，可直接取值后向下传递。
- 字段类型以官方文档为准，类型不符视为非法并报错中断。
- 字段的枚举校验可用值以官方文档为准。
- boolean 字段传入字符串 `"true"` / `"false"` 时交由 `base.bool` 处理。
- `os` 字段不渲染。
- 输入包含当前 `os` 不可用的字段时报错中断，与 `definitions.podSecurityContext` 一致。
- 空值、null、`0`、`false` 的取舍沿用 `definitions.podSecurityContext`；`runAsGroup`、`runAsUser` 显式 `0` 有效并输出，空值不按 `0` 处理。

## 约束

- 采用直白写法。
- 部分字段的处理参考 `definitions.podSecurityContext`。
- `definitions.capabilities` 子模板不存在，本 change 不创建，仅按名称占位使用。

## 非目标

- 不创建 `definitions.capabilities` 子模板。

## 验收

- 合法输入按官方文档顺序渲染字段。
- 类型非法的输入报错并中断渲染。
- 输出不包含 `os` 字段。
- 当前 `os` 不可用的字段出现在输入中时渲染中断。
