# Przygotowanie środowiska

Cała praca odbywa się na Twoim komputerze: Docker Desktop w dniu 1 i lokalny klaster Kubernetes (kind) w dniu 2. Nie potrzebujesz konta w chmurze.

**Wymagania sprzętowe:** 8 GB RAM (zalecane 16 GB), 15 GB wolnego miejsca, uprawnienia administratora do instalacji.

## 1. Narzędzia

| Narzędzie | macOS | Windows | Linux |
|---|---|---|---|
| Docker Desktop | [docs.docker.com/desktop](https://docs.docker.com/desktop/setup/install/mac-install/) | [z WSL 2](https://docs.docker.com/desktop/setup/install/windows-install/) | Docker Engine: [docs.docker.com/engine/install](https://docs.docker.com/engine/install/) |
| kubectl | `brew install kubectl` | `winget install -e --id Kubernetes.kubectl` | [instrukcja](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) |
| kind | `brew install kind` | `winget install -e --id Kubernetes.kind` | [instrukcja](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) |
| helm | `brew install helm` | `winget install -e --id Helm.Helm` | [instrukcja](https://helm.sh/docs/intro/install/) |
| git | `brew install git` | `winget install -e --id Git.Git` | menedżer pakietów |
| edytor | [VS Code](https://code.visualstudio.com/) + rozszerzenia „Docker” i „Kubernetes” | | |

**Docker Desktop → Settings → Resources:** przydziel co najmniej 4 CPU i 6 GB pamięci (macOS; na Windows zobacz niżej).

### Windows: jedna powłoka — Git Bash w Windows Terminal

Wszystkie polecenia z labów są w bashu i działają tak samo jak na macOS i Linuksie. Na Windows:

1. Uruchamiaj je w **Git Bash otwartym w Windows Terminal** (lista rozwijana przy karcie → *Git Bash*). Nie w PowerShellu i nie w osobnym oknie „Git Bash” (mintty) — tam nie działają polecenia interaktywne `-it`.
2. Raz, po instalacji Gita, wyłącz zamianę ścieżek, którą robi Git Bash (bez tego `docker run … cat /dane/plik` szuka pliku w `C:/Program Files/Git/…`):

   ```bash
   echo 'export MSYS_NO_PATHCONV=1' >> ~/.bashrc && source ~/.bashrc
   ```
3. Po instalacji narzędzi przez `winget` zamknij i otwórz terminal na nowo, żeby widział je w `PATH`.
4. Pamięć dla Dockera (backend WSL 2) ustawiasz w pliku `%UserProfile%\.wslconfig`, nie w Docker Desktop. Potem `wsl --shutdown` i restart Docker Desktop:

   ```ini
   [wsl2]
   memory=6GB
   processors=4
   ```

## 2. Repozytorium

```bash
git clone <adres repozytorium podany na czacie>
cd docker-k8s-altkom
```

## 3. Sprawdzenie przed dniem 1

```bash
./setup/sprawdz.sh
```

Skrypt sprawdza narzędzia, działanie Dockera i wolne porty. Na końcu powinno być `✅`.

Warto też pobrać obrazy wcześniej — na szkoleniu łącze bywa obciążone:

```bash
./setup/sprawdz.sh --pobierz
```

### Pełny test środowiska

```bash
./setup/test-srodowiska.sh
```

Sprawdza w 3–5 minut wszystko, na czym stoją laby: kontenery i porty, bind mount i wolumen, budowanie obrazów, ToDos w Docker Compose, a potem klaster Kubernetes (jeśli go nie ma, tworzy go), Ingress pod `*.localhost` i metrics-server. Przy każdym ❌ podpowiada, co poprawić. Szczegóły zapisuje w `setup/test-srodowiska.log`. Po sobie sprząta, klaster `szkolenie` zostaje.

## 4. Klaster Kubernetes (pod koniec dnia 1, lab05)

```bash
./setup/start-klastra.sh
```

Tworzy klaster `szkolenie` z trzema węzłami (każdy to kontener Dockera), Ingress Controller (Traefik, porty 80/443 na Twoim laptopie) i metrics-server. Kontekst `kind-szkolenie`, domyślny namespace `szkolenie`.

> **Nie twórz klastra w Docker Desktop.** Docker Desktop ma własny Kubernetes (*Settings → Kubernetes*, także w wariancie „kind”). Nie włączaj go: taki klaster nie ma portów 80/443 do Ingressu, Traefika ani metrics-server, a kontekst nazywa się `docker-desktop`, więc polecenia z labów 05–09 nie zadziałają. Klaster stawiamy tylko skryptem `start-klastra.sh`. Jeśli Kubernetes w Docker Desktop jest już włączony, wyłącz go (odznacz *Enable Kubernetes* → *Apply & restart*).

| Problem | Rozwiązanie |
|---|---|
| `port 80 is already allocated` | port 80 zajmuje inny program — zobacz [niżej](#port-80-zajęty), zwolnij go i uruchom skrypt ponownie |
| `Cannot connect to the Docker daemon` | uruchom Docker Desktop |
| klaster działa wolno albo pody są `Pending` | zwiększ zasoby Docker Desktop (punkt 1) |
| chcę zacząć od zera | `./setup/start-klastra.sh --usun` i `./setup/start-klastra.sh` |

### Port 80 zajęty

Skrypt `./setup/sprawdz.sh` pokazuje ❌ przy porcie 80, jeśli zajmuje go coś innego niż klaster. Sprawdź, co to jest (dla portu 443 postępujesz tak samo, wpisując `:443`).

**Windows** — PowerShell **jako administrator**:

```powershell
netstat -ano | findstr ":80 " | findstr LISTENING     # ostatnia kolumna to PID
Get-Process -Id <PID>                                 # jaki to program
```

- **PID 4 (`System`)** — port trzyma usługa Windows przez `http.sys`, najczęściej IIS („World Wide Web Publishing Service”). Zatrzymaj ją i wyłącz autostart na czas szkolenia:

  ```powershell
  Stop-Service W3SVC
  Set-Service W3SVC -StartupType Disabled      # po szkoleniu: -StartupType Automatic
  ```

  Jeśli `W3SVC` nie istnieje, sprawdź, kto korzysta z `http.sys`: `netsh http show servicestate` (szukaj procesu z adresem `:80`).
- **Inny PID** — to zwykły program (np. XAMPP, Apache, nginx, Skype). Zamknij go albo `Stop-Process -Id <PID>`.

**macOS / Linux:**

```bash
sudo lsof -nP -iTCP:80 -sTCP:LISTEN     # nazwa programu i PID
```

Potem uruchom jeszcze raz `./setup/sprawdz.sh` — przy porcie 80 powinno być ✅.

