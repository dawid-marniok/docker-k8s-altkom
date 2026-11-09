# Lab 01 — odpowiedzi

W tym labie wszystkie polecenia są w treści, więc tu są odpowiedzi na pytania i wyniki, które warto porównać ze swoimi.

| Krok | Co powinieneś zobaczyć |
|---|---|
| 1 | `cat /etc/os-release` → `Alpine Linux`; `ps aux` → 2 procesy (`sh` z PID 1 i samo `ps`); `hostname` → 12 znaków, takie samo jak początek ID kontenera |
| 2 | strona „Welcome to nginx!”; w `docker logs web` linia `"GET / HTTP/1.1" 200`; w `/usr/share/nginx/html` pliki `index.html` i `50x.html` |
| 3 | po `docker stop` kontener ma status `Exited (0)`; po `docker start` wraca z tym samym portem i nazwą |
| 4 | błąd `Bind for 0.0.0.0:8080 failed: port is already allocated`; kontener `web2` zostaje w stanie `Created`, więc przed ponownym `docker run --name web2` trzeba go usunąć (`docker rm web2`) |
| 5 | `Cześć Ania z Kraków`; postgres bez hasła kończy się błędem `Database is uninitialized and superuser password is not specified`; z hasłem na końcu logów `database system is ready to accept connections` |
| 6 | dwie linie (`zapisane …` i `znowu …`) — dane są w wolumenie `notatki`, nie w kontenerze |

## Dla chętnych

- **`docker inspect web1`** — adres IP: `NetworkSettings.Networks.bridge.IPAddress`; zmienne: `Config.Env`; porty: `NetworkSettings.Ports` (`80/tcp → 0.0.0.0:8080`). Krócej: `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web1`.
- **Dlaczego `alpine` jest mały (ok. 8 MB)?** Zawiera tylko minimalny system: `musl` zamiast `glibc` i `busybox` zamiast pełnych narzędzi GNU. `nginx:1.29` (Debian) waży ok. 150–200 MB.
- **`--memory 64m --cpus 0.5`** — w `docker stats limit` kolumna `MEM USAGE / LIMIT` pokazuje `… / 64MiB`. Kontener, który przekroczy limit pamięci, zostanie zabity (OOM).
