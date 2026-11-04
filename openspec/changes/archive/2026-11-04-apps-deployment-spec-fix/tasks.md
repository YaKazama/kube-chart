# Deployment strategy 解析修复任务

## 实施

- [x] T1 `templates/base/_env.tpl`：把 `APPS.DEPLOYMENT.STRATEGY` 改为首槽可省略且接受显式空字符串的 3 槽全量匹配表达式，并删除 `APPS.DEPLOYMENT.ROLLING_UPDATE`；writable scope 为 `base.env` 定义体内 `APPS.DEPLOYMENT` 段；对应 `Decision: 常量合并且移除失效键`。
- [x] T2 `templates/api-resources/Apps/_DeploymentSpec.tpl`：string 分支改为先以 `fromYaml (printf "v: %s" <文本>)` 还原 YAML 标量，再单次全量匹配三槽捕获，逐槽剥离外层引号并 `trim`，`type` 为空取 `RollingUpdate`、非空归并为官方拼写，`maxSurge`、`maxUnavailable` 非空时写入 `rollingUpdate`，`type` 为 `Recreate` 时丢弃 `rollingUpdate`；writable scope 为 `apps.deploymentSpec` 定义体的 strategy 功能块；对应 `Decision: string 简写单次全量匹配三槽捕获`、`Decision: 捕获值剥离引号后归一化`。
- [x] T3 `templates/api-resources/Apps/_DeploymentSpec.tpl`：map 分支改用 `base.get` 分别取 `type`、`rollingUpdate`，`type` 缺失、`null` 或空字符串时补充 `RollingUpdate`，非空时按大小写不敏感归并为官方拼写、其他取值原样保留，`rollingUpdate` 仅在 `type` 非 `Recreate` 时读取、非 map 时中断、空 map 时丢弃，内部字段以 `mustDeepCopy` 原样透传；writable scope 为 `apps.deploymentSpec` 定义体的 strategy 功能块；对应 `Decision: map 分支只做容器级校验`。
- [x] T4 `templates/api-resources/Apps/_DeploymentSpec.tpl`：string 简写归一化后三项均为空时不调用子模板也不渲染 `strategy`，其余情况把归一化 map 交给 `apps.deploymentStrategy`，对返回字符串直接 `fromYaml` 恢复并仅保留空输出与 YAML 解析错误检查，最终 map 类型交由 `base.map` 门禁，失败前缀为 `[apps.deploymentSpec]`；writable scope 为 `apps.deploymentSpec` 定义体的 strategy 功能块；对应 `Decision: 归一化结果为空时不渲染字段`、`Decision: 委托目标切换为 apps.deploymentStrategy`。
- [x] T5 `templates/api-resources/Apps/_DeploymentSpec.tpl`：同步文件头整体契约注释中 strategy 的委托目标与解析说明，以及 strategy 功能块的紧邻字段注释；writable scope 为该文件头部整体契约注释的 strategy 条目与紧邻 strategy 功能块的字段注释；对应 `Decision: 委托目标切换为 apps.deploymentStrategy`、`Decision: map 分支只做容器级校验`。
- [x] T6 `openspec/references/template-snippets.md`：把「多类型字段规整」示例更新为 3 个捕获组并按规范槽位命名，同时修正该章节的常量读取说明；writable scope 为 `## 多类型字段规整` 章节的示例代码块与该章节末尾说明段；对应 `Decision: string 简写单次全量匹配三槽捕获`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：加载真实 `_DeploymentSpec.tpl`、真实 `_env.tpl` 与 `apps.deploymentStrategy` 同名 fixture，渲染 `RollingUpdate 1 30%`、`1 30%`、`1`，预期 `type: RollingUpdate` 且 `rollingUpdate` 字段集合分别含两项、两项、仅 `maxSurge`；对应 `Decision: string 简写单次全量匹配三槽捕获`。
- [x] V2 `/tmp/` 最小 application Chart：渲染 `RollingUpdate "" 30%`、`RollingUpdate '' 30%`、`"" 30%`、`'' 30%`、`"" 1 30%`、`'' 1 30%`，预期同义输入结果一致且空槽不产生对应键；对应 `Decision: 捕获值剥离引号后归一化`。
- [x] V3 `/tmp/` 最小 application Chart：渲染 `rollingupdate`、`RollingUpdate1`、`RollingUpdate "" ""` 与 `Recreate 1 30%`，预期分别为 `type: RollingUpdate`、与 `RollingUpdate 1` 结果一致、只含 `type`、只含 `type: Recreate`；对应 `Decision: 捕获值剥离引号后归一化`。
- [x] V4 `/tmp/` 最小 application Chart：渲染 `""`、`''`、`"" ""`、`'' ''` 与缺失 `strategy`，预期均不产生 `strategy` 字段；对应 `Decision: 归一化结果为空时不渲染字段`。
- [x] V5 `/tmp/` 最小 application Chart：渲染 map 输入 `{rollingUpdate: {maxSurge: 1}}`、`{type: recreate}`、`{}`（未提供 `type`）、`{rollingUpdate: 1}`、`{rollingUpdate: {}}`，预期依次为原样 `rollingUpdate` 加默认 `type`、`type: Recreate`、默认 `type`、中断、只含 `type: RollingUpdate`；对应 `Decision: map 分支只做容器级校验`。
- [x] V6 `/tmp/` 最小 application Chart：渲染 `BlueGreen`、`1 30% 5`、`1 30% 5 6`、`1.5`、`-1` 与非 string 非 map 输入，预期全部中断且失败消息前缀为 `apps.deploymentSpec`；对应 `Decision: string 简写单次全量匹配三槽捕获`。
- [x] V7 `/tmp/` 最小 application Chart：让 fixture 分别返回空输出、`null`、无效 YAML 与非 map，预期当前模板全部中断并输出 `[apps.deploymentSpec]` 前缀消息；对应 `Decision: 委托目标切换为 apps.deploymentStrategy`。
- [x] V8 `templates/api-resources/Apps/_DeploymentSpec.tpl`、`templates/base/_env.tpl` 与 `openspec/references/template-snippets.md`：检查空白、冲突标记和文件末尾单一换行，并确认 `APPS.DEPLOYMENT.ROLLING_UPDATE` 已无残留引用。
