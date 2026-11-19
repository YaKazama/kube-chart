---
change-id: definitions-container-restart-rule
updated_at: "2026-11-19T17:26:30Z"
---

# definitions.containerRestartRule

## 目标

- 新增命名模板 `definitions.containerRestartRule`，把用户输入渲染为 Kubernetes container restart rule 结构。

## 需求

- 调用入口为父模板 `definitions.container` 中的 `definitions.container.array`，本模板上下文为单个 `restartPolicyRules` 元素。
- `_Container.tpl` 的 `restartPolicyRules` 调用需开启 `"allowString" true`，与 `ports`、`resizePolicy` 保持一致，使 string 元素能到达本模板。
- 模板上下文支持 map 或 string 两种类型。
- 上下文为 string 时，在本模板内清洗：第 1 段为本模板的 `action`，第 2 段为子模板的 `exitCodes.operator`，括号内为子模板的 `exitCodes.values`。
- string 中的 `operator` 只在本模板按简写格式捕获并原样下传；枚举、大小写与内容合法性由子模板负责，本模板不归一化 `operator`。
- 上下文为 map 时不清洗，`exitCodes` 直接传给子模板。
- `action` 属于本模板字段，两种上下文都由本模板完成大小写不敏感校验和归一化，输出 `Restart`；缺失或非 `restart` 取值时中断报错；不向下传递给子模板。
- map 上下文除 `action`、`exitCodes` 外的未知键静默忽略，不参与输出，也不导致中断。
- values 为 integer array，允许显式 `0`。
- exitCodes 必填，非法或为空时中断报错。
- 子模板返回空内容时中断报错，不省略 `exitCodes`。
- values 为空列表 `()` 时中断报错。
- 本 change 只保证从 string 中过滤出指定字段值，不对字段内容做额外校验。
- 子模板 `definitions.containerRestartRuleOnExitCodes` 本 change 仅占位，不创建。

## 期望输入格式

- 上下文为 string 时格式为 `<action> <operator> (int, int, ...)`，所有内容必填。
- 解析用正则大小写不敏感，分隔符为空格和逗号，正则不匹配即中断报错。

## 约束

- 取值使用 `base.get`。
- 采用直白写法。
- `definitions.container.array` 默认 `allowString: false`，本 change 需在 `_Container.tpl` 调用处显式开启。
- `definitions.container.array` 会把本模板输出 `fromYaml`，本模板必须输出可解析为 map 的 YAML。

## 非目标

- 不实现 `definitions.containerRestartRuleOnExitCodes` 子模板内容。
- 不校验 values 数量上限 255；operator 的枚举、大小写与内容合法性属于子模板职责。

## 验收

- string 与 map 两种上下文都能渲染出 container restart rule 结构。
- string 输入按空格与逗号正确产出 `action`、`exitCodes.operator`、`exitCodes.values`。
- string 与 map 两种上下文都输出 `action: Restart`。
- 非法 action、缺失 action、缺失或为空 exitCodes、空 values `()`、正则不匹配时中断报错。
- 子模板返回空内容时中断报错。
- map 上下文的未知键被静默忽略。
- `definitions.containerRestartRuleOnExitCodes` 只有占位引用，无实际实现。
- values 中的 `0` 能正常输出，不被当作空值丢弃。
