# Aplikacje kontenerowe w klastrach z wykorzystaniem Docker oraz Kubernetes

Repozytorium uczestnika · Altkom Akademia · 2 dni · prowadzi Dawid Marniok

Przez dwa dni idziemy jedną drogą: od pojedynczego kontenera, przez własny obraz i Docker Compose, do aplikacji wdrożonej na klaster Kubernetes pod własnym adresem. Wątkiem przewodnim jest aplikacja **ToDos** (`app/todos/`): w dniu 1 uruchamiasz ją w Compose, w dniu 2 przenosisz na Kubernetesa.

## Zanim zaczniesz

Instalacja i sprawdzenie środowiska: **[setup/README.md](setup/README.md)**. Zrób to przed pierwszym dniem, najlepiej z dostępem do internetu bez firmowego proxy.

## Plan

| Dzień | Temat | Laby |
|---|---|---|
| 1 | Kontenery i podstawy Dockera | [lab01](labs/lab01-docker-podstawy/) |
| 1 | Sieci, wolumeny, logi | [lab02](labs/lab02-sieci-wolumeny/) |
| 1 | Obrazy i Dockerfile | [lab03](labs/lab03-dockerfile/) |
| 1 | Docker Compose — ToDos | [lab04](labs/lab04-compose-todos/) |
| 1 | Kubernetes: architektura i kubectl | [lab05](labs/lab05-kubectl/) |
| 2 | Pod i Namespace | [lab06](labs/lab06-pod/) |
| 2 | Deployment, ConfigMap, Secret | [lab07](labs/lab07-deployment-konfiguracja/) |
| 2 | Service i Ingress | [lab08](labs/lab08-service-ingress/) |
| 2 | Ćwiczenie końcowe: ToDos na Kubernetesie | [lab09](labs/lab09-todos-k8s/) |

Każdy lab ma część podstawową (dla wszystkich) i „Dla chętnych” (gdy skończysz wcześniej). W katalogu `rozwiazanie/` każdego labu są rozwiązania i odpowiedzi — zajrzyj, gdy utkniesz albo żeby porównać po skończeniu.

## Dema

Polecenia z dem pokazywanych przed labami: **[demo/README.md](demo/README.md)**. Możesz je powtórzyć u siebie.

## Ściągi

- [sciagi/docker.md](sciagi/docker.md) — najważniejsze polecenia Dockera i Compose
- [sciagi/kubectl.md](sciagi/kubectl.md) — kubectl na co dzień i diagnostyka podów

## Struktura

```
app/todos/     aplikacja ToDos: api (Node.js) + web (nginx) — do lab04 i lab09
labs/          ćwiczenia, po jednym katalogu na lab (w każdym rozwiazanie/)
demo/          dema ze szkolenia: pliki i polecenia
setup/         instalacja narzędzi i lokalny klaster kind
sciagi/        polecenia pod ręką
```

## Po szkoleniu

- Dokumentacja: [docs.docker.com](https://docs.docker.com/), [kubernetes.io/docs](https://kubernetes.io/docs/)
- Interaktywnie: [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- Klaster usuniesz poleceniem `./setup/start-klastra.sh --usun`
