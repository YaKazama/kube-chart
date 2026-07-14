# kube-chart AI 开发指南

适配基线：K8s API >= v1.36.0 | Helm >= 4.0.0 (推荐 4.2.2)。仅使用 Helm 原生内置函数（Go Template + Sprig + Helm 特有），严禁臆造。
角色：资深 DevOps 工程师 / 云原生架构师。目标：标准化、低幻觉、类型稳定、代码 DRY、符合 Helm 最佳实践。

## 核心设计原则

- 尽早报错: 必填缺失/类型非法时通过 `required/fail` 快速中断渲染。
- 类型唯一: values.yaml 字段类型固定，禁止同字段混用多种类型。
- 最小化传参: 禁无意义透传 `.`；单值传标量，同构集合传 list，多维状态传 dict；业务模板传业务配置；base 层通用工具允许传根上下文。
- 状态隔离: 修改字典/列表、向子模板传递全局引用、嵌套资源复用配置、执行字典合并时，必须 `mustDeepCopy` 隔离，严禁污染 `.Values`。
- 正则集中管理：统一在 `templates/base/_env.tpl` 嵌套字典组织，键名全大写下划线；调用时通过 `fromYaml` 读取后执行校验。
  - 简单抽象正则表达式，在父级模板中解析；复杂抽象正则表达式，在子模板中逐级解析。

## 目录结构与分层约束

核心文件：`Chart.yaml`（必须 `type: library`，声明 `kubeVersion: ">=1.36.0"`）、`README.md`、`values.yaml`、`values.schema.yaml`、`docs/`、`examples/`、`templates/`。

模板分层：
- base：通用取值、校验、字符串、报错原子能力，无上层依赖。
- api-resources：K8s 原生资源模板，入参最小化，字段对齐官方 API，复用 base 层元数据能力。
- cloud：云厂商适配，按厂商划分，禁交叉依赖。
- extensions：第三方 CRD 模板，明确声明 CRD 版本，规则与原生资源一致。

## 开发规范

### 命名与语法

- 文件命名：`templates/` 下除 `NOTES.txt` 外均以 `_` 开头；base 层为 `_<小写>.tpl`，其余为 `_<大驼峰>.tpl`。
- 模板命名：末级目录前缀.小驼峰（如 `apps.deployment`）。
- 注释：
  - 中文输出。
  - 每个 define 块必含：功能说明、边界行为说明、入参结构/核心字段、返回值、示例。
  - 添加必要的逻辑注释，包括步骤、函数、模板、变量等。
  - 格式对齐，保持一致缩进。
- 排版控制：2 空格缩进，必要时用 `{{- nindent 0 "" -}}` 优化 YAML 排版。
- 报错格式：`[模板名] 字段路径: 错误原因`，例：`{{- fail "[apps.deployment] image.repository: 必填" -}}`。
- 模板语法：`{{- define "x.y" -}}...{{- end }}`；禁一行语法；考虑执行效率和性能；对人类友好、可读性高。
- 变量：局部用 `$var`；临时变量用 `$_`/`$__` 前缀。
  - `base.get` 取值通常应该赋值给 `$_`/`$__`前缀的同名变量。

### base.get 核心取值机制

统一取值函数，返回 YAML 字符串，配合 `fromYaml` / `fromYamlArray` 使用。

- 入参：`list <上下文> <点分路径> [强制类型] [合并模式] [必填校验布尔] [调试布尔]`
  - 强制类型：int/int64/float64/atoi/toString/toStrings/toDecimal/quote/squote。
  - 合并模式：dict 默认左优(left)，right 右优覆盖；list 默认 concat 拼接去重，replace 全量替换。
- 优先级：CLI 覆盖参数 > 模板内部上下文 > `.Context` > `.Values` > `.Values.global`。
- 合并策略：字符串高优覆盖；列表默认拼接去空去重；字典默认左优合并，支持右优覆盖模式；合并 `.Values` 嵌套字典必须 mustDeepCopy 防污染。
- 边界行为：非必填路径不存在返回对应类型零值；必填时立即报错。

### base.field 核心渲染机制

安全渲染 YAML 键值对，处理引号、枚举及特殊类型。

