# Docker Compose

**Cel:** dwie usługi z jednego pliku: start, DNS po nazwie usługi, co zostaje po `down`. W części 2 cała aplikacja: frontend, API z własnego obrazu, baza, healthcheck, kolejność startu, osobne sieci, plik `.env`.
**Pliki:** `compose.yaml` (Adminer + PostgreSQL), `zakupy/` (lista zakupów: nginx + Flask + PostgreSQL + pgAdmin).

## Część 1: Adminer + PostgreSQL

Adminer to panel do bazy danych w przeglądarce. Łączy się z PostgreSQL po nazwie usługi `db`.

```bash
cat compose.yaml                  # dwie usługi, jeden wolumen; brak sekcji networks, a sieć i tak będzie
docker compose up -d              # w logu: Network, Volume, Containers
docker compose ps                 # nazwy kontenerów, port 8080
```

Otwórz http://localhost:8080 i zaloguj się:

| Pole | Wartość |
|---|---|
| System | PostgreSQL |
| Serwer | `db` |
| Użytkownik | `postgres` |
| Hasło | `demo` |

W Adminerze: „SQL command” i np. `CREATE TABLE notatki (tekst text); INSERT INTO notatki VALUES ('przeżyję down');`

```bash
docker compose exec adminer getent hosts db   # to samo DNS, którego użył Adminer
docker compose logs db
docker compose down
docker volume ls                  # d1-04-compose_dane zostaje
docker compose up -d              # zaloguj się ponownie: tabela notatki nadal jest
```

To, co w demie d1-02 wymagało kilku poleceń, Compose robi z jednego pliku. Nazwy kontenerów mają postać `projekt-usługa-numer` (np. `d1-04-compose-db-1`), a projekt to nazwa katalogu.
`down -v` kasuje także wolumeny, czyli dane.

## Na co zwrócić uwagę (część 1)

- jedno polecenie tworzy sieć, wolumen i dwa kontenery
- w polu „Serwer” wpisujesz `db`, czyli nazwę usługi, bo sieć Compose ma DNS
- `db` nie ma sekcji `ports`, a Adminer i tak się z nią łączy: ruch idzie wewnątrz sieci Compose
- `down` usuwa kontenery i sieć, wolumen zostaje

## Część 2: lista zakupów (`zakupy/`)

Cztery usługi:

| Usługa | Co robi | Port na hoście |
|---|---|---|
| `frontend` | nginx: strona HTML i reverse proxy `/api/` → `api:5000` | 8000 |
| `api` | REST API na Flasku, obraz budowany z `app/` | brak |
| `db` | PostgreSQL | brak |
| `pgadmin` | panel bazy w przeglądarce | 5050 |

Sieci: `front` (frontend, api) i `back` (api, db, pgadmin). Frontend nie ma dostępu do bazy.

```bash
cd zakupy
cat .env                          # zmienne podstawiane w compose.yaml jako ${...}
docker compose config             # plik po podstawieniu zmiennych: to faktycznie uruchomi Compose
docker compose up -d --build      # kolejność: db Healthy -> api Healthy -> frontend
docker compose ps                 # kolumna STATUS: (healthy), porty tylko frontend i pgadmin
```

Aplikacja: http://localhost:8000. Dodaj kilka pozycji, odhacz jedną, usuń drugą. Nad listą widać nazwę kontenera API, który obsłużył zapytanie.

To samo z terminala, przez nginx:

```bash
curl -X POST localhost:8000/api/items -H 'Content-Type: application/json' -d '{"name":"mleko","quantity":2,"unit":"l"}'
curl localhost:8000/api/items
docker compose exec db psql -U zakupy -c "SELECT * FROM items;"   # te same dane w bazie
```

Izolacja sieci:

```bash
docker compose exec frontend getent hosts api   # jest: wspólna sieć front
docker compose exec frontend getent hosts db    # pusto: frontend nie jest w sieci back
curl -m 2 localhost:5000                        # API nie jest wystawione na hosta
```

pgAdmin: http://localhost:5050. Serwer `zakupy (db)` jest już dodany z pliku `pgadmin/servers.json`. Hasło do bazy: `demo` (z `.env`). Tabela: Databases → zakupy → Schemas → public → Tables → items.

Zmiana kodu bez przebudowy obrazu: katalogi `app/` i `frontend/` są podmontowane do kontenerów (bind mount), a Flask działa w trybie debug.

```bash
# w app/app.py zmień app="zakupy" na app="zakupy v2" i zapisz
curl localhost:8000/api/
docker compose logs api           # "Detected change ... reloading"
# w frontend/index.html zmień tytuł <h1> i odśwież stronę
```

Dane przeżywają `down`, bo leżą w wolumenie:

```bash
docker compose down
docker compose up -d
curl localhost:8000/api/items     # pozycje nadal są
```

## Na co zwrócić uwagę (część 2)

- jedynym wejściem do aplikacji jest `frontend`. API i baza nie mają sekcji `ports`
- nginx przekazuje `/api/...` do usługi `api` po nazwie, dzięki czemu przeglądarka rozmawia tylko z jednym adresem
- dwie sieci rozdzielają warstwy: `frontend` nie widzi `db`, a `api` jest w obu
- `depends_on` z `condition: service_healthy` czeka, aż healthcheck przejdzie, a samo `depends_on` czeka tylko na start kontenera
- hasła w `.env` są wygodne na laptopie, ale w produkcji trzymasz je poza repozytorium
- bind mount kodu służy do pracy nad nim. Obraz do wdrożenia ma kod w środku (`COPY`), bez montowania

## Sprzątanie

```bash
docker compose down -v                            # w d1-04-compose/
cd zakupy && docker compose down -v --rmi local   # także zbudowany obraz zakupy-api
```
