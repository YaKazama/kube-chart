## 添加库 Chart

- 同步仓库到本地
- 进入需要制作 YAML 文件的 Chart（目录）
- 执行 `helm dependency update` 同步依赖包
  - 查看 `Chart.yaml` 中的 `dependencies` 进行确认

    ```bash
    dependencies:
    - name: kube-chart
      version: v1.34
      repository: https://helm.12334.icu/
    ```

  - 若遇到以下报错，可忽略。

    ```txt
    Could not verify charts/.gitkeep for deletion: file 'charts/.gitkeep' does not appear to be a gzipped archive; got 'application/octet-stream' (Skipping)
    ```

示例：

```bash
git clone https://git.example.com/helm-charts/example.git
cd path/to/example
helm dependency update
```

## 发布

- 进入目录并检查目录结构
- 打包 `tgz` 文件
  - 检查 `Chart.yaml` 中的 `version`
- 制作 `index.yaml` 文件
  - 注意 **合并** 文件操作
- 上传打包后的 `tgz` 文件及 `index.yaml`
- 清理本地文件

示例：

```bash
cd path/to/example
export VERSION="1.34"

helm package .
helm repo index . --url https://helm-repository.example.com
curl -XPUT https://helm-repository.example.com/upload/<example>-${VERSION}.tgz --data-binary @<example>-${VERSION}.tgz
curl -XPUT https://helm-repository.example.com/upload/index.yaml --data-binary @index.yaml
rm -rf <example>-${VERSION}.tgz index.yaml
```

## 约束

- 尽早报错退出。
- 应用前需要对值进行类型判断。
- 类型处理原则（[base.getValue](templates/base/_base.tpl#L20)）：
  - `string`：同名替换。
  - `list`：合并、去空、去重。参考 [concat](https://helm.sh/zh/docs/chart_template_guide/function_list/#concat)、[mustCompact](https://helm.sh/zh/docs/chart_template_guide/function_list/#compact-mustcompact)、[mustUniq](https://helm.sh/zh/docs/chart_template_guide/function_list/#uniq-mustuniq)
  - `dict`：合并、同名替换。按 *取值顺序* 从左到右覆盖，参考 [mustMerge](https://helm.sh/zh/docs/chart_template_guide/function_list/#merge-mustmerge)
- 取值顺序（先后）：命令行传值覆盖 > 模板定义内部上下文 > `.Context` > `.Values` > `.Values.global`
  - 命令行参数传值：由模板决定。
  - 模板定义内部上下文: 具体的处理逻辑参考 [base.getValue](templates/base/_base.tpl#L20) 模板定义。
    - 主要针对模板定义接收到的上下文并不是最顶层的情况。这并不影响后续取值。
  - 从组件自身命名空间（一般会映射到 `.Context`）取值：由模板决定。
  - 从 `.Values` 取值：跳出组件自身命名空间的定义，但也不在 `.Values.global` 中定义。
  - 从 `.Values.global` 取值：有限的定义，一般是 **跨组件、跨模板甚至跨子 chart 共享的通用配置**。
- 针对 `values.yaml` 中的变量定义，确保“变量类型唯一”（本质是类型的一致性和可预测性）。保持类型稳定能避免模板渲染错误、逻辑异常，提高配置的可维护性。这是 Helm 配置管理中减少隐蔽问题的关键实践之一。
- 模板定义只专注处理内部的字段。
  - 每一个模板定义均只处理自身的数据，这些数据理论上应该是 map 类型。
  - values.yaml 中定义的如果是字符串，则在外层将这些数据单独处理后再向下传递，尽量减少认知、逻辑处理负担且保持模板定义只处理 map 类型。
- 自定义参数：
  - `helmLabels(bool)`: true/false
  - `imageRef(object/map)`: 基于 map 格式管理 containers[].image 。使用多个字段拼接 `image` 镜像名称
    - `registry`: 这一般是一个域名（可以带上端口号，如 example.com:443 ）
    - `namespace`: 格式 a/b/c 或 a
    - `repository`: 【必填】镜像名
    - `tag`: 镜像标签 默认值 latest
    - `digest`: 镜像 sha256 摘要
  - `X.service`: 基于某个 workloads 资源下定义 Service
  - `*FileRefs`: 基于外部文件的配置管理。均为 list 格式。优先级 `*FileRefs`（多个值时，后定义的优先生效） 最高，其次是 `imageRef`（如果 `imageRef` 存在），最后是 `image`、`env`、`envFrom`、`resources`、`data`、`binaryData`、`stringData`
    - `envFileRefs`: 在外部文件管理 containers[].env
      - 列表支持参数
        - `filePath`: 外部文件路径。这是一个相对路径
        - `fieldPaths`: 外部文件中的取值路径，格式为 “path.to.key”。可以为空
    - `envFromFileRefs`: 在外部文件管理 containers[].envFrom
      - 列表支持参数同 `envFileRefs`
    - `resourcesFileRefs`: 在外部文件管理 containers[].resources
      - 列表支持参数同 `envFileRefs`
    - `imageFileRefs`: 在外部文件管理 containers[].image
      - 列表支持参数同 `envFileRefs`
    - `dataFileRefs`: 在外部文件管理 configMap.data
      - 列表支持参数
        - `filePath`: 外部文件路径。这是一个相对路径
        - `key`: 文件内容所属的 key。可以为空，为空时会将 `filePath` 中的文件名作为 key
    - `binaryDataFileRefs`: 在外部文件管理 configMap.binaryData
      - 列表支持参数同 `dataFileRefs`
    - `dataFileRefs`: 在外部文件管理 secret.data
      - 列表支持参数同 `dataFileRefs`
    - `stringDataFileRefs`: 在外部文件管理 secret.stringData
      - 列表支持参数同 `dataFileRefs`
