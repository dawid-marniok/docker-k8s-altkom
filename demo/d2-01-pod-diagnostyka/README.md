# Pod, który nie wstaje

**Cel:** pod z YAML, wejście do środka, potem trzy awarie i diagnoza metodą get → describe → logs.
**Pliki:** `pod.yaml`, `awarie.yaml`.

## Kroki

### 1. Zdrowy pod

```bash
kubectl apply -f pod.yaml
kubectl get pods -o wide              # IP poda, węzeł
kubectl port-forward pod/www 8086:80  # przeglądarka: localhost:8086, potem Ctrl+C
kubectl exec -it www -- bash
  hostname; cat /etc/resolv.conf; exit   # DNS klastra
```

### 2. Trzy awarie

```bash
kubectl apply -f awarie.yaml
kubectl get pods -w                   # po ~30 s Ctrl+C
```

| Pod | Status | Gdzie przyczyna |
|---|---|---|
| `awaria-pamiec` | `OOMKilled` → `CrashLoopBackOff` | `kubectl describe pod awaria-pamiec` → Last State: Terminated, Reason: OOMKilled, Exit Code 137 |
| `awaria-wezel` | `Pending` | `describe` → Events: `didn't match Pod's node affinity/selector` (brak węzła z `dysk=ssd`) |
| `awaria-sonda` | `Running`, ale `0/1` READY | `describe` → Events: `Readiness probe failed: HTTP probe failed with statuscode: 404` |

```bash
kubectl describe pod awaria-pamiec | grep -A4 "Last State"
kubectl describe pod awaria-wezel  | tail -3
kubectl describe pod awaria-sonda  | tail -3
kubectl logs awaria-pamiec              # „zaczynam jesc pamiec” i koniec
```

**Pułapka:** gdy pod ma status `OOMKilled`/`CrashLoopBackOff`, bieżący kontener już nie żyje i `kubectl logs` pokazuje właśnie jego logi. `--previous` sięga wtedy do jeszcze wcześniejszego kontenera, który kubelet zdążył usunąć → `unable to retrieve container logs`. `--previous` przydaje się, gdy nowy kontener akurat wystartował (`Running`) i jego logi są jeszcze puste.

`Running` nie znaczy „działa”. Liczy się kolumna READY. Pod z niezdaną sondą gotowości nie dostanie ruchu z Service.

### 3. Naprawa jednej awarii

```bash
kubectl label node szkolenie-worker dysk=ssd
kubectl get pods awaria-wezel -w        # Pending → Running
kubectl label node szkolenie-worker dysk-   # zdejmujemy etykietę
```

## Sprzątanie

```bash
kubectl delete -f . --now
```
