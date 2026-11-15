# AppArmorProfile 共享结构任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_AppArmorProfile.tpl`：新建文件并在 `writable-scopes` 内 `add` 紧邻 `define` 之前的中文整体契约注释与 `define "definitions.appArmorProfile"` 骨架，注释覆盖入参为 `localhostProfile` 与 `type`、输出仅为 `AppArmorProfile` 字段片段且字段顺序、`type` 必填与枚举失败边界、`localhostProfile` 条件渲染与类型失败边界、恒有输出；对应 `Decision: 目标文件与命名模板归属`、`Decision: 返回值形态`。
- [x] T2 `templates/api-resources/Definitions/_AppArmorProfile.tpl`：在 `writable-scopes` 内实现 `type` 取值与归一：`base.get` 非必填取值、经 `base.string.normalize` 解码后 `trim`、仍为空时以本模板前缀中断，补齐该步骤的中文注释；对应 `Decision: type 取值与空值判定`。
- [x] T3 `templates/api-resources/Definitions/_AppArmorProfile.tpl`：在 `writable-scopes` 内实现 `localhostProfile` 条件渲染：仅在 `$type` 等于 `Localhost` 时 `base.get` 取值、`base.string.normalize` 解码、`trim`、空则中断、非空时 `base.field` + `quote` 输出，补齐该字段的中文注释；对应 `Decision: localhostProfile 条件渲染`。
- [x] T4 `templates/api-resources/Definitions/_AppArmorProfile.tpl`：在 `writable-scopes` 内实现 `type` 枚举校验与输出：`base.field` + `base.string` + 允许值列表 `Localhost`、`RuntimeDefault`、`Unconfined`，置于 `localhostProfile` 之后以满足 API 字段顺序，补齐该字段的中文注释；对应 `Decision: type 枚举校验委托 base.field`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：输入 `{type: RuntimeDefault}`，验证输出只含 `type: RuntimeDefault`、可被 `fromYaml` 回收为 map，且不含父级键与 `apiVersion`、`kind`。
- [x] V2 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：输入 `{type: Localhost, localhostProfile: k8s-apparmor-example-deny-write}`，验证输出先 `localhostProfile` 后 `type` 且取值一致；另验证 `{type: Unconfined}` 只输出 `type`、范围外键被忽略、含 `:` 的 profile 名回收后仍为 string；再验证 `{type: "  Localhost  "}` 输出 `type: Localhost`、`{type: Localhost, localhostProfile: "  prof  "}` 输出取值为 `prof`。
- [x] V3 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：验证 `type` 缺失、`null`、空字符串、`"   "`、`localhost`、`RUNTIMEDEFAULT`、`Disabled`、`{type: Localhost}`、`{type: Localhost, localhostProfile: null}`、`{type: Localhost, localhostProfile: ""}`、`{type: Localhost, localhostProfile: "   "}`、`{type: Localhost, localhostProfile: 123}` 均中断渲染；枚举失败场景断言错误信息包含 `Localhost`、`RuntimeDefault`、`Unconfined`。
- [x] V4 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：验证 `{type: RuntimeDefault, localhostProfile: prof}` 与 `{type: Unconfined, localhostProfile: 123}` 均渲染成功，且输出只含 `type`。
- [x] V5 静态检查：`templates/api-resources/Definitions/_AppArmorProfile.tpl` 无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
