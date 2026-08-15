# 通用边界行为约定

## 输出与异常

- 规范未定义的输入字段静默忽略，不渲染。
- 禁止输出 `status` 字段。
- 标记为必填的字段缺失、为 `nil` 或为空时，必须立即失败。
- 非法枚举值必须报错并给出合法范围。
- 类型不匹配时仅允许安全转换；无法转换必须报错。
- 字段冲突或互斥时，按正式 SDD 定义的优先级处理；无法确定优先级时必须报错。
- 空值与零值是否输出由字段生效条件决定。

## Helm 4.2.2 YAML 兼容性

- map/dict 解析必须使用 `base.isFromYamlError` 拦截 `fromYaml` 对非 map 输入的错误 map 返回。
- slice/list 解析必须使用 `base.isFromYamlArrayError` 拦截 `fromYamlArray` 对非 slice/list 输入的异常返回。
- 处理 string、map、list 等多类型字段时，必须先识别解析错误和真实类型，禁止将错误 map 误判为有效对象。
