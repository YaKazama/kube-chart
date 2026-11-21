# definitions.capabilities 任务

## 实施

- [x] T1 `templates/base/_env.tpl`：在 `SPLIT` 下新增 `SPACE_COMMA_SEMICOLON`，在 `K8S` 下新增 `CAPABILITY_NAME`；对应 `Decision: 拆分、校验与归一`。
- [x] T2 `templates/api-resources/Definitions/_Capabilities.tpl`：新增 `definitions.capabilities`，实现 `add`、`drop` 的类型门禁、拆分、校验、大写归一、去重与按序渲染；对应 `Decision: 同构字段顺序处理`、`Decision: 输入解析与类型门禁`、`Decision: 拆分、校验与归一`、`Decision: 空字段与渲染`。
- [x] T3 `templates/api-resources/Definitions/_SecurityContext.tpl`：更新 `capabilities` 相关注释，移除“模板不存在”和“由后续 change 实现”等过期描述，不改委托逻辑；对应 `Requirement: capability 名称校验与归一`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小 fixture：`add: [net_admin]` 输出 `NET_ADMIN`。
- [x] V2 `/tmp/sd-kube-chart/` 较完整 fixture：同时提供 `add`、`drop`，覆盖 `CAP_` 前缀、复合分隔字符串、首尾或连续分隔符与重复项，确认字段顺序、拆分和归一化后去重。
- [x] V3 `/tmp/sd-kube-chart/` 关键失败 fixture：非空字符串 `add`、非 string 元素、含 `-` 的名称分别中断。
- [x] V4 `/tmp/sd-kube-chart/` 集成 fixture：通过真实 `definitions.securityContext` 的 `capabilities` 字段渲染，确认输出可解析。
