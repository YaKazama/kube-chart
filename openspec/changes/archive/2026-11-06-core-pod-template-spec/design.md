# core.podTemplateSpec 设计

## 技术目标

- capability：`core.podTemplateSpec`
- artifact-type：Helm 命名模板（Kubernetes 原生 API 共享结构）
- target：`templates/api-resources/Core/_PodTemplateSpec.tpl` 中的 `core.podTemplateSpec`

## 设计决策

### Decision: 目录与命名空间归属

- requirements：`PodTemplateSpec 结构渲染`
- choice：文件为 `templates/api-resources/Core/_PodTemplateSpec.tpl`，命名模板为 `core.podTemplateSpec`，一级分类目录为 `api-resources`，API 组目录使用官方稳定目录名 `Core`。
- rationale：用户已确认维持 `core.*` 与 `templates/api-resources/Core/`；`PodTemplateSpec` 属于 core/v1 API 结构，文件名按结构名保持 `_PodTemplateSpec.tpl`，命名空间保持小写 API 组前缀。

### Decision: 入参为透传上下文

- requirements：`PodTemplateSpec 结构渲染`
- choice：`define` 内直接使用传入的 `.`，不构造 `dict`，不增加 `kindIs "map"` 入口门禁。
- rationale：用户已确认接收父级模板透传的上下文；顶层调用方按父 Chart 契约传入可写 map，重复入口类型门禁与工程规则冲突。

### Decision: 资源身份原地写入

- requirements：`PodTemplateSpec 结构渲染`
- choice：以 `set . "_kind" "PodTemplateSpec"` 原地覆盖后继续使用同一上下文，不复制上下文。
- rationale：`_kind` 由拥有当前结构的模板写入，工程规则明确该契约写入不要求 `mustDeepCopy`；原地写入与 `apps.deployment` 的既有写法一致。

### Decision: `_pkind` 只透传不处理

- requirements：`PodTemplateSpec 结构渲染`
- choice：不设置 `_pkind`、不覆盖其取值、不读取；该键随同一上下文原样进入子模板。
- rationale：用户已确认仅设置 `_kind`，`_pkind` 属于父级身份控制键，由其所有者写入；本模板只读透传以满足“不设置、不覆盖”的规格边界。

### Decision: metadata 委托与省略条件

- requirements：`子模板无有效输出时省略字段`
- choice：`include "definitions.objectMeta" .` 后 `fromYaml`；先以 `base.isFromYamlError` 识别错误 map 并省略字段，再以 `if` 判断恢复结果并省略空值，均不 `fail`；非空时经 `base.field (list "metadata" <值> "base.map")` 渲染。
- rationale：规格要求空输出、无效 YAML 与无法恢复为有效 map 的内容均省略且不中断；当前 Helm 版本下非 map 输入由 `fromYaml` 返回错误 map，与非法 YAML 走同一条判据，因此无需单独类型分支即可满足全部省略场景。

### Decision: spec 委托与省略条件

- requirements：`子模板无有效输出时省略字段`
- choice：`include "core.podSpec" .` 后按与 `metadata` 完全相同的错误识别、空值省略与 `base.field` + `base.map` 渲染路径处理；仅处理 `core.podSpec` 的返回内容，不包裹 `include` 调用本身，使其内部 `fail` 原样向上传播。
- rationale：两个字段的可观察边界一致，复用同一处理形态；`core.podSpec` 在本 change 不可用，字段级省略逻辑必须在调用侧完成，不能依赖子模板；规格要求子模板自身失败不被拦截，而 `fail` 不返回字符串，无需也无法在调用侧额外判定。

### Decision: 不承担必填校验

- requirements：`子模板无有效输出时省略字段`
- choice：模板内不出现针对 `metadata`、`spec` 的 `required`、`fail` 或非空断言；也不以 `if`/`with` 或错误捕获包裹子模板调用来改变失败传播。
- rationale：用户已确认必填性由父级调用方负责，既有调用方 `apps.deploymentSpec` 已自行判定 `template` 必填；`core.podSpec` 的失败由其自身管理，本模板重复校验会与其产生双重失败路径，包裹调用则会改变其失败传播。

