
云平台

包括：

  - GCP
  - Tencent
    - https://cloud.tencent.com/document/product/457/45490
    - https://cloud.tencent.com/document/product/457/45700

## 使用

- 通过 Ingress 注解 ingress.cloud.tencent.com/tke-service-config:<config-name>，您可以指定目标配置应用到 Ingress 中。
- 通过 Service 注解 service.cloud.tencent.com/tke-service-config:<config-name>，您可以指定目标配置并应用到 Service 中。
