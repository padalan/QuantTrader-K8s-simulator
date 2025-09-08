# GitOps Structure

This directory hosts ArgoCD Application and environment configurations.

```
gitops/
├── applications/
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
└── shared/
```

- `applications/`: ArgoCD Application manifests for services
- `environments/`: Kustomize overlays per environment
- `shared/`: Common patches/manifests shared across envs 