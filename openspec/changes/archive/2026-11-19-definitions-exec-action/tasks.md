# definitions.execAction 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_ExecAction.tpl`：在 writable scope 整个新文件内新增 `definitions.execAction`，实现 `command` 必填取值、空值不渲染、元素类型校验、`base.slice` 输出及仅输出 `command`；对应 `Decision: command 取值与必填校验`、`Decision: command 元素校验与渲染`、`Decision: 单字段输出边界`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：以单个字符串 `command` 渲染 `definitions.execAction`，预期 `helm template` 成功且仅输出 `command` 字段。
- [x] V2 `/tmp/` 最小 application Chart：渲染包含空格、逗号与空字符串的多元素 `command`，预期元素不拆分、顺序和内容保持；同时验证空 array 不产生输出。
- [x] V3 `/tmp/` 最小 application Chart：执行 `command` 缺失、`command` 不是 array、存在非 string 元素场景，预期 `helm template` 非零退出并命中对应错误。
