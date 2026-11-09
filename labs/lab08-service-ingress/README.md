# Lab 08 — Service i Ingress

**Cel:** dać aplikacji stały adres w klastrze, a potem adres z przeglądarki.
Katalog `labs/lab08-service-ingress/` · potrzebny Deployment `hello` z lab07

```bash
kubectl get deploy hello     # 2/2 READY
```

Nie masz `hello` albo pody nie są gotowe? Wdróż rozwiązanie lab07 (Deployment, ConfigMap i Secret naraz):

```bash
kubectl apply -f ../lab07-deployment-konfiguracja/rozwiazanie/
```

## 1. Service ClusterIP

Utwórz `service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hello
spec:
  selector:
    app: hello        # ruch idzie do podów z tą etykietą
  ports:
    - port: 80        # port Service
      targetPort: 80  # port kontenera
```

```bash
kubectl apply -f service.yaml
kubectl get svc hello
kubectl get endpointslices -l kubernetes.io/service-name=hello
```

**Sprawdź:** w EndpointSlice są 2 adresy IP — po jednym na pod `hello`. Porównaj z `kubectl get pods -l app=hello -o wide`.

## 2. Test z wnętrza klastra

```bash
kubectl run klient --rm -it --image=busybox:1.37 -- sh
# zobaczysz „If you don't see a command prompt, try pressing enter” — naciśnij Enter
# w środku, kilka razy:
wget -qO- http://hello | grep 'Server name'
wget -qO- http://hello.szkolenie.svc.cluster.local | grep 'Server name'
exit
```

**Sprawdź:** odpowiadają różne pody. Service rozkłada ruch losowo, więc przy dwóch podach ten sam może odpowiedzieć kilka razy z rzędu — powtórz `wget`. Service znajduje się po nazwie (DNS klastra).

## 3. Selektor to wszystko

Zmień w `service.yaml` selektor na `app: helo` (literówka) i zrób `apply`.

```bash
kubectl get endpointslices -l kubernetes.io/service-name=hello
```

Pusto — Service istnieje, ale nie ma dokąd wysłać ruchu. To najczęstszy błąd przy pierwszych wdrożeniach. Popraw selektor.

## 4. NodePort (dla porównania)

Utwórz `service-np.yaml` — drugi Service dla tych samych podów, tym razem typu NodePort:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-np
spec:
  type: NodePort
  selector:
    app: hello
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080   # port otwarty na każdym węźle (zakres 30000–32767)
```

```bash
kubectl apply -f service-np.yaml
kubectl get svc hello-np        # PORT(S): 80:30080/TCP
docker exec szkolenie-worker curl -s localhost:30080 | head -3
```

Pusta odpowiedź zaraz po `apply`? Klaster potrzebuje kilku sekund na ustawienie reguł — powtórz polecenie.
`provided port is already allocated`? Port 30080 jest zajęty — wpisz inny z zakresu albo usuń linię `nodePort`, a Kubernetes wybierze go sam.

Na kind węzły to kontenery, więc NodePort sprawdzamy „z węzła”. W prawdziwym klastrze to port otwarty na każdym węźle.

## 5. Ingress: adres dla przeglądarki

Utwórz `ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello
spec:
  rules:
    - host: hello.localhost
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: hello
                port:
                  number: 80
```

```bash
kubectl apply -f ingress.yaml
kubectl get ingress
curl http://hello.localhost
```

Otwórz http://hello.localhost w przeglądarce. Adresy `*.localhost` zawsze wskazują Twój komputer, a port 80 laptopa prowadzi do Ingress Controllera (Traefik) w klastrze.

> Nie działa w przeglądarce? Spróbuj `curl -H "Host: hello.localhost" http://localhost`.

## 6. Dwie aplikacje pod jednym adresem

Druga aplikacja jest gotowa w pliku `echo.yaml`: Deployment `echo` (obraz `hashicorp/http-echo`, odpowiada stałym tekstem) i Service `echo`. Przejrzyj plik: kontener słucha na porcie **5678**, a Service wystawia go na porcie **80** (`port` → `targetPort`).

```bash
kubectl apply -f echo.yaml
kubectl get deploy,svc,endpointslices -l app=echo
```

Dodaj do Ingressu drugą ścieżkę `/echo` prowadzącą do Service `echo` i zrób `kubectl apply -f ingress.yaml`.

<details><summary>Podpowiedź</summary>

W tej samej regule `host: hello.localhost`, pod `paths:`, dopisz drugi element listy — skopiuj blok `- path: / …` i zmień `path` na `/echo`, a `service.name` na `echo`. Kolejność nie ma znaczenia: wygrywa najdłuższy pasujący prefiks.
</details>

**Sprawdź:** `curl http://hello.localhost/echo` i `curl http://hello.localhost/`.

`no available server`? Traefik potrzebuje kilku sekund, żeby zauważyć nowe pody — powtórz `curl`.

## Dla chętnych

- `kubectl describe ingress hello` — gdzie widać, do jakich podów trafi ruch?
- Ustaw `replicas: 0` w `../lab07-deployment-konfiguracja/deployment.yaml`, zrób `apply` i otwórz stronę. Jaki błąd zwraca Ingress? Potem przywróć 2 repliki.
- Podejrzyj Ingress Controller: `kubectl get pods,svc -n traefik`.

## Sprzątanie

Usuwamy wszystko, co opisują pliki z tego labu i z lab07 (Deployment `hello`, ConfigMap, Secret):

```bash
kubectl delete -f . --ignore-not-found
kubectl delete -f ../lab07-deployment-konfiguracja/ --ignore-not-found
kubectl get all,ingress,configmap,secret     # zostaje tylko configmap/kube-root-ca.crt
```

`delete -f <katalog>` bierze wszystkie pliki YAML z katalogu (bez podkatalogów, więc `rozwiazanie/` zostaje nietknięte).

Rozwiązanie: [`rozwiazanie/`](rozwiazanie/) — `service.yaml` (krok 1), `service-np.yaml` (krok 4), `ingress.yaml` (po kroku 6).
