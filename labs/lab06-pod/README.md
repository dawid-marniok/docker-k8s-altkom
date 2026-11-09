# Lab 06 — Pody i diagnostyka

**Cel:** utworzyć pod z pliku YAML, dostać się do niego i zdiagnozować pody, które nie wstają.
Katalog `labs/lab06-pod/`

## 1. Pod z pliku

```bash
kubectl apply -f pod.yaml
kubectl get pods -o wide
kubectl describe pod web
```

Dostań się do nginxa z laptopa:

```bash
kubectl port-forward pod/web 8085:80
```

Otwórz http://localhost:8085, potem w terminalu Ctrl+C.

## 2. Zmiana przez `apply`

W `pod.yaml` zmień etykietę `env: dev` na `env: test` i zrób `kubectl apply -f pod.yaml`.

```bash
kubectl get pods --show-labels
kubectl get pods -l env=test
```

Teraz zmień obraz na `nginx:1.28` i spróbuj `apply`. Część pól poda jest niezmienna albo zmiana restartuje kontener. Sprawdź `kubectl get pods` (kolumna RESTARTS) i `kubectl describe pod web` (pola `Image`, `Restart Count` i sekcja Events).

## 3. Wejście do środka

```bash
kubectl exec -it web -- bash
# w środku:
hostname; cat /etc/resolv.conf; exit
kubectl logs web
```

Plik `resolv.conf` wskazuje DNS klastra: dzięki niemu pody znajdują się po nazwach usług.

## 4. Trzy zepsute pody

```bash
kubectl apply -f zepsute.yaml
kubectl get pods
```

Dla każdego poda ustal, **co** się dzieje i **dlaczego**. Używaj:

| Polecenie | Kiedy |
|---|---|
| `kubectl get pods` | status: `ImagePullBackOff`, `CrashLoopBackOff`, `Pending`… |
| `kubectl describe pod <nazwa>` | sekcja **Events** na dole |
| `kubectl logs <nazwa>` | co wypisała aplikacja |
| `kubectl logs <nazwa> --previous` | logi poprzedniego, padniętego uruchomienia (gdy samo `logs` jest puste; nie zawsze jest dostępne) |

Zapisz przyczyny na czacie. Napraw `zepsuty-1` w pliku i zastosuj ponownie (dla poda zwykle trzeba `kubectl delete` + `apply`).

## 5. Pod z dwoma kontenerami

Utwórz `dwa.yaml`: pod `para` z kontenerem `nginx:1.29` oraz kontenerem `busybox:1.37`, który co 5 s robi `wget -qO- localhost:80 | head -1`.

```bash
kubectl apply -f dwa.yaml
kubectl logs para -c <nazwa-kontenera-busybox>
```

**Wniosek:** kontenery w jednym podzie dzielą adres IP (`localhost`) i zawsze trafiają na ten sam węzeł.

## Dla chętnych

- Dodaj do `pod.yaml` `readinessProbe` (`httpGet` na `/`, port 80) i obserwuj kolumnę READY. Zmień ścieżkę na `/nie-ma` — co się stanie?
- `kubectl get pod web -o jsonpath='{.status.podIP}{"\n"}'`
- Utwórz namespace `test`, uruchom w nim pod i sprawdź `kubectl get pods -n test` oraz `kubectl get pods -A`.

## Sprzątanie

```bash
kubectl delete -f pod.yaml -f zepsute.yaml --now
kubectl delete pod para --now --ignore-not-found
```

Odpowiedzi i rozwiązania: [`rozwiazanie/README.md`](rozwiazanie/README.md) — zajrzyj po samodzielnej próbie.
