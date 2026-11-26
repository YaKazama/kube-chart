# core.persistentVolumeClaimSpec 任务

## 实施

- [x] T1 `templates/api-resources/Core/_PersistentVolumeClaimSpec.tpl`：新增 `core.persistentVolumeClaimSpec`，按官方顺序实现 `accessModes`、`dataSource`、`dataSourceRef`、`resources`、`selector`、`storageClassName`、`volumeAttributesClassName`、`volumeMode`、`volumeName` 的取值、校验与渲染，仅写入该文件；对应 `原生 map 与官方字段顺序`、`accessModes 逐项枚举校验`、`标量与 volumeMode 处理`、`子结构委托`、`空输入输出`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小有效与空输入：仅提供 `accessModes` 时输出单个 `accessModes` 字段；空 map 输出空内容。
- [x] V2 `/tmp/sd-kube-chart/` 完整输入：九个字段按官方顺序输出并支持别名；三个不可用子模板使用同名最小 fixture，`selector` 使用真实 `definitions.labelSelector` 且 `matchLabels` 非空。
- [x] V3 `/tmp/sd-kube-chart/` 关键失败：字符串形式的 `accessModes`、非字符串元素、非法访问模式、非法 `volumeMode`、非字符串标量以及 fixture 返回非法 YAML 均中断渲染。
