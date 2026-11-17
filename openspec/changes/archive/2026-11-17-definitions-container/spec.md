---
updated_at: "2026-11-16T15:06:48Z"
---

# definitions.container 规格

## Purpose

按 Kubernetes `Container` 结构渲染单个容器字段片段，供 `PodSpec` 的 `containers` 与 `initContainers` 数组逐项复用。

## ADDED Requirements

### Requirement: Container 字段片段渲染

系统 MUST 以单个 map 作为上下文，按官方字段顺序渲染 Container 字段片段，并返回可解析为 map 的 YAML 内容。

字段顺序固定为 `args`、`command`、`env`、`envFrom`、`image`、`imagePullPolicy`、`lifecycle`、`livenessProbe`、`name`、`ports`、`readinessProbe`、`resizePolicy`、`resources`、`restartPolicy`、`restartPolicyRules`、`securityContext`、`startupProbe`、`stdin`、`stdinOnce`、`terminationMessagePath`、`terminationMessagePolicy`、`tty`、`volumeDevices`、`volumeMounts`、`workingDir`。

`name` 必填并按 DNS_LABEL 校验，其余字段可选。`env`、`envFrom`、`lifecycle`、`livenessProbe`、`ports`、`readinessProbe`、`resizePolicy`、`resources`、`restartPolicyRules`、`securityContext`、`startupProbe`、`volumeDevices`、`volumeMounts` 委托同域子模板渲染；其余字段由本模板直接渲染。

#### Scenario: 渲染最简容器

- **WHEN** 上下文只提供 `name` 与 `image`
- **THEN** 输出包含 `image` 与 `name`，且 `image` 排在 `name` 之前

#### Scenario: 渲染完整结构

- **WHEN** 上下文提供全部 25 个字段且取值合法
- **THEN** 输出按固定顺序包含 25 个字段，字段间无缺失或错位

#### Scenario: name 缺失

- **WHEN** `name` 未提供、为 null、为空字符串或仅含空白
- **THEN** 渲染中断

#### Scenario: name 符合 DNS_LABEL

- **WHEN** `name` 为仅含小写字母、数字与 `-` 且首尾为字母或数字的字符串，长度不超过 63 字符
- **THEN** 校验通过并输出该 `name`

#### Scenario: name 不符合 DNS_LABEL

- **WHEN** `name` 含大写字母、下划线、点号或以 `-` 开头结尾，或长度超过 63 字符
- **THEN** 渲染中断，失败消息给出校验规则

#### Scenario: 委托字段

- **WHEN** `env`、`envFrom`、`lifecycle`、`livenessProbe`、`ports`、`readinessProbe`、`resizePolicy`、`resources`、`restartPolicyRules`、`securityContext`、`startupProbe`、`volumeDevices` 或 `volumeMounts` 非空
- **THEN** 该字段内容完全由对应子模板决定，本模板只传递上下文、回收结果并以该字段名为父键输出

#### Scenario: 委托结果为空

- **WHEN** 某个委托字段的上下文非空，但子模板返回空内容
- **THEN** 不输出该字段，且不中断渲染

#### Scenario: 布尔字段

- **WHEN** `stdin`、`stdinOnce` 或 `tty` 为布尔值
- **THEN** 输出对应的 YAML 布尔值，显式 `false` 同样输出

#### Scenario: 未知字段

- **WHEN** 上下文包含上述 25 个字段与引用字段以外的键
- **THEN** 该键被忽略，不参与输出

#### Scenario: 不输出 status

- **WHEN** 上下文包含 `status`
- **THEN** 该键被忽略

### Requirement: image 三源解析

系统 MUST 按 `imageFileRefs` > `imageRefs` > `image` 的优先级确定最终 `image`，并在最终结果为空时中断渲染。

#### Scenario: 仅提供 image

- **WHEN** 上下文只提供 `image` 且非空
- **THEN** 输出该 `image` 值

#### Scenario: imageRefs 覆盖 image

- **WHEN** `imageRefs` 可生成有效镜像且同时提供 `image`
- **THEN** 输出由 `imageRefs` 拼接得到的值，忽略 `image`

#### Scenario: imageFileRefs 覆盖其余来源

- **WHEN** `imageFileRefs` 可读取到有效内容，且同时提供 `imageRefs` 与 `image`
- **THEN** 输出由 `imageFileRefs` 得到的值，忽略 `imageRefs` 与 `image`

#### Scenario: 三个来源均不可得

- **WHEN** `imageFileRefs` 无有效内容、`imageRefs` 未提供且 `image` 为空
- **THEN** 渲染中断

#### Scenario: imageRefs 拼接完整引用

- **WHEN** `imageRefs` 提供 `registry`、`namespace`、`repository`、`tag`、`digest`
- **THEN** 输出形如 `registry/namespace/repository:tag@digest` 的引用

#### Scenario: imageRefs 去除首尾斜杠

- **WHEN** `imageRefs` 的 `registry` 或 `namespace` 带首尾 `/`
- **THEN** 输出中该段不带首尾 `/`

#### Scenario: imageRefs 省略 registry 与 namespace

- **WHEN** `imageRefs` 只提供 `repository`
- **THEN** 输出仅由 `repository` 与缺省标签规则组成，不产生多余分隔符

#### Scenario: imageRefs 缺少 repository

- **WHEN** `imageRefs` 的 `repository` 未提供、为 null 或为空字符串
- **THEN** 渲染中断

