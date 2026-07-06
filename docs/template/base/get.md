# base.get 命名模板功能描述

从多层上下文统一、安全取值，类型转换与合并。返回 toYamlPretty 后的 YAML 字符串。

## 参数说明

传参格式：`list <上下文> <点分路径> [强制类型] [合并模式] [必填校验布尔] [调试布尔]`
- 上下文(context): 根上下文，通常为 `.`，必填
- 目标键名(key): 点分取值路径(支持多级嵌套，如 image.repository)，字符串，必填
- 强制类型(type): (可选)强制类型转换
  - 可选值：int/int64/float64/atoi/toString/toStrings/toDecimal/quote/squote
- 合并模式(mergeMode): (可选)集合类合并模式，默认 left
  - 字典: left 左优合并(mustMerge)、right 右优覆盖(mustMergeOverwrite)
  - 列表: concat 拼接去重(默认)、replace 全量替换
- 必填校验(required): (可选)布尔值，是否为必填项，为 `true` 时取值为空立即中断报错，默认 `false`
- 调试日志(debug): (可选)布尔值，开启后输出调试日志，默认 `false`

## 模板内部取值优先级

上下文自身 > .Context > .Values > .Values.global。

## 返回值

结果统一由 toYamlPretty 处理并返回；默认返回空。

## 其他

目标：add，`templates/base/_base.tpl`，模板 base.get
约束：
- 必填项缺失则立即中断并报错
- base.getValue 中如果存在 BUG 需在 base.get 中进行修复
参考：旧版 `docs/name-template.example` 中的 `base.getValue`
