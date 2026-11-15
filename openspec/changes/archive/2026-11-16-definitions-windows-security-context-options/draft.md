---
change-id: definitions-windows-security-context-options
updated_at: "2026-11-15T17:37:17Z"
---

# definitions.windowsSecurityContextOptions 模板

## 目标

- 新增 `definitions.windowsSecurityContextOptions` 模板，用于渲染 Kubernetes `WindowsSecurityContextOptions` 子对象。

## 需求

- 支持渲染 `gmsaCredentialSpec`、`gmsaCredentialSpecName`、`hostProcess`、`runAsUserName` 四个字段。
- 调用与入参形态为 map：以单个上下文 map 作为入参，从该 map 读取上述四个字段。
- 返回可被 `fromYaml` 解析为 map 的 YAML 字段片段，无有效内容时返回空内容。
- 所有字段均为可选，未提供时不渲染对应键。
- 字段值为 `null`、空字符串或仅含空白时不渲染该字段。
- `hostProcess` 沿用 `base.bool` 的既有语义：接受原生布尔或字面量字符串 `"true"`、`"false"`，其他类型或非法字面量中断渲染。
- `hostProcess` 为 `false` 时不渲染该字段。
- 字段渲染顺序按官方文档顺序排列。

## 期望输入格式

```yaml
gmsaCredentialSpec: <string>
gmsaCredentialSpecName: <string>
hostProcess: <boolean>
runAsUserName: <string>
```

## 约束

- 字段顺序固定为 `gmsaCredentialSpec`、`gmsaCredentialSpecName`、`hostProcess`、`runAsUserName`，与官方文档顺序一致。

## 非目标

- 本 change 不处理 Schema。

## 验收

- 仅提供部分字段时，输出只包含已提供的字段，且顺序符合约束。
- `hostProcess: false` 时输出中不包含该字段。
- 字段值为 `null`、空字符串或仅含空白时不产生对应键，且不中断渲染。
- `hostProcess` 为原生布尔或字面量 `"true"`、`"false"` 时均按 `base.bool` 语义处理；其他值中断渲染。
- 全部字段缺省时模板可正常渲染，不产生错误。
- 返回内容可被 `fromYaml` 解析为 map。

## 开放问题

- 无。
