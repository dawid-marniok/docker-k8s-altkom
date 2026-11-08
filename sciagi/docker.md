# Ściąga: Docker i Compose

## Kontenery

| Polecenie | Co robi |
|---|---|
| `docker run -d --name web -p 8080:80 nginx:1.29` | uruchamia w tle, port laptopa 8080 → 80 w kontenerze |
| `docker run --rm -it alpine:3.22 sh` | kontener interaktywny, usuwany po wyjściu |
| `docker run -e KLUCZ=wartosc …` | zmienna środowiskowa |
| `docker run -v dane:/ścieżka …` | wolumen (dane przeżywają kontener) |
| `docker run -v "$(pwd)/kat:/ścieżka:ro" …` | bind mount katalogu z laptopa, tylko do odczytu |
| `docker ps` / `docker ps -a` | działające / wszystkie kontenery |
| `docker logs -f web` | logi na żywo |
| `docker exec -it web sh` | powłoka w działającym kontenerze |
| `docker stop web` · `docker start web` · `docker rm -f web` | zatrzymaj · uruchom ponownie · usuń |
| `docker inspect web` | pełna konfiguracja i stan (JSON) |
| `docker stats` | zużycie CPU i pamięci |

## Obrazy

| Polecenie | Co robi |
|---|---|
| `docker build -t nazwa:1.0 .` | buduje obraz z `Dockerfile` w bieżącym katalogu |
| `docker build -f Dockerfile.inny -t …` | inny plik Dockerfile |
| `docker image ls` · `docker rmi nazwa:1.0` | lista · usunięcie obrazu |
| `docker history nazwa:1.0` | warstwy obrazu |
| `docker tag nazwa:1.0 login/nazwa:1.0` · `docker push login/nazwa:1.0` | nowa etykieta · wysłanie do rejestru |

## Dockerfile — dobre nawyki

```dockerfile
FROM node:22-alpine          # konkretna wersja, nigdy :latest
WORKDIR /app
COPY package*.json ./        # najpierw zależności (cache)
RUN npm ci --omit=dev
COPY . .                     # potem kod
USER node                    # nie root
EXPOSE 3000
CMD ["node", "server.js"]    # forma z nawiasami
```

Plus `.dockerignore` (`node_modules`, `.git`) i multi-stage dla języków kompilowanych.

## Sieci i wolumeny

| Polecenie | Co robi |
|---|---|
| `docker network create app-net` | własna sieć z DNS po nazwach kontenerów |
| `docker run --network app-net --name db …` | kontener w sieci, osiągalny jako `db` |
| `docker volume ls` · `docker volume rm nazwa` | lista · usunięcie wolumenu |

## Compose

| Polecenie | Co robi |
|---|---|
| `docker compose up -d --build` | buduje i uruchamia wszystko w tle |
| `docker compose ps` · `docker compose logs -f api` | stan · logi jednej usługi |
| `docker compose exec mongo mongosh` | polecenie w kontenerze usługi |
| `docker compose up -d --scale api=3` | kilka instancji usługi |
| `docker compose down` · `down -v` | usuń kontenery i sieć · także wolumeny |
| `docker compose config` | plik po rozwinięciu zmiennych |

## Sprzątanie

```bash
docker system df          # ile miejsca zajmuje Docker
docker system prune       # usuwa zatrzymane kontenery, nieużywane sieci i obrazy bez tagu
```
