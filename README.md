# Flashcard API

Bu proje, Test Mühendisliği dönem projesi için seçilen basit bir `Flashcard` mini servis başlangıcıdır. Flask ile monolitik ama katmanlı bir yapı kullanır: controller, service ve repository.

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

API varsayılan olarak `http://127.0.0.1:5000` adresinde çalışır.

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

- `GET /health`
- `POST /api/decks`
- `GET /api/decks`
- `GET /api/decks/<deck_id>`
- `POST /api/decks/<deck_id>/flashcards`
- `PATCH /api/flashcards/<flashcard_id>/review`
- `DELETE /api/flashcards/<flashcard_id>`
