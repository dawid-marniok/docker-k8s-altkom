# Pierwszy kontener

**Cel:** kontener to proces z własnym widokiem systemu, ale ze wspólnym jądrem. Zmiany w środku znikają razem z kontenerem.
**Pliki:** brak, same obrazy z Docker Huba (`busybox:1.37`, `httpd:2.4`).

## Kroki

### 1. Kontener na chwilę

```bash
docker run --rm -it busybox:1.37 sh
```

W środku:

```sh
ps                 # tylko sh i ps, sh ma PID 1
hostname           # skrócone ID kontenera
uname -r           # jądro maszyny wirtualnej Docker Desktop, nie „busyboxa”
exit
```

Kontener nie ma własnego jądra. Ma własne procesy, sieć i system plików, a jądro dzieli z hostem. Dlatego startuje w ułamku sekundy.

### 2. Serwer WWW w tle

```bash
docker run -d --name apache -p 8090:80 httpd:2.4
docker ps                       # kolumna PORTS: 0.0.0.0:8090->80/tcp
curl localhost:8090             # „It works!”
docker logs apache              # widać żądanie z curla
```

### 3. Zmiana w środku działającego kontenera

```bash
docker exec -it apache bash
  echo '<h1>Zmienione na żywo</h1>' > htdocs/index.html
  exit
curl localhost:8090             # nowa treść
```

### 4. Cykl życia i to, co zostaje

```bash
docker stop apache
docker ps -a                    # Exited, ale kontener nadal istnieje
docker start apache && curl localhost:8090   # zmiana przetrwała stop/start
docker rm -f apache
docker run -d --name apache -p 8090:80 httpd:2.4
curl localhost:8090             # znowu „It works!” — zmiana zniknęła razem z kontenerem
```

**Wniosek:** stop to nie usunięcie. Usunięcie kasuje wszystko, co było zapisane w kontenerze. Dane, które mają przetrwać, trzymamy w wolumenach.

## Sprzątanie

```bash
docker rm -f apache
```
