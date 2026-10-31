# Apps Deployment 任务

## 实施

- [x] T1 `templates/api-resources/Apps/_Deployment.tpl`：按依赖顺序输出单个 Deployment，原地设置 `_kind`，并为 metadata 与 spec 实现 `fromYaml` 错误保护和 `base.map` 渲染委托；对应 `原地设置资源身份`、`结构化子模板输出恢复` 和 `map 类型失败归属`。
- [x] T2 `openspec/rules/helm-templates.md`：明确结构化输出的解析错误保护、单一目标类型门禁和多类型分支职责；对应 `map 类型失败归属`。
- [x] T3 `openspec/rules/core-capabilities.md`：明确 `base.field` 调用方与最终 `base.*` 渲染模板的类型校验职责；对应 `map 类型失败归属`。
- [x] T4 `templates/api-resources/Apps/_Deployment.tpl`：在 metadata 与 spec 各自的 `base.isFromYamlError` 检查之后、调用 `base.field` 之前增加显式非空检查，并以字段级错误中断空字符串、`null` 或空 map；对应 `结构化子模板输出恢复`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：加载 `apps.deployment` 与真实直接依赖，实际执行 `helm template`，验证最小有效和较完整有效输入输出单个字段顺序正确的 `apps/v1` Deployment。
- [x] V2 `/tmp/` 最小 application Chart：使用 metadata/spec 同名 fixture 返回无效、list 或 scalar YAML，实际执行 `helm template`，验证对应字段以 `[apps.deployment]` 解析错误失败。
- [x] V3 `/tmp/` 最小 application Chart：使用 metadata/spec 同名 fixture 返回空字符串、`null` 和空 map，实际执行 `helm template`，验证对应字段在解析错误检查后以必填非空错误失败。
- [x] V4 `openspec/rules/helm-templates.md`、`openspec/rules/core-capabilities.md`：静态核对并统一单一目标类型与多类型分支的校验职责。
