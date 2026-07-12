# admissionregistration.MutatingAdmissionPolicy 模板规范（AI 重写版）

## 功能描述

实现 Kubernetes `MutatingAdmissionPolicy` 资源（`admissionregistration.k8s.io/v1`）的命名模板 `admissionregistration.MutatingAdmissionPolicy`，写入文件 `templates/api-resources/Admissionregistration/_MutatingAdmissionPolicy.tpl`。

- 模板仅负责按 K8s API 规范字段顺序渲染 `MutatingAdmissionPolicy` 资源的 YAML 字段。
- `apiVersion` 与 `kind` 为固定值，不允许覆盖。
- `metadata` 必填，委托 `definitions.objectMeta` 渲染；由于 `definitions.objectMeta` 内部不污染源上下文，无需 `mustDeepCopy`。
- `spec` 可选，委托 `admissionregistration.mutatingAdmissionPolicySpec` 渲染（不在本模板内创建该模板），向下透传 `.`。
- 模板不输出顶级 `---`，由调用方决定是否输出。
- 模板不处理 Helm Hooks。

## 接口与参数描述

### 模板调用

```yaml
---
{{- include "admissionregistration.MutatingAdmissionPolicy" . }}
```

### 入参

唯一上下文 `.`（`dict`），可包含以下字段：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| 其余字段 | any | - | 透传给 `definitions.objectMeta`（如 `annotations` / `generateName` / `labels` / `name` / `namespace`） |
| `spec` | dict | 否 | `MutatingAdmissionPolicySpec` 结构，向下透传 `.` 至 `admissionregistration.mutatingAdmissionPolicySpec` |

模板内部强制设置 `_kind = "MutatingAdmissionPolicy"` 后再调用 `definitions.objectMeta`，调用方无需、也不应预设 `_kind`。

### 返回值

`MutatingAdmissionPolicy` 资源的 YAML 字段（不含顶级 `---`）：

- `apiVersion: "admissionregistration.k8s.io/v1"`（固定）
- `kind: "MutatingAdmissionPolicy"`（固定）
- `metadata: { ... }`（必填）
- `spec: { ... }`（可选）

## 核心业务逻辑与实现细节

### 模板结构

模板按以下顺序组装：

1. **顶部多行注释块**（`{{- /* ... */ -}}`）：覆盖 5 段说明，顺序与字段名固定，缺一不可：
   - 渲染对象：声明本模板渲染 Kubernetes `MutatingAdmissionPolicy` 资源，并附官方 API 参考链接。
   - 行为（按 K8s API 规范字段顺序）：依次列出 `apiVersion` / `kind` / `metadata` / `spec` 四个字段的类型、必填性与渲染方式。
   - 核心字段：说明上下文 `map` 可包含的字段（透传给 `definitions.objectMeta` 的元字段 + 可选 `spec`）。
   - 返回值：声明返回 `MutatingAdmissionPolicy` 资源 YAML 字段，不含顶级 `---`，由调用方决定。
   - 示例：给出最小调用代码 `{{- include "admissionregistration.MutatingAdmissionPolicy" . }}`。
2. **define 入口**：`{{- define "admissionregistration.MutatingAdmissionPolicy" -}}`。
3. **Step 1 ~ Step 3**：依次实现 `apiVersion` / `kind`、`metadata`、`spec` 渲染。
4. **define 闭合**：`{{- end -}}`。

参考注释块示例：

