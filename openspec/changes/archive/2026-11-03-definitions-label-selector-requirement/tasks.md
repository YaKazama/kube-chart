# Definitions LabelSelectorRequirement 任务

## 实施

- [x] T1 `templates/base/_env.tpl`：在 `K8S.SELECTOR` 下新增 `KEY_NAME_FOR_APPS` 与 `KEY_PREFIX_FOR_APPS` 两个常量，值分别为名称段与前缀段正则，不动其余常量；对应 `Decision: 标签键正则作为项目固定常量新增`。
- [x] T2 `templates/api-resources/Definitions/_LabelSelectorRequirement.tpl`：新增中文整体契约注释与 `define "definitions.labelSelectorRequirement"`，按 `key`、`operator`、`values` 顺序实现字段闭环，`key` 与 `operator` 在入口显式校验缺失与 string 类型，`key` 按单个 `/` 拆分后分段校验并区分失败消息归属，`operator` 以允许值列表委托 `base.field`，`values` 仅在非空时委托 `base.field` 与 `base.slice`；对应 `Decision: 新增模板文件与 define 名称`、`Decision: 直接读取入参 map 字段并显式校验类型`、`Decision: 按单个斜杠拆分并分段校验`、`Decision: key 使用 base.rawString 渲染`、`Decision: operator 枚举交由 base.field 允许值列表`、`Decision: values 只按非空生效并委托渲染能力`、`Decision: 不实现 fromYamlArray 错误保护`、`Decision: 失败消息前缀按来源区分`。

## 验证

- [x] V1 `/tmp/` 最小 Chart 加载真实 `_env.tpl`、base 模板与新模板，执行 `helm template` 断言最小有效与较完整有效：`{key: app, operator: Exists}` 只输出 `key` 与 `operator`；`{key: app.kubernetes.io/name, operator: In, values: [web, api]}` 按 `key`、`operator`、`values` 顺序输出且 `values` 为 string array；`key` 为 `app.kubernetes.io` 时通过校验。
- [x] V2 `/tmp/` 最小 Chart 加载真实 `_env.tpl`、base 模板与新模板，执行 `helm template` 断言入口失败：`key` 缺失、`key` 为 int、`operator` 缺失、`operator` 为 int 均失败，且失败消息带 `[definitions.labelSelectorRequirement]` 前缀与对应字段路径。
- [x] V3 `/tmp/` 最小 Chart 加载真实 `_env.tpl` 与新模板，执行 `helm template` 断言 key 长度边界：名称段 63 个字符通过、64 个字符失败并归属 `key.name`；前缀段总长 253 个字符通过、254 个字符失败并归属 `key.prefix`；前缀段中单个 DNS 标签为 64 个字符时失败并归属 `key.prefix`。
- [x] V4 `/tmp/` 最小 Chart 加载真实 `_env.tpl` 与新模板，执行 `helm template` 断言 key 关键失败：`app-`、`-app`、`a b` 归属 `key.name`；`App.io/name`、`app..io/name`、`/name` 归属 `key.prefix`；`prefix/` 归属 `key.name`；`a/b/c` 归属整体 `key`。
- [x] V5 `/tmp/` 最小 Chart 加载真实 `_env.tpl`、base 模板与新模板，执行 `helm template` 断言 operator 失败：`in`、`exist`、`Other` 均失败，且失败消息包含 `In`、`NotIn`、`Exists`、`DoesNotExist`。
- [x] V6 `/tmp/` 最小 Chart 加载真实 `_env.tpl`、base 模板与新模板，执行 `helm template` 断言生效与门禁边界：`values` 为空 array 时不输出 `values`；`operator` 为 `Exists` 且 `values` 非空时仍输出 `values`；`operator` 为 `In` 且缺 `values` 时不失败；非空的非 array `values` 失败并保留 `[base.slice]` 前缀。
- [x] V7 `/tmp/` 最小 Chart 加载真实 `_env.tpl`、base 模板与新模板，执行 `helm template` 断言原值保留：`key` 为 `007` 时输出 `key: 007`，不被零折叠为 `07`。
