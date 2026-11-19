# definitions.containerRestartRule 任务

## 实施

- [x] T1 `templates/base/_env.tpl`：将 `K8S.CONTAINER_RESTART_RULE` 更新为捕获任意非空 operator token、不限制 `in` / `notin` 的完整匹配表达式，并同步紧邻注释；对应 `Decision: operator 原样下传`。
- [x] T2 `templates/api-resources/Definitions/_ContainerRestartRule.tpl`：完成 string 与 map 分派、action 归一化、operator 原样下传、values 整数化、`exitCodes` 委托，以及子模板空结果中断；同步文件契约注释；对应 `Decision: 上下文类型分派`、`Decision: action 归一化`、`Decision: exitCodes 构造与委托`、`Decision: values 整数归一`、`Decision: map 未知键忽略`。
- [x] T3 `templates/api-resources/Definitions/_Container.tpl`：在 `restartPolicyRules` 的 `definitions.container.array` 调用中开启 `"allowString" true`，并同步该字段的整体契约注释与字段注释；对应 `Decision: 父模板开放 string 元素`。

## 验证

- [x] V1 `/tmp/` 最小 Chart 加载真实 `templates/base/`、`_ContainerRestartRule.tpl`，并以同名 fixture 替代 `definitions.containerRestartRuleOnExitCodes`；渲染 map 上下文 `{action: restart, exitCodes: {operator: in, values: [1]}}`，预期输出 `action: "Restart"` 与 `exitCodes`，且 `action` 在 `exitCodes` 之前。
- [x] V2 同 V1 环境渲染 string `restart Once (0, 1, 2)`，预期 `action: "Restart"` 且 fixture 收到 `{operator: Once, values: [0, 1, 2]}`；渲染 `RESTART NotIn (7)`，预期 fixture 收到 `operator: NotIn`。
- [x] V3 同 V1 环境执行关键失败输入：`{action: stop}`、缺少 `action`、缺少 `exitCodes`、`restart in ()`、`restart notin 1, 2`、`restart in (a, 1)`、空 string，以及 fixture 返回空内容，预期全部中断。
- [x] V4 `/tmp/` 最小 Chart 加载真实 `templates/base/` 与 `_Container.tpl`，并以同名 fixture 替代依赖；渲染 `restartPolicyRules: ["restart in (1, 2)"]`，预期 string 元素被接受并交给 `definitions.containerRestartRule`；渲染 `restartPolicyRules: [1]`，预期中断。
