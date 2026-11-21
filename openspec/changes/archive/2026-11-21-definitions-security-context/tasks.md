# SecurityContext 共享结构任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_SecurityContext.tpl`（writable scope 为 `definitions.securityContext` 的契约注释与 `define` 块）：新建文件并 `add` 紧邻 `define` 之前的中文整体契约注释与 `define "definitions.securityContext"` 骨架，注释覆盖原生 map 入参、`os` 控制键、十二个字段、官方字段顺序、类型与枚举、空值与零值、委托边界与错误前缀；实现 `base.env` 常量读取、`os.name` 归一与按 `os` 的禁止字段前置校验，补齐 `os` 与适用性校验的中文注释；对应 `Decision: 目标文件与命名模板归属`、`Decision: os 取值与容错归一`、`Decision: 适用性前置校验与存在性判定`。
- [x] T2 `templates/api-resources/Definitions/_SecurityContext.tpl`（writable scope 为 `definitions.securityContext.struct` 的契约注释与 `define` 块）：`add` 辅助模板 `definitions.securityContext.struct` 及紧邻之前的中文整体契约注释，实现 `key`、`define`、`raw` 入参，原始输出判空、`fromYaml` 与解析错误中断、空 map 跳过、子模板委托、结果解析错误中断、非空时 `base.field` + `base.map` 输出；对应 `Decision: 委托结构字段的辅助模板`。
- [x] T3 `templates/api-resources/Definitions/_SecurityContext.tpl`（writable scope 为 `definitions.securityContext` 的 `define` 块）：按官方顺序实现十二个字段的处理闭环与各字段中文注释，`allowPrivilegeEscalation`、`appArmorProfile`、`capabilities`、`privileged`、`procMount`、`readOnlyRootFilesystem`、`runAsGroup`、`runAsNonRoot`、`runAsUser`、`seLinuxOptions`、`seccompProfile`、`windowsOptions` 分别使用对应标量门禁或 `definitions.securityContext.struct` 委托；对应 `Decision: 标量字段的取值与渲染`、`Decision: 固定顺序与逐字段直白写法`、`Decision: 返回值形态`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小 application Chart（真实 `base` 与四个既有子模板，无 fixture）：验证最小输入 `{os: {name: linux}, runAsNonRoot: true}`、linux 可渲染字段集合与官方顺序、windows 下 `windowsOptions` 与 `runAsNonRoot`、无有效字段的空输出、显式 `0` 与 `false`、范围外键忽略、`os.name: Windows` 大写、`os.name: darwin`、`os` 缺省与标量首尾空白。
- [x] V2 `/tmp/sd-kube-chart/` 最小 application Chart（真实依赖，无 fixture）：验证适用性失败边界，`os.name: windows` 下的 linux 专属字段（含 `{}`、`[]`、`""`、`0` 形式）与按 `linux` 处理时的 `windowsOptions` 逐项渲染中断，失败信息包含字段名与当前 `os`。
- [x] V3 `/tmp/sd-kube-chart/` 最小 application Chart（真实依赖，无 fixture）：验证类型与枚举失败边界，非法 `procMount` 枚举、非 string `procMount`、非布尔布尔字段、非整数整数字段逐项渲染中断；另验证 `procMount: Unmasked` 与 `privileged: "false"` 的正常输出。
- [x] V4 `/tmp/sd-kube-chart/` 最小 application Chart（真实 `definitions.appArmorProfile`、`definitions.seLinuxOptions`、`definitions.seccompProfile`、`definitions.windowsSecurityContextOptions`）：验证结构字段委托成功、空 map 跳过、子模板结果为空时省略字段、结构字段非 map 输入中断且失败信息包含字段名。
- [x] V5 `/tmp/sd-kube-chart/` 最小 application Chart：不提供 `definitions.capabilities` 时验证空 map 跳过与非空 map 渲染中断；再提供同名最小 fixture，验证本层把非空 map 交给子模板并回收输出，fixture 结果仅证明调用方自身行为。
- [x] V6 静态检查：`templates/api-resources/Definitions/_SecurityContext.tpl` 无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
