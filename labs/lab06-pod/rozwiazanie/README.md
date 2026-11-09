# Lab 06 — odpowiedzi

## Krok 4 — trzy zepsute pody

| Pod | Status | Przyczyna | Gdzie widać |
|---|---|---|---|
| `zepsuty-1` | `ErrImagePull`, potem `ImagePullBackOff` | tag `nginx:1.299` nie istnieje | `kubectl describe pod zepsuty-1` → Events: `nginx:1.299: not found` |
| `zepsuty-2` | `Error`, potem `CrashLoopBackOff` | `cat /konfiguracja/app.conf` — pliku nie ma, proces kończy się kodem 1, a Kubernetes uruchamia go ponownie coraz rzadziej | `kubectl logs zepsuty-2`: `cat: can't open '/konfiguracja/app.conf': No such file or directory` (jeśli pusto — `--previous`) |
| `zepsuty-3` | `Pending` | żąda 64Gi pamięci (`requests`) — żaden węzeł tyle nie ma, scheduler nie ma gdzie go umieścić | `kubectl describe pod zepsuty-3` → Events: `FailedScheduling … Insufficient memory` |

Naprawa `zepsuty-1`: w `zepsute.yaml` zmień obraz na `nginx:1.29`, potem:

```bash
kubectl delete pod zepsuty-1
kubectl apply -f zepsute.yaml
```

## Krok 2 — zmiana obrazu

Obraz w działającym podzie **można** zmienić przez `apply`: kubelet zatrzymuje stary kontener i uruchamia nowy (RESTARTS = 1). Większości innych pól (np. `resources`, `command`, porty) zmienić się nie da — `apply` zwróci błąd `Forbidden: pod updates may not change fields…`. Dlatego w praktyce nie tworzymy gołych podów, tylko Deploymenty (lab07).

## Krok 5 — pod z dwoma kontenerami

Plik [`dwa.yaml`](dwa.yaml):

```bash
kubectl apply -f rozwiazanie/dwa.yaml
kubectl logs para -c sonda        # co 5 s: <!DOCTYPE html>
```

## Dla chętnych — readinessProbe

```yaml
      readinessProbe:
        httpGet: { path: /, port: 80 }
        periodSeconds: 5
```

Dopisz pod `resources:` w kontenerze, potem `kubectl delete pod web` i `kubectl apply -f pod.yaml` (sondy nie da się dodać do działającego poda).
Ścieżka `/nie-ma` → nginx zwraca 404 → pod `Running`, ale `READY 0/1`, bez restartów: readiness tylko wyłącza pod z ruchu, nie restartuje go (to robi liveness).
