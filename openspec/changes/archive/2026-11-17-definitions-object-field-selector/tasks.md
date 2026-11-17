# definitions.objectFieldSelector 任务

## 实施

- [x] T1 `templates/base/_env.tpl`：在 `K8S` 下新增 `FIELD_REF` 常量，允许列表为 `EnvVarSource.fieldRef` 与 `DownwardAPIVolumeFile.fieldRef` 的官方路径并集；对应 `fieldPath 用新增的 base.env 常量做支持列表校验`。
- [x] T2 `templates/api-resources/Definitions/_ObjectFieldSelector.tpl`：新增 define `definitions.objectFieldSelector`，按 `apiVersion` → `fieldPath` 顺序渲染；`apiVersion` 缺省不输出，`fieldPath` 自控判空并按 `K8S.FIELD_REF` 校验；对应 `单文件承载并按官方字段顺序渲染`、`apiVersion 缺省不输出`、`fieldPath 自控判空`、`fieldPath 用新增的 base.env 常量做支持列表校验`。

## 验证

- [x] V1 `/tmp/` 最小 Chart（真实 `templates/base/` 与两个已变更文件）：输入 `fieldPath: metadata.name`，渲染成功且输出只含 `fieldPath: "metadata.name"`，不含 `apiVersion`。
- [x] V2 同上：`apiVersion: v1` 与 `fieldPath: metadata.name` 齐全时按 `apiVersion`、`fieldPath` 顺序输出，均为双引号字符串。
- [x] V3 同上：`fieldPath` 分别为 `metadata.name`、`metadata.namespace`、`metadata.uid`、`spec.nodeName`、`spec.serviceAccountName`、`status.hostIP`、`status.podIP`、`status.podIPs`、`metadata.labels['app']`、`metadata.annotations['note']` 十个取值均渲染成功。
- [x] V4 同上：输入含未定义键 `foo` 时输出不含 `foo`。
- [x] V5 同上：`fieldPath` 缺失、`fieldPath` 为空白、`metadata.labels['']`、`spec.containers[0].name`、`status.podIPs[0]`、`metadata.labels`、`Metadata.Name`、`metadata.UID`、`spec.nodename` 九种输入分别 `helm template` 失败，失败消息符合预期。
