目标: 新增命名模板 `base.get`，写入 `templates/base/_get.tpl`。
需求:
- 行为: 从多层上下文统一、安全取值，类型转换与合并；返回 `toYamlPretty` 后的 YAML 字符串，配合 `fromYaml` / `fromYamlArray` 使用。
- 入参：`list <上下文> <点分路径> [强制类型] [合并模式] [必填校验布尔] [调试布尔]`。
  - `上下文`：根上下文，通常为 `.`，必填。
  - `点分路径`：支持多级嵌套 (如 `image.repository`)，字符串，必填。
  - `强制类型` (可选): 强制类型转换。
    - 可选值：`int` / `int64` / `float64` / `atoi` / `toString` / `toStrings` / `toDecimal` / `quote` / `squote`。
  - `合并模式` (可选): 集合类合并模式，默认 `left`。
    - 字典: `left` 左优合并 (`mustMerge`) / `right` 右优覆盖 (`mustMergeOverwrite`)。
    - 列表: `concat` 拼接去重 (默认) / `replace` 全量替换。
  - `必填校验` (可选): 布尔值，是否为必填项，为 `true` 时取值为空立即中断报错，默认 `false`。
  - `调试日志` (可选): 布尔值，开启后输出调试日志，默认 `false`。
- 模板内部取值优先级: 上下文自身 > `.Context` > `.Values` > `.Values.global`。
- 字段类型默认行为:
  - string: `base.get` 不需要强制类型转换；`base.field` 常用 `base.string` 模板渲染。
  - integer/int: `base.get` 不需要强制类型转换；`base.field` 常用 `base.int` 模板渲染。
  - boolean/bool: `base.get` 不需要强制类型转换；`base.field` 常用 `base.bool` 模板渲染。
  - object/map: `base.get` 常结合 `fromYaml` 使用、不需要 `trim` 空格；`base.field` 常用 `base.map` 模板渲染。
  - array/slice: `base.get` 常结合 `fromYamlArray` 使用、不需要 `trim` 空格；`base.field` 常用 `base.slice` 模板渲染。
- 返回值: 结果统一由 `toYamlPretty` 处理并返回；默认返回空。
约束:
- 引用约束 `docs/rules/const-general.md`。
- 必填项缺失则立即中断并报错，报错格式 `[模板名] 字段路径: 错误原因`。
- 允许读取 `docs/samples/` 和 `templates/` 目录下的 `tpl` 文件，获取示例代码。
参考:
- 示例代码:
  - 引用 `docs/rules/const-example-code.md`。
