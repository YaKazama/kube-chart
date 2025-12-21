
基于 [kubernetes-api v1.34](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.34/)，字段的定义，与 k8s 原生字段及语义对齐，但有许多字段进行了抽象处理。可查看各配置文件示例：

- Workloads
  - [CronJob](CronJob.yaml)
  - [DaemonSet](DaemonSet.yaml)
  - [Deployment](Deployment.yaml)
  - [Job](Job.yaml)
  - [StatefulSet](StatefulSet.yaml)

- Service
  - [Ingress](Ingress.yaml)
  - [IngressClass](IngressClass.yaml)
  - [Service](Service.yaml)

- Config and Storage
  - [ConfigMap](ConfigMap.yaml)
  - [Secret](Secret.yaml)
  - [StorageClass](StorageClass.yaml)

- Metadata
  - [HorizontalPodAutoscaler](HorizontalPodAutoscaler.yaml)
  - [PodTemplate](PodTemplate.yaml)

- Cluster
  - [Binding](Binding.yaml)
  - [ClusterRole](ClusterRole.yaml)
  - [ClusterRoleBinding](ClusterRoleBinding.yaml)
  - [Namespace](Namespace.yaml)
  - [PersistentVolume](PersistentVolume.yaml)
  - [Role](Role.yaml)
  - [RoleBinding](RoleBinding.yaml)
  - [ServiceAccount](ServiceAccount.yaml)
  - [NetworkPolicy](NetworkPolicy.yaml)

- Cloud
  - [Cloud](Cloud.yaml)

- Kustomize
  - [Kustomization](Kustomization.yaml)

- MetalLB
  - [MetalLB](MetalLB.yaml)

调用示例，可以在以下文件中查看：

- [example](example.yaml)
- [values-dev-example](values-dev-example.yaml)
- [values](values.yaml)
