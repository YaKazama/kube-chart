# 修正 definitions.volume 的 csi string 中 nodePublishSecretRef 为可选任务

## 实施

- [x] T1 `templates/base/_env.tpl`：把 `K8S.VOLUME.CSI` 的 `nodePublishSecretRef` 捕获组改为可选 `(?:\s+(\S+))?`，其余字符与组序不变；对应 `Decision: csi 位置段可选 secret 与枚举归属`。
- [x] T2 `templates/api-resources/Definitions/_Volume.tpl`：更新 `csi` 行内语法注释与解析分支，`$2` 命中枚举时写入 `fsType`、否则以原始字符串写入 `nodePublishSecretRef`，空捕获跳过键写入，枚举重复赋值中断，格式不匹配消息改为新位置段说明；对应 `Decision: csi 位置段可选 secret 与枚举归属`、`Decision: 空值与重复赋值失败边界`、`Decision: 错误消息同步`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小有效渲染：加载 `_env.tpl`、`_Volume.tpl` 及 base 依赖，提供 `definitions.csiVolumeSource` 回显 fixture，渲染 `csi: "driver.example"`，确认上下文只有 `driver` 且没有 `nodePublishSecretRef` 键；对应 `验证设计` 的最小有效项。
- [x] V2 `/tmp/sd-kube-chart/` 完整字符串渲染：覆盖 `driver.example regcred`、`driver.example ext4`、`driver.example EXT4 true`、`driver.example true`、`driver.example secret ext4 TRUE`、`driver.example secret ext4 TRUE attr (mode 0777, foo:bar)`、`driver.example "" xfs`、`driver.example attr (mode 0777, foo:bar)`，确认键存在性、枚举小写归一化与 attributes 处理；对应 `验证设计` 的较完整有效项。
- [x] V3 `/tmp/sd-kube-chart/` 关键失败：覆盖多余位置段、`driver.example ext4 xfs` 重复 `fsType`、空括号组与属性段缺少 value，确认全部中断且消息符合新语法；对应 `验证设计` 的关键失败项。
