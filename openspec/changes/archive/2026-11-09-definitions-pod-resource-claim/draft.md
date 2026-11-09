---
change-id: definitions-pod-resource-claim
updated_at: "2026-11-09T14:21:36Z"
---

# definitions.podResourceClaim

## 目标

- 新增渲染模板 `definitions.podResourceClaim`，把父级传入的资源声明上下文转换为 PodResourceClaim 片段。

## 需求

- 入参为父级传递的上下文，示例字段为 `name`、`resourceClaimName`、`resourceClaimTemplateName`。
- 仅空白字符串（如 `" "`）等同于未设置，三个字段均适用。
- `name`：string，必填；缺失、为空或仅空白时中断渲染，失败消息遵循项目统一格式 `[模板名] 字段路径: 错误原因`。
- `resourceClaimName`：string，可选；不做名称格式校验。
- `resourceClaimTemplateName`：string，可选；不做名称格式校验。
- `resourceClaimName` 与 `resourceClaimTemplateName` 必须且只能设置一个：同时设置或同时未设置均中断渲染，失败消息遵循项目统一格式。
- 输出字段顺序为 `name` → `resourceClaimName` → `resourceClaimTemplateName`，与 Kubernetes API 文档字段顺序一致。
- 模板文件为 `templates/api-resources/Definitions/_PodResourceClaim.tpl`，与同级 Definitions 模板保持一致。

## 期望输入格式

```yaml
name: string
resourceClaimName: string
resourceClaimTemplateName: string
```

## 约束

- 入参由父级传入，模板不自行读取 values 路径。

## 非目标

- 不新增或修改其他模板，包括父级 `core.podSpec.resourceClaims` 等接入。

## 验收

- 仅设置 `resourceClaimName` 时，输出含 `name` 与该引用字段的 PodResourceClaim 片段。
- 仅设置 `resourceClaimTemplateName` 时，输出含 `name` 与该引用字段的 PodResourceClaim 片段。
- `name` 缺失或为空时渲染中断。
- 两个引用字段同时设置或同时未设置时渲染中断。
- 父级通过 `include` 调用即可获得上述片段，无需额外包装层。

## 开放问题
