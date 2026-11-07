# fix-kindis-check 任务

## 实施

- [x] T1 `templates/api-resources/Apps/_DeploymentSpec.tpl`：把 `strategy` 字段中 `if and (not $_strategyIsError) (kindIs "map" $_strategyParsed)` 改为 `if not $_strategyIsError`，保留 `else` 字符串简写分支与 `rollingUpdate` 分支的类型门禁；对应 `Decision: strategy 分支删除重复类型判断`、`Decision: rollingUpdate 分支保留类型门禁`。
- [x] T2 `templates/base/_k8s.tpl`：把 `base.labels` 中 `customLabels` 与 `helmLabels` 两处 `if and <parsed> (eq (include "base.isFromYamlError" <parsed>) "false") (kindIs "map" <parsed>)` 改为 `if and <parsed> (eq (include "base.isFromYamlError" <parsed>) "false")`，保留非空判断与错误 helper；对应 `Decision: base.labels 删除两处重复类型判断`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：以同一组输入分别在修改前与修改后渲染 `base.labels`，覆盖仅自定义 `labels`、仅 `helmLabels`、两者同时存在、`justNameLabel=true`、`labels` 为非 map 标量五类输入，输出与失败结果完全一致。
- [x] V2 `/tmp/` 最小 application Chart：以同一组输入分别在修改前与修改后渲染 `apps.deploymentSpec`，覆盖 `strategy` 为 map、字符串简写、`null`、非法标量四类输入，输出与失败消息完全一致。
- [x] V3 `/tmp/` 最小 application Chart：对 `templates/` 下全部 `*.tpl` 重新扫描错误 helper 之后的同类 `kindIs`，确认剩余命中仅为 `_PodSpec.tpl` 的 `os` 多类型分支、`_DeploymentSpec.tpl` 的 `rollingUpdate` 类型门禁、`_get.tpl` 的标量空值判定与 `Definitions` 中 map 值类型校验。
- [x] V4 静态检查：两个修改文件无冲突标记、无行尾空白、末尾单换行。