```go
{{- /*
  渲染 Kubernetes MutatingAdmissionPolicy 资源。参考 https://kubernetes.io/docs/reference/kubernetes-api/admissionregistration/mutating-admission-policy-v1/#MutatingAdmissionPolicy

  行为 (按 K8s API 规范字段顺序):
    - apiVersion (string, 必填): 固定为 admissionregistration.k8s.io/v1, 与 K8s API 规范对齐, 不允许覆盖。
    - kind (string, 必填): 固定为 MutatingAdmissionPolicy, 与 K8s API 规范对齐, 不允许覆盖。
    - metadata (dict, 必填): 委托 definitions.objectMeta 渲染, 强制 _kind = MutatingAdmissionPolicy, 渲染结果为空时立即中断并报错。
    - spec (dict, 可选): 委托 admissionregistration.mutatingAdmissionPolicySpec 渲染, 缺失或为 nil 时不渲染 spec 字段, 非 dict 类型时立即中断并报错。

  核心字段: 上下文 map, 可包含以下字段:
    - 其余字段透传给 definitions.objectMeta (annotations / generateName / labels / name / namespace)
    - spec       (dict, 可选)   MutatingAdmissionPolicySpec 结构

  返回值: MutatingAdmissionPolicy 资源 YAML 字段 (不含顶级 "---", 由调用方决定)

  示例:
    {{- include "admissionregistration.MutatingAdmissionPolicy" . }}
*/ -}}
```

### 字段渲染顺序

严格按 K8s API 规范字段顺序渲染：`apiVersion` → `kind` → `metadata` → `spec`。

### Step 1：apiVersion / kind

- 固定输出 `apiVersion: "admissionregistration.k8s.io/v1"` 与 `kind: "MutatingAdmissionPolicy"`，与 K8s API 规范对齐，不允许覆盖、不读取上下文。
- 参考示例：

  ```go
  {{- nindent 0 "" -}}apiVersion: "admissionregistration.k8s.io/v1"
  {{- nindent 0 "" -}}kind: "MutatingAdmissionPolicy"
  ```

### Step 2：metadata（必填）

- 委托 `definitions.objectMeta` 渲染元数据。
- 强制设置 `_kind = "MutatingAdmissionPolicy"`，传入 `definitions.objectMeta`。
- 因 `definitions.objectMeta` 内部不污染源上下文，无需 `mustDeepCopy`。
- 渲染结果（`fromYaml` 解析后）若为空（`nil` / `false`），立即中断并报错，符合"必填项缺失"边界行为。
- 渲染成功后通过 `base.field` 以 `base.map` 模式输出 `metadata` 字段。
- 参考示例：

  ```go
  {{- $_ := set . "_kind" "MutatingAdmissionPolicy" }}
  {{- $metadata := include "definitions.objectMeta" . | fromYaml }}
  {{- if not $metadata }}
    {{- fail "[admissionregistration.MutatingAdmissionPolicy] metadata: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "metadata" $metadata "base.map") }}
  ```

### Step 3：spec（可选）

- 调用 `admissionregistration.mutatingAdmissionPolicySpec` 并向下透传 `.`；不创建该子模板，由调用方确保其已存在。
- 缺失 / `nil` / 空字符串时跳过 `spec` 字段，不渲染。
- 非空时先 `fromYaml` 解析：
  - 解析结果若为 `nil` / `false` 视为缺失，跳过 `spec`。
  - 通过 `base.isFromYamlError` 检测 Helm 4.2.2 `fromYaml` 对非 YAML 输入返回错误 `map` 的 BUG；若为错误 `map`，立即中断并报错。
    - 布尔比较必须使用 `{{- if eq (include "base.isFromYamlError" $specObj) "true" }}`，不能直接 `{{- if include "base.isFromYamlError" $specObj }}`（字符串 `"false"` 也为真值）。
  - 通过 `kindIs "map"` 校验 `spec` 必须为 `dict` 类型；非 `dict` 立即中断并报错。
  - 通过 `base.field` 以 `base.map` 模式输出 `spec` 字段。
