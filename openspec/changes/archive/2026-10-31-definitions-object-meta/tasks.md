# definitions.objectMeta 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_ObjectMeta.tpl`：实现 map 上下文保护、`_pkind` 优先的身份解析、五字段输出顺序和 annotations 专用来源；对应 `上下文身份与输出边界`、`annotations 来源隔离`。
- [x] T2 `templates/api-resources/Definitions/_ObjectMeta.tpl`：实现 `generateName` 与 `name` 互斥、`1035` 校验和失败传播；对应 `generateName 与 name 互斥`。
- [x] T3 `templates/api-resources/Definitions/_ObjectMeta.tpl`：实现 `name` 的 `rbac`、`apiservice`、默认模式及嵌套模板排除；对应 `name 资源模式`。
- [x] T4 `templates/api-resources/Definitions/_ObjectMeta.tpl`：实现 `labels` 委托与返回校验、`namespace` 委托与身份排除；对应 `labels 委托`、`namespace 委托与资源边界`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：普通资源身份仅提供 `name`，验证默认 `labels`、`namespace` 和字段顺序。
- [x] V2 `/tmp/` 最小 application Chart：验证 `_pkind` 覆盖、三种专用注解、通用注解忽略、显式空 `name` 启用 `generateName`、RBAC 与 `APIService` 模式、PVC 和嵌套模板排除。
- [x] V3 `/tmp/` 最小 application Chart：验证非 map 上下文、注解非 map 或非 string、`generateName` 校验失败、`base.name` 与 `base.namespace` 拒绝的关键失败场景。
- [x] V4 `/tmp/` 最小 application Chart：使用同名 `base.labels` fixture 返回非法值，验证 `labels` 失败分支；该场景只证明调用方行为。
- [x] V5 `templates/api-resources/Definitions/_ObjectMeta.tpl`：检查空白、冲突标记和文件末尾单一换行。
