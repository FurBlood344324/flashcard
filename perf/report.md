# Performance Report

## Test Setup

- **Tool**: k6
- **Scenario**: 40s smoke test, ramping 1→5 VUs, steady 20s, ramp down
- **Base URL**: `http://192.168.49.2:30139` (Minikube flashcard-api)

## Results

| Endpoint | Method | p95 Latency | Threshold | Status |
|---|---|---|---|---|
| `/health` | GET | **6.33ms** | p95<200ms | Pass |
| `/api/decks` | POST (create) | **237.35ms** | p95<500ms | Pass |
| `/api/decks` | GET (list) | **13.01ms** | p95<300ms | Pass |
| `/api/decks/:id/flashcards` | POST (create) | **7.8ms** | p95<500ms | Pass |

## Summary

- **372 total requests** over 40s, 0 failures
- **100% checks passed** (298/298)
- **Avg response time**: 33.39ms
- **Median response time**: 6.69ms
- **Max response time**: 562.85ms
- **Overall p95**: 197.15ms

## Analysis

Tum threshold'lar basarili. Sistem 5 eszamanli kullanici altinda stabil, hic hata yok.

**create-deck** en agir endpoint. p95=237ms ile threshold'un (500ms) rahatca altinda ama max 562ms gorulmus. p90→p95 farki (197→237ms) bazi isteklerde DB disk I/O yaptigini gosteriyor. Minikube'un kisitli kaynaklarinda bu normal.

**health**, **list-decks**, **create-flashcard** cok hizli (p95 < 15ms). Salt okuma veya basit yazma islemleri oldugu icin beklendigi gibi.

## Run Command

```bash
# Minikube
./scripts/kubernetes-test-with-k6.sh

# Local dev server
k6 run -e BASE_URL=http://localhost:5000 perf/load-test.js
```

## Notes

- p95 latency values measured via k6 `http_req_duration` with tagged requests (`tags: { name: '...' }`).
- Thresholds configured in `perf/load-test.js` options block.
- Smoke test duzeyinde bottleneck yok. Daha yuksek VUs (50, 100) ile test edilirse DB baglanti havuzu davranisi daha net gorulecektir.
