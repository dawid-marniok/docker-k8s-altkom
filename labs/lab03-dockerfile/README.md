# Lab 03 — Własny obraz z Dockerfile

**Cel:** zbudować trzy obrazy i zobaczyć, co wpływa na czas budowania i rozmiar obrazu.
Katalog `labs/lab03-dockerfile/`

## 1. Strona w nginx (`1-nginx/`)

Utwórz plik `1-nginx/Dockerfile`, który:
- startuje z obrazu `nginx:1.29-alpine`,
- kopiuje `index.html` do `/usr/share/nginx/html/`.

```bash
cd 1-nginx
docker build -t moja-strona:1.0 .
docker run -d --name strona -p 8083:80 moja-strona:1.0
```

**Sprawdź:** http://localhost:8083 pokazuje Twoją stronę bez żadnego wolumenu.

<details><summary>Podpowiedź</summary>

Wystarczą dwie instrukcje: `FROM` i `COPY`.
</details>

## 2. Aplikacja Node.js (`2-node/`)

Napisz `2-node/Dockerfile`:
1. obraz bazowy `node:22-alpine`,
2. katalog roboczy `/app`,
3. **najpierw** `COPY package*.json ./` i `RUN npm install`, **potem** reszta kodu,
4. `EXPOSE 3000`,
5. `USER node` — aplikacja nie działa jako root,
6. `CMD ["node", "server.js"]` (forma z nawiasami).

Dodaj `.dockerignore` z linią `node_modules`.

```bash
cd ../2-node
docker build -t hello-node:1.0 .
docker run -d --name hello -p 3000:3000 -e GREETING=Dzień\ dobry hello-node:1.0
curl localhost:3000
```

**Sprawdź cache:** zmień tekst w `server.js` i zbuduj jeszcze raz. Krok `npm install` powinien mieć `CACHED`. Teraz zmień kolejność (najpierw `COPY . .`, potem `npm install`), zmień `server.js` i zbuduj. Co się dzieje z cache? Na koniec przywróć dobrą kolejność.

**Sprawdź użytkownika:** w odpowiedzi `curl` powinno być `użytkownik: node`, a nie `root`.

## 3. Multi-stage: ten sam program, inny rozmiar (`3-go/`)

```bash
cd ../3-go
docker build -f Dockerfile.jeden-etap -t hello-go:duzy .
```

Napisz `Dockerfile` w dwóch etapach:
- etap `build`: `FROM golang:1.25 AS build`, `WORKDIR /src`, `COPY . .`, `RUN CGO_ENABLED=0 go build -o /hello .` (podejrzyj `Dockerfile.jeden-etap` — to prawie to samo)
- etap końcowy: `FROM gcr.io/distroless/static-debian12`, `COPY --from=build /hello /hello`, `CMD ["/hello"]`

```bash
docker build -t hello-go:maly .
docker image ls hello-go
docker run --rm -p 8084:8080 hello-go:maly
```

Kontener działa na pierwszym planie (bez `-d`), więc terminal jest zajęty. Otwórz http://localhost:8084 w przeglądarce, a potem wróć do terminala i zatrzymaj kontener **Ctrl+C**.

**Sprawdź:** porównaj rozmiary. Duży obraz zawiera cały kompilator, którego w produkcji nikt nie potrzebuje.

## 4. Tagi i historia obrazu

```bash
docker tag hello-node:1.0 hello-node:latest
docker image ls hello-node        # ten sam IMAGE ID, dwie etykiety
docker history hello-node:1.0     # warstwy i ich rozmiary
```

## Dla chętnych

- Dodaj do `2-node/Dockerfile` instrukcję `HEALTHCHECK` (np. `wget -qO- localhost:3000`) i obserwuj kolumnę STATUS w `docker ps`.
- Zbuduj obraz z argumentem: `ARG WERSJA=1.0` + `LABEL version=$WERSJA`, `docker build --build-arg WERSJA=2.0 …`, sprawdź `docker inspect`.
- Masz konto na Docker Hub? `docker login`, `docker tag hello-node:1.0 <login>/hello-node:1.0`, `docker push <login>/hello-node:1.0`.

## Sprzątanie

```bash
docker rm -f strona hello
```

Rozwiązania: katalog [`rozwiazanie/`](rozwiazanie/) — zajrzyj dopiero, gdy spróbujesz sam.
