# WeightedPodAffinityTerm 共享结构任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_WeightedPodAffinityTerm.tpl`：新建文件并在 `writable-scopes` 内 `add` 紧邻 `define` 之前的中文整体契约注释与 `define "definitions.weightedPodAffinityTerm"` 骨架，注释覆盖入参含必填 `weight` 与必填 `podAffinityTerm`、`*Alias` 识别、字段输出顺序、失败边界与返回值为可 `fromYaml` 回收的 map 文本；对应 `Decision: 目标文件与命名模板归属`、`Decision: 返回值形态与字段顺序`。
- [x] T2 `templates/api-resources/Definitions/_WeightedPodAffinityTerm.tpl`：在 `writable-scopes` 内实现 `weight` 闭环：`base.get` 必填取值、`SYS.YAML_QUOTED` 去引号、`base.int` 整数形态校验、`int64` 归一化、`base.int.range` 校验 1 - 100、`base.field` 搭配 `base.int` 输出，并补齐该字段的中文注释；对应 `Decision: weight 取值、整数归一化与范围校验`。
- [x] T3 `templates/api-resources/Definitions/_WeightedPodAffinityTerm.tpl`：在 `writable-scopes` 内实现 `podAffinityTerm` 闭环：`base.get` 必填取值、`fromYaml` 与 `base.isFromYamlError` 保护、`kindIs "map"` 类型门禁、整 map 只读委托 `definitions.podAffinityTerm`、返回值 `fromYaml` 与 `base.isFromYamlError` 保护、`base.field` 搭配 `base.map` 输出，并补齐该字段的中文注释；对应 `Decision: podAffinityTerm 必填取值与 map 归一化`、`Decision: podAffinityTerm 整体委托`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（`definitions.podAffinityTerm` 为同名回显 fixture）：提供 `weight: 1` 与只含 `topologyKey` 的 `podAffinityTerm`，验证输出同时含 `weight: 1` 与 `podAffinityTerm`，且 `podAffinityTerm` 在前。
- [x] V2 `/tmp/` 最小 application Chart（fixture）：提供 `weight: 100` 与含 `topologyKey`、`labelSelector`、`namespaceSelector`、`matchLabelKeys`、`namespaces` 的 `podAffinityTerm`，验证 fixture 收到的上下文与输入 `podAffinityTerm` 逐键一致；另验证 `weightAlias` 覆盖 `weight`、空 `podAffinityTermAlias` 回退 `podAffinityTerm`。
- [x] V3 `/tmp/` 最小 application Chart（fixture）：`weight` 分别为缺失、`null`、空字符串、`abc`、`true`、map、list、`1.5`、`0`、`-1`、`101`，逐一验证渲染中断；缺失、`null` 与空字符串断言 `[base.get]`，非整数形态断言 `[base.int]`，越界断言 `[base.int.range]`，且错误信息包含 `weight`；另验证 `weight: "11"` 按整数接受并输出 `weight: 11`。
- [x] V4 `/tmp/` 最小 application Chart（fixture）：`podAffinityTerm` 分别为缺失、`null`、空 map、字符串、list，逐一验证渲染中断并断言错误信息包含 `[base.get]` 或 `[definitions.weightedPodAffinityTerm] podAffinityTerm`；fixture 返回非 YAML 文本时同样验证中断。
- [x] V5 静态检查：`templates/api-resources/Definitions/_WeightedPodAffinityTerm.tpl` 无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
