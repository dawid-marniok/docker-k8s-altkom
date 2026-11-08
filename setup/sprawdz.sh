#!/usr/bin/env bash
# Sprawdza środowisko przed szkoleniem.  Użycie:  ./setup/sprawdz.sh [--pobierz]
#   --pobierz   dodatkowo pobiera obrazy używane w labach (oszczędza czas na zajęciach)
set -uo pipefail
export MSYS_NO_PATHCONV=1   # Git Bash na Windows: nie zamieniaj ścieżek /x na C:/... (na macOS/Linux bez znaczenia)

ok=0
pass() { echo "  ✅ $1"; }
fail() { echo "  ❌ $1"; ok=1; }

echo "Narzędzia:"
for t in docker kubectl kind helm git; do
  if command -v "$t" >/dev/null 2>&1; then pass "$t"; else fail "$t — brak (setup/README.md, punkt 1)"; fi
done

echo "Docker:"
if docker info >/dev/null 2>&1; then
  pass "Docker działa ($(docker version --format '{{.Server.Version}}'))"
  mem=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo 0)
  if (( mem >= 5000000000 )); then pass "pamięć dla Dockera: $((mem / 1024 / 1024 / 1024)) GB"
  else fail "pamięć dla Dockera: $((mem / 1024 / 1024)) MB — ustaw co najmniej 6 GB w Docker Desktop"; fi
  if docker run --rm hello-world >/dev/null 2>&1; then pass "docker run hello-world"; else fail "nie da się pobrać/uruchomić obrazu (sieć? proxy?)"; fi
else
  fail "Docker nie odpowiada — uruchom Docker Desktop"
fi

echo "Porty na laptopie:"
for p in 80 443 8080; do
  if (exec 3<>/dev/tcp/127.0.0.1/$p) 2>/dev/null; then
    if docker ps --format '{{.Ports}}' 2>/dev/null | grep -q ":$p->"; then pass "$p zajęty przez kontener (OK, jeśli to klaster szkolenia)"
    else fail "$p zajęty przez inny program — zwolnij go przed szkoleniem"; fi
  else
    pass "$p wolny"
  fi
done

if [[ ${1:-} == --pobierz ]]; then
  echo "Pobieram obrazy do labów:"
  for img in alpine:3.22 busybox:1.37 nginx:1.29 nginx:1.29-alpine postgres:17 mongo:7.0 \
             node:22-alpine golang:1.25 gcr.io/distroless/static-debian12 \
             nginxinc/nginx-unprivileged:1.29-alpine kindest/node:v1.37.0; do
    if docker pull -q "$img" >/dev/null 2>&1; then pass "$img"; else fail "$img"; fi
  done
fi

echo
if (( ok == 0 )); then echo "✅ Wszystko gotowe"; else echo "❌ Popraw powyższe i uruchom skrypt ponownie"; fi
exit $ok