### Decision: 按 API 字段顺序输出

- requirements：`PodTemplateSpec 结构渲染`
- choice：先渲染 `metadata`，再渲染 `spec`。
- rationale：`PodTemplateSpec` 官方字段表顺序为 `metadata`、`spec`。

## 依赖契约

### Dependency: `definitions.objectMeta`

- availability：`existing`
- source：`templates/api-resources/Definitions/_ObjectMeta.tpl`
- operation：`consume`
- input：已原地写入 `_kind = PodTemplateSpec` 的同一上下文 map，只读
- output：ObjectMeta 字段片段 YAML；可解析为空输出或非法 YAML
- ownership：提供 `annotations`、`generateName`、`labels`、`name`、`namespace` 的身份相关渲染；当前模板负责解析错误识别、空值省略与字段嵌入

### Dependency: `core.podSpec`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：同一上下文 map，只读
- output：PodSpec 字段片段 YAML map；空输出与非法 YAML 由当前模板省略
- ownership：依赖负责 PodSpec 内部字段、必填与失败边界，其自身 `fail` 直接中断渲染并向上传播；本 change 不实现也不拦截；当前模板只负责调用、解析错误识别、空值省略与字段嵌入

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list "metadata" <值> "base.map"` 与 `list "spec" <值> "base.map"`
- output：字段 YAML；渲染为空时不输出
- ownership：负责字段序列化与渲染输出；当前模板负责字段生效条件与是否调用

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：经 `fromYaml` 恢复且非空的 map
- output：map 的 YAML 序列化；非 map 输入 `fail`
- ownership：作为最终类型门禁；当前模板不重复 `kindIs` 判断。当前 Helm 版本下 `fromYaml` 对非 map 输入返回错误 map 并被提前省略，因此该门禁在当前调用链中不会被触发

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值
- output：错误 map 时为 `"true"`，否则为 `"false"`
- ownership：识别 Helm YAML 解析错误形态；当前模板负责据其省略字段

## 代码边界

### `templates/api-resources/Core/_PodTemplateSpec.tpl`

- access：`write`
- operations：add `core.podTemplateSpec` 命名模板及其整体契约注释；add `_kind` 写入、`metadata` 与 `spec` 两个字段功能块及紧邻字段注释
- writable-scopes：新建文件的全部内容

### `templates/api-resources/Definitions/_ObjectMeta.tpl`

- access：`read`
- operations：consume `definitions.objectMeta`

### `templates/base/_field.tpl`

- access：`read`
- operations：consume `base.field`

### `templates/base/_types.tpl`

- access：`read`
- operations：consume `base.map`

### `templates/base/_convert.tpl`

- access：`read`
- operations：consume `base.isFromYamlError`

## 验证设计

- 最小有效：`/tmp/` 最小 application Chart 加载本模板与真实 `definitions.objectMeta`，以同名最小 fixture 提供 `core.podSpec` 并返回最小 `PodSpec`，断言输出含 `metadata` 与 `spec` 且顺序正确。
- 较完整有效：fixture 的 `core.podSpec` 返回多字段内容，断言 `spec` 完整透传；同时提供 `podAnnotations`、`labels` 等数据，断言 `metadata` 走 `PodTemplateSpec` 专用注解来源且不含 `name`、`namespace`。
- 输出形态边界：fixture 返回数组与标量，断言 `spec` 被省略且渲染不中断；同时确认当前 Helm 版本下此类输出由 `fromYaml` 返回错误 map，不进入 `base.map` 类型门禁。
- 失败传播：fixture 的 `core.podSpec` 内部 `fail`，断言渲染中断、错误向上传播且未被降级为省略 `spec`。
- 省略边界：fixture 分别返回空输出、非法 YAML 与两者组合，断言对应字段被省略且渲染不中断；两者均空时输出为空。
- 身份透传：父级上下文预置非空 `_pkind` 时，断言渲染成功且输出不含 `_pkind`，并断言 `_pkind` 原样传入子模板、未被设置或覆盖。
- 边界说明：`core.podSpec` 为 `unavailable` 依赖，fixture 只证明当前模板自身的调用、省略与门禁行为，不构成 `core.podSpec` 真实集成通过。
