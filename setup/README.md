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

## 4. Klaster Kubernetes (pod koniec dnia 1, lab05)

```bash
./setup/start-klastra.sh
```

Tworzy klaster `szkolenie` z trzema węzłami (każdy to kontener Dockera), Ingress Controller (Traefik, porty 80/443 na Twoim laptopie) i metrics-server. Kontekst `kind-szkolenie`, domyślny namespace `szkolenie`.

| Problem | Rozwiązanie |
|---|---|
| `port 80 is already allocated` | zatrzymaj program, który zajmuje port 80 (inny serwer WWW, IIS, Skype), i uruchom skrypt ponownie |
| `Cannot connect to the Docker daemon` | uruchom Docker Desktop |
| klaster działa wolno albo pody są `Pending` | zwiększ zasoby Docker Desktop (punkt 1) |
| chcę zacząć od zera | `./setup/start-klastra.sh --usun` i `./setup/start-klastra.sh` |