- 参考示例：

  ```go
  {{- $specRaw := include "admissionregistration.mutatingAdmissionPolicySpec" . }}
  {{- if $specRaw }}
    {{- $specObj := $specRaw | fromYaml }}
    {{- if $specObj }}
      {{- if eq (include "base.isFromYamlError" $specObj) "true" }}
        {{- fail "[admissionregistration.MutatingAdmissionPolicy] spec: invalid YAML output from admissionregistration.mutatingAdmissionPolicySpec" }}
      {{- end }}

      {{- if not (kindIs "map" $specObj) }}
        {{- fail "[admissionregistration.MutatingAdmissionPolicy] spec: must be dict type" }}
      {{- end }}

      {{- include "base.field" (list "spec" $specObj "base.map") }}
    {{- end }}
  {{- end }}
  ```

### 排版与命名

- 2 空格缩进；使用 `{{- nindent 0 "" -}}` 控制 `apiVersion` / `kind` 字段排版。
- 模板命名末级目录前缀.小驼峰：`admissionregistration.MutatingAdmissionPolicy`。
- 文件名以 `_` 开头、大驼峰命名：`_MutatingAdmissionPolicy.tpl`。
- `{{- else if }}` 前保留空行，提升可读性。

## 系统约束与异常处理

### 通用约束

- 遵循 `docs/rules/const-general.md`：
  - 仅使用 Helm 原生内置函数（Go Template + Sprig + Helm 特有），禁止臆造。
  - 必填缺失 / 类型非法时通过 `required` / `fail` 快速中断渲染。
  - 模板首尾严禁输出 `---`，仅独立资源间输出分隔符。
  - 不得禁用 `base.get` / `base.field` 手写取值或渲染。
  - 不在工程目录下进行任何验证（如创建 `.verify/` 目录），所有验证仅在 `/tmp/` 目录进行。
  - 完成后需检查隐性 BUG 并修复（如 `base.isFromYamlError` / `base.isFromYamlArrayError` 的布尔判断必须使用 `eq ... "true"`，不能直接用 `if include`）。
- 仅可读取 `docs/samples/` 与 `templates/` 下的 `tpl` 文件作为示例代码参考；正则统一在 `templates/base/_env.tpl` 集中管理。
- 不得引用 `status` 字段。

### 必填校验

- 必填项缺失或值为 `nil`（`base.get` 返回字符串 `"null"`）时，立即中断并通过 `fail` 报错。
- `metadata` 渲染结果为空时立即报错（见 Step 2）。

### 类型与 BUG 兼容

- `slice` / `list` 类型字段需通过 `base.isFromYamlArrayError` 兼容 Helm 4.2.2 `fromYamlArray` 对非 `slice` / `list` 输入返回错误切片的 BUG。
- `map` / `dict` 类型字段需通过 `base.isFromYamlError` 兼容 Helm 4.2.2 `fromYaml` 对非 `map` 类型输入返回错误 `map` 的 BUG。
- 对应的布尔判断统一使用 `{{- if eq (include "base.isFromYamlError" $obj) "true" }}` 模式，避免字符串 `"false"` 误判为真值。
- `spec` 必须为 `dict` 类型，非 `dict` 立即中断并报错。

### 报错格式

统一使用 `[admissionregistration.MutatingAdmissionPolicy] 字段路径: 错误原因` 格式，例如：

- `[admissionregistration.MutatingAdmissionPolicy] metadata: required field is missing or empty`
- `[admissionregistration.MutatingAdmissionPolicy] spec: invalid YAML output from admissionregistration.mutatingAdmissionPolicySpec`
- `[admissionregistration.MutatingAdmissionPolicy] spec: must be dict type`

修改完成后必须通过 `helm lint` 校验。

## 参考

- API 规范：
  - https://kubernetes.io/docs/reference/kubernetes-api/admissionregistration/mutating-admission-policy-v1/#MutatingAdmissionPolicy
  - https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#mutatingadmissionpolicy-v1-admissionregistration-k8s-io
- 工程约束：
  - `docs/rules/const-general.md`
  - `docs/rules/const-example-code.md`
  - `docs/samples/env.tpl`
  - `docs/samples/example.tpl`
