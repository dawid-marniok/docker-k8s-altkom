# Lab 07 — Deployment, aktualizacja i konfiguracja

**Cel:** wdrożyć aplikację Deploymentem, zaktualizować ją bez przerwy, cofnąć zmianę i przekazać konfigurację z zewnątrz.
Katalog `labs/lab07-deployment-konfiguracja/`

Każdą zmianę robisz w pliku YAML i zatwierdzasz poleceniem `kubectl apply -f <plik>`. Plik opisuje stan, jaki ma być w klastrze. Kilka poleceń (`scale`, `rollout undo`, `rollout restart`) jest imperatywnych celowo: pokazują, co się dzieje, gdy klaster zmienia się obok pliku.

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

## 2. Skalowanie: polecenie kontra plik

Najpierw imperatywnie:

```bash
kubectl scale deploy hello --replicas=5
kubectl get pods -o wide        # 5 podów; na których węzłach?
```

Teraz w `deployment.yaml` zmień `replicas: 3` na `replicas: 2`:

```bash
kubectl apply -f deployment.yaml
kubectl get pods                # 2 pody
```

**Wniosek:** ostatnie słowo ma plik. `scale` zmienił tylko klaster, więc pierwszy `apply` go nadpisał.

## 3. Aktualizacja bez przerwy (rolling update)

W drugim terminalu uruchom podgląd:

```bash
kubectl get pods -w
```

W `deployment.yaml` zmień obraz:

```yaml
          image: nginxdemos/hello:0.4-plain-text
```

```bash
kubectl apply -f deployment.yaml
kubectl rollout status deploy/hello
kubectl rollout history deploy/hello
kubectl get rs                 # stary ReplicaSet ma 0 podów, ale zostaje
```

**Sprawdź:** w drugim terminalu nowe pody pojawiają się, zanim znikną stare.

## 4. Zła wersja i rollback

W `deployment.yaml` wpisz obraz, który nie istnieje:

```yaml
          image: nginxdemos/hello:nie-ma-takiej
```

```bash
kubectl apply -f deployment.yaml
kubectl rollout status deploy/hello --timeout=30s
kubectl get pods
```

`rollout status` po 30 s kończy się błędem `timed out waiting for the condition` — tak ma być. Nowy pod nie wstaje (`ErrImagePull` / `ImagePullBackOff`), ale **stare dalej działają**: rolling update ich nie wyłączył, bo nowy nie był gotowy.

Cofnij wdrożenie jednym poleceniem, tak jak przy awarii na produkcji:

```bash
kubectl rollout undo deploy/hello
kubectl rollout status deploy/hello
kubectl get deploy hello -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'   # 0.4-plain-text
```

Ostrzeżenie `resource deployments/hello was previously managed with 'kubectl apply'` jest niegroźne. Przypomina, że `undo` zmienił klaster, ale nie plik: w `deployment.yaml` nadal jest `nie-ma-takiej`, więc kolejny `apply` znowu wdroży złą wersję.

**Popraw plik:** wpisz z powrotem `image: nginxdemos/hello:0.4-plain-text` i zrób `kubectl apply -f deployment.yaml`. Odpowiedź `deployment.apps/hello configured` bez nowych podów w `kubectl get pods` oznacza, że plik i klaster znowu się zgadzają.

## 5. ConfigMap jako zmienne środowiskowe

Utwórz `configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: hello-config
data:
  KOLOR: zielony
  TRYB: szkolenie
```

```bash
kubectl apply -f configmap.yaml
kubectl get configmap hello-config -o yaml
```

Dodaj do kontenera w `deployment.yaml` (na tym samym poziomie co `image:` i `ports:`):

```yaml
          envFrom:
            - configMapRef:
                name: hello-config
```

```bash
kubectl apply -f deployment.yaml          # zmiana szablonu poda = nowy rollout
kubectl rollout status deploy/hello
kubectl exec deploy/hello -- env | grep -E 'KOLOR|TRYB'
```

