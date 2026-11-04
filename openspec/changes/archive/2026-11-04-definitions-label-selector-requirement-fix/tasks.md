# 修正 LabelSelectorRequirement 模板任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_LabelSelectorRequirement.tpl`：`key`、`operator` 改用 `base.get` 并启用必填校验，`values` 改用 `base.get` 且保持可选，真值非空时整体 `toStrings` 后渲染；`key` 保留分段校验并改由 `base.string.verify` 执行名称段与前缀段校验；同步文件头注释入参表；对应 `Decision: 子模板改用 base.get 取值` 与 `Decision: 标签键保留分段校验`。
- [x] T2 `templates/api-resources/Definitions/_LabelSelector.tpl`：`matchExpressions` 原生对象分支改用 `base.get` 分别取 `key`、`operator`、`values`，由 `base.get` 识别 `*Alias`，父级校验非空与 `operator` 枚举并归一化，同时同步文件头注释的原生对象项边界说明；writable scope 为 `kindIs "map"` 分支与文件头注释的原生对象项边界说明；对应 `Decision: 父级 map 分支统一用 base.get 取值`。
- [x] T3 `templates/api-resources/Definitions/_LabelSelector.tpl`：`matchExpressions` 原生对象分支按 `operator` 校验 `values` 适用性，`In`、`NotIn` 要求非空数组，`Exists`、`DoesNotExist` 拒绝非空 `values`；writable scope 为 `kindIs "map"` 分支与文件头注释的原生对象项边界说明；对应 `Decision: values 适用性由父级校验`。
- [x] T4 `templates/api-resources/Definitions/_LabelSelectorRequirement.tpl` 与 `templates/api-resources/Definitions/_LabelSelector.tpl`：`key` 经包装解析还原真实类型并做 string 门禁；writable scope 分别为 `definitions.labelSelectorRequirement` 定义体与文件头注释、`kindIs "map"` 分支与文件头注释的原生对象项边界说明；对应 `Decision: key 还原真实类型后做 string 门禁`。
- [x] T5 `templates/api-resources/Definitions/_LabelSelectorRequirement.tpl`、`templates/api-resources/Definitions/_LabelSelector.tpl` 与 `templates/base/_collection.tpl`：`values` 去除 `null` 元素后判空，`base.slice.cleanup` 放行 `bool` 元素；writable scope 分别为三个文件中的对应定义体与注释；对应 `Decision: values 去除 null 元素与 bool 元素放行`。
- [x] T6 `templates/base/_convert.tpl`：`base.isFromYamlArrayError` 改为 `first` 取值后 `toString`、`lower` 再 `contains`，首元素非 string 不再中断；writable scope 为 `base.isFromYamlArrayError` 定义体及其紧邻注释。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：渲染 `In` 带两项 `values` 的表达式，预期输出含 `key`、`operator`、`values` 三个字段且 `values` 为两项字符串数组。
- [x] V2 `/tmp/` 最小 application Chart：渲染 `Exists` 无 `values`、`Exists` 空数组与 `In` 空数组三种输入，预期前两者只含 `key`、`operator`，`In` 空数组中断。
- [x] V3 `/tmp/` 最小 application Chart：渲染原生对象携带 `keyAlias`、字符串简写 `app = web`、`k in (a,b)`、`!app`，预期别名生效且简写输出与修复前一致。
- [x] V4 `/tmp/` 最小 application Chart：渲染前缀段 253 字符与 254 字符两种 `key`，预期前者通过、后者中断并输出带 `[definitions.labelSelectorRequirement]` 前缀的失败消息。
- [x] V5 `/tmp/` 最小 application Chart：渲染 `key` 缺失、`key` 为空字符串、`operator` 缺失、`operator` 为 `in`，预期全部中断且消息前缀符合规格。
- [x] V6 `/tmp/` 最小 application Chart：渲染 `key` 含两个 `/`、名称段含非法字符、前缀段含大写字母，预期全部中断且消息前缀符合规格。
- [x] V7 `/tmp/` 最小 application Chart：渲染 `In` 缺少 `values`、`Exists` 携带非空 `values`、`DoesNotExist` 携带非空 `values`，预期全部中断并输出带 `[definitions.labelSelector]` 前缀的失败消息。
- [x] V8 `/tmp/` 最小 application Chart：直接渲染 `definitions.labelSelectorRequirement`，`values` 为 `["a", 3, true]`，预期输出三项字符串数组；同一输入经父级传入时元素类型由 `base.slice.cleanup` 收敛。
- [x] V9 `/tmp/` 最小 application Chart：渲染 `key` 为数字、布尔、map、list 四种非字符串输入，预期全部中断并输出带 `[definitions.labelSelectorRequirement]` 或 `[definitions.labelSelector]` 前缀的类型失败消息。
- [x] V10 `/tmp/` 最小 application Chart：渲染 `values` 为 `[null]` 与 `[null, "a"]`，预期子模板前者不输出 `values`、后者输出一项；父级前者在 `In` 下中断、在 `Exists` 下只输出 `key` 与 `operator`。
- [x] V11 `/tmp/` 最小 application Chart：直接渲染 `base.isFromYamlArrayError` 的错误消息、普通字符串、数字首元素、布尔首元素、空数组与 `null` 首元素，预期仅错误消息返回真值且其余均返回 false 而不中断。
- [x] V12 `/tmp/` 最小 application Chart：渲染父级 `values` 含 `0`、`false`、`true`，预期 `0` 与 `false` 不被剔除，`true` 渲染为字符串 `"true"`。
- [x] V13 `/tmp/` 最小 application Chart：直接渲染 `definitions.labelSelectorRequirement`，`operator` 为 `Exists` 且 `values` 非空，预期正常输出三个字段，验证子模板不判定适用性。
- [x] V14 `/tmp/` 最小 application Chart：渲染 `keyAlias` 非空且同时提供 `key`、`keyAlias` 为空且提供 `key` 两种输入，预期前者用别名值、后者回退规范键。
- [x] V15 `/tmp/` 最小 application Chart：渲染 `operator` 为 `Exists ` 与 `in`，预期前者去除首尾空白后正常渲染 `operator: Exists`，后者中断并输出合法取值范围。
