# Lab 05 — odpowiedzi

| Pytanie | Odpowiedź |
|---|---|
| Ile węzłów? | 3: `szkolenie-control-plane`, `szkolenie-worker`, `szkolenie-worker2`, wszystkie `Ready` |
| Gdzie jest control plane? | `etcd`, `kube-apiserver`, `kube-scheduler`, `kube-controller-manager` działają na `szkolenie-control-plane` (kolumna `NODE` w `-o wide`). `kube-proxy` i `kindnet` są po jednym na każdym węźle |
| Węzły jako kontenery | `docker ps --filter name=szkolenie` pokazuje 3 kontenery z obrazem `kindest/node` |
| Na jakim węźle `ping`? | na jednym z workerów (`szkolenie-worker` albo `szkolenie-worker2`) — zwykłe pody nie trafiają na control plane, bo ma on *taint* `NoSchedule` |
| Statusy w `get pods -w` | `Pending` (scheduler wybiera węzeł) → `ContainerCreating` (pobieranie obrazu) → `Running` |
| Events w `describe pod ping` | `Scheduled` → `Pulling` / `Pulled` → `Created` → `Started` |

## Dla chętnych

- **`kubectl delete pod ping` — czy wrócił?** Nie. Goły pod nie ma nikogo, kto by go pilnował. Odtwarzaniem podów zajmuje się ReplicaSet tworzony przez Deployment (lab07).
- **`kubectl get events --sort-by=.lastTimestamp`** — te same zdarzenia co w `describe`, ale dla całego namespace, posortowane od najstarszych.
