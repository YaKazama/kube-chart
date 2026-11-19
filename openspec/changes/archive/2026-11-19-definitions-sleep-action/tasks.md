# 新增 definitions.sleepAction 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_SleepAction.tpl`：新增命名模板 `definitions.sleepAction` 及其契约注释，在 writable scope（整个新文件）内完成 `base.get` 取值、`fromYaml` 回读归一、缺失与空值跳过、int/int64/整值 float64 门禁、float64 域的 `[1, 9007199254740991]` 闭区间校验、`int` 归一与 `base.field` + `base.int` 渲染；对应 `Decision: 以 base.get 取值并经 fromYaml 回读归一`、`Decision: 在 float64 域完成整值与闭区间校验`、`Decision: 缺失、null 与空字符串统一为空输出`。

## 验证

- [x] V1 `/tmp/` fixture Chart：加载当前 change 的新增模板与 `base/`，以 `seconds: 30` 渲染出 `seconds: 30`；int64、`30.0`、12345678 的 float64 与 9007199254740991 同样按 integer 输出。
- [x] V2 `/tmp/` fixture Chart：`seconds` 缺失、为 `null`、为空字符串时输出为空内容且渲染不中断。
- [x] V3 `/tmp/` fixture Chart：0、-1、9007199254740992、`"30"`、true、list、map 与 3.7 均中断渲染。
- [x] V4 `/tmp/` fixture Chart：经 `definitions.lifecycleHandler` 的 `sleep` 委托时输出 `sleep` 字段片段，确认既有调用契约可渲染。
