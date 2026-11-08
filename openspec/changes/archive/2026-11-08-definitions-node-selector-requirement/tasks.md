# definitions.nodeSelectorRequirement 模板任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_NodeSelectorRequirement.tpl`：新增 `define "definitions.nodeSelectorRequirement"`，以 `if .` 包裹主体实现空 map 早退；`key`、`operator` 经 `base.get` 必填模式取值并用 `fromYaml` 确认 string 类型、`SYS.YAML_QUOTED` 剥离引号；`values` 经 `base.get` 非必填模式、`fromYamlArray`、`base.isFromYamlArrayError`、`toStrings` 归一化；按 `In`/`NotIn`、`Gt`/`Lt`、`Exists`/`DoesNotExist` 三类完成一致性校验并读取 `base.env` 的 `TYPES.INT`；`values` 的输出由 `operator` 分组分支显式决定（`In`、`NotIn`、`Gt`、`Lt` 渲染，`Exists`、`DoesNotExist` 不渲染），不以 `values` 非空作为输出开关；按 `key`、`operator`、`values` 顺序渲染并补齐整体契约注释与字段注释；对应 `Decision: 空 map 早退`、`Decision: 字段取值统一委托 base.get`、`Decision: values 归一化`、`Decision: 字段渲染与 operator 枚举`、`Decision: values 与 operator 一致性校验`、`Decision: values 渲染由 operator 分支决定`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart 调用本模板：最小有效输入 `{key: "kubernetes.io/os", operator: "In", values: ["linux"]}` 输出 `key`、`operator`、`values` 三个字段，且 `values` 为字符串列表；对应 `NodeSelectorRequirement 字段片段渲染`。
- [x] V2 `/tmp/` 最小 application Chart 调用本模板：六种 `operator` 各自渲染成功；`Gt` 使用整数 `values` 时输出字符串元素；`In` 传入 `["a", "a", "b"]` 时顺序与重复均保留；`DoesNotExist`、`Exists` 的输出不含 `values`；空 map 无字段输出；`keyAlias` 非空时覆盖 `key`，`keyAlias` 为空时回退 `key`；对应 `NodeSelectorRequirement 字段片段渲染`。
- [x] V3 `/tmp/` 最小 application Chart 调用本模板：缺 `key`、`key` 非 string、`key` 为 `"   "`、缺 `operator`、`operator` 为 `in` 与 `Foo`、`In` 无 `values`、`Exists` 携带 `values`、`Gt` 两个 `values`、`Gt` 单个非整数、`values` 为非数组标量，均使 `helm template` 渲染中断；`key`、`operator` 缺失报 `[base.get]` 错误并携带字段路径，`operator` 不在枚举内报 `[base.field]` 错误并列出六个合法值，其余错误使用 `[definitions.nodeSelectorRequirement]` 前缀并携带字段名；对应 `NodeSelectorRequirement 输入校验`。
