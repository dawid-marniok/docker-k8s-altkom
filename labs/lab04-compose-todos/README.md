# Lab 04 — ToDos w Docker Compose

**Cel:** uruchomić aplikację z trzech kontenerów jednym poleceniem.
Katalog `labs/lab04-compose-todos/`

Aplikacja ToDos (kod w `app/todos/`) to trzy części:

| Usługa | Co robi | Obraz |
|---|---|---|
| `web` | strona + przekazuje `/api/*` do API | budowany z `app/todos/web` |
| `api` | REST API w Node.js | budowany z `app/todos/api` |
| `mongo` | baza danych | `mongo:7.0` |

Ten sam ToDos jutro wdrożymy na Kubernetesa.

> **Mongo nie startuje?** Jeśli `docker compose logs mongo` jest pusty, a `docker compose ps -a` pokazuje `Exited (132)` / `Illegal instruction`, procesor Twojego komputera (częsty przypadek na maszynach wirtualnych) nie ma instrukcji AVX, których wymaga MongoDB od wersji 5.0. Użyj w `compose.yaml` obrazu `mongo:4.4`, a w poleceniach poniżej zamiast `mongosh` wpisuj `mongo` (także w healthchecku w kroku 4). Szybki test: `docker run --rm mongo:7.0 mongod --version`.

## Kroki

### 1. Start wersji startowej

```bash
docker compose up -d --build
docker compose ps
docker compose logs api
```

API działa, ale nie ma jak go otworzyć w przeglądarce: brakuje usługi `web`.

### 2. Dodaj usługę `web`

Uzupełnij `compose.yaml` (TODO krok 2), potem:

```bash
docker compose up -d --build
```

Otwórz http://localhost:8080 i dodaj kilka zadań. Na górze strony widać, który kontener API odpowiedział.

### 3. Dane, które przeżyją `down`

```bash
docker compose down
docker compose up -d
```

Zadania zniknęły. Dodaj nazwany wolumen dla `mongo` (`/data/db`) i sekcję `volumes:` na dole pliku. Sprawdź jeszcze raz: dodaj zadanie, potem `down` i `up -d`.

> `docker compose down -v` usuwa także wolumeny. Używaj świadomie.

### 4. Kolejność startu

Restart wszystkiego naraz:

```bash
docker compose down && docker compose up -d && docker compose logs -f api
```

API przez chwilę pisze „Baza niedostępna”. Dodaj do `mongo` healthcheck:

```yaml
healthcheck:
  test: ["CMD", "mongosh", "--quiet", "--eval", "db.adminCommand('ping').ok"]
  interval: 5s
  retries: 10
```

a do `api`:

```yaml
depends_on:
  mongo:
    condition: service_healthy
```

**Sprawdź:** `docker compose up -d` czeka, aż `mongo` będzie `healthy`, i dopiero wtedy startuje API.

### 5. Kilka instancji API

```bash
docker compose up -d --scale api=3
docker compose ps
```

Odśwież stronę kilka razy i obserwuj nazwę hosta na górze. Wciąż ten sam? To nie błąd: nginx w `web` sprawdza adres `api` w DNS tylko raz, przy starcie, i zapamiętał wtedy jeden kontener. Uruchom go ponownie:

```bash
docker compose restart web
```

Teraz odśwież stronę kilka razy — nazwa hosta się zmienia. DNS Dockera zwraca pod nazwą `api` adresy wszystkich trzech kontenerów, a nginx rozkłada między nie ruch. (W Kubernetesie tego problemu nie będzie: Service ma jeden stały adres.)

> Dlaczego da się skalować `api`, a `web` już nie? Spójrz na `ports:`.

### 6. Podejrzyj, co się dzieje

```bash
docker compose top
docker compose exec mongo mongosh todos --eval 'db.todos.find()'
docker network ls | grep todos
docker volume ls | grep todos
```

## Dla chętnych

- Zmień `APP_VERSION` na `"1.1"` i zrób `docker compose up -d`. Compose odtwarza tylko kontenery, które się zmieniły.
- Dodaj panel bazy `mongo-express:1.0` z `profiles: [debug]` i uruchom go przez `docker compose --profile debug up -d`.
- `docker compose config` — jak Compose widzi plik po rozwinięciu wszystkich wartości?

## Sprzątanie

```bash
docker compose down        # obrazy todos-api:1.0 i todos-web:1.0 zostają — przydadzą się jutro
```

Rozwiązanie: [`rozwiazanie/compose.yaml`](rozwiazanie/compose.yaml). Uruchomisz je z tego katalogu: `docker compose -f rozwiazanie/compose.yaml up -d --build`.
