# definitions.clusterTrustBundleProjection 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_ClusterTrustBundleProjection.tpl`：新增 `definitions.clusterTrustBundleProjection` 及紧邻中文契约注释，按官方顺序渲染 `labelSelector`、`name`、`optional`、`path`、`signerName`，落实互斥、相对路径、非空 `labelSelector` 委托、空 `labelSelector` 省略与非法输入中断；对应 `渲染字段与顺序`、`name 与 signerName 二选一`、`path 必填相对路径`、`labelSelector 委托与伴随约束`、`optional 布尔`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小 Chart：以 `{name: "trust-bundle", path: "ca.crt"}` 渲染，预期仅输出 `name` 与 `path` 且顺序正确。
- [x] V2 `/tmp/sd-kube-chart/` 最小 Chart：以 `{signerName: "example.com/signer", labelSelector: {matchLabels: {app: "web"}}, optional: false, path: "ca.crt"}` 渲染，预期按官方顺序输出 `labelSelector`、`optional: false`、`path`、`signerName`，且 `labelSelector` 由真实 `definitions.labelSelector` 渲染。
- [x] V3 `/tmp/sd-kube-chart/` 最小 Chart：验证缺失或空白 `path`、绝对路径、`../` 逃逸、`name` 与 `signerName` 同时或同时缺失、非空 `labelSelector` 缺少 `signerName`、`name` 与非空 `labelSelector` 并存、非空 `labelSelector` 非 map 或缺少 `matchLabels`、`optional` 非法值时均中断并报告字段错误。
- [x] V4 `/tmp/sd-kube-chart/` 最小 Chart：以 `labelSelector` 为 `{}`、null 与空字符串分别配合 `name` 或 `signerName` 渲染，预期均省略 `labelSelector` 且不中断，空 selector 不触发伴随校验。
