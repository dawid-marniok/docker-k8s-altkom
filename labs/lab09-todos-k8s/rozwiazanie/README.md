# Lab 09 — rozwiązanie

| Plik | Co zawiera |
|---|---|
| `01-mongo.yaml` | ten sam plik co w labie: PVC, Deployment (strategia `Recreate`) i Service `mongo` |
| `02-api.yaml` | ConfigMap `api-config`, Secret `api-secret`, Deployment `api` (2 repliki, sondy, limity) i Service `api` |
| `03-web.yaml` | Deployment `web`, Service `web` (80 → 8080) i Ingress `todos` dla `todos.localhost` |

Wdrożenie całości (z katalogu `labs/lab09-todos-k8s/`, po kroku 0 — `kind load`):

```bash
kubectl apply -f rozwiazanie/
kubectl get all -l part-of=todos
curl http://todos.localhost/api/info
```

## Na co zwrócić uwagę

- `imagePullPolicy: IfNotPresent` — obrazy `todos-*` są tylko w klastrze (wgrane przez `kind load`), nie w rejestrze.
- Service API musi nazywać się `api` i mieć port `3000`: obraz `web` ma wpisane `API_URL=http://api:3000`.
- `readinessProbe` na `/readyz` — API dostaje ruch dopiero, gdy połączy się z bazą. `livenessProbe` na `/healthz` sprawdza tylko, czy proces żyje — inaczej awaria bazy restartowałaby wszystkie pody API.
- `MONGO_URL` jest w Secrecie, bo w prawdziwej aplikacji zawiera login i hasło do bazy.
- Etykieta `part-of: todos` na każdym obiekcie pozwala jednym poleceniem pokazać i usunąć całą aplikację.

## Dla chętnych

[`dla-chetnych/04-hpa.yaml`](dla-chetnych/04-hpa.yaml) — HPA dla `api`. Leży w podkatalogu, więc `kubectl apply -f rozwiazanie/` go nie wdraża. Ręcznie: `kubectl apply -f rozwiazanie/dla-chetnych/04-hpa.yaml`.

Gdy działa HPA, liczbą replik `api` steruje on. `replicas: 2` w `02-api.yaml` przy kolejnym `apply` na chwilę ją nadpisze, a HPA zaraz ją poprawi. W projektach z HPA pole `replicas` zwykle usuwa się z Deploymentu.
