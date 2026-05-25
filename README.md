# Flashcard

Flask ile monolitik ama katmanlı bir Flashcard uygulaması. Backend katmanlı mimari (controller → service → repository) kullanır; frontend ise aynı Flask uygulaması içinde Jinja2 şablonları ve Tailwind CSS (CDN) ile sunulur.

## Gereksinimler

- uv
- Docker ve Docker Compose
- PostgreSQL için varsayılan bağlantı: `postgresql+psycopg://flashcard:flashcard@localhost:5432/flashcard`

## Kurulum

```bash
uv python install 3.11
uv sync --group dev --python 3.11
cp .env.example .env
```

Bu projede `pyenv` kullanılmaz. Python sürümünü, `.venv` ortamını, dependency kurulumunu ve komut çalıştırmayı `uv` yönetir.

PostgreSQL'i başlat:

```bash
docker compose up -d postgres
```

Tabloları oluştur:

```bash
uv run flask --app app init-db
```

Uygulamayı çalıştır:

```bash
uv run flask --app app run --debug
```

Uygulama varsayılan olarak `http://127.0.0.1:5000` adresinde çalışır. Tarayıcıdan bu adrese giderek arayüzü kullanabilirsin.

## Testler

Tüm testleri çalıştır:

```bash
uv run pytest
```

Sadece unit test:

```bash
uv run pytest tests/unit
```

Sadece integration test:

```bash
uv run pytest tests/integration
```

Docker ile gerçek PostgreSQL Testcontainers testi de çalışsın istersen:

```bash
RUN_TESTCONTAINERS=true uv run pytest tests/integration
```

Sadece e2e test:

```bash
uv run pytest tests/e2e
```

Lint kontrolü:

```bash
uv run ruff check .
```

## Postman

Postman içinde şu iki dosyayı import edebilirsin:

- `postman/flashcard-api.postman_collection.json`
- `postman/flashcard-local.postman_environment.json`

Collection içindeki istekler sırasıyla çalıştırıldığında `deck_id` ve `flashcard_id` environment değişkenleri otomatik set edilir.

## Kubernetes / Minikube

Bu manifestler Flask API'yi ve yerel geliştirme için PostgreSQL'i Minikube ortamına deploy eder. API başlangıçta veritabanı tablolarını `flask --app app init-db` komutu ile oluşturur.

Minikube başlat:

```bash
minikube start
```

Docker image'ını Minikube Docker ortamında build et:

```bash
eval $(minikube docker-env)
docker build -t flashcard-api:dev .
```

Kubernetes kaynaklarını uygula:

```bash
kubectl apply -f k8s/postgres-secret.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/postgres-pvc.yaml
kubectl apply -f k8s/postgres-service.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Pod ve Service durumunu kontrol et:

```bash
kubectl get pods
kubectl get service postgres
kubectl get service flashcard-api
```

Deployment'ların hazır olmasını bekle:

```bash
kubectl rollout status deployment/postgres
kubectl rollout status deployment/flashcard-api
```

API URL'ini al ve health check çalıştır:

```bash
API_URL=$(minikube service flashcard-api --url)
curl "$API_URL/health"
```

Veritabanı kullanan endpointleri dene:

```bash
curl "$API_URL/api/decks"
```

## Endpointler

### Sayfa (HTML)

| Yol | Açıklama |
|-----|----------|
| `GET /` | Deste listesi |
| `GET /decks/<deck_id>` | Deste detayı ve çalışma modu |

### API (JSON)

| Yol | Açıklama |
|-----|----------|
| `GET /health` | Sağlık kontrolü |
| `POST /api/decks` | Yeni deste oluştur |
| `GET /api/decks` | Tüm desteleri listele |
| `GET /api/decks/<deck_id>` | Deste detayı (kartlarla birlikte) |
| `POST /api/decks/<deck_id>/flashcards` | Desteye kart ekle |
| `PATCH /api/flashcards/<flashcard_id>/review` | Kartı değerlendir |
| `DELETE /api/flashcards/<flashcard_id>` | Kartı sil |

## Frontend

Arayüz Flask uygulamasının içinde Jinja2 şablonları ile sunulur. Ayrı bir build adımı veya ek bağımlılık gerektirmez; Tailwind CSS, CDN üzerinden yüklenir.

### Şablonlar

```
src/templates/
├── base.html          # Ortak layout, navbar, Tailwind CDN, font
├── index.html         # Deste listesi + oluşturma modalı
└── deck_detail.html   # Kart listesi, çalışma modu, kart ekleme/silme
```

### Özellikler

- **Koyu tema** — zinc-950 tabanlı, göz yormayan tasarım
- **Kart çevirme animasyonu** — CSS 3D transform ile çalışma deneyimi
- **Zorluk derecelendirme** — Tekrar / Zor / İyi / Kolay
- **Responsive** — mobil ve masaüstü uyumlu
- **Playwright uyumlu** — tüm interaktif elementlerde `data-testid`

### Playwright Test Selectors

Tüm interaktif elementlerde `data-testid` attribute'u bulunur. Başlıca selector'lar:

```
# Deste listesi
[data-testid="page-title"]
[data-testid="btn-open-create-deck"]
[data-testid="deck-grid"]
[data-testid="deck-card-{id}"]
[data-testid="form-create-deck"]
[data-testid="input-deck-name"]
[data-testid="btn-submit-deck"]
[data-testid="empty-state"]

# Deste detayı
[data-testid="deck-title"]
[data-testid="btn-study"]
[data-testid="btn-open-add-card"]
[data-testid="card-row-{id}"]
[data-testid="btn-delete-card-{id}"]
[data-testid="form-add-card"]

# Çalışma modu
[data-testid="study-view"]
[data-testid="study-card"]
[data-testid="btn-diff-again"]
[data-testid="btn-diff-easy"]
[data-testid="study-complete"]
```

## Proje Yapısı

```
src/
├── app.py                          # Flask uygulama fabrikası
├── config.py                       # Konfigürasyon
├── extensions.py                   # SQLAlchemy instance
├── models.py                       # Deck ve Flashcard modelleri
├── controllers/
│   ├── deck_controller.py          # /api/* JSON endpointleri
│   └── view_controller.py          # / ve /decks/<id> sayfa endpointleri
├── services/
│   ├── deck_service.py             # İş mantığı
│   └── errors.py                   # Servis hataları
├── repositories/
│   ├── deck_repository.py          # Deck veritabanı işlemleri
│   └── flashcard_repository.py     # Flashcard veritabanı işlemleri
└── templates/
    ├── base.html                   # Ortak layout
    ├── index.html                  # Deste listesi
    └── deck_detail.html            # Deste detay ve çalışma modu
```
