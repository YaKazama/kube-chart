# Deployment 部署策略任务

## 实施

- [x] T1 `templates/api-resources/Apps/_DeploymentStrategy.tpl`：新建 `apps.deploymentStrategy` 命名模板、整体契约注释、`rollingUpdate` 与 `type` 两个字段功能块及紧邻字段注释；writable scope 为该文件全部内容；对应 `Decision: 入参形态与字段读取`、`Decision: type 空值归一化`、`Decision: type 为空时不渲染字段，仅驱动 rollingUpdate 判定`、`Decision: type 非空时经 base.field 完成枚举校验`、`Decision: rollingUpdate 生效条件与委托`、`Decision: 按 API 字段顺序输出 rollingUpdate 后 type`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：加载真实 `_DeploymentStrategy.tpl`、`_env.tpl`、`_get.tpl`、`_convert.tpl`、`_field.tpl`、`_types.tpl` 与 `apps.rollingUpdateDeployment` 同名 fixture，渲染 `{type: "RollingUpdate"}`、`{type: "Recreate"}`，预期均只输出 `type`；对应 `Decision: type 非空时经 base.field 完成枚举校验`。
- [x] V2 `/tmp/` 最小 application Chart：渲染 `{type: null}`、`{type: ""}`、`{type: null, rollingUpdate: {maxSurge: 1}}`、`{type: "", rollingUpdate: {maxSurge: 1}}` 与 `{rollingUpdate: {maxSurge: 1}}`，预期均不输出 `type` 且不失败，带非空 `rollingUpdate` 时只输出 `rollingUpdate`；对应 `Decision: type 空值归一化`、`Decision: type 为空时不渲染字段，仅驱动 rollingUpdate 判定`。
- [x] V3 `/tmp/` 最小 application Chart：渲染 `{type: "RollingUpdate", rollingUpdate: {maxSurge: 1, maxUnavailable: "30%"}}` 与 `{type: "Recreate", rollingUpdate: {maxSurge: 1}}`，预期前者输出 `rollingUpdate` 与 `type` 且顺序为 `rollingUpdate` 在前，后者只输出 `type: Recreate` 且不失败；对应 `Decision: rollingUpdate 生效条件与委托`、`Decision: 按 API 字段顺序输出 rollingUpdate 后 type`。
- [x] V4 `/tmp/` 最小 application Chart：渲染 `type` 为 `Recreate` 且 `rollingUpdate` 为字符串的入参，预期只输出 `type: Recreate`，`apps.rollingUpdateDeployment` fixture 未被调用；对应 `Decision: rollingUpdate 生效条件与委托`。
- [x] V5 `/tmp/` 最小 application Chart：分别渲染空 map、`{rollingUpdate: {}}` 与未提供入参，预期全部为空输出且不失败；对应 `Decision: 入参形态与字段读取`、`Decision: rollingUpdate 生效条件与委托`。
- [x] V6 `/tmp/` 最小 application Chart：渲染 `{type: "Recreate", unknown: "x"}`，预期只输出 `type: Recreate`，不输出 `unknown`；对应 `Decision: 入参形态与字段读取`。
- [x] V7 `/tmp/` 最小 application Chart：渲染 `type` 为 `rollingupdate`、`recreate`、`BlueGreen`，预期全部中断渲染且失败消息包含 `Recreate`、`RollingUpdate`；对应 `Decision: type 非空时经 base.field 完成枚举校验`。
- [x] V8 `/tmp/` 最小 application Chart：`apps.rollingUpdateDeployment` fixture 返回空输出时预期不渲染 `rollingUpdate`、不失败，`type` 非空时仍输出 `type`；分别返回无效 YAML、YAML 标量与 YAML 数组时预期全部中断渲染；对应 `Decision: rollingUpdate 生效条件与委托`。
