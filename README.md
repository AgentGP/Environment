# Environment
### aka, k8s home lab cause I always wanted one  
A small Kubernetes platform I'm building step by step: a reusable Helm chart for services, Gateway API routing through Traefik, and self-hosted apps on top. It runs on minikube today and is headed for k3s, provisioned with Terraform.

## How traffic gets in

```
browser ── http://joplin.localhost
   │
   ▼
Traefik (Service: LoadBalancer, port 80)
   │   Gateway "traefik-gateway"
   ▼
HTTPRoute  joplin.localhost  /
   │
   ▼
Service joplin (ClusterIP :22300) ──► Joplin pod ──► Service joplin-postgres (ClusterIP :5432) ──► Postgres pod
```

Only Traefik is exposed. Every app stays on ClusterIP and gets a route by setting `httpRoute.enabled: true`.

## Repo layout

| Path | What it is |
|---|---|
| `platform/base/` | Cluster-wide prerequisites, applied once with Kustomize. Right now: the Gateway API CRDs, pinned to v1.6.3. |
| `microservice/` | A generic chart: Deployment, Service, ConfigMap, Secret and HTTPRoute, all driven by values. |
| `services/<app>/` | One wrapper chart per app. It pulls in `microservice` (aliased once per component) or an upstream chart, and holds that app's values. |
| `*.ps1` | Small shortcuts for the Helm commands I run most. |

## Running it

**Prerequisites:** minikube, kubectl, Helm.

1. **Install the Gateway API CRDs**
   ```bash
   kubectl apply -k platform/base
   ```
2. **Install Traefik**
   ```bash
   helm dependency update services/traefik
   helm upgrade -i traefik services/traefik
   ```
3. **Create the secret values.** This file is gitignored and never committed:
   ```yaml
   # services/joplin/values-secret.yaml
   global:
     environment:
       secret:
         POSTGRES_PASSWORD: <your password>
   ```
4. **Install Joplin**
   ```bash
   helm dependency update services/joplin
   helm upgrade -i joplin services/joplin -f services/joplin/values-secret.yaml
   ```
5. **Open it.** On minikube the LoadBalancer has no external IP, so forward Traefik locally and browse to http://joplin.localhost:
   ```bash
   kubectl port-forward svc/traefik 80:80
   ```

## Design decisions

- **Gateway API instead of Ingress.** It's where Kubernetes routing is heading, and it separates roles: the platform owns the `Gateway`, and each app owns its `HTTPRoute`. Ingress puts everything in one resource plus controller-specific annotations. The best-known Ingress controller, ingress-nginx, was retired in 2026.
- **CRDs live in `platform/`, not inside the Traefik chart.** A CRD is cluster-wide and can be shared by several controllers. Helm never upgrades or deletes CRDs it installed, so a pinned Kustomize reference is easier to upgrade, with one version bump in git.
- **One shared `microservice` chart.** Most simple services need the same handful of resources. Each app is just values, and a fix in the chart reaches every app.
- **Global values as defaults.** Values under `global.environment` (for example the DB password) reach every component. A component's own values override them.

## Status and next steps

WoWorking: Gateway API + Traefik routing, secrets kept out of git.

In progress: connecting Joplin to Postgres through the shared secret.
nown gaps:
- Secrets are supplied by hand through a gitignored values file.
- Postgres has no persistent volume yet, so data is lost when the pod restarts.

Next:
1. CI: `helm lint`, schema validation and image scanning on every PR
2. GitOps with Argo CD
3. k3s on VMs provisioned with Terraform
4. Monitoring, alerts and Postgres backups
5. Hardening: NetworkPolicies, Sealed Secrets, resource limits
or abstraction.


