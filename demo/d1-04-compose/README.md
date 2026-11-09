# Docker Compose

**Cel:** dwie usługi z jednego pliku: start, DNS po nazwie usługi, co zostaje po `down`.
**Pliki:** `compose.yaml` (nginx + postgres).

## Kroki

```bash
cat compose.yaml                  # dwie usługi, jeden wolumen; brak sekcji networks, a sieć i tak będzie
docker compose up -d              # w logu: Network, Volume, Containers
docker compose ps                 # nazwy kontenerów, port 8080; przeglądarka localhost:8080
docker compose exec web getent hosts db   # IP usługi db
docker compose logs db
docker compose down
docker volume ls                  # d1-04-compose_dane zostaje
```

To, co w demie d1-02 wymagało kilku poleceń, Compose robi z jednego pliku. Nazwy kontenerów mają postać `projekt-usługa-numer` (np. `d1-04-compose-db-1`), a projekt to nazwa katalogu.
`down -v` kasuje także wolumeny, czyli dane.

## Na co zwrócić uwagę

- jedno polecenie tworzy sieć, wolumen i dwa kontenery
- `web` widzi `db` po nazwie usługi, bo sieć Compose ma DNS
- `down` usuwa kontenery i sieć, wolumen zostaje

## Sprzątanie

```bash
docker compose down -v
```
