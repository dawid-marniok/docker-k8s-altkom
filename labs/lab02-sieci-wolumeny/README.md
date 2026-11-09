# Lab 02 — Sieci i dane

**Cel:** połączyć kontenery po nazwie i wybrać właściwy sposób przechowywania danych.
Uruchamiaj z katalogu `labs/lab02-sieci-wolumeny/`

## Kroki

### 1. Domyślna sieć nie zna nazw

```bash
docker run -d --name serwer nginx:1.29
docker run --rm busybox:1.37 wget -qO- -T 3 http://serwer
```

Nie działa (`wget: bad address 'serwer'`) — i tak ma być: kontenery w domyślnej sieci `bridge` nie widzą się po nazwie.

### 2. Własna sieć = DNS po nazwie

```bash
docker network create app-net
docker network connect app-net serwer
docker run --rm --network app-net busybox:1.37 wget -qO- http://serwer | head -4
docker run --rm --network app-net busybox:1.37 nslookup serwer
```

**Wniosek:** w sieci utworzonej przez Ciebie Docker ma wbudowany DNS. Nazwa kontenera staje się adresem. Na tym opiera się Docker Compose.

### 3. Izolacja

```bash
docker network create inna-net
docker run --rm --network inna-net busybox:1.37 wget -qO- -T 3 http://serwer
```

Znowu `bad address 'serwer'` — i tak ma być: kontenery z różnych sieci się nie widzą.

### 4. Bind mount: plik z laptopa w kontenerze

```bash
docker run -d --name strona -p 8082:80 \
  -v "$(pwd)/strona:/usr/share/nginx/html:ro" nginx:1.29
```

Otwórz http://localhost:8082, zmień tekst w `strona/index.html` i odśwież stronę. `:ro` oznacza tylko do odczytu, więc kontener nie zmieni Twoich plików.

### 5. Wolumen: dane bazy

```bash
docker run -d --name pg --network app-net -e POSTGRES_PASSWORD=changeme-lab02 \
  -v pgdata:/var/lib/postgresql/data postgres:17
sleep 5
docker exec pg psql -U postgres -c "CREATE TABLE notatki(tekst text); INSERT INTO notatki VALUES ('przetrwam');"
docker rm -f pg
docker run -d --name pg --network app-net -e POSTGRES_PASSWORD=changeme-lab02 \
  -v pgdata:/var/lib/postgresql/data postgres:17
sleep 5
docker exec pg psql -U postgres -c "SELECT * FROM notatki;"
```

**Sprawdź:** dane są, choć kontener został usunięty i utworzony od nowa.

Jeśli `psql` zwróci `the database system is starting up` albo `could not connect`, baza jeszcze startuje — odczekaj kilka sekund i powtórz polecenie.

| Kiedy | Co |
|---|---|
| dane aplikacji (baza, pliki użytkowników) | wolumen (`-v nazwa:/ścieżka`) |
| kod lub konfiguracja z laptopa podczas pracy | bind mount (`-v $(pwd)/x:/ścieżka`) |
| pliki tymczasowe, nic nie trzeba zachować | brak wolumenu albo `--tmpfs` |

### 6. Logi

```bash
docker logs --tail 5 pg
docker logs -t --since 1m pg
```

Aplikacja w kontenerze pisze logi na **stdout/stderr**, nie do pliku. Docker (a później Kubernetes) je zbiera.

## Dla chętnych

- Klient bazy po nazwie: `docker run --rm -it --network app-net -e PGPASSWORD=changeme-lab02 postgres:17 psql -h pg -U postgres`
- Kopia wolumenu: `docker run --rm -v pgdata:/dane -v "$(pwd):/backup" alpine:3.22 tar czf /backup/pgdata.tgz -C /dane .`
- `docker network inspect app-net` — które kontenery są w sieci i jakie mają adresy?

## Sprzątanie

```bash
docker rm -f serwer strona pg
docker network rm app-net inna-net
docker volume rm pgdata
```

Odpowiedzi i oczekiwane wyniki: [`rozwiazanie/README.md`](rozwiazanie/README.md).
