# definitions.podCertificateProjection 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_PodCertificateProjection.tpl`：新增 `definitions.podCertificateProjection` 及紧邻中文契约注释，按官方顺序渲染七个字段，落实路径相对性与文件布局约束、`signerName`/`keyType` 必填与枚举、`maxExpirationSeconds` 范围、`userAnnotations` 键值校验与类型中断；对应 `渲染字段与顺序`、`signerName 与 keyType 必填`、`文件布局与相对路径`、`maxExpirationSeconds 范围`、`userAnnotations 键校验`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小 Chart：以 `{signerName: "example.com/signer", keyType: "RSA3072", credentialBundlePath: "credential-bundle.pem"}` 渲染，预期按 `credentialBundlePath`、`keyType`、`signerName` 顺序输出。
- [x] V2 `/tmp/sd-kube-chart/` 最小 Chart：分别以仅双文件布局和全量输入渲染，预期双文件两个路径均输出，全量输入按 `certificateChainPath`、`credentialBundlePath`、`keyPath`、`keyType`、`maxExpirationSeconds`、`signerName`、`userAnnotations` 顺序输出。
- [x] V3 `/tmp/sd-kube-chart/` 最小 Chart：验证双文件字段不成对、未配置任何布局、绝对路径与路径字段类型非法时均中断并报告对应错误。
- [x] V4 `/tmp/sd-kube-chart/` 最小 Chart：验证缺失 `signerName`/`keyType`、非法 `keyType`、`maxExpirationSeconds` 越界或非整数、`userAnnotations` 非 map、值非 string、键缺少前缀或键语法非法、其他字段类型非法时均中断并报告对应错误。
