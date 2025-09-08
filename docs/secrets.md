# Secrets Management (External Secrets Operator)

## Install ESO

```
kubectl create namespace external-secrets
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds.yaml
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/operator.yaml
```

## AWS Secrets Manager

- Create a test secret:
```
aws secretsmanager create-secret --name test-secret --secret-string '{"key":"value"}'
```

- Create SecretStore and ExternalSecret manifests in `gitops/shared/eso/`

## Verify
```
kubectl get secret test-secret -o yaml
``` 