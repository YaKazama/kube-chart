## 添加库 Chart

- 同步仓库到本地
- 进入需要制作 YAML 文件的 Chart（目录）
- 执行 `helm dependency update` 同步依赖包
  - 查看 `Chart.yaml` 中的 `dependencies` 进行确认

    ```bash
    dependencies:
    - name: kube-chart
      version: v1.34
      repository: https://helm-repository.example.com/
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
- 类型处理原则：
  - `string`：同名替换。
  - `list`：合并、去空、去重。参考 [concat](https://helm.sh/zh/docs/chart_template_guide/function_list/#concat)、[mustCompact](https://helm.sh/zh/docs/chart_template_guide/function_list/#compact-mustcompact)、[mustUniq](https://helm.sh/zh/docs/chart_template_guide/function_list/#uniq-mustuniq)
  - `dict`：合并、同名替换。从右到左覆盖，参考 [mustMergeOverwrite](https://helm.sh/zh/docs/chart_template_guide/function_list/#mergeoverwrite-mustmergeoverwrite)
- 取值顺序（先后）：命令行传值覆盖 > `.Context` > `.Values` > `.Values.global`
  - 命令行参数传值：由模板决定。
  - 从组件自身命名空间（一般会映射到 `.Context`）取值：由模板决定。
  - 从 `.Values` 取值：跳出组件自身命名空间的定义，但也不在 `.Values.global` 中定义。
  - 从 `.Values.global` 取值：有限的定义，一般是 **跨组件、跨模板甚至跨子 chart 共享的通用配置**。
- 针对 `values.yaml` 中的变量定义，确保“变量类型唯一”（本质是类型的一致性和可预测性）。保持类型稳定能避免模板渲染错误、逻辑异常，提高配置的可维护性。这是 Helm 配置管理中减少隐蔽问题的关键实践之一。
- 模板定义只专注处理内部的字段。

## TODO

- `env, resource, image`: 从指定文件加载配置
  - `envFiles`
  - `envFromFiles`
  - `resourcesFiles`
  - `imageFiles`
- `$` 根作用域丢失 31522
  - 12115 中指出，此问题不会有任何处理
  - 需要单独处理，必要时将单独将全局上下文传递下去
- `volumes`: 是否支持原生 map 格式？
- Kustomization
- base.fail 重写或移除
