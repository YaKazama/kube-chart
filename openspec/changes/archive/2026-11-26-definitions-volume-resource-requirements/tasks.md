# definitions.volumeResourceRequirements 任务

## 实施

- [x] T1 `templates/base/_k8s.tpl`：在现有 `base.quantity` 之后新增 `base.quantity.ge` 的整体契约注释与 `define` 块，接受两个 Quantity 字符串，按数值换算后比较，首个大于或等于第二个返回 `true`，非法 Quantity 中断；对应 `base.quantity.ge 数值化比较`、`失败消息归属`。
- [x] T2 `templates/api-resources/Definitions/_VolumeResourceRequirements.tpl`：新增 `definitions.volumeResourceRequirements`，按 `limits` → `requests` 顺序渲染，空 map 省略，值经 `base.map.verify` 校验后按原值输出，并仅对共同键用 `base.quantity.ge` 校验 `requests` 不超过 `limits`；对应 `字段顺序、空值省略与原值渲染`、`共同键比较`、`失败消息归属`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/`：加载真实 `base.*` 模板，直接验证 `base.quantity.ge`：`1Gi` 与 `1024Mi` 为 `true`，`2Gi` 与 `1Gi` 为 `true`，`500m` 与 `1` 为 `false`，非法 Quantity 中断。
- [x] V2 `/tmp/sd-kube-chart/`：仅 `limits`、仅 `requests`、以及两者均含共同键且请求不超过限制三种输入，输出字段顺序、空 map 省略与原值均符合规格。
- [x] V3 `/tmp/sd-kube-chart/`：共同键请求超过限制、非法 Quantity、非 map 类型均中断；仅 `requests` 独有键时不触发比较失败。
