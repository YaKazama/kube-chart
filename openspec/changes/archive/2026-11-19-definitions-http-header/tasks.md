# definitions.httpHeader 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_HTTPHeader.tpl`，writable scope 为新文件完整内容：新增 `definitions.httpHeader`，按 `name`、`value` 顺序完成取值、string 归一、trim、非空校验与带引号渲染；对应 `Decision: 字段顺序、归一化与必填门禁` 与 `字段校验与输出`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：以带首尾空白的 `name`、`value` 调用 `definitions.httpHeader`，`helm template` 输出 trim 后的 `name`、`value` 且顺序正确。
- [x] V2 `/tmp/` 最小 application Chart：分别缺少 `name`、缺少 `value`、提供空字符串或仅含空白字符，`helm template` 均中断渲染。
- [x] V3 `/tmp/` 最小 application Chart：`name` 或 `value` 不是 string 时，`helm template` 中断渲染。