Teraz w `configmap.yaml` zmień `KOLOR: zielony` na `KOLOR: niebieski`:

```bash
kubectl apply -f configmap.yaml
kubectl exec deploy/hello -- env | grep KOLOR      # wciąż zielony
```

Działający kontener nie przeładuje zmiennych: czyta je tylko przy starcie. Uruchom pody od nowa:

```bash
kubectl rollout restart deploy/hello
kubectl rollout status deploy/hello
kubectl exec deploy/hello -- env | grep KOLOR      # niebieski
```

## 6. Secret

Utwórz `secret.yaml`. W `stringData` wpisujesz wartość otwartym tekstem, a Kubernetes sam ją zakoduje:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: hello-secret
type: Opaque
stringData:
  DB_PASSWORD: changeme-lab07
```

```bash
kubectl apply -f secret.yaml
kubectl get secret hello-secret -o yaml       # pole data, wartość w base64
kubectl get secret hello-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d; echo
```

Zwróć uwagę na adnotację `kubectl.kubernetes.io/last-applied-configuration` w wyniku `-o yaml`: `apply` zapisał w niej cały plik, razem z hasłem otwartym tekstem.

**Wniosek:** Secret to **nie** szyfrowanie, tylko base64. Każdy, kto może czytać Secrety, odczyta hasło. Ochronę daje RBAC i szyfrowanie etcd po stronie klastra. Plik `secret.yaml` z prawdziwym hasłem nie powinien trafić do Gita. W projektach używa się zewnętrznego sejfu (Key Vault, Secrets Manager) i operatora, np. External Secrets.

Dodaj Secret do Deploymentu tak samo jak ConfigMap — druga pozycja w `envFrom`:

```yaml
          envFrom:
            - configMapRef:
                name: hello-config
            - secretRef:
                name: hello-secret
```

```bash
kubectl apply -f deployment.yaml
kubectl rollout status deploy/hello
kubectl exec deploy/hello -- env | grep -E 'KOLOR|TRYB|DB_PASSWORD'
```

**Sprawdź:** widać trzy zmienne: `KOLOR=niebieski`, `TRYB=szkolenie`, `DB_PASSWORD=changeme-lab07`.

## Dla chętnych

- **ConfigMap jako plik.** Utwórz `strona.yaml` z ConfigMap `strona`, w którym klucz `index.html` ma treść strony (użyj `|`, żeby wpisać kilka linii). Dopisz w tym samym pliku Deployment `strona` z obrazem `nginx:1.29`, który montuje tę ConfigMap jako wolumen w `/usr/share/nginx/html`. Sprawdź przez `kubectl port-forward deploy/strona 8088:80`. Wzór: [`rozwiazanie/dla-chetnych/strona.yaml`](rozwiazanie/dla-chetnych/strona.yaml).
- **Strategia.** Dodaj w `deployment.yaml` pod `spec:` blok `strategy.rollingUpdate` z `maxUnavailable: 0` i `maxSurge: 1`, zmień obraz i obserwuj kolejność podów.
- `kubectl rollout history deploy/hello --revision=2`
- `kubectl diff -f deployment.yaml` — zmień coś w pliku i zobacz, co `apply` by zmienił, zanim go uruchomisz.

## Sprzątanie

Nic nie usuwaj: Deployment `hello` (razem z ConfigMap i Secretem, z których korzysta) przyda się w lab08 i tam go posprzątamy.

> Gdybyś usunął ConfigMap albo Secret, a Deployment dalej się do nich odwołuje, nowe pody utkną w `CreateContainerConfigError`. Najpierw usuń `envFrom` z `deployment.yaml` i zrób `apply`.

Rozwiązanie (pliki po kroku 6): [`rozwiazanie/`](rozwiazanie/) — `deployment.yaml`, `configmap.yaml`, `secret.yaml`. Wszystko naraz: `kubectl apply -f rozwiazanie/`.
