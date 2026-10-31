# Apps DeploymentSpec 模板任务

## 实施

- [x] T1 `templates/api-resources/Apps/_DeploymentSpec.tpl`：新增 `apps.deploymentSpec` 整体契约与 integer、paused 字段的默认值、类型和边界闭环；对应 `标量字段闭环`。
- [x] T2 `templates/api-resources/Apps/_DeploymentSpec.tpl`：实现 selector 必填、字段清洗、基础标签左优合并、子模板返回保护和字段渲染；对应 `Selector 清洗与标签合并`。
- [x] T3 `templates/api-resources/Apps/_DeploymentSpec.tpl`：实现 strategy map/string 互斥归一化、集中正则捕获、空 map 传递、子模板返回保护和字段渲染；对应 `Strategy 多类型归一化`。
- [x] T4 `templates/api-resources/Apps/_DeploymentSpec.tpl`：实现原始上下文到 `core.podTemplateSpec` 的必填委托、返回保护和 template 渲染；对应 `PodTemplateSpec 委托`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：使用真实 base read boundary 和 unavailable 子模板 fixture，验证最小有效输入与建议默认值输出。
- [x] V2 `/tmp/` 最小 application Chart：验证较完整有效输入、整数字符串、显式零值与上限、负数抑制、空 selector、selector 合并以及 strategy map/string/空 map 分支。
- [x] V3 `/tmp/` 最小 application Chart：验证标量类型、integer 超限、selector 必填和类型、strategy 非法输入及子模板非法返回的关键失败场景。
- [x] V4 `templates/api-resources/Apps/_DeploymentSpec.tpl`：检查空白、冲突标记和文件末尾单一换行。
