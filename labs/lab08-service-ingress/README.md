# Lab 08 — Service i Ingress

**Cel:** dać aplikacji stały adres w klastrze, a potem adres z przeglądarki.
Katalog `labs/lab08-service-ingress/` · potrzebny Deployment `hello` z lab07

```bash
kubectl get deploy hello     # jeśli go nie ma: kubectl apply -f ../lab07-deployment-konfiguracja/deployment.yaml
kubectl scale deploy hello --replicas=3
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

**Sprawdź:** w EndpointSlice są 3 adresy IP — po jednym na pod.

## 2. Test z wnętrza klastra

```bash
kubectl run klient --rm -it --image=busybox:1.37 -- sh
# zobaczysz „If you don't see a command prompt, try pressing enter” — naciśnij Enter
# w środku, kilka razy:
wget -qO- http://hello | grep 'Server name'
wget -qO- http://hello.szkolenie.svc.cluster.local | grep 'Server name'
exit
```

**Sprawdź:** odpowiadają różne pody. Service rozkłada ruch i znajduje się po nazwie (DNS klastra).

## 3. Selektor to wszystko

Zmień w `service.yaml` selektor na `app: helo` (literówka) i zrób `apply`.

```bash
kubectl get endpointslices -l kubernetes.io/service-name=hello
```

Pusto — Service istnieje, ale nie ma dokąd wysłać ruchu. To najczęstszy błąd przy pierwszych wdrożeniach. Popraw selektor.

## 4. NodePort (dla porównania)

```bash
kubectl expose deploy hello --name=hello-np --type=NodePort --port=80
kubectl get svc hello-np        # zapamiętaj port 3xxxx
docker exec szkolenie-worker curl -s localhost:<port> | head -3
```

Pusta odpowiedź zaraz po `expose`? Klaster potrzebuje kilku sekund na ustawienie reguł — powtórz polecenie.

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

Utwórz drugi Deployment i Service:

```bash
kubectl create deployment echo --image=hashicorp/http-echo:1.0 -- /http-echo -text="to jest echo" -listen=:5678
kubectl expose deployment echo --port=80 --target-port=5678
```

Dodaj do Ingressu drugą ścieżkę `/echo` prowadzącą do Service `echo` i zrób `kubectl apply -f ingress.yaml`.

<details><summary>Podpowiedź</summary>

W tej samej regule `host: hello.localhost`, pod `paths:`, dopisz drugi element listy — skopiuj blok `- path: / …` i zmień `path` na `/echo`, a `service.name` na `echo`. Kolejność nie ma znaczenia: wygrywa najdłuższy pasujący prefiks.
</details>

**Sprawdź:** `curl http://hello.localhost/echo` i `curl http://hello.localhost/`.

`no available server`? Traefik potrzebuje kilku sekund, żeby zauważyć nowe pody — powtórz `curl`.

## Dla chętnych

- `kubectl describe ingress hello` — gdzie widać, do jakich podów trafi ruch?
- Przeskaluj `hello` do 0 replik i otwórz stronę. Jaki błąd zwraca Ingress?
- Podejrzyj Ingress Controller: `kubectl get pods,svc -n traefik`.

## Sprzątanie

```bash
kubectl delete ingress hello
kubectl delete svc hello hello-np echo
kubectl delete deploy hello echo
kubectl delete configmap hello-config --ignore-not-found
kubectl delete secret hello-secret --ignore-not-found
```

Rozwiązanie (Ingress po kroku 6): [`rozwiazanie/ingress.yaml`](rozwiazanie/ingress.yaml).
