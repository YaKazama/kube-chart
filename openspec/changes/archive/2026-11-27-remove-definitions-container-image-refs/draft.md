---
change-id: remove-definitions-container-image-refs
updated_at: "2026-11-27T03:23:10Z"
---

# 移除 definitions.container 的 imageRefs 设计

## 背景

- `imageRefs` 用 map 补强 `image` string，增加认知成本，并引入不直观的覆盖优先级。
- 经思考与分析，认为该设计不够好，存在过度设计嫌疑。

## 目标

- 移除 `definitions.container` 的 `imageRefs` 设计，使 `image` 只接受 string。

## 需求

- 移除 `imageRefs` 输入及其高于 `image` 的优先级。
- 调用方仍传入 `imageRefs` 时静默忽略。
- `image` 仍为必填 string，最终为空时中断渲染。
- 覆盖 `image` 时使用完整原值直接替换。
- 保留 `imageFileRefs` 作为文件来源，优先级高于 `image`。
- `imageFileRefs` 引用的内容只接受 string；内容为 map 时中断报错。
- 移除 `definitions.container.imageRef` 镜像组件拼接逻辑。
- 当前处于开发阶段，直接执行破坏性删除，不保留弃用期或兼容分支。

## 验收

- 仅提供 `image` 时正常渲染，输出完整镜像引用。
- 仍传入 `imageRefs` 时静默忽略，不影响最终镜像引用。
- `imageFileRefs` 引用 string 内容时生效并覆盖 `image`。
- `imageFileRefs` 引用 map 内容时渲染中断并报错。
- `imageFileRefs` 与 `image` 同时提供时，`imageFileRefs` 优先。
- `image` 与 `imageFileRefs` 均无有效值时渲染中断。
