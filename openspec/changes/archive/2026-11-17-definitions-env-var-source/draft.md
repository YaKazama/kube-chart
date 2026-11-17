---
change-id: definitions-env-var-source
updated_at: "2026-11-17T15:27:49Z"
---

# definitions.envVarSource

## 目标

- 新增命名模板 `definitions.envVarSource`，把单个 `EnvVarSource` 上下文分发到对应的选择器子模板。
- 承接收拾 `definitions.envVar` 已完成的字符串第一层拆解，把五个 `*Ref` 字段的字符串或原生 map 归一为子模板可用的 map。

## 需求

- 入参上下文为原生 map，或形如 `{<EnvVarSource 字段>: string}` 的单键 map。
- 五个字段互斥，同一上下文只能出现其中之一；出现多个时中断渲染。
- 识别 `EnvVarSource` 的五个字段，分别委托下列子模板：
  - `configMapKeyRef` → `definitions.configMapKeySelector`
  - `fieldRef` → `definitions.objectFieldSelector`
  - `fileKeyRef` → `definitions.fileKeySelector`
  - `resourceFieldRef` → `definitions.resourceFieldSelector`
  - `secretKeyRef` → `definitions.secretKeySelector`
- 上述五个子模板在本 change 中仅占位调用，不创建实现，也不新增占位 `define`。
- 字段值为原生 map 时直接把该 map 透传给对应子模板。
- 字段值为 string 时先按空白或逗号切分并组装为 map，再透传给对应子模板。
- 字段值既不是 map 也不是 string 时中断报错。
- 字符串段数不足该字段的必需段数时不组装该字段，也不报错。
- 字符串到 map 的段位顺序：

  ```text
  # configMapKeyRef → definitions.configMapKeySelector
  <name> [key] [optional]
  # fieldRef → definitions.objectFieldSelector
  <fieldPath> [apiVersion]
  # fileKeyRef → definitions.fileKeySelector
  <volumeName> <path> [key] [optional]
  # resourceFieldRef → definitions.resourceFieldSelector
  <resource> [containerName] [divisor]
  # secretKeyRef → definitions.secretKeySelector
  <name> [key] [optional]
  ```

- 本模板只负责分发与字符串切分组装，选择器对象的字段校验、类型转换与失败边界由各子模板负责。
- 组装出的 map 使用官方字段名；`optional`、`divisor`、`apiVersion` 等可选段的字面量原样传递，具体类型由子模板渲染时校验。
- 本模板返回自身字段片段（如 `configMapKeyRef: {...}`），不再额外包一层 `valueFrom`。

## 期望输入格式

- `definitions.envVarSource` 的入参为单个 `EnvVarSource` map，键为上述五个字段之一。
- 字段值可为原生 map，或按上述段位顺序书写的字符串。
- 字符串段之间可混用逗号或空格作为分隔符。

## 约束

- 五个 `*Ref` 字段互斥，只处理实际出现的那一个。
- 每个字段的必需段数：`configMapKeyRef` 1 段（`name`）、`fieldRef` 1 段（`fieldPath`）、`fileKeyRef` 2 段（`volumeName`、`path`）、`resourceFieldRef` 1 段（`resource`）、`secretKeyRef` 1 段（`name`）。
- 段数不足时不组装该字段，也不报错。
- 可选段按位次顺序取值，缺省时不出现在组装的 map 中。

## 非目标

- 不创建五个选择器子模板本体。
- 不实现选择器对象内部字段的校验、类型转换与缺省处理。
- 不处理 `definitions.envVar` 层的关键字识别与第一层拆解。

## 验收

- 原生 map 形态的五个字段分别原样透传给对应子模板。
- 字符串形态的五个字段分别按段位顺序组装为 map 后透传，可选段字面量保持字符串原样。
- 段数不足的字符串不产生待透传内容，且不中断渲染。
- 字段值既非 map 也非 string 时中断；多个 `*Ref` 字段同时出现时中断。
- 返回值为单键的 `*Ref` 字段片段，不含 `valueFrom` 父键。
- 五个子模板仅占位，不引入本 change 之外的实现。

## 开放问题

- 无。
