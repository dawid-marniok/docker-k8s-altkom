# Lab 02 — odpowiedzi

Polecenia są w treści labu; tu wyniki do porównania i wyjaśnienia.

| Krok | Wynik | Dlaczego |
|---|---|---|
| 1 | `wget: bad address 'serwer'` | domyślna sieć `bridge` nie ma DNS z nazwami kontenerów |
| 2 | HTML strony nginx; `nslookup` zwraca adres IP `serwer` | sieć utworzona przez `docker network create` ma wbudowany DNS (`127.0.0.11`) |
| 3 | znowu `bad address 'serwer'` | `serwer` nie jest w sieci `inna-net` — różne sieci są od siebie odizolowane |
| 4 | Twoja strona na :8082; zmiana w `strona/index.html` widoczna po odświeżeniu, bez restartu kontenera | bind mount pokazuje w kontenerze ten sam plik, który leży na dysku laptopa |
| 5 | `SELECT` zwraca wiersz `przetrwam` | dane bazy są w wolumenie `pgdata`, a nie w warstwie kontenera, którą usunęło `docker rm` |
| 6 | ostatnie linie logów Postgresa, w tym `database system is ready to accept connections` | aplikacja pisze na stdout, Docker zapisuje i pokazuje te logi |

Po `docker rm -f pg` w logach nowego kontenera mogą pojawić się linie o odtwarzaniu (`redo`, `checkpoint`). To normalne: `-f` zabił bazę bez zamknięcia, więc przy starcie sprawdza swoje pliki.

## Dla chętnych

- **Klient po nazwie:** łączysz się z `-h pg` — nazwa kontenera działa jako adres, bo oba kontenery są w `app-net`. Wyjście z `psql`: `\q`.
- **Kopia wolumenu:** w bieżącym katalogu powstaje `pgdata.tgz`. Pomocniczy kontener montuje jednocześnie wolumen (`/dane`) i katalog z laptopa (`/backup`) — to standardowy sposób na backup wolumenu.
- **`docker network inspect app-net`** — w sekcji `Containers` są `serwer` i `pg` (jeśli działają) z adresami z podsieci sieci `app-net`.
