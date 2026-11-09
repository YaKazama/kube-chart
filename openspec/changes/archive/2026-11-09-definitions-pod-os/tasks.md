# PodOS 共享结构任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_PodOS.tpl`：新建文件并在 `writable-scopes` 内 `add` 紧邻 `define` 之前的中文整体契约注释与 `define "definitions.podOS"` 骨架，注释覆盖入参只含 `name` 及其同级 `nameAlias`、输出仅含 `name`、小写归一、空值跳过、枚举失败边界与返回值为可 `fromYaml` 回收的字段片段；对应 `Decision: 目标文件与命名模板归属`、`Decision: 返回值形态`。
- [x] T2 `templates/api-resources/Definitions/_PodOS.tpl`：在 `writable-scopes` 内实现 `name` 闭环：`base.get` 非必填取值、`base.env` 的 `SYS.YAML_QUOTED` 去引号与 `trim`、剥离后为空跳过、`lower` 归一化、`base.field` 以 `base.string` 与允许值列表 `linux`、`windows` 完成枚举校验与输出，并补齐该字段的中文注释；对应 `Decision: name 取值、去引号与空值跳过`、`Decision: 小写归一`、`Decision: 枚举校验委托 base.field`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（真实 `base` 依赖，无同名 fixture）：只提供 `name: linux`，验证输出为 `name: linux` 且不含其他键；另验证 `nameAlias: windows` 覆盖 `name`、空 `nameAlias` 回退 `name`，以及输出可被 `fromYaml` 回收为 map。
- [x] V2 `/tmp/` 最小 application Chart（真实 `base` 依赖）：`name` 分别为缺失、`null`、空字符串、只含空白，验证渲染成功且输出为空内容。
- [x] V3 `/tmp/` 最小 application Chart（真实 `base` 依赖）：`name` 分别为 `Linux`、`WINDOWS`、`"  Linux  "`、`windows`，验证输出为归一化后的小写取值。
- [x] V4 `/tmp/` 最小 application Chart（真实 `base` 依赖）：`name` 分别为 `darwin`、`linux2`，验证渲染中断且错误信息包含 `[base.field]`、`name` 与允许值 `linux`、`windows`。
- [x] V5 `/tmp/` 最小 application Chart（真实 `base` 依赖）：`name` 分别为布尔值 `true`、整数 `123`、map、list，逐一验证渲染中断且错误信息包含 `[base.field]` 与 `name`。
- [x] V6 静态检查：`templates/api-resources/Definitions/_PodOS.tpl` 无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
