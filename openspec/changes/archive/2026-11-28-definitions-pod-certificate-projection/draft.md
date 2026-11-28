---
change-id: definitions-pod-certificate-projection
updated_at: "2026-11-28T09:39:18Z"
---

# definitions.podCertificateProjection

## 目标

- 新增命名模板 `definitions.podCertificateProjection`，用于渲染 Kubernetes core/v1 `PodCertificateProjection`。

## 需求

- 字段按官方定义，按官方字段顺序 `certificateChainPath`、`credentialBundlePath`、`keyPath`、`keyType`、`maxExpirationSeconds`、`signerName`、`userAnnotations` 渲染。
- `signerName` 与 `keyType` 必填；其余字段可选。
- `keyType` 为枚举，只允许 `RSA3072`、`RSA4096`、`ECDSAP256`、`ECDSAP384`、`ECDSAP521`、`ED25519`。
- `maxExpirationSeconds` 为整数秒，范围 3600–7862400；未提供时省略，由 API 默认 86400 秒。
- `userAnnotations` 为 map 类型，键与值均为 string；键必须为带 DNS 子域前缀的限定名 `<prefix>/<name>`，prefix 不超过 253 字符，name 符合注解键名称语法。
- 所有字段类型非法时中断渲染。
- `keyPath`、`certificateChainPath`、`credentialBundlePath` 均为相对路径。
- 文件布局至少配置一种：`credentialBundlePath` 单文件方式，或 `keyPath` 与 `certificateChainPath` 双文件方式；双文件方式的两个字段必须同时出现或同时缺失；两种方式可同时配置。

## 期望输入格式

- 模板上下文为原生 map。

## 约束

- 实现使用简洁直白的写法，避免无必要的中间片段或重复结构。

## 非目标

## 验收

- 调用该模板可得到合法的 `PodCertificateProjection`，字段按官方定义与官方顺序输出。
- 仅配置单文件方式、仅配置双文件方式或两种方式全配均可正常渲染。
- 双文件字段只配置一个、或两种方式都未配置时中断渲染。
- 非法 `keyType`、越界 `maxExpirationSeconds`、非 string 的 `userAnnotations` 键值、缺少域名前缀或不符合限定名语法的 `userAnnotations` 键，或任一字段类型非法时中断渲染。
- 三个路径字段保持相对路径。
