# Build, cache i multi-stage

**Cel:** kolejność instrukcji decyduje o czasie budowania, a multi-stage o rozmiarze obrazu.
**Pliki:** `python/` (Flask), `c/` (program w C).

## Kroki

### 1. Dobra kolejność warstw (`python/`)

```bash
cd python
cat Dockerfile                  # najpierw requirements.txt + pip install, potem COPY . .
docker build -t demo-py:1.0 .
docker run -d --rm --name py -p 5000:5000 demo-py:1.0
curl localhost:5000             # „Wersja 1 z kontenera …”
docker rm -f py
```

Na macOS port 5000 bywa zajęty przez AirPlay Receiver (`address already in use`). Wtedy użyj `-p 5050:5000` i `curl localhost:5050`.

Zmień `Wersja 1` na `Wersja 2` w `app.py` i zbuduj ponownie:

```bash
docker build -t demo-py:1.0 .   # pip install → CACHED, przebudowuje się tylko COPY . .
```

### 2. Zła kolejność

```bash
cat Dockerfile.zla-kolejnosc    # COPY . . przed pip install
docker build -f Dockerfile.zla-kolejnosc -t demo-py:zla .
# zmiana w app.py (Wersja 3)
docker build -f Dockerfile.zla-kolejnosc -t demo-py:zla .   # pip install od nowa
```

Każda warstwa zależy od poprzednich. Zmiana w kodzie unieważnia wszystko pod `COPY . .`, więc zależności instalujemy wcześniej.

### 3. Multi-stage (`c/`)

```bash
cd ../c
cat Dockerfile.jeden-etap       # alpine + kompilator w obrazie końcowym
docker build -f Dockerfile.jeden-etap -t demo-c:duzy .
cat Dockerfile                  # etap build + FROM scratch
docker build -t demo-c:maly .
docker image ls demo-c          # ok. 244 MB kontra 136 kB
docker run --rm demo-c:maly
docker history demo-c:maly      # jedna warstwa: COPY /hello
```

`scratch` to pusty obraz: bez powłoki, menedżera pakietów i bibliotek. W obrazie nie ma nic do zaatakowania poza samym programem.

## Na co zwrócić uwagę

- `CACHED` przy `pip install` po zmianie kodu (dobra kolejność) i jego brak (zła kolejność)
- czas drugiego buildu: sekunda kontra kilka sekund
- rozmiar: ok. 244 MB kontra 136 kB

## Sprzątanie

```bash
docker rmi demo-py:1.0 demo-py:zla demo-c:duzy demo-c:maly
```

Przywróć `Wersja 1` w `app.py`.
