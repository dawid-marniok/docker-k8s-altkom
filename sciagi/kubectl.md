# Ściąga: kubectl

## Kontekst i namespace

```bash
kubectl config get-contexts
kubectl config use-context kind-szkolenie
kubectl config set-context --current --namespace=szkolenie
```

## Oglądanie

| Polecenie | Co robi |
|---|---|
| `kubectl get pods` · `-o wide` · `-w` | lista · z węzłem i IP · na żywo |
| `kubectl get all` | pody, Deploymenty, ReplicaSety, Service |
| `kubectl get pods -A` | wszystkie namespace'y |
| `kubectl get pods -l app=api` | po etykiecie |
| `kubectl get pod web -o yaml` | pełny obiekt |
| `kubectl describe pod web` | szczegóły + **Events** na dole |
| `kubectl logs web` · `-f` · `--previous` · `-c kontener` | logi · na żywo · poprzednie uruchomienie · wybrany kontener |
| `kubectl logs deploy/api` | logi jednego poda z Deploymentu |
| `kubectl top pods` · `kubectl top nodes` | CPU i pamięć |
| `kubectl get events --sort-by=.lastTimestamp` | zdarzenia w kolejności |

## Zmiany

| Polecenie | Co robi |
|---|---|
| `kubectl apply -f plik.yaml` · `-f katalog/` | utwórz lub zaktualizuj z pliku |
| `kubectl delete -f plik.yaml` | usuń to, co jest w pliku |
| `kubectl create deployment web --image=nginx:1.29 --dry-run=client -o yaml > web.yaml` | szkielet manifestu |
| `kubectl scale deploy web --replicas=3` | skalowanie |
| `kubectl set image deploy/web web=nginx:1.28` | nowa wersja obrazu |
| `kubectl rollout status · history · undo · restart deploy/web` | stan · historia · cofnięcie · restart podów |
| `kubectl edit deploy web` | edycja w edytorze |

## Dostęp do aplikacji

| Polecenie | Co robi |
|---|---|
| `kubectl port-forward pod/web 8080:80` | port laptopa → pod |
| `kubectl port-forward svc/web 8080:80` | port laptopa → Service |
| `kubectl exec -it web -- sh` | powłoka w podzie |
| `kubectl run klient --rm -it --image=busybox:1.37 -- sh` | tymczasowy pod do testów z wnętrza klastra |

## Diagnostyka poda

| STATUS | Najczęstsza przyczyna | Sprawdź |
|---|---|---|
| `Pending` | brak zasobów na węzłach, brak PVC | `describe` → Events |
| `ImagePullBackOff` / `ErrImagePull` | literówka w obrazie lub tagu, prywatny rejestr | `describe` → Events |
| `CrashLoopBackOff` | aplikacja startuje i pada | `logs`, a gdy puste — `logs --previous` |
| `Running`, ale `0/1 READY` | nie przechodzi `readinessProbe` | `describe` → Events, `logs` |
| `OOMKilled` | przekroczony limit pamięci | `describe` → Last State |

Service bez ruchu? `kubectl get endpointslices -l kubernetes.io/service-name=<nazwa>` — pusto = selektor nie pasuje do etykiet podów.

## Dokumentacja w terminalu

```bash
kubectl explain deployment.spec.template.spec.containers
kubectl api-resources
```
