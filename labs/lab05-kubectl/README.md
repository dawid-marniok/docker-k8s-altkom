# Lab 05 — Twój klaster i kubectl

**Cel:** postawić lokalny klaster i rozejrzeć się w nim przez `kubectl`.
Z głównego katalogu repo

## 1. Klaster

```bash
./setup/start-klastra.sh
```

> Windows: uruchom w Git Bash w Windows Terminal (setup/README.md). Skrypt robi kolejno: `kind create cluster`, Ingress Controller (Traefik), metrics-server, namespace `szkolenie`.

Pierwsze uruchomienie trwa 2–4 minuty: kind pobiera obraz węzła.

**Sprawdź:** `kubectl get nodes` pokazuje 3 węzły `Ready`.

## 2. Gdzie jestem

```bash
kubectl config get-contexts          # gwiazdka = aktywny kontekst
kubectl config current-context       # kind-szkolenie
kubectl config view --minify | grep namespace   # szkolenie
```

Każdy węzeł kind to kontener Dockera:

```bash
docker ps --filter name=szkolenie
```

## 3. Co jest w środku

```bash
kubectl get namespaces
kubectl get pods -n kube-system -o wide
```

Znajdź na liście: `etcd`, `kube-apiserver`, `kube-scheduler`, `kube-controller-manager` (control plane) oraz `kube-proxy` i `kindnet` (na każdym węźle). Na którym węźle działa control plane?

```bash
kubectl get pods -A                   # wszystko we wszystkich namespace'ach
kubectl top nodes                     # CPU i pamięć węzłów (metrics-server)
```

`error: metrics not available yet`? metrics-server zbiera dane co ok. minutę — poczekaj chwilę i powtórz.

## 4. kubectl jako dokumentacja

```bash
kubectl api-resources | head -30      # wszystkie typy obiektów i ich skróty
kubectl explain pod.spec.containers   # pola, które możesz wpisać w YAML
kubectl explain deployment.spec --recursive | head -40
```

## 5. Pierwszy obiekt imperatywnie

```bash
kubectl run ping --image=busybox:1.37 -- sh -c 'while true; do date; sleep 5; done'
kubectl get pods -w        # obserwuj Pending → ContainerCreating → Running, wyjdź Ctrl+C
kubectl logs -f ping       # Ctrl+C
kubectl describe pod ping  # przewiń do sekcji Events na dole
```

Na jakim węźle wylądował pod? (`kubectl get pod ping -o wide`)

## 6. Ten sam obiekt jako YAML

```bash
kubectl get pod ping -o yaml | less   # przewijanie strzałkami, wyjście: q
kubectl run ping2 --image=busybox:1.37 --dry-run=client -o yaml -- sleep 3600
```

Drugie polecenie niczego nie tworzy, tylko wypisuje manifest. Tak najszybciej zaczyna się nowy plik YAML.

## Dla chętnych

- `kubectl get events --sort-by=.lastTimestamp`
- `kubectl delete pod ping` i od razu `kubectl get pods`. Czy pod wrócił? Dlaczego nie? (odpowiedź jutro: Deployment)
- Zainstaluj `k9s` i przejrzyj klaster w terminalu.

## Sprzątanie

```bash
kubectl delete pod ping --now
```

Klaster zostaw — jutro pracujemy na nim cały dzień.

Odpowiedzi i oczekiwane wyniki: [`rozwiazanie/README.md`](rozwiazanie/README.md).
