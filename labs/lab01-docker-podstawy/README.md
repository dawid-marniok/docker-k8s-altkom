# Lab 01 — Pierwsze kontenery

**Cel:** uruchomić kontener, zobaczyć jego cykl życia i skonfigurować go z zewnątrz.
**Czas:** ok. 25 minut · **Środowisko:** Docker Desktop na Twoim laptopie

## Zanim zaczniesz

```bash
docker version        # widać Client i Server? Docker działa
docker run hello-world
```

Jeśli `Server` nie odpowiada, uruchom Docker Desktop i poczekaj, aż ikona wieloryba przestanie się animować.

## Kroki

### 1. Kontener na chwilę

```bash
docker run --rm -it alpine:3.22 sh
```

W środku sprawdź:

```sh
cat /etc/os-release     # inny system niż na Twoim laptopie
ps aux                  # tylko kilka procesów, sh ma PID 1
hostname                # nazwa = skrócone ID kontenera
exit
```

**Sprawdź:** `docker ps -a` — kontenera nie ma, bo `--rm` usunął go po wyjściu.

### 2. Serwer WWW w tle

```bash
docker run -d --name web -p 8080:80 nginx:1.29
docker ps
```

Otwórz http://localhost:8080. Potem:

```bash
docker logs web            # widać Twoje żądanie z przeglądarki
docker logs -f web         # na żywo; odśwież stronę kilka razy, wyjdź Ctrl+C
docker exec -it web sh     # wejście do działającego kontenera
```

W środku: `ls /usr/share/nginx/html` i `exit`.

### 3. Cykl życia

```bash
docker stop web
docker ps            # nie ma
docker ps -a         # jest, status Exited
docker start web     # wraca z tą samą konfiguracją
docker rm -f web     # stop + usunięcie
```

### 4. Port już zajęty

```bash
docker run -d --name a -p 8080:80 nginx:1.29
docker run -d --name b -p 8080:80 nginx:1.29
```

Drugi kontener nie wystartuje. Przeczytaj błąd. Uruchom `b` na porcie **8081** i otwórz oba adresy w przeglądarce.

**Wniosek:** w kontenerze oba nginxy słuchają na 80 i sobie nie przeszkadzają. Konflikt jest tylko po stronie hosta.

### 5. Konfiguracja przez zmienne środowiskowe

```bash
docker run --rm -e IMIE=Ania -e MIASTO=Kraków alpine:3.22 \
  sh -c 'echo "Cześć $IMIE z $MIASTO"; env | sort'
```

Baza danych bez hasła nie wstanie:

```bash
docker run -d --name db postgres:17
docker logs db         # przeczytaj, czego brakuje
docker rm -f db
docker run -d --name db -e POSTGRES_PASSWORD=changeme-lab01 postgres:17
docker logs db | tail -3
```

### 6. Dane, które przeżywają kontener

```bash
docker volume create notatki
docker run --rm -v notatki:/dane alpine:3.22 sh -c 'echo "zapisane $(date)" >> /dane/log.txt'
docker run --rm -v notatki:/dane alpine:3.22 sh -c 'echo "znowu $(date)" >> /dane/log.txt'
docker run --rm -v notatki:/dane alpine:3.22 cat /dane/log.txt
```

**Sprawdź:** widać dwie linie, choć każdy kontener już nie istnieje.

## Dla chętnych

- `docker inspect web` — znajdź adres IP kontenera, zmienne środowiskowe i mapowanie portów.
- `docker stats` — zużycie CPU i pamięci przez działające kontenery.
- `docker image ls` — ile zajmują obrazy, które pobrałeś? Dlaczego `alpine` jest taki mały?
- `docker run -d --name limit --memory 64m --cpus 0.5 nginx:1.29`, potem `docker stats limit`.

## Sprzątanie

```bash
docker rm -f a b db limit 2>/dev/null
docker volume rm notatki
```
