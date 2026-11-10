# Dokumentacja

Ściągi z poleceniami i diagramy, które pokazują, jak to działa w środku.

## Ściągi

- [docker.md](docker.md) — najważniejsze polecenia Dockera i Compose
- [kubectl.md](kubectl.md) — kubectl na co dzień i diagnostyka podów

## Diagramy

Pliki HTML otwórz w przeglądarce, np. `open docs/k8s-droga-zapytania.html` (macOS), `xdg-open …` (Linux) albo `start …` (Windows). Działają bez internetu. Większość diagramów da się przejść krok po kroku.

| Plik | O czym | Przydaje się przy |
|---|---|---|
| [docker-obraz-i-warstwy.html](docker-obraz-i-warstwy.html) | warstwy obrazu, warstwa zapisu kontenera, cache builda, multi-stage | lab02, lab03 |
| [compose-vs-k8s.html](compose-vs-k8s.html) | ToDos w Compose i na Kubernetesie: co czemu odpowiada | lab04 → lab09 |
| [k8s-droga-zapytania.html](k8s-droga-zapytania.html) | droga zapytania Ingress → Service → Pod, co robi `kubectl apply`, rolling update | lab05, lab07, lab08 |
| [diagnostyka-poda.html](diagnostyka-poda.html) | etapy życia poda i co sprawdzić przy każdym błędzie | lab06 i każdy zepsuty pod |
| [cert-manager.html](cert-manager.html) | automatyczne certyfikaty HTTPS dla Ingress (Let's Encrypt): jak działa, konfiguracja, diagnoza | materiał poglądowy, bez laba |
