# Lab 09 — Ćwiczenie końcowe: ToDos na Kubernetesie

**Cel:** przenieść ToDos z Docker Compose (lab04) na klaster i otworzyć go pod adresem http://todos.localhost.
**Czas:** ok. 50 minut · katalog `labs/lab09-todos-k8s/`

To ćwiczenie składa wszystko z dwóch dni: obraz, Deployment, Service, ConfigMap, Secret, sondy i Ingress.

## Od Compose do Kubernetesa

| W `compose.yaml` | W Kubernetesie |
|---|---|
| `services.api` z `image` | Deployment `api` |
| nazwa usługi `api` jako adres | Service `api` |
| `environment:` | ConfigMap + Secret (`envFrom`) |
| `healthcheck` | `readinessProbe` / `livenessProbe` |
| `volumes: mongo-data` | PersistentVolumeClaim |
| `ports: "8080:8080"` | Service `web` + Ingress |
| `--scale api=3` | `replicas: 3` |

## Krok 0. Obrazy w klastrze

Obrazy z lab04 są w Dockerze na laptopie, a węzły kind mają własny magazyn obrazów. Wgraj je:

```bash
docker image ls | grep todos            # todos-api:1.0 i todos-web:1.0
# brak? zbuduj:
#   docker build -t todos-api:1.0 ../../app/todos/api
#   docker build -t todos-web:1.0 ../../app/todos/web
kind load docker-image todos-api:1.0 todos-web:1.0 --name szkolenie
```

W manifestach ustaw `imagePullPolicy: IfNotPresent`, żeby Kubernetes nie szukał tych obrazów w internecie.

## Krok 1. Baza

```bash
kubectl apply -f 01-mongo.yaml
kubectl get pvc,pods -l app=mongo
```

## Krok 2. API — napisz `02-api.yaml`

Wymagania:
- **ConfigMap** `api-config`: `APP_VERSION: "1.0"`, `DB_NAME: todos`
- **Secret** `api-secret`: `MONGO_URL: mongodb://mongo:27017` (użyj `stringData`)
- **Deployment** `api`: obraz `todos-api:1.0`, 2 repliki, port 3000, `envFrom` z ConfigMap i Secret
  - `readinessProbe`: `httpGet` na `/readyz`, port 3000
  - `livenessProbe`: `httpGet` na `/healthz`, port 3000
  - `resources`: requests `50m`/`64Mi`, limits `250m`/`128Mi`
- **Service** `api` na porcie 3000 — **nazwa ma znaczenie**: `web` szuka API pod `http://api:3000`

```bash
kubectl apply -f 02-api.yaml
kubectl get pods -l app=api        # READY 1/1 dopiero, gdy API połączy się z bazą
kubectl logs deploy/api
```

## Krok 3. Strona — napisz `03-web.yaml`

- **Deployment** `web`: obraz `todos-web:1.0`, 2 repliki, port 8080, `readinessProbe` na `/healthz`, port 8080
- **Service** `web`: port 80 → `targetPort` 8080
- **Ingress** `todos`: host `todos.localhost`, ścieżka `/` → Service `web`, port 80

```bash
kubectl apply -f 03-web.yaml
kubectl get ingress todos
```

## Jak sprawdzić

```bash
kubectl get all -l part-of=todos
curl http://todos.localhost/api/info
```

Otwórz http://todos.localhost i dodaj kilka zadań.

## SUKCES

- [ ] strona działa pod http://todos.localhost, zadania się zapisują
- [ ] na górze strony widać zmieniającą się nazwę poda API (odśwież kilka razy)
- [ ] `kubectl delete pod -l app=mongo` → po chwili zadania nadal są (PVC)
- [ ] `kubectl delete pod -l app=api` → strona działa dalej albo wraca po kilku sekundach

## Dla chętnych

1. **Nowa wersja bez przerwy:** zmień `APP_VERSION` w ConfigMap na `"1.1"`, zrób `kubectl rollout restart deploy/api` i obserwuj stronę.
2. **Rollback:** ustaw w Deploymencie obraz `todos-api:2.0` (nie istnieje). Co się dzieje ze stroną? Cofnij `kubectl rollout undo deploy/api`.
3. **Autoskalowanie:** `kubectl autoscale deploy api --min=2 --max=5 --cpu-percent=50`, potem `kubectl get hpa -w`.
4. **Gdzie jest dysk?** `kubectl get pv`, `kubectl describe pvc mongo-data`.

## Gdy coś nie działa

| Objaw | Gdzie szukać |
|---|---|
| pod `mongo` w `CrashLoopBackOff`, w `kubectl describe pod -l app=mongo` kod wyjścia 132 | brak AVX w procesorze (tak jak w lab04): w `01-mongo.yaml` ustaw obraz `mongo:4.4` |
| `ErrImageNeverPull` / `ImagePullBackOff` | krok 0 (`kind load`) i `imagePullPolicy: IfNotPresent` |
| pod API `0/1 READY` | `kubectl logs deploy/api` — czy jest połączenie z bazą? czy Service `mongo` istnieje? |
| strona działa, ale „Brak połączenia z API” | czy Service nazywa się dokładnie `api` i ma port 3000? `kubectl get endpointslices` |
| `404 page not found` pod todos.localhost | `kubectl describe ingress todos` — host, nazwa Service, port |

## Sprzątanie (dopiero po zakończeniu szkolenia)

```bash
kubectl delete all,ingress,configmap,secret,pvc -l part-of=todos
./setup/start-klastra.sh --usun        # z głównego katalogu repo: usuwa cały klaster
```
