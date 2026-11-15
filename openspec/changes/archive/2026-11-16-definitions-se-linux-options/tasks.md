# SELinuxOptions 共享结构任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_SELinuxOptions.tpl`：新建文件并在 `writable-scopes` 内 `add` 紧邻 `define` 之前的中文整体契约注释与 `define "definitions.seLinuxOptions"` 骨架，注释覆盖入参为四个可选 string 字段、输出仅为 `SELinuxOptions` 字段片段且字段顺序、空内容返回、非 string 中断与强制加引号边界；对应 `Decision: 目标文件与命名模板归属`、`Decision: 返回值形态`。
- [x] T2 `templates/api-resources/Definitions/_SELinuxOptions.tpl`：在 `writable-scopes` 内实现四字段循环闭环：`range` 固定键列表 `level`、`role`、`type`、`user`，逐键 `base.get` 非必填取值、`base.string.normalize` 解码、`trim` 后为空则 `continue` 跳过，非空时 `base.field` + `quote` 输出，补齐该字段组的中文注释；对应 `Decision: 四字段同构处理与顺序`、`Decision: 字段取值、归一与空值跳过`、`Decision: 字段值输出形态`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：输入 `{level: s0}`，验证输出只含 `level: "s0"`、可被 `fromYaml` 回收为 map，且不含父级键与 `apiVersion`、`kind`。
- [x] V2 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：输入四字段完整 `{level: s0, role: sysadm_r, type: container_t, user: system_u}`，验证输出顺序为 `level`、`role`、`type`、`user` 且取值一致；另验证 `{level: s0, type: container_t}` 只输出两字段且顺序正确、`{level: s0, foo: bar}` 忽略范围外键、`{level: "  s0  "}` 输出取值 `s0`。
- [x] V3 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：输入 `{level: "on", role: "yes", type: "true"}`，验证输出为 `level: "on"`、`role: "yes"`、`type: "true"`，且回读后三者 `kindIs "string"` 均为 true。
- [x] V4 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：验证跳过边界均渲染成功：`{}` 输出为空内容、`{level: "", role: "   ", type: null}` 输出为空内容、`{level: "", role: sysadm_r}` 只输出 `role`、`{level: "   ", user: system_u}` 只输出 `user`、`{level: null, role: sysadm_r}` 只输出 `role`。
- [x] V5 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：四个字段分别取 `123`、`true`、`{a: b}`、`[a]`，逐项验证渲染中断。
- [x] V6 静态检查：`templates/api-resources/Definitions/_SELinuxOptions.tpl` 无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
