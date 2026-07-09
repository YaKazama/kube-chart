# base.field 命名模板功能描述

安全渲染 YAML 键值对，处理引号、枚举及特殊类型。

## 参数说明

传参格式：`list <key> <value> [渲染模板] [允许值列表枚举]`
- key：键名，字符串，必传
- value：需要渲染的值，任意类型，必传
- 渲染模板：用来处理 value 的命名模板名称，可选
  - `base.string`：默认值。通常会自动添加双引号/转义符
  - `quote`：强制添加双引号
  - `containers.env`：特殊定义。处理 containsers 下 env 变量中的 value，为 `0/true/false/数值` 自动添加双引号。通常使用一个抽象的独立命名模板处理，如 `base.process.containers.env`
- 允许值列表枚举：值校验列表，可选。
  - 使用传入的列表项逐一检查 value 的值
    - 匹配成功则保留
    - 匹配失败则丢弃
    - 如果都不匹配则报错
  - 指定时，渲染模板的值会强制使用 `base.string`

## 返回值

序列化后的 YAML 格式内容。

## 其他

目标：add，`templates/base/_field.tpl`，模板 `base.field`
约束：
- 必填项缺失则立即中断并报错
- 分析示例 `docs/name-template.example` 的 `base.field` 和 `base.process.containers.env` 中存在 BUG，并在新的 `base.field` 中修复
