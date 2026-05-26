import http from 'k6/http';
import { check, sleep, group } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:5000';

export const options = {
  thresholds: {
    'http_req_duration{name:health}': ['p(95)<200'],
    'http_req_duration{name:create-deck}': ['p(95)<500'],
    'http_req_duration{name:list-decks}': ['p(95)<300'],
    'http_req_duration{name:create-flashcard}': ['p(95)<500'],
  },
  scenarios: {
    smoke: {
      executor: 'ramping-vus',
      startVUs: 1,
      stages: [
        { duration: '10s', target: 5 },
        { duration: '20s', target: 5 },
        { duration: '10s', target: 0 },
      ],
    },
  },
};

const PARAMS = { headers: { 'Content-Type': 'application/json' } };

export default function () {
  group('health check', () => {
    const res = http.get(`${BASE_URL}/health`, { tags: { name: 'health' } });
    check(res, { 'status 200': (r) => r.status === 200 });
    sleep(0.5);
  });

  group('create deck', () => {
    const payload = JSON.stringify({ name: `k6-deck-${__VU}-${__ITER}` });
    const res = http.post(`${BASE_URL}/api/decks`, payload, { ...PARAMS, tags: { name: 'create-deck' } });
    check(res, { 'status 201': (r) => r.status === 201 });
    sleep(0.5);
  });

  group('list decks', () => {
    const res = http.get(`${BASE_URL}/api/decks`, { tags: { name: 'list-decks' } });
    check(res, { 'status 200': (r) => r.status === 200 });
    sleep(0.5);
  });

  group('create flashcard', () => {
    const deckRes = http.post(
      `${BASE_URL}/api/decks`,
      JSON.stringify({ name: `k6-flashcard-deck-${__VU}-${__ITER}` }),
      PARAMS,
    );
    if (deckRes.status === 201) {
      const deckId = deckRes.json().data.id;
      const payload = JSON.stringify({ front: 'What is k6?', back: 'A load testing tool' });
      const res = http.post(`${BASE_URL}/api/decks/${deckId}/flashcards`, payload, {
        ...PARAMS,
        tags: { name: 'create-flashcard' },
      });
      check(res, { 'status 201': (r) => r.status === 201 });
    }
    sleep(0.5);
  });
}
