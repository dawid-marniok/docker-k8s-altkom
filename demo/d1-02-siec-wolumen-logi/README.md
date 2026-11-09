# Sieć, wolumen i logi

**Cel:** kontenery łączą się po nazwie we własnej sieci, dane w wolumenie przeżywają usunięcie kontenera, logi czytamy ze stdout.
**Pliki:** brak, same obrazy (`mongo:7.0`, `busybox:1.37`).

## Kroki

### 1. Sieć i DNS po nazwie

```bash
docker network create demo
docker run -d --name baza --network demo -v demo-dane:/data/db mongo:7.0
docker run --rm --network demo busybox:1.37 nslookup baza   # IP bazy
docker network inspect demo                                  # to samo IP w Containers
```

### 2. Zapis do bazy

Mongo potrzebuje 2–3 s na start (inaczej `MongoNetworkError: connect ECONNREFUSED`). Pewniej jest poczekać, aż odpowie:

```bash
until docker exec baza mongosh --quiet --eval 'db.adminCommand("ping").ok' >/dev/null 2>&1; do sleep 1; done
docker exec baza mongosh --quiet --eval 'db.notatki.insertOne({t: "przetrwam"})'
```

### 3. Usunięcie kontenera, dane zostają

```bash
docker stop baza ; docker rm baza
docker volume ls                      # demo-dane nadal jest
docker run -d --name baza --network demo -v demo-dane:/data/db mongo:7.0
# znowu 2–3 s na start (albo pętla until z kroku 2)
docker exec baza mongosh --quiet --eval 'db.notatki.find()'   # notatka jest
docker logs --tail 5 baza
```

**Uwaga:** `stop` + `rm`, nie `rm -f`. SIGKILL tuż po zapisie potrafi zgubić świeży insert.

Nowy kontener może dostać inny IP, a nazwa zostaje. Dlatego aplikacje łączą się po nazwie, nie po IP.

## Na co zwrócić uwagę

- `nslookup baza` zwraca IP z sieci `demo`
- kontener usunięty, a notatka jest, bo siedzi w wolumenie
- logi bazy czytamy bez wchodzenia do kontenera

## Sprzątanie

```bash
docker rm -f baza ; docker volume rm demo-dane ; docker network rm demo
```
