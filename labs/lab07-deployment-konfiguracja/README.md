# Lab 07 — Deployment, aktualizacja i konfiguracja

**Cel:** wdrożyć aplikację Deploymentem, zaktualizować ją bez przerwy, cofnąć zmianę i przekazać konfigurację z zewnątrz.
**Czas:** ok. 35 minut · katalog `labs/lab07-deployment-konfiguracja/`

## 1. Deployment i samonaprawianie

```bash
kubectl apply -f deployment.yaml
kubectl get deploy,rs,pods
```

Usuń jeden pod i od razu sprawdź listę:

```bash
kubectl delete pod <nazwa-jednego-poda> --now
kubectl get pods
```

**Sprawdź:** liczba podów wraca do 3. Wczoraj goły pod `ping` nie wrócił — tu pilnuje go ReplicaSet.

## 2. Skalowanie

```bash
kubectl scale deploy hello --replicas=5
kubectl get pods -o wide        # na których węzłach?
```

Teraz zmień `replicas` w pliku na 2 i zrób `kubectl apply -f deployment.yaml`. Ostatnie słowo ma plik — to podejście deklaratywne.

## 3. Aktualizacja bez przerwy (rolling update)

W drugim terminalu uruchom podgląd:

```bash
kubectl get pods -w
```

W pierwszym zmień obraz:

```bash
kubectl set image deploy/hello hello=nginxdemos/hello:0.4-plain-text
kubectl rollout status deploy/hello
kubectl rollout history deploy/hello
kubectl get rs                 # stary ReplicaSet ma 0 podów, ale zostaje
```

## 4. Zła wersja i rollback

```bash
kubectl set image deploy/hello hello=nginxdemos/hello:nie-ma-takiej
kubectl rollout status deploy/hello --timeout=30s
kubectl get pods
```

Nowe pody nie wstają, ale **stare dalej działają** — rolling update nie wyłączył ich, bo nowe nie były gotowe.

```bash
kubectl rollout undo deploy/hello
kubectl rollout status deploy/hello
```

## 5. ConfigMap jako zmienne środowiskowe

```bash
kubectl create configmap hello-config --from-literal=KOLOR=zielony --from-literal=TRYB=szkolenie
kubectl get configmap hello-config -o yaml
```

Dodaj do kontenera w `deployment.yaml`:

```yaml
          envFrom:
            - configMapRef:
                name: hello-config
```

```bash
kubectl apply -f deployment.yaml
kubectl exec deploy/hello -- env | grep -E 'KOLOR|TRYB'
```

Zmień wartość w ConfigMap (`kubectl edit configmap hello-config`) i sprawdź `env` ponownie. Zmiennych nie widać od razu: działający kontener ich nie przeładuje. Pomoże `kubectl rollout restart deploy/hello`.

## 6. Secret

```bash
kubectl create secret generic hello-secret --from-literal=DB_PASSWORD=changeme-lab07
kubectl get secret hello-secret -o yaml
echo '<wartość z pola data>' | base64 -d
```

**Wniosek:** Secret to **nie** szyfrowanie, tylko base64. Ochronę daje RBAC (kto może czytać Secrety) i szyfrowanie etcd po stronie klastra.

Dodaj Secret do Deploymentu tak samo jak ConfigMap (`secretRef`) i sprawdź `env`.

## Dla chętnych

- ConfigMap jako **plik**: `kubectl create configmap strona --from-file=index.html=./index.html` (stwórz dowolny plik), zamontuj jako wolumen w `/usr/share/nginx/html` w Deploymencie z obrazem `nginx:1.29`.
- Strategia: dodaj `strategy.rollingUpdate.maxUnavailable: 0` i `maxSurge: 1`, zaktualizuj obraz i obserwuj kolejność.
- `kubectl rollout history deploy/hello --revision=2`

## Sprzątanie

Deployment `hello` zostaw — przyda się w lab08.

```bash
kubectl delete configmap hello-config; kubectl delete secret hello-secret
```

Jeśli usuwasz ConfigMap i Secret, usuń też `envFrom` z `deployment.yaml` i zrób `apply`.
