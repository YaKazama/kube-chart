# PodAffinityTerm 共享结构任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_PodAffinityTerm.tpl`：新建文件并在 `writable-scopes` 内 `add` 紧邻 `define` 之前的中文整体契约注释与 `define "definitions.podAffinityTerm"`，注释覆盖入参六字段、`*Alias` 识别、字段输出顺序、失败边界与返回值为可 `fromYaml` 回收的 map 文本；对应 `Decision: 目标文件与命名模板归属`、`Decision: 返回值形态`。
- [x] T2 `templates/base/_k8s.tpl`：在 `writable-scopes` 内 `add` 紧邻 `define` 之前的中文契约注释与 `define "base.labelKey"`：`kindOf` 类型门禁、`trim`、单斜杠 `splitList` 拆分、段数超 2 时 `fail`、`base.string.verify` 搭配 `K8S.SELECTOR.KEY_NAME_FOR_APPS` 校验名称段、存在前缀段时搭配 `K8S.SELECTOR.KEY_PREFIX_FOR_APPS` 校验并在超过 253 字符时 `fail`、通过后返回 trim 后的原值；对应 `Decision: 标签键校验公共能力`。
- [x] T3 `templates/api-resources/Definitions/_PodAffinityTerm.tpl`：在 `writable-scopes` 内按顺序逐字段实现 `labelSelector` 与 `namespaceSelector`：`base.get` 取值、trim 判空跳过、`fromYaml` 与 `base.isFromYamlError` 保护、`kindIs "map"` 判定、空 map 跳过、只读委托 `definitions.labelSelector`、返回值错误保护、`base.field` 搭配 `base.map` 输出，并补齐各自字段的中文注释；对应 `Decision: 逐字段顺序处理`、`Decision: 选择器字段的取值、委托与空值跳过`。
- [x] T4 `templates/api-resources/Definitions/_PodAffinityTerm.tpl`：在 `writable-scopes` 内按顺序逐字段实现 `matchLabelKeys`、`mismatchLabelKeys`、`namespaces`、`topologyKey`：键数组使用 `fromYamlArray` 与 `base.isFromYamlArrayError`、逐项 `toString` 后 trim、空项跳过、经 `base.labelKey` 校验、`mustUniq` 去重、`base.field` 搭配 `base.slice` 输出；`namespaces` 使用 `fromYamlArray` 与 `base.isFromYamlArrayError`、`base.slice.cleanup` 搭配 `SPLIT.SPACE_COMMA` 拆分清洗、逐项 `base.string.verify` 搭配 `RFC.RFC1123` 校验、`mustUniq` 去重、`toStrings` 归一、`base.field` 搭配 `base.slice` 输出；`topologyKey` 使用 `base.get` 必填取值、`fromYaml (printf "v: %s")` 类型门禁、`SYS.YAML_QUOTED` 去引号、经 `base.labelKey` 校验、`base.field` 搭配 `base.rawString` 输出，并补齐各自字段的中文注释；对应 `Decision: 键数组的归一化与去重`、`Decision: namespaces 的拆分、校验与去重`、`Decision: topologyKey 必填取值与类型门禁`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（装载真实 `definitions.labelSelector`、`definitions.labelSelectorRequirement`、`base.labelKey`）：只提供 `topologyKey: zone`，验证输出只含 `topologyKey`。
- [x] V2 `/tmp/` 最小 application Chart（真实依赖）：提供用户示例六字段，验证输出顺序为 `labelSelector`、`matchLabelKeys`、`mismatchLabelKeys`、`namespaceSelector`、`namespaces`、`topologyKey`，`namespaces` 中 `aaa bbb` 拆分为 `aaa`、`bbb`，`matchLabelKeys: []` 不输出该字段。
- [x] V3 `/tmp/` 最小 application Chart（真实依赖）：`labelSelector`/`namespaceSelector` 分别为缺失、`null`、空 map，验证不输出对应字段；`matchLabelKeys` 与 `mismatchLabelKeys` 含重复项与空字符串项时去重去空；`namespaces` 含逗号分隔、首尾与中间空白项、重复项时正确清洗；`topologyKeyAlias` 覆盖 `topologyKey`，空 `labelSelectorAlias` 回退 `labelSelector`，`topologyKey` 带首尾空白时输出 trim 后的值。
- [x] V4 `/tmp/` 最小 application Chart（真实依赖）：`topologyKey` 分别为缺失、`null`、空字符串、布尔、数值、map、list、`-zone`、`zone-`、`Zone Key`、`a/b/c`、名称段 64 字符，逐一验证渲染中断并断言错误前缀；`labelSelector` 为字符串或 list、`matchLabelKeys` 为字符串或 map、`matchLabelKeys` 含 `-app`、`namespaces` 为字符串或含 `Bad_Name`，逐一验证渲染中断并断言 `[base.get]`、`[base.labelKey]`、`[base.string.verify]` 或 `[definitions.podAffinityTerm]` 前缀与字段名。
- [x] V5 静态检查：`templates/api-resources/Definitions/_PodAffinityTerm.tpl` 与 `templates/base/_k8s.tpl` 均无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
