# definitions.containerRestartRuleOnExitCodes 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_ContainerRestartRuleOnExitCodes.tpl`：新增 `definitions.containerRestartRuleOnExitCodes`，完成 `operator` 归一化与枚举渲染、`values` 数组解析、数量与整数元素校验及字段输出；对应 `退出码匹配规则字段片段渲染`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：以 `operator: In`、`values: [0]` 调用模板，预期成功输出 `operator: "In"` 和保留 `0` 的 `values` 数组。
- [x] V2 `/tmp/` 最小 application Chart：覆盖 `in`、`notin` 等大小写变体及 1 个和 255 个元素，预期 `operator` 归一化为 `In` / `NotIn` 且上述数量边界均成功输出。
- [x] V3 `/tmp/` 最小 application Chart：覆盖非 map 上下文，以及 `operator` 缺失、null、空字符串、非 string 和非法枚举，预期均中断渲染。
- [x] V4 `/tmp/` 最小 application Chart：覆盖 `values` 缺失、null、非 array、空数组、非整数元素和 256 个元素，预期均中断渲染。
