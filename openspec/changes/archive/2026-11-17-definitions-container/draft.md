---
change-id: definitions-container
updated_at: "2026-11-16T15:06:48Z"
---

# definitions.container 模板

## 目标

- 新增 `definitions.container` 模板，用于渲染 Kubernetes `Container` 子对象。

## 需求

- 上下文为原生 map，包含 `os`、`Files`、`Values`、`Context` 以及 Container 自身字段。
- 父级模板传入的上下文不包含 `containers` 包装键，而是直接传入 `containers` map 中的单个元素字段，外加 `os`、`Files`、`Values`、`Context`。
- `Files`、`Values`、`Context` 由 `base.get` 隐式处理，本模板不做额外取值封装。
- `os` 需继续透传给 `securityContext` 子模板，作为其判断条件。
- `name` 必填并按 DNS_LABEL 校验（RFC1123 label：小写字母数字与 `-`，首尾为字母数字，最长 63 字符），复用 `base.rfc` 的 `1123` 模式，校验不通过时中断；其余字段可选。
- `image` 的必填指：处理完 `imageFileRefs`、`imageRefs`、`image` 三个来源后，若最终 `image` 仍为空则中断报错。
- 字段按官方文档顺序渲染；除必要逻辑外采用直白写法。
- 以下字段委托同名子模板渲染：

  | 字段 | 子模板 |
  |---|---|
  | `env` | `definitions.enVar` |
  | `envFrom` | `definitions.envFromSource` |
  | `lifecycle` | `definitions.lifecycle` |
  | `livenessProbe` | `definitions.probe` |
  | `ports` | `definitions.containerPort` |
  | `readinessProbe` | `definitions.probe` |
  | `resizePolicy` | `definitions.containerResizePolicy` |
  | `resources` | `definitions.resourceRequirements` |
  | `restartPolicyRules` | `definitions.containerRestartRule` |
  | `securityContext` | `definitions.securityContext` |
  | `startupProbe` | `definitions.probe` |
  | `volumeDevices` | `definitions.volumeDevice` |
  | `volumeMounts` | `definitions.volumeMount` |

- 额外支持以下引用字段：

  | 字段 | 形态 |
  |---|---|
  | `imageFileRefs` | `slice` |
  | `imageRefs` | `map` |
  | `envFileRefs` | `slice` |
  | `envFromFileRefs` | `slice` |
  | `resourcesFileRefs` | `slice` |

- `image` 按 `*FileRefs` > `imageRefs` > `image` 的优先级解析：先处理 `imageFileRefs`，再处理 `imageRefs`，最后回退 `image`；最终 `image` 不能为空。
- `imageRefs` 包含 `registry`、`namespace`、`repository`、`tag`、`digest`，其中 `repository` 必填，其余可选。
- `imageRefs` 的 `registry`、`namespace` 去除首尾 `/`。
- `imageRefs` 的 `tag` 与 `digest` 均为空时两者都不处理；`digest` 非空且 `tag` 为空时 `tag` 取 `latest`。
- `imageRefs` 的 `digest` 不以 `sha256` 开头时补全 `sha256:` 前缀。
- 除 13 个委派字段外，官方 Container 的其余字段均由本模板直接渲染。
- `restartPolicy` 按 `Always`、`OnFailure`、`Never` 枚举校验。
- `*FileRefs` 字段优先级高于对应的原生字段：`envFileRefs` > `env`、`envFromFileRefs` > `envFrom`，其他 `*FileRefs` 同理。
- 部分字段有枚举校验，取值以官方文档列出的为准。
- 本 change 同步修改调用方 `templates/api-resources/Core/_PodSpec.tpl` 的上下文构造，去掉 `containers` 包装键。

## 期望输入格式

```yaml
args: <string array>
command: <string array>
env: <EnvVar array>
envFrom: <EnvFromSource array>
image: <string>
imagePullPolicy: <string>
lifecycle: <Lifecycle>
livenessProbe: <Probe>
name: <string>
ports: <ContainerPort array>
readinessProbe: <Probe>
resizePolicy: <ContainerResizePolicy array>
resources: <ResourceRequirements>
restartPolicy: <string>
restartPolicyRules: <ContainerRestartRule array>
securityContext: <SecurityContext>
startupProbe: <Probe>
stdin: <boolean>
stdinOnce: <boolean>
terminationMessagePath: <string>
terminationMessagePolicy: <string>
tty: <boolean>
volumeDevices: <VolumeDevice array>
volumeMounts: <VolumeMount array>
workingDir: <string>
```

`imageRefs` 示例：

```yaml
imageRefs:
  registry: registry.example.com
  namespace: library
  repository: nginx
  tag: "1.27"
  digest: abc123
```

## 约束

- 上表列出的 13 个子模板仅作为占位依赖，不在本 change 创建。
- `image` 拼接行为可参考本地存在的旧版实现 `origin/release/v1.34:templates/api-resources/Workloads/_Container.tpl` 中的 `workloads.Container.image` 与 `workloads.Container.imageRef`。

## 非目标

- 不创建上述 13 个子模板。
- 不处理其他 PodSpec 字段，也不组合多个资源。

## 验收

- 仅提供 `name` 与可解析的 `image` 时模板正常渲染，输出包含 `name` 与 `image`。
- 字段输出顺序与官方文档顺序一致。
- `imageFileRefs`、`imageRefs`、`image` 三者按优先级取最高有效来源；三者均不可得时渲染中断。
- 仅提供 `imageRefs` 且 `repository` 非空、`image` 留空时，模板正常渲染并输出拼接后的 `image`。
- `imageRefs` 缺少 `repository` 时渲染中断。
- `imageRefs` 的 `tag` 与 `digest` 均为空时，输出不含对应尾缀；`digest` 非空且 `tag` 为空时输出 `latest` 标签；`digest` 不以 `sha256` 开头时输出补全前缀后的值。
- `name` 缺失时渲染中断。
- `name` 不符合校验规则时渲染中断。
- `restartPolicy` 不在 `Always`、`OnFailure`、`Never` 内时渲染中断。
- 枚举字段取值不在官方枚举内时渲染中断。
- `envFileRefs`、`envFromFileRefs` 有值时优先于 `env`、`envFrom`。
- `templates/api-resources/Core/_PodSpec.tpl` 调用 `definitions.container` 时不再传递 `containers` 包装键。

## 开放问题

- 无。
