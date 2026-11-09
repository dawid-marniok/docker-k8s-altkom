# Lab 09 — Ćwiczenie końcowe: ToDos na Kubernetesie

**Cel:** przenieść ToDos z Docker Compose (lab04) na klaster i otworzyć go pod adresem http://todos.localhost.
Katalog `labs/lab09-todos-k8s/`

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

PVC przez pierwsze sekundy ma status `Pending` — to normalne: dysk powstaje dopiero, gdy pod bazy trafi na węzeł. Po chwili: `Bound` i pod `Running`.

> **Etykiety:** każdy obiekt w `01-mongo.yaml` ma etykiety `app: mongo` i `part-of: todos`. Nadaj tak samo `part-of: todos` wszystkim obiektom, które napiszesz w krokach 2 i 3 (a `app: api` / `app: web` odpowiednio). Dzięki temu zadziała sprawdzanie `kubectl get all -l part-of=todos` i sprzątanie na końcu. `01-mongo.yaml` to też dobry wzór składni Deploymentu i Service.

## Krok 2. API — napisz `02-api.yaml`

Wymagania:
- **ConfigMap** `api-config`: `APP_VERSION: "1.0"`, `DB_NAME: todos`
- **Secret** `api-secret`: `MONGO_URL: mongodb://mongo:27017` (użyj `stringData`)
- **Deployment** `api`: obraz `todos-api:1.0`, 2 repliki, port 3000, `envFrom` z ConfigMap i Secret
  - `readinessProbe`: `httpGet` na `/readyz`, port 3000
  - `livenessProbe`: `httpGet` na `/healthz`, port 3000
  - `resources`: requests `50m`/`64Mi`, limits `250m`/`128Mi`
- **Service** `api` na porcie 3000 — **nazwa ma znaczenie**: `web` szuka API pod `http://api:3000`

<details><summary>Podpowiedź: sondy i envFrom</summary>

```yaml
          envFrom:
            - configMapRef:
                name: api-config
            - secretRef:
                name: api-secret
          readinessProbe:
            httpGet:
              path: /readyz
              port: 3000
          livenessProbe:
            httpGet:
              path: /healthz
              port: 3000
```
</details>

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

1. **Nowa wersja bez przerwy:** w `02-api.yaml` zmień w ConfigMap `APP_VERSION` na `"1.1"`, zrób `kubectl apply -f 02-api.yaml`, potem `kubectl rollout restart deploy/api` i obserwuj stronę (zmienne z ConfigMap pod czyta tylko przy starcie).
2. **Rollback:** w `02-api.yaml` ustaw obraz `todos-api:2.0` (nie istnieje) i zrób `apply`. Co się dzieje ze stroną? Cofnij `kubectl rollout undo deploy/api`, a potem przywróć w pliku `todos-api:1.0` — inaczej następny `apply` znowu wdroży złą wersję.
3. **Autoskalowanie:** utwórz `04-hpa.yaml` z HorizontalPodAutoscalerem dla Deploymentu `api` (2–5 replik, 50% CPU), zrób `apply`, potem `kubectl get hpa -w`. Wzór: [`rozwiazanie/dla-chetnych/04-hpa.yaml`](rozwiazanie/dla-chetnych/04-hpa.yaml).
4. **Gdzie jest dysk?** `kubectl get pv`, `kubectl describe pvc mongo-data`.

## Gdy coś nie działa

| Objaw | Gdzie szukać |
|---|---|
| pod `mongo` w `CrashLoopBackOff`, w `kubectl describe pod -l app=mongo` kod wyjścia 132 | brak AVX w procesorze (tak jak w lab04): w `01-mongo.yaml` ustaw obraz `mongo:4.4` |
| `ErrImageNeverPull` / `ImagePullBackOff` | krok 0 (`kind load`) i `imagePullPolicy: IfNotPresent` |
| pod API `0/1 READY` | `kubectl logs deploy/api` — czy jest połączenie z bazą? czy Service `mongo` istnieje? |
| strona działa, ale „Brak połączenia z API” | czy Service nazywa się dokładnie `api` i ma port 3000? `kubectl get endpointslices` |
| `404 page not found` pod todos.localhost | `kubectl describe ingress todos` — host, nazwa Service, port |

## Rozwiązanie

Gotowe manifesty: [`rozwiazanie/`](rozwiazanie/). Zajrzyj, gdy utkniesz, albo porównaj po skończeniu. Całość wdrożysz jednym poleceniem z tego katalogu: `kubectl apply -f rozwiazanie/` (po kroku 0).

## Sprzątanie (dopiero po zakończeniu szkolenia)

```bash
kubectl delete all,ingress,configmap,secret,pvc,hpa -l part-of=todos
./setup/start-klastra.sh --usun        # z głównego katalogu repo: usuwa cały klaster
```
