#!/usr/bin/env bash
# Szybki test: czy na tym komputerze zadziałają laby (Docker + Kubernetes).
# Nie przechodzi labów krok po kroku — sprawdza tylko to, na czym one stoją.
# Użycie (z głównego katalogu repo):  ./setup/test-srodowiska.sh
# Czas: 3–5 min, przy pierwszym uruchomieniu dłużej (pobieranie obrazów, tworzenie klastra).
# Po sobie sprząta; klaster „szkolenie” zostaje (jest potrzebny w labach).
set -uo pipefail
export MSYS_NO_PATHCONV=1   # Git Bash na Windows: nie zamieniaj ścieżek /x na C:/...
cd "$(dirname "$0")/.."
ROOT=$(pwd)
LOG="$ROOT/setup/test-srodowiska.log"
NS=test-srodowiska
: >"$LOG"

bledy=0
pass() { echo "  ✅ $1"; }
fail() { echo "  ❌ $1"; [[ -n ${2:-} ]] && echo "     → $2"; bledy=$((bledy + 1)); }
# sprawdz "opis" "podpowiedź" polecenie...
sprawdz() { local d=$1 h=$2; shift 2; if "$@" >>"$LOG" 2>&1; then pass "$d"; else fail "$d" "$h"; fi; }
# ponawiaj SEKUNDY polecenie...  (dla rzeczy, które potrzebują chwili na start)
ponawiaj() { local koniec=$((SECONDS + $1)); shift; until "$@"; do ((SECONDS >= koniec)) && return 1; sleep 2; done; }
strona_ma() { curl -fsS -m 5 "$1" 2>/dev/null | grep -q "$2"; }
k() { kubectl --context kind-szkolenie -n "$NS" "$@"; }

COMPOSE="docker compose -p test-srodowiska -f labs/lab04-compose-todos/rozwiazanie/.test-compose.yaml"
sprzataj() {
  {
    docker rm -f test-nginx test-strona
    docker volume rm test-dane
    [[ -f labs/lab04-compose-todos/rozwiazanie/.test-compose.yaml ]] && $COMPOSE down -v
    rm -f labs/lab04-compose-todos/rozwiazanie/.test-compose.yaml
    kubectl --context kind-szkolenie delete namespace "$NS" --wait=false
  } >>"$LOG" 2>&1
}
trap sprzataj EXIT

echo "▶ Narzędzia, Docker, porty, obrazy do labów (setup/sprawdz.sh --pobierz)"
if ./setup/sprawdz.sh --pobierz >>"$LOG" 2>&1; then pass "sprawdz.sh: wszystko ✅"
else fail "sprawdz.sh zgłosił problem" "uruchom ./setup/sprawdz.sh --pobierz i popraw pozycje z ❌"; fi
docker info >/dev/null 2>&1 || { echo; echo "❌ Docker nie działa — dalsze testy nie mają sensu. Uruchom Docker Desktop."; exit 1; }

echo "▶ Docker (dzień 1)"
docker rm -f test-nginx test-strona >/dev/null 2>&1
sprawdz "kontener z portem na laptopie (localhost:18081)" "port 18081 zajęty albo firewall blokuje localhost" \
  bash -c 'docker run -d --name test-nginx -p 18081:80 nginx:1.29 && sleep 1'
sprawdz "strona z kontenera otwiera się przez curl" "sprawdź docker logs test-nginx" \
  ponawiaj 20 strona_ma http://localhost:18081 "Welcome to nginx"
sprawdz "bind mount: plik z laptopa w kontenerze (lab02)" \
  "Windows: uruchamiaj w Git Bash i ustaw MSYS_NO_PATHCONV=1 (setup/README.md); Docker Desktop → Settings → Resources → File sharing" \
  bash -c 'cd labs/lab02-sieci-wolumeny && docker run -d --name test-strona -p 18082:80 -v "$(pwd)/strona:/usr/share/nginx/html:ro" nginx:1.29'
sprawdz "bind mount: nginx pokazuje plik z dysku" "jak wyżej — katalog nie został zamontowany" \
  ponawiaj 20 strona_ma http://localhost:18082 "Strona z mojego laptopa"
sprawdz "wolumen: dane przeżywają kontener" "" bash -c '
  docker run --rm -v test-dane:/dane alpine:3.22 sh -c "echo przetrwam > /dane/plik" &&
  docker run --rm -v test-dane:/dane alpine:3.22 cat /dane/plik | grep -q przetrwam'
