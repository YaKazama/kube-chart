# RollingUpdateDeployment 任务

## 实施

- [x] T0 `templates/base/_get.tpl`：在 `base.get` 的“处理第一个有效值”分支把 `kindIs "invalid"` 与空字符串一并视为未命中并 `continue`，同步整体契约注释“标量取首个非空值（显式 null 视为空）”；对应 `Decision: base.get 将显式 null 归并为空值`。
- [x] T1 `templates/base/_env.tpl`：在 `APPS` 下新增 `ROLLING_UPDATE` 映射，包含 `MAX_SURGE`（`^\d+(?:%)?$`）与 `MAX_UNAVAILABLE`（`^(?:\d+|0*(?:100|\d{1,2})%)$`）两个键，按 YAML 双引号转义 `\d`；对应 `Decision: 独立正则集中定义`。
- [x] T2 `templates/api-resources/Apps/_RollingUpdateDeployment.tpl`：新增 `apps.rollingUpdateDeployment` 整体契约注释与 `define` 块，用 `base.get` 读取 `maxSurge`、`maxUnavailable`，经 `SYS.YAML_QUOTED` 剥离引号并 `trim` 归一化，空值跳过；对应 `Decision: 入参形态与字段读取`、`Decision: 取值归一化与空值判据`。
- [x] T3 `templates/api-resources/Apps/_RollingUpdateDeployment.tpl`：为两个字段分别按 `APPS.ROLLING_UPDATE.MAX_SURGE`、`APPS.ROLLING_UPDATE.MAX_UNAVAILABLE` 校验，不匹配时 `fail`；对应 `Decision: 小数与非法形态失败`、`Decision: 独立正则集中定义`。
- [x] T4 `templates/api-resources/Apps/_RollingUpdateDeployment.tpl`：两个字段都生效且各自用 `trimAll` 折叠前导零后为空时整体返回空输出；否则按 `maxSurge`、`maxUnavailable` 顺序调用 `base.field`，渲染模板统一为 `base.rollingUpdate`；对应 `Decision: 零值判定用 trimAll 折叠前导零`、`Decision: 双零取值整体省略`、`Decision: base.rollingUpdate 作为渲染模板完成二次格式校验`、`Decision: 按 API 字段顺序输出`。

## 验证

- [x] V0 `/tmp/` 最小 application Chart：加载真实 `_get.tpl`，分别以 `maxSurge: null`、`maxSurge: ~`、空值键 `maxSurge:`、`maxUnavailable: null` 调用 `base.get`，预期均为空输出；以 `maxSurge: 'null'` 与 `{maxSurgeAlias: null, maxSurge: 5}` 验证引号字符串仍为 string、空别名仍回退规范键；对应 `Decision: base.get 将显式 null 归并为空值`。
- [x] V1 `/tmp/` 最小 application Chart：加载真实 `_RollingUpdateDeployment.tpl`、`_env.tpl`、`_get.tpl`、`_k8s.tpl`、`_field.tpl` 与 `_DeploymentStrategy.tpl`，渲染 `{maxSurge: 1}`、`{maxUnavailable: "25%"}` 与空 map，预期依次只输出对应单字段、空输出；对应 `Decision: 入参形态与字段读取`、`Decision: 取值归一化与空值判据`。
- [x] V2 `/tmp/` 最小 application Chart：渲染 `{maxSurge: 3, maxUnavailable: "30%"}`，预期 `maxSurge` 在前且两个字段均输出；渲染 `{maxSurge: "150%"}` 与 `{maxUnavailable: 150}`，预期均正常输出；渲染 `{maxSurge: 0}`，预期输出 `maxSurge: 0`；对应 `Decision: 按 API 字段顺序输出`、`Decision: base.rollingUpdate 作为渲染模板完成二次格式校验`。
- [x] V3 `/tmp/` 最小 application Chart：渲染 `{maxUnavailable: "101%"}`、`{maxSurge: 1.5}`、`{maxSurge: "-1"}`、`{maxSurge: "abc"}`，预期全部中断渲染；渲染 `{maxSurge: 1.0}`，预期输出 `maxSurge: 1`；对应 `Decision: 小数与非法形态失败`、`Decision: 原生浮点 1.0 不单独判定`、`Decision: 独立正则集中定义`。
- [x] V4 `/tmp/` 最小 application Chart：渲染 `{maxSurge: 0, maxUnavailable: 0}`、`{maxSurge: "0%", maxUnavailable: "0%"}`、`{maxSurge: 0, maxUnavailable: "0%"}`，预期 `strategy` 均不含 `rollingUpdate` 且不失败；对应 `Decision: 零值判定用 trimAll 折叠前导零`、`Decision: 双零取值整体省略`。
