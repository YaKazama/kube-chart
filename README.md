## 添加库 Chart

- 同步仓库到本地
- 进入需要制作 YAML 文件的 Chart（目录）
- 执行 `helm dependency update` 同步依赖包
  - 查看 `Chart.yaml` 中的 `dependencies` 进行确认

    ```bash
    dependencies:
    - name: library-charts
      version: v0.1.0
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
export VERSION="0.1.0"

helm package .
helm repo index . --url https://helm-repository.example.com
curl -XPUT https://helm-repository.example.com/upload/<example>-${VERSION}.tgz --data-binary @<example>-${VERSION}.tgz
curl -XPUT https://helm-repository.example.com/upload/index.yaml --data-binary @index.yaml
rm -rf <example>-${VERSION}.tgz index.yaml
```
