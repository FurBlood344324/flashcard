# Performance Report

## Test Setup

- **Tool**: k6
- **Scenario**: 40s smoke test, ramping 1→5 VUs, steady 20s, ramp down
- **Base URL**: `http://localhost:5000`

## Results

| Endpoint | Method | p95 Latency | Threshold | Status |
|---|---|---|---|---|
| `/health` | GET | **1.69ms** | p95<200ms | Pass |
| `/api/decks` | POST (create) | **20.04ms** | p95<500ms | Pass |
| `/api/decks` | GET (list) | **12.85ms** | p95<300ms | Pass |
| `/api/decks/:id/flashcards` | POST (create) | **12.47ms** | p95<500ms | Pass |

## Summary

- **390 total requests** over 40s, 0 failures
- **100% checks passed** (312/312)
- **Avg response time**: 7.42ms
- **Max response time**: 53.98ms

## Run Command

```bash
# Local dev server
k6 run perf/load-test.js

# Custom base URL
k6 run -e BASE_URL=http://localhost:5000 perf/load-test.js
```

## Notes

- p95 latency values measured via k6 `http_req_duration` with tagged requests.
- Thresholds configured in the script options block.
