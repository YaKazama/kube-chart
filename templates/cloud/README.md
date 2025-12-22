
云平台

包括：

  - GCP
    - BackendConfig 参考：
      - https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-configuration?hl=zh-cn

    - ManagedCertificate 参考：
      - https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs?hl=zh-cn

  - Tencent
    - https://cloud.tencent.com/document/product/457/45490
    - https://cloud.tencent.com/document/product/457/45700

## 使用

GCP

- BackendConfig
  - 1 在 Service 所在的命名空间中创建 BackendConfig 对象。
  - 2 您可以使用 cloud.google.com/backend-config 或 beta.cloud.google.com/backend-config 注释来指定 BackendConfig 的名称。

- ManagedCertificate
  - 1 在 Ingress 所在的命名空间中创建 ManagedCertificate 对象。
  - 2 通过将 networking.gke.io/managed-certificates 注解添加到 Ingress，将 ManagedCertificate 对象与 Ingress 相关联。此注解一个是英文逗号分隔的 ManagedCertificate 对象列表。

Tencent

- 通过 Ingress 注解 ingress.cloud.tencent.com/tke-service-config:<config-name>，您可以指定目标配置应用到 Ingress 中。
- 通过 Service 注解 service.cloud.tencent.com/tke-service-config:<config-name>，您可以指定目标配置并应用到 Service 中。
