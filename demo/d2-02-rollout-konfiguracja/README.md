# Rolling update, rollback i konfiguracja

**Cel:** wymiana wersji bez przerwy, zepsucie jej i cofnięcie, potem konfiguracja z ConfigMap.
**Pliki:** `deployment.yaml`, `configmap.yaml`.

Aplikacja to `traefik/whoami` (v1.10.4 → v1.11.0). Czyta zmienną `WHOAMI_NAME` i wypisuje ją w odpowiedzi jako `Name:`. Przydadzą się dwa terminale.

## Kroki

### 1. Deployment

```bash
kubectl apply -f deployment.yaml
kubectl get deploy,rs,pods
```

Terminal 2:

```bash
kubectl get pods -w
```

### 2. Rolling update

```bash
kubectl set image deploy/whoami whoami=traefik/whoami:v1.11.0
kubectl rollout status deploy/whoami
kubectl get rs                    # nowy ReplicaSet: 4, stary: 0 (zostaje do rollbacku)
kubectl rollout history deploy/whoami
```

W terminalu 2 widać, że nowe pody pojawiają się, zanim znikną stare.

### 3. Zła wersja i rollback

```bash
kubectl set image deploy/whoami whoami=traefik/whoami:v9.9
kubectl get pods                  # 2 nowe w ErrImagePull, 3 stare dalej Running (czwarty stary chwilę jako Error/Terminating — to wyłączany pod)
kubectl rollout undo deploy/whoami
kubectl rollout status deploy/whoami
```

Rolling update nie wyłączył starych podów, bo nowe nie przeszły sondy gotowości. `maxUnavailable` 25% z 4 to 1 pod mniej, reszta obsługuje ruch.
Ostrzeżenie o `last-applied-configuration` przy `undo` jest w porządku — w kolejnym kroku i tak wracamy do pliku.

### 4. Konfiguracja z ConfigMap

```bash
kubectl apply -f configmap.yaml
```

W `deployment.yaml` odkomentuj blok `envFrom` (3 linie), potem:

```bash
kubectl apply -f deployment.yaml          # zmiana szablonu = nowy rollout
kubectl rollout status deploy/whoami
kubectl port-forward deploy/whoami 8087:80   # terminal 2 (zamiast get pods -w) — blokuje terminal
curl localhost:8087                       # pierwsza linia: Name: demo-na-szkoleniu
```

Zmień wartość w `configmap.yaml`, zrób `apply` i znowu `curl`: wciąż stara wartość. Dopiero:

```bash
kubectl rollout restart deploy/whoami
kubectl rollout status deploy/whoami
```

**Pułapka:** `port-forward deploy/whoami` łączy się z **jednym** podem wybranym przy starcie. Po `rollout restart` ten pod znika i port-forward się zrywa (`lost connection to pod`). W terminalu 2: Ctrl+C, jeszcze raz `kubectl port-forward deploy/whoami 8087:80`, potem `curl localhost:8087` → nowa wartość.

Zmienne środowiskowe są czytane przy starcie kontenera. Po zmianie ConfigMap trzeba zrestartować pody.

## Sprzątanie

Zakomentuj z powrotem `envFrom` w `deployment.yaml`, potem:

```bash
kubectl delete -f . --now
```
