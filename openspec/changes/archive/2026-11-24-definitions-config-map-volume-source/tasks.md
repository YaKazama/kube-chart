# definitions.configMapVolumeSource 任务

## 实施

- [x] T1 `templates/base/_env.tpl`：更新 `SYS.FILE_MODE` 的十进制分支，接受十进制 `0`-`511` 全量（含单字符 `1`-`9`）；对应 `Decision: 文件模式公共能力更新`。
- [x] T2 `templates/base/_validate.tpl`：让 `base.fileMode` 的字符串分支返回十进制 int，并同步契约注释、返回值说明与示例；对应 `Decision: 文件模式公共能力更新`、`Decision: defaultMode 归一化`。
- [x] T3 `templates/api-resources/Definitions/_ConfigMapVolumeSource.tpl`：新增 `definitions.configMapVolumeSource` 命名模板、契约注释与错误消息前缀，实现字段顺序、`name` 校验、`defaultMode` 归一化、`items` 混合元素解析、`definitions.keyToPath` 调用与失败分支；对应 `Decision: 字段取值与空值语义`、`Decision: name 校验`、`Decision: defaultMode 归一化`、`Decision: items 解析与 keyToPath 委托`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 文件模式：加载真实 `_env.tpl` 与 `_validate.tpl`，验证 `base.fileMode` 对 `"0000"`、`"0777"`、`"0512"`、`"9"`、`"493"`、数值 `0` 与 `511` 的十进制结果（`"0512"` 为 330），以及 `"9999"`、`"0778"`、数值 `512` 中断；对应 `验证设计` 的文件模式项。
- [x] V2 `/tmp/sd-kube-chart/` 最小与完整渲染：加载真实 `_ConfigMapVolumeSource.tpl` 与 base 依赖，为 `definitions.keyToPath` 提供同名 fixture；验证只含 `name` 的最小输入，以及含 `defaultMode: "0755"`、`optional: false` 与混合 `items` 的完整输入的字段顺序和值；对应 `验证设计` 的最小有效与较完整有效项。
- [x] V3 `/tmp/sd-kube-chart/` 关键失败：覆盖 `name` 缺失/空/大写/超长、`defaultMode` 越界或非法、`items` 非数组、元素类型非法、string 元素段数不在 2-3、`optional` 非布尔，以及 `definitions.keyToPath` 返回空内容/非 map/非法 YAML；对应 `验证设计` 的关键失败项。
- [x] V4 `/tmp/sd-kube-chart/` 父级集成：用真实 `definitions.volume` 接收 configMap 字符串简写 `cm TRUE 0644 items (key path, key1 path1 0400)`，确认原始 item 字符串被本模板解析；`definitions.keyToPath` 仍为 fixture，只证明调用方行为；对应 `验证设计` 的集成边界项。
