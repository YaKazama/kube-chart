---
updated_at: "2026-11-27T03:24:59Z"
---

# 移除 imageRefs 规格

## MODIFIED Requirements

### Requirement: image 来源解析

系统 MUST 按 `imageFileRefs` > `image` 的优先级确定最终 `image`，`imageFileRefs` 的解析结果只接受 string，最终结果为空时中断渲染；`imageRefs` 不再参与镜像解析。

#### Scenario: 仅提供 image

- **WHEN** 上下文只提供 `image` 且非空
- **THEN** 输出该 `image` 值

#### Scenario: imageRefs 被静默忽略

- **WHEN** 上下文提供 `image`，同时提供任意形态的 `imageRefs`
- **THEN** 输出 `image` 值，`imageRefs` 不参与解析且不产生错误

#### Scenario: imageFileRefs 覆盖 image

- **WHEN** `imageFileRefs` 解析出非空 string，且同时提供 `image`
- **THEN** 输出 `imageFileRefs` 解析结果，忽略 `image`

#### Scenario: imageFileRefs 解析结果为 map

- **WHEN** `imageFileRefs` 解析结果为 map
- **THEN** 渲染中断并报错

#### Scenario: imageFileRefs 解析结果不是 string

- **WHEN** `imageFileRefs` 解析结果为 map 之外的 list、number、boolean 等非 string 值
- **THEN** 渲染中断并报错

#### Scenario: 两个来源均不可得

- **WHEN** `imageFileRefs` 无有效结果且 `image` 为空
- **THEN** 渲染中断并报错

## 非目标

- 不修改 `imageFileRefs` 的 `filePath`、`fieldPaths` 读取协议。
- 不修改其他 Container 字段及其 FileRefs 行为。
