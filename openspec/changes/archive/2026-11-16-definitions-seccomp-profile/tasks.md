# SeccompProfile 共享结构任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_SeccompProfile.tpl`：新建文件并在 `writable-scopes` 内 `add` 紧邻 `define` 之前的中文整体契约注释与 `define "definitions.seccompProfile"` 骨架，注释覆盖入参为 `type` 必填与 `localhostProfile` 条件必填的 string 字段、输出仅为 `SeccompProfile` 字段片段且字段顺序、非 string 中断、枚举失败与强制加引号边界；对应 `Decision: 目标文件与命名模板归属`、`Decision: 返回值形态`。
- [x] T2 `templates/api-resources/Definitions/_SeccompProfile.tpl`：在 `writable-scopes` 内实现 `type` 归一化与必填闭环：`base.get` 取值、`base.string.normalize` 解码、`trim` 赋给 `$type`，归一后为空则 `fail` 必填缺失，补齐 `type` 的中文注释；对应 `Decision: type 单次归一化并共用`。
- [x] T3 `templates/api-resources/Definitions/_SeccompProfile.tpl`：在 `writable-scopes` 内实现 `localhostProfile` 条件分支：仅在 `$type` 为 `Localhost` 时以同一 `base.get` + `base.string.normalize` + `trim` 链路取值，归一后为空则 `fail`，非空时 `base.field` + `quote` 输出；随后无条件以 `base.field` 传 `Localhost`、`RuntimeDefault`、`Unconfined` 允许值列表 + `quote` 输出 `type`，枚举校验由该调用完成，补齐各字段的中文注释；对应 `Decision: localhostProfile 条件读取`、`Decision: 枚举校验委托 base.field 的允许值列表`、`Decision: 字段输出顺序与形态`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：输入 `{type: RuntimeDefault}`，验证输出只含 `type: "RuntimeDefault"`、可被 `fromYaml` 回收为 map，且不含父级键与 `apiVersion`、`kind`。
- [x] V2 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：输入 `{type: Localhost, localhostProfile: profiles/a.json}`，验证输出顺序为 `localhostProfile`、`type` 且取值一致；另验证 `{type: " Localhost ", localhostProfile: "  profiles/a.json  "}` 输出取值为 `Localhost` 与 `profiles/a.json`。
- [x] V3 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：验证非 `Localhost` 时忽略 `localhostProfile` 与范围外键：`{type: RuntimeDefault, localhostProfile: 123}`、`{type: Unconfined, localhostProfile: {a: b}}`、`{type: RuntimeDefault, foo: bar}` 均渲染成功且输出只含 `type`。
- [x] V4 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：验证 `type` 失败边界：缺失、`null`、`""`、`"   "`、`localhost`、`RUNTIMEDEFAULT`、`Bogus`、`123`、`true`、`{a: b}`、`[a]` 逐项渲染中断，枚举类失败断言错误信息给出合法取值。
- [x] V5 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：验证 `type: Localhost` 下 `localhostProfile` 失败边界：缺失、`""`、`"   "`、`123`、`{a: b}` 逐项渲染中断。
- [x] V6 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：输入 `{type: Localhost, localhostProfile: "on"}`，验证输出为 `localhostProfile: "on"`、`type: "Localhost"`，且回读后两者 `kindIs "string"` 均为 true。
- [x] V7 静态检查：`templates/api-resources/Definitions/_SeccompProfile.tpl` 无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