#### Scenario: tag 与 digest 均为空

- **WHEN** `imageRefs` 的 `tag` 与 `digest` 均为空
- **THEN** 输出不含标签与摘要尾缀，不补 `latest`

#### Scenario: digest 非空且 tag 为空

- **WHEN** `imageRefs` 的 `digest` 非空且 `tag` 为空
- **THEN** 标签取 `latest`

#### Scenario: digest 补全 sha256 前缀

- **WHEN** `imageRefs` 的 `digest` 不以 `sha256` 开头
- **THEN** 输出中的摘要带 `sha256:` 前缀

#### Scenario: imageFileRefs 解析为对象

- **WHEN** `imageFileRefs` 的文件内容解析为对象
- **THEN** 按 `imageRefs` 的拼接规则生成镜像引用

#### Scenario: imageFileRefs 解析为标量

- **WHEN** `imageFileRefs` 的文件内容解析为字符串
- **THEN** 直接使用该字符串作为镜像引用

### Requirement: 引用字段优先级

系统 MUST 在五个 `*FileRefs` 字段有有效结果时使用该结果，并忽略对应的内联字段。

#### Scenario: envFileRefs 覆盖 env

- **WHEN** 同时提供 `envFileRefs` 与 `env`，且 `envFileRefs` 可读取到有效内容
- **THEN** `env` 输出取自 `envFileRefs`

#### Scenario: envFromFileRefs 覆盖 envFrom

- **WHEN** 同时提供 `envFromFileRefs` 与 `envFrom`，且 `envFromFileRefs` 可读取到有效内容
- **THEN** `envFrom` 输出取自 `envFromFileRefs`

#### Scenario: resourcesFileRefs 覆盖 resources

- **WHEN** 同时提供 `resourcesFileRefs` 与 `resources`，且 `resourcesFileRefs` 可读取到有效内容
- **THEN** `resources` 输出取自 `resourcesFileRefs`

#### Scenario: FileRefs 无有效结果时回退

- **WHEN** `*FileRefs` 字段未提供或解析后无有效内容
- **THEN** 使用对应的内联字段

#### Scenario: FileRefs 条目缺少 filePath

- **WHEN** `*FileRefs` 的任一条目缺少 `filePath` 或为空
- **THEN** 渲染中断

#### Scenario: FileRefs 指向 Chart 外路径

- **WHEN** `*FileRefs` 的 `filePath` 为绝对路径或逃逸 Chart 根目录
- **THEN** 渲染中断

### Requirement: 枚举字段校验

系统 MUST 对具有官方枚举的字符串字段执行大小写敏感校验。

#### Scenario: imagePullPolicy 合法取值

- **WHEN** `imagePullPolicy` 为 `Always`、`Never` 或 `IfNotPresent`
- **THEN** 输出该值

#### Scenario: imagePullPolicy 非法取值

- **WHEN** `imagePullPolicy` 不是上述三个值之一
- **THEN** 渲染中断，失败消息给出合法范围

#### Scenario: restartPolicy 合法取值

- **WHEN** `restartPolicy` 为 `Always`、`OnFailure` 或 `Never`
- **THEN** 输出该值

#### Scenario: restartPolicy 非法取值

- **WHEN** `restartPolicy` 不是上述三个值之一
- **THEN** 渲染中断，失败消息给出合法范围

#### Scenario: terminationMessagePolicy 合法取值

- **WHEN** `terminationMessagePolicy` 为 `File` 或 `FallbackToLogsOnError`
- **THEN** 输出该值

#### Scenario: terminationMessagePolicy 非法取值

- **WHEN** `terminationMessagePolicy` 不是上述两个值之一
- **THEN** 渲染中断，失败消息给出合法范围

#### Scenario: 枚举大小写敏感

- **WHEN** 枚举字段取 `always`、`onfailure` 等非精确匹配形式
- **THEN** 渲染中断，不做大小写归一化

### Requirement: 上下文契约

系统 MUST 以展开后的单个容器字段 map 作为上下文，不要求 `containers` 包装键；`os`、`Files`、`Values`、`Context` 与容器字段处于同一层。

#### Scenario: 顶层字段直接生效

- **WHEN** 调用方以容器字段 map 直接作为上下文
- **THEN** 本模板正常渲染，不从 `containers` 键读取字段

#### Scenario: os 透传给 securityContext

- **WHEN** 上下文提供 `os` 且 `securityContext` 非空
- **THEN** `os` 随 `securityContext` 一起传给 `definitions.securityContext`

#### Scenario: Files 用于 FileRefs

- **WHEN** 上下文提供 `Files` 且 `*FileRefs` 非空
- **THEN** 按 `filePath` 从 `Files` 读取内容

#### Scenario: 调用方去掉 containers 包装键

- **WHEN** `core.podSpec` 渲染 `containers` 或 `initContainers`
- **THEN** 传给本模板的上下文不包含 `containers` 包装键

## 非目标

- 不实现 `definitions.enVar`、`definitions.envFromSource`、`definitions.lifecycle`、`definitions.probe`、`definitions.containerPort`、`definitions.containerResizePolicy`、`definitions.containerRestartRule`、`definitions.securityContext`、`definitions.volumeDevice`、`definitions.volumeMount`。
- 不处理 `ephemeralContainers` 与 `ContainerStatus`。
- 不处理其他 PodSpec 字段，也不组合多个资源。
