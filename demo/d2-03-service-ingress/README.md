# Service i Ingress

**Cel:** stały adres w klastrze dla podów, które się zmieniają, a potem adres dla przeglądarki.
**Pliki:** `app.yaml` (Deployment `kto` z 3 replikami + Service `kto`), `ingress.yaml`.

Aplikacja to `traefik/whoami`: odpowiada nazwą poda (`Hostname:`) i nagłówkami żądania, więc widać, który pod odpowiedział i którędy przyszło żądanie.

## Kroki

### 1. Service i jego endpointy

```bash
kubectl apply -f app.yaml
kubectl rollout status deploy/kto
kubectl get svc kto                       # CLUSTER-IP: stały adres
kubectl get pods -l app=kto -o wide       # trzy różne IP podów
kubectl get endpointslices -l kubernetes.io/service-name=kto   # te same trzy IP
```

### 2. Nazwa Service to adres

```bash
kubectl run klient --rm -it --image=busybox:1.37 -- sh
# naciśnij Enter, potem w środku:
for i in 1 2 3 4 5 6; do wget -qO- http://kto | grep Hostname; done   # różne pody
nslookup kto                              # nazwa → CLUSTER-IP Service, nie IP poda
exit
```

### 3. Lista podów aktualizuje się sama

```bash
kubectl scale deploy kto --replicas=1
kubectl get endpointslices -l kubernetes.io/service-name=kto   # jeden adres
kubectl scale deploy kto --replicas=3
kubectl get endpointslices -l kubernetes.io/service-name=kto   # znowu trzy
```

Adres i nazwa Service się nie zmieniają. Zmienia się tylko lista podów za nim, a klienci niczego nie muszą wiedzieć.

### 4. Ingress: adres dla przeglądarki

```bash
kubectl apply -f ingress.yaml
kubectl get ingress kto
curl http://kto.localhost                 # kilka razy: Hostname się zmienia
```

Otwórz http://kto.localhost w przeglądarce. W odpowiedzi są nagłówki `X-Forwarded-Host: kto.localhost` i `X-Forwarded-For` — dopisał je Ingress Controller (Traefik), przez który przeszło żądanie.

Droga żądania: przeglądarka → port 80 laptopa → Traefik → Service `kto` → jeden z podów.

> Nie działa w przeglądarce? `curl -H "Host: kto.localhost" http://localhost`.

## Na co zwrócić uwagę

- IP podów są różne i zmienne, a CLUSTER-IP i nazwa Service — stałe
- EndpointSlice to aktualna lista gotowych podów za Service
- Ingress sam niczego nie obsługuje — robi to Ingress Controller, który czyta jego reguły

## Sprzątanie

```bash
kubectl delete -f . --now
```
