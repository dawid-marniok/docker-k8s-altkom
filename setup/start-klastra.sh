#!/usr/bin/env bash
# Tworzy lokalny klaster kind „szkolenie” z Ingress Controllerem (Traefik) i metrics-server.
# Użycie:  ./setup/start-klastra.sh        (z głównego katalogu repo)
#          ./setup/start-klastra.sh --usun (kasuje klaster)
set -euo pipefail
export MSYS_NO_PATHCONV=1   # Git Bash na Windows: nie zamieniaj ścieżek /x na C:/... (na macOS/Linux bez znaczenia)
cd "$(dirname "$0")"

if [[ ${1:-} == --usun ]]; then
  kind delete cluster --name szkolenie
  exit 0
fi

# Windows (Git Bash): brakujące kind/kubectl/helm pobieramy do ~/bin — bez winget i bez uprawnień administratora
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    export PATH="$HOME/bin:$PATH"
    declare -A url=(
      [kind]=https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-windows-amd64
      [kubectl]=https://dl.k8s.io/release/v1.37.0/bin/windows/amd64/kubectl.exe
      [helm]=https://get.helm.sh/helm-v4.3.0-windows-amd64.zip
    )
    # curl i tar.exe to programy Windows, a MSYS_NO_PATHCONV=1 wyłącza zamianę ścieżek — podajemy je w formie C:/...
    bin=$(cygpath -m "$HOME/bin")
    for t in kind kubectl helm; do
      command -v "$t" >/dev/null && continue
      echo "▶ Brak $t — pobieram do ~/bin"
      mkdir -p "$HOME/bin"
      if [[ $t == helm ]]; then
        # helm jest w .zip — rozpakowuje go tar.exe wbudowany w Windows 10/11
        curl -fsSLo "$bin/helm.zip" "${url[$t]}" \
          && "$(cygpath -u "${SYSTEMROOT:-C:/Windows}")/System32/tar.exe" -xf "$bin/helm.zip" -C "$bin" windows-amd64/helm.exe \
          && mv "$HOME/bin/windows-amd64/helm.exe" "$HOME/bin/helm.exe" \
          && rm -rf "$HOME/bin/helm.zip" "$HOME/bin/windows-amd64" \
          || { echo "❌ Nie udało się pobrać helm (sprawdź internet)"; exit 1; }
      else
        curl -fsSLo "$bin/$t.exe" "${url[$t]}" || { echo "❌ Nie udało się pobrać $t (sprawdź internet)"; exit 1; }
      fi
      grep -qs 'HOME/bin' "$HOME/.bashrc" || echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
    done
    ;;
esac

for t in docker kind kubectl helm; do
  command -v "$t" >/dev/null || { echo "❌ Brak narzędzia: $t (zobacz setup/README.md)"; exit 1; }
done
docker info >/dev/null 2>&1 || { echo "❌ Docker nie działa — uruchom Docker Desktop"; exit 1; }

if kind get clusters 2>/dev/null | grep -qx szkolenie; then
  echo "ℹ️  Klaster „szkolenie” już istnieje — pomijam tworzenie"
else
  kind create cluster --config kind-config.yaml
fi
kubectl config use-context kind-szkolenie >/dev/null

echo "▶ Ingress Controller (Traefik)"
helm repo add traefik https://traefik.github.io/charts >/dev/null 2>&1 || true
helm repo update traefik >/dev/null
helm upgrade --install traefik traefik/traefik -n traefik --create-namespace \
  --version 42.3.1 -f traefik-values.yaml --wait --timeout 5m >/dev/null

echo "▶ metrics-server (kubectl top, HPA)"
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/ >/dev/null 2>&1 || true
helm repo update metrics-server >/dev/null
helm upgrade --install metrics-server metrics-server/metrics-server --version 3.14.0 -n kube-system \
  --set 'args={--kubelet-insecure-tls}' --wait --timeout 5m >/dev/null

echo "▶ Twój namespace: szkolenie (domyślny w kontekście)"
kubectl create namespace szkolenie --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl config set-context --current --namespace=szkolenie >/dev/null

echo
kubectl get nodes
echo
echo "✅ Klaster gotowy. Kontekst: kind-szkolenie, namespace: szkolenie"
