# PreferredSchedulingTerm 共享结构任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_PreferredSchedulingTerm.tpl`：新建文件并在 `writable-scopes` 内 `add` 紧邻 `define` 之前的中文整体契约注释与 `define "definitions.preferredSchedulingTerm"` 骨架，注释覆盖入参含 `weight` 与可选 `preference`、`*Alias` 识别、字段输出顺序、失败边界与返回值为可 `fromYaml` 回收的 map 文本；对应 `Decision: 目标文件与命名模板归属`、`Decision: 返回值形态`。
- [x] T2 `templates/api-resources/Definitions/_PreferredSchedulingTerm.tpl`：在 `writable-scopes` 内实现 `weight` 闭环：`base.get` 必填取值、`SYS.YAML_QUOTED` 去引号、`base.int` 整数形态校验、`int64` 归一化、`base.int.range` 校验 1 - 100、`base.field` 搭配 `base.int` 输出，并补齐该字段的中文注释；对应 `Decision: weight 取值、整数归一化与范围校验`。
- [x] T3 `templates/api-resources/Definitions/_PreferredSchedulingTerm.tpl`：在 `writable-scopes` 内实现 `preference` 闭环：`base.get` 非必填取值、空输出跳过、`fromYaml` 与 `base.isFromYamlError` 保护、恢复后空 map 跳过、整 map 委托 `definitions.nodeSelectorTerm`、返回值 `fromYaml` 与 `base.isFromYamlError` 保护、非空时 `base.field` 搭配 `base.map` 输出，并补齐该字段的中文注释；对应 `Decision: preference 取值、解析错误保护与空值跳过`、`Decision: preference 整体委托 nodeSelectorTerm`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（`definitions.nodeSelectorTerm` 为同名回显 fixture）：只提供 `weight: 1`，验证输出只含 `weight: 1` 且不出现 `preference` 字段。
- [x] V2 `/tmp/` 最小 application Chart（fixture）：提供 `weight: 100` 与非空 `preference`，验证输出顺序为 `weight` 在前、fixture 收到的上下文与输入 `preference` 完全一致；另验证 `weightAlias` 覆盖 `weight`、空 `preferenceAlias` 回退 `preference`。
- [x] V3 `/tmp/` 最小 application Chart（fixture）：`preference` 分别为缺失、`null`、空 map，以及 fixture 返回空 map，验证输出只含 `weight` 且不出现 `preference: {}`。
- [x] V4 `/tmp/` 最小 application Chart（fixture）：`weight` 分别为缺失、`null`、空字符串、`abc`、`true`、map、list、`1.5`、`0`、`-1`、`101`，逐一验证渲染中断；缺失、`null` 与空字符串断言 `[base.get]`，非整数形态断言 `[base.int]`，越界断言 `[base.int.range]`，且错误信息包含 `weight`。
- [x] V5 `/tmp/` 最小 application Chart（fixture）：`preference` 为字符串、`preference` 为 list、fixture 返回非 YAML 文本三种输入，验证渲染中断且错误信息包含 `[definitions.preferredSchedulingTerm] preference`。
- [x] V6 静态检查：`templates/api-resources/Definitions/_PreferredSchedulingTerm.tpl` 无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
