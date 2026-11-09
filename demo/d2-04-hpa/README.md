# Autoskalowanie z HPA

**Cel:** HPA zwiększa liczbę podów, gdy zużycie CPU przekracza próg liczony od `requests`.
**Pliki:** `app.yaml` — aplikacja „liczydło” (Python, każde żądanie to chwila liczenia) i jej Service; `hpa.yaml` — HorizontalPodAutoscaler dla niej.

Wymaga metrics-server (jest w klastrze ze `setup/start-klastra.sh`). Przydadzą się dwa terminale.

## Kroki

### 1. Aplikacja i HPA

```bash
kubectl apply -f app.yaml
kubectl rollout status deploy/liczydlo
kubectl apply -f hpa.yaml                # 1–5 replik, cel 50% CPU z requests
```

Terminal 2:

```bash
kubectl get hpa -w
```

`TARGETS` przez pierwsze ~15 s pokazuje `<unknown>`, to normalne: metrics-server nie zebrał jeszcze danych.

### 2. Obciążenie

```bash
kubectl run obciazenie --rm -it --image=busybox:1.37 -- \
  sh -c 'while true; do wget -qO- http://liczydlo >/dev/null; done'
```

Po ~20 s `TARGETS` ok. 500%/50%, po ~40 s `REPLICAS` 5. W trzecim terminalu albo po chwili:

```bash
kubectl top pods
kubectl get pods -o wide            # pody rozłożone na dwa workery
```

### 3. Koniec obciążenia

Ctrl+C w oknie `obciazenie`. CPU spada od razu, a `REPLICAS` dopiero po ok. 5 min (okno stabilizacji skalowania w dół).

HPA patrzy na % z `requests`, nie z `limits`. Bez `requests` pokaże `<unknown>` i nic nie zrobi. HPA dodaje pody, a węzły dokłada osobno Cluster Autoscaler albo Karpenter.

## Sprzątanie

```bash
kubectl delete -f . --now
```
