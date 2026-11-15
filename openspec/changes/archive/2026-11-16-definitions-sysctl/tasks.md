# Sysctl 共享结构任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_Sysctl.tpl`：新建文件并在 `writable-scopes` 内 `add` 紧邻 `define` 之前的中文整体契约注释与 `define "definitions.sysctl"` 骨架，注释覆盖上下文为 map、两字段均必填且仅接受 string、同级 `<字段>Alias` 隐式生效并优先于规范键、`value` 为 `null` 或空串时输出 `""`、字符串 `"null"` 为普通取值、`name` 恒带引号、`value` 按 YAML 回读决定引号、输出仅为 `Sysctl` 字段片段且字段顺序等边界；对应 `Decision: 目标文件与命名模板归属`、`Decision: 返回值形态`。
- [x] T2 `templates/api-resources/Definitions/_Sysctl.tpl`：在 `writable-scopes` 内实现 `name` 闭环：`base.get` 取值、`base.string.normalize` 解码、`trim` 后为空则 `fail`，补齐 `name` 的中文注释；对应 `Decision: 使用 base.get 统一取值并隐式支持别名`。
- [x] T3 `templates/api-resources/Definitions/_Sysctl.tpl`：在 `writable-scopes` 内实现 `value` 闭环与输出：`hasKey` 同时判定 `value` 与 `valueAlias` 均缺失时 `fail`，`base.get` + `base.string.normalize` + `trim` 取值，以 `fromYaml` 回读判定是否需要加引号，两字段均以 `quote` 预处理后交给 `base.field` + `base.rawString` 输出，`name` 先输出、`value` 后输出，补齐各字段的中文注释；对应 `Decision: value 必填判定覆盖规范键与别名键`、`Decision: name 恒加双引号`、`Decision: value 按 YAML 回读结果决定引号`、`Decision: 使用 quote 加 base.rawString 而非 base.field 的 quote 渲染模板`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：输入 `{name: net.ipv4.ip_forward, value: "0"}`，验证输出顺序为 `name`、`value`、`name` 带双引号、`value` 为 `"0"`、可被 `fromYaml` 回收为 map，且不含父级键与 `apiVersion`、`kind`。
- [x] V2 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：输入 `{name: kernel.domainname, value: abc}`，验证输出为 `value: abc` 且不加引号；另验证 `{name: " kernel.x ", value: "  1  "}` 输出取值为 `kernel.x` 与 `1`。
- [x] V3 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：验证需要引号的字面量：`"0"`、`"true"`、`"on"`、`"1.5"` 均输出带双引号形式，且回读后仍为 string。
- [x] V4 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：验证取值不被改写：`"007"` 输出 `value: "007"`、`"0000"` 输出 `value: "0000"`。
- [x] V5 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：验证空值边界渲染成功且输出 `value: ""`：`{value: ""}`、`{value: "   "}`、`{value: null}`；另验证 `{value: "null"}` 输出 `value: "null"`。
- [x] V6 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：验证 `name` 失败边界：缺失、`null`、`""`、`"   "`、`123`、`true`、`{a: b}`、`[a]` 逐项渲染中断；验证 `value` 失败边界：与 `valueAlias` 均缺失、`0`、`true`、`{a: b}`、`[a]` 逐项渲染中断。
- [x] V7 `/tmp/` 最小 application Chart（真实 `base` 依赖，无 fixture）：验证别名与范围外键：`{name: a, value: "1", valueAlias: "2"}` 输出 `value: "2"`、`{name: a, valueAlias: "2"}` 输出 `value: "2"`、`{nameAlias: b, value: "1"}` 输出 `name: "b"`、`{name: a, value: "1", foo: bar}` 输出不含 `foo`。
- [x] V8 静态检查：`templates/api-resources/Definitions/_Sysctl.tpl` 无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
