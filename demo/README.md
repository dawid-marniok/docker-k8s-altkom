# Dema

Polecenia z dem pokazywanych na szkoleniu. Możesz je powtórzyć u siebie w trakcie szkolenia albo po nim.
Dema używają innych przykładów niż laby, więc w labie ćwiczysz to samo na innym materiale.

| Demo | Temat | Przed labem |
|---|---|---|
| [d1-01-pierwszy-kontener](d1-01-pierwszy-kontener/) | kontener, cykl życia, zmiany w środku | lab01 |
| [d1-02-siec-wolumen-logi](d1-02-siec-wolumen-logi/) | sieć z DNS, wolumen, logi | lab02 |
| [d1-03-build-cache-multistage](d1-03-build-cache-multistage/) | cache warstw, multi-stage | lab03 |
| [d1-04-compose](d1-04-compose/) | Docker Compose | lab04 |
| [d2-01-pod-diagnostyka](d2-01-pod-diagnostyka/) | Pod i diagnozowanie awarii | lab06 |
| [d2-02-rollout-konfiguracja](d2-02-rollout-konfiguracja/) | rolling update, rollback, ConfigMap | lab07 |
| [d2-03-service-ingress](d2-03-service-ingress/) | Service, DNS klastra, Ingress | lab08 |
| [d2-04-hpa](d2-04-hpa/) | autoskalowanie z HPA | — |

Polecenia uruchamiaj w katalogu danego dema.

Dema Kubernetesa (`d2-*`) najlepiej robić w osobnym namespace, żeby nie mieszać ich z labami:

```bash
kubectl create namespace demo
kubectl config set-context --current --namespace=demo
# z powrotem do labów:
kubectl config set-context --current --namespace=szkolenie
```
