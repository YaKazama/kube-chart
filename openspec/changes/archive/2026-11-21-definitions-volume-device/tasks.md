# 新增 definitions.volumeDevice 模板任务

## 实施

- [x] T1 `templates/base/_env.tpl`：新增 `K8S.VOLUME_DEVICE` 固定正则常量；对应 `string 简写解析`。
- [x] T2 `templates/api-resources/Definitions/_Container.tpl`：新增 `definitions.container.array.normalize`，使用 `K8S.VOLUME_DEVICE` 按捕获组提取；扩展 `definitions.container.array` 的 `normalize` 与 `dedupe` 入参；更新 `definitions.container` 的 `volumeDevices` 调用与契约注释；对应 `父模板空间统一 string 归一化`、`父级去空与去重`、`调用契约`。
- [x] T3 `templates/api-resources/Definitions/_VolumeDevice.tpl`：新增 `definitions.volumeDevice`，实现 map/string 入口、空值与单字段缺失判断、`devicePath` 绝对路径校验、`name` RFC1123 Label 校验及 `devicePath`、`name` 顺序输出；对应 `string 简写解析`、`字段顺序、校验与空值`、`输出形态`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小 application Chart：加载真实 `_env.tpl`、`_Container.tpl`、`_VolumeDevice.tpl` 与 base 模板，验证 map、string、string array、混合数组、首尾/连续/混用分隔符、绝对路径归一化、完全重复去重、非完全重复保留、空项剔除与全部为空不输出；预期 `helm template` 成功且字段顺序与内容符合 spec。
- [x] V2 `/tmp/sd-kube-chart/` 最小 application Chart：加载真实 `_env.tpl`，验证单字段缺失、超过两个非空段、非法 `name`、相对 `devicePath`、非数组 `volumeDevices`、非法数组元素类型、直接调用非法上下文类型，以及直接调用 `definitions.volumeDevice` 的 map/string 等价与别名行为；预期按 spec 中断或输出一致。
