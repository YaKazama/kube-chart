目标: 新增命名模板 `definitions.LabelSelector`，写入 `templates/api-resources/Definitions/_LabelSelector.tpl`
需求:
- 入参：dict，由 `definitions.DeploymentSpec` 传递, 包含 `matchLabels`、`matchExpressions` 字段
- 字段：
  - `matchExpressions`: array，可选
  - `matchLabels`: object，必填。上层引入了 `base.labels` 模板，默认会有 `name` 字段
 行为：
- `matchExpressions`: array(string/原生 object)，委托 `definitions.labelSelectorRequirement`
  - 列表元素支持 string/原生 object（包括 `key`（必填）、`operator`（必填）、`values` 字段）类型
  - string 类型：
    - 标签选择可以基于等值(=、== 和 !=)、基于集合(In、NotIn、Exists、DoesNotExist)、基于原生定义。重点参考 https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors
    - 正则定义参考：`k8s.selector.equality0`、`k8s.selector.set0`、`k8s.selector.setExists`
- `matchLabels`: object，直接渲染
边界：
  - 引用 `docs/rules/const-boundary.md`
  - `matchExpressions`：向下传递前，需要选转换为 dict 类型；回收时，需要去重、去空。
    - 列表元素：
      - dict 类型：原生 object 类型，直接传递，包括 `key`（必填）、`operator`（必填）、`values` 字段
      - string 类型：正则解析为 dict 后传递，包含 `key`、`operator`、`values` 字段
约束:
- 引用 `docs/rules/const-general.md`
- 允许读取`参考`提供的 URL ，通过 Field 和 Description 确认是否必填项及正则校验、可用设置、默认值、数量限制等
参考:
- API：
  - https://kubernetes.io/docs/reference/kubernetes-api/definitions/label-selector-v1-meta/#LabelSelector
  - https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#labelselector-v1-meta
  - https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
  - https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors
- 示例代码：
  - 引用 `docs/rules/const-example-code.md`