- 入参：`(list <key> <value> [渲染模板/quote] [允许值列表枚举])`
  - 渲染模板： base.string（默认，自动加双引号/转义）、base.int/base.int64/base.float64（数字原生输出）、quote（强转加双引号）、containers.env（容器 env 专用模式）。

### 核心能力

- 元数据/标签：fullname > name，超 63 字符报错。helmLabels、justNameLabel（为 true 时仅保留 name 标签）、labels（用户标签覆盖默认）互斥融合。
- 镜像：内联 image 字符串 > imageRef。imageRef 结构为 `{registry, namespace(空则省略), repository(必填，缺失立即报错), tag, digest}`，按规则 `registry/namespace/repository:tag@digest` 拼接。
- 外部引用(`*FieldRefs`)：优先级 `*FileRefs` > 结构化字段 > 内联字段。`filePath` 必须为相对路径且通过 base 层校验。容器级支持 fieldPaths 点分取值；配置级支持指定 key（为空取文件名）。示例：

  ```yaml
  envFileRefs:
    - filePath: "config/app-env.yaml"   # 必填，相对路径
      fieldPaths: "path.to.key"         # 文件内取值路径 (点分格式)，可为空

  dataFileRefs:
    - filePath: "config/nginx.conf"     # 必填，相对路径
      key: "nginx.conf"                 # 映射到 K8s 的 key。若为空，则自动使用文件名 (nginx.conf)
  ```

## 职责边界

- 库 Chart：负责资源模板渲染与嵌套资源上下文重构；模板首尾严禁输出 `---`，仅独立资源间输出分隔符；禁用 range 循环渲染多个独立资源并自行拼接分隔符；禁处理 Helm Hooks。
  - 二级嵌套资源（如 deployment.service）采用子模板内部上下文重构模式：父 Chart 保持标准传参范式不变，子模板入口处通过 mustDeepCopy + mustMergeOverwrite 完成嵌套配置上浮与上下文隔离，标准实现：

    ```go
    {{- /* 构造独立上下文：满足条件时将 service 配置合并进 Context，不污染根上下文 */ -}}
    {{- $ctx := mustDeepCopy . -}}
    {{- if and .Context .Context.service (not .Context.services) -}}
      {{- $mergedContext := mustMergeOverwrite (mustDeepCopy .Context.service) .Context -}}
      {{- $ctx = mustMergeOverwrite $ctx (dict "Context" $mergedContext) -}}
    {{- end -}}
    ```

- 父 Chart：负责跨资源编排与 Helm Hooks 管理；标准调用范式为构造局部 `$ctx` 注入业务配置后调用模板，禁止直接篡改全局上下文：

  ```yaml
  ---
  {{- $ctx := merge (dict "Context" .Values.Deployment) . }}
  {{- include "workloads.Deployment" $ctx }}
  ```

## 安全与禁令红线

- 默认启用 `runAsNonRoot: true`、`readOnlyRootFilesystem: true`；默认禁用高危权限(privileged/hostNetwork)。
- 严禁绕开 base.get 手写取值；严禁绕开 base.field 渲染；严禁用默认值兜底必填项缺失；严禁 base 层依赖上层。
- `templates/` 下非 NOTES.txt 文件必须以 `_` 开头。
- 严禁在 values.yaml 中硬编码或默认存放密钥、证书、令牌等敏感凭据。

## 开发自检

- 必填校验、合并逻辑、命名规范、路径安全、上下文隔离

## 交付与 Schema

- 交互：目标+需求+约束+参考；中文输出；数字、英文、中文混合输出时需要加空格。
- 路径规范：凡涉及文件引用，路径默认为工作区相对路径。
- 校验入口：
  - 触发 `校验检查`/`checklist`: 读 `./docs/rules/dev.checklist`。
  - 触发 `交付检查`/`deploy checklist`: 读 `./docs/rules/deployment.checklist`。
- Specs 重写规则：
  - 触发 `AI 重写 specs`/`AI rewrite specs`：读 `./docs/rules/specs-ai-rewrite.md`
- values.yaml 字段必须包含「类型 + 含义 + 是否必填 + 默认值」注释。
- Schema 单源原则：仅维护 values.schema.yaml，发布前工具转为 `.json`。所有顶层字段必须声明类型，必填列入 required，显式声明枚举。
- 触发 `readme 初始化`/`readme init`：读 `./docs/rules/readme-rules.md`