sprawdz "MongoDB uruchamia się na tym procesorze" \
  "kod 132 = brak instrukcji AVX (częste w maszynach wirtualnych): w lab04 i lab09 użyj mongo:4.4" \
  docker run --rm mongo:7.0 mongod --version
sprawdz "budowanie obrazu ToDos API (npm ci z internetu)" "brak dostępu do registry.npmjs.org? proxy?" \
  docker build -t todos-api:1.0 app/todos/api
sprawdz "budowanie obrazu ToDos web" "" docker build -t todos-web:1.0 app/todos/web

sed 's/"8080:8080"/"18080:8080"/' labs/lab04-compose-todos/rozwiazanie/compose.yaml \
  >labs/lab04-compose-todos/rozwiazanie/.test-compose.yaml
sprawdz "Docker Compose: ToDos (web + api + mongo) wstaje" "szczegóły w logu: docker compose logs" \
  $COMPOSE up -d --wait --wait-timeout 180
sprawdz "ToDos w Compose odpowiada i ma połączenie z bazą" "" \
  ponawiaj 60 strona_ma http://localhost:18080/api/info '"db":"ok"'
$COMPOSE down -v >>"$LOG" 2>&1

echo "▶ Kubernetes (dzień 2)"
if kind get clusters 2>/dev/null | grep -qx szkolenie; then
  pass "klaster szkolenie istnieje"
else
  echo "  … tworzę klaster (./setup/start-klastra.sh, 2–4 min)"
  sprawdz "utworzenie klastra skryptem start-klastra.sh" \
    "zobacz setup/README.md, punkt 4 (port 80 zajęty? za mało pamięci?)" ./setup/start-klastra.sh
fi
if kubectl --context kind-szkolenie get nodes >/dev/null 2>&1; then
  sprawdz "3 węzły Ready" "zwiększ zasoby Dockera (setup/README.md, punkt 1)" \
    ponawiaj 60 bash -c '[[ $(kubectl --context kind-szkolenie get nodes --no-headers | grep -c " Ready") == 3 ]]'
  sprawdz "Ingress Controller (Traefik) działa" "./setup/start-klastra.sh jeszcze raz (doinstaluje)" \
    kubectl --context kind-szkolenie -n traefik rollout status deploy/traefik --timeout=60s
  sprawdz "metrics-server: kubectl top nodes" "metrics-server potrzebuje ok. minuty po starcie klastra" \
    ponawiaj 90 kubectl --context kind-szkolenie top nodes
  sprawdz "wgranie obrazów do klastra (kind load, lab09)" "" \
    kind load docker-image todos-api:1.0 todos-web:1.0 --name szkolenie

  kubectl --context kind-szkolenie delete namespace "$NS" --ignore-not-found --wait=true >>"$LOG" 2>&1
  kubectl --context kind-szkolenie create namespace "$NS" >>"$LOG" 2>&1
  k create deployment web --image=nginx:1.29 --replicas=2 >>"$LOG" 2>&1
  k expose deployment web --port=80 >>"$LOG" 2>&1
  k create ingress web --rule="test-srodowiska.localhost/*=web:80" >>"$LOG" 2>&1
  sprawdz "Deployment w klastrze: 2 pody Running (obraz z internetu)" "kubectl describe pod — sekcja Events" \
    k rollout status deploy/web --timeout=180s
  if ponawiaj 30 strona_ma http://test-srodowiska.localhost "Welcome to nginx" >>"$LOG" 2>&1; then
    pass "Ingress: http://*.localhost z laptopa do klastra"
  elif ponawiaj 10 bash -c 'curl -fsS -m 5 -H "Host: test-srodowiska.localhost" http://localhost | grep -q "Welcome to nginx"' >>"$LOG" 2>&1; then
    fail "Ingress działa, ale curl nie rozwiązuje *.localhost" \
      "w lab08/09 używaj curl -H \"Host: hello.localhost\" http://localhost (przeglądarka zwykle działa)"
  else
    fail "Ingress: brak odpowiedzi z http://test-srodowiska.localhost" \
      "port 80 musi prowadzić do klastra: setup/README.md → Port 80 zajęty"
  fi
else
  fail "kubectl nie łączy się z klastrem (kontekst kind-szkolenie)" "./setup/start-klastra.sh"
fi

echo
if ((bledy == 0)); then
  echo "✅ Środowisko gotowe — laby powinny działać. ($((SECONDS / 60)) min $((SECONDS % 60)) s)"
else
  echo "❌ Problemów: $bledy. Szczegóły: setup/test-srodowiska.log"
fi
exit $((bledy > 0))
