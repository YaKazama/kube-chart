# core.podTemplateSpec 任务

## 实施

- [x] T1 `templates/api-resources/Core/_PodTemplateSpec.tpl`：新建文件并实现 `core.podTemplateSpec` 命名模板、整体契约注释、`_kind` 原地写入、`metadata` 与 `spec` 两个字段功能块及紧邻字段注释，子模板调用不含错误捕获或必填断言；对应 `目录与命名空间归属`、`入参为透传上下文`、`资源身份原地写入`、`_pkind 只透传不处理`、`metadata 委托与省略条件`、`spec 委托与省略条件`、`不承担必填校验`、`按 API 字段顺序输出`。

## 验证

- [x] V1 `templates/api-resources/Core/_PodTemplateSpec.tpl`：在 `/tmp/` 最小 application Chart 中加载本模板与真实 `definitions.objectMeta`，以同名最小 fixture 提供 `core.podSpec` 并返回最小 `PodSpec`，执行 `helm template` 断言输出含 `metadata` 与 `spec` 且顺序为 `metadata` 在前；对应 `PodTemplateSpec 结构渲染`。
- [x] V2 `templates/api-resources/Core/_PodTemplateSpec.tpl`：fixture 返回多字段 `PodSpec`，并在上下文提供 `podAnnotations`、`labels` 等数据，断言 `spec` 完整透传且 `metadata` 走 PodTemplateSpec 专用注解来源、不含 `name` 与 `namespace`；对应 `PodTemplateSpec 结构渲染`。
- [x] V3 `templates/api-resources/Core/_PodTemplateSpec.tpl`：fixture 分别返回空输出、非法 YAML 与两者组合，断言对应字段被省略且渲染不中断，两者均空时输出为空；对应 `子模板无有效输出时省略字段`。
- [x] V4 `templates/api-resources/Core/_PodTemplateSpec.tpl`：fixture 返回数组与标量等非 map 内容，断言 `spec` 被省略且渲染不中断，并确认当前 Helm 版本下此类输出不进入 `base.map` 类型门禁；对应 `子模板无有效输出时省略字段`。
- [x] V5 `templates/api-resources/Core/_PodTemplateSpec.tpl`：父级上下文预置非空 `_pkind`，断言渲染成功、输出不含 `_pkind` 且该值原样透传给子模板；对应 `PodTemplateSpec 结构渲染`。
- [x] V6 `templates/api-resources/Core/_PodTemplateSpec.tpl`：fixture 的 `core.podSpec` 内部 `fail`，断言渲染中断、错误向上传播且未降级为省略 `spec`；对应 `子模板无有效输出时省略字段`。
