# Lab 03 — rozwiązanie

Gotowe pliki `Dockerfile` (i `.dockerignore` dla Node.js) w tych samych podkatalogach co w labie.
Żeby ich użyć, skopiuj je obok kodu i zbuduj tak jak w README labu (polecenia z katalogu `labs/lab03-dockerfile/`):

```bash
cp rozwiazanie/1-nginx/Dockerfile 1-nginx/
cp rozwiazanie/2-node/Dockerfile rozwiazanie/2-node/.dockerignore 2-node/
cp rozwiazanie/3-go/Dockerfile 3-go/
```

## Na co zwrócić uwagę

| Plik | Dlaczego tak |
|---|---|
| `1-nginx/Dockerfile` | `FROM` + `COPY` wystarczą: obraz nginx sam uruchamia serwer (ma własne `CMD`) |
| `2-node/Dockerfile` | `package*.json` i `npm install` **przed** `COPY . .` — zmiana w `server.js` nie unieważnia cache warstwy z zależnościami. `--omit=dev` pomija zależności deweloperskie (tu ich nie ma, ale to dobry nawyk). `USER node` na końcu: pliki kopiujemy jako root, aplikacja działa bez roota |
| `2-node/.dockerignore` | `node_modules` z laptopa nie trafia do obrazu (zależności instaluje `npm install` w obrazie) |
| `3-go/Dockerfile` | etap `build` ma cały kompilator Go (~950 MB), do etapu końcowego kopiujemy tylko gotowy plik (~10 MB). `CGO_ENABLED=0` daje plik bez zależności od bibliotek systemowych — inaczej nie uruchomi się w `distroless/static`. `USER nonroot` to użytkownik wbudowany w obrazy distroless |

## Odpowiedzi

- **Cache po zmianie kolejności:** przy `COPY . .` przed `npm install` każda zmiana w `server.js` unieważnia warstwę `COPY`, a z nią wszystkie kolejne — `npm install` wykonuje się od nowa przy każdym buildzie.
- **Rozmiary:** `hello-go:duzy` ok. 950 MB, `hello-go:maly` ok. 10 MB. Ten sam program.
- **Tagi:** `hello-node:1.0` i `hello-node:latest` mają ten sam IMAGE ID — tag to tylko etykieta wskazująca na obraz.
