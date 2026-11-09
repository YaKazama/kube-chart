# base.string.normalize 任务

## 实施

- [x] T1 `templates/base/_convert.tpl`：新增命名模板 `base.string.normalize`，接收标量 string，经一次 YAML 解码返回 string 值或空字符串，解析失败与非 string 结果中断；对应 `字符串标量解码`、`空输入返回空字符串`、`非法入参中断渲染`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：入参 `gpu`，预期返回 `gpu`。
- [x] V2 `/tmp/` 最小 application Chart：入参覆盖 `"on"`、`'yes'`、`"007"`、`"a: b"`、`'  spaced  '`、`'   '`、块标量 `|` 与折叠标量 `>`，预期值与 YAML 语义一致，结果不含 `|`、`>` 指示符，首尾空白保持原样。
- [x] V3 `/tmp/` 最小 application Chart：入参 `""`、`null`、`~`，预期返回空字符串且渲染不中断。
- [x] V4 `/tmp/` 最小 application Chart：入参 `a: b`、`- x`，预期 `helm template` 中断且消息带 `[base.string.normalize]` 前缀。
- [x] V5 `/tmp/` 最小 application Chart：入参 `true`、`123`、`{a: b}`、`[a, b]`，预期 `helm template` 中断且消息带 `[base.string.normalize]` 前缀并指明实际类型。
- [x] V6 `/tmp/` 最小 application Chart：直接向模板传入 map（非 string），预期 `helm template` 中断且消息带 `[base.string.normalize]` 前缀并指明实际类型。
