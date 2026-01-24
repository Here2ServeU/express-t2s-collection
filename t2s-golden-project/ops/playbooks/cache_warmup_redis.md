# Cache Warmup (Redis)

This playbook warms critical Redis keys to reduce cold-start latency after deployments or failovers.

## When to Run
- After a deployment that impacts read-heavy endpoints
- After Redis restart/failover
- When p95 latency spikes due to cold cache

## Preconditions
- Redis is healthy (PING OK; replication OK if applicable)
- Application is healthy (/health is green)
- Warmup will not overload upstream databases

## Warmup Strategy
1. Identify critical keys/endpoints (top read paths)
2. Warm via application endpoints (preferred)
3. Warm via scripts (optional) with rate limiting

## Example (curl loop)
```bash
export BASE_URL="http://your-service.default.svc.cluster.local"
for path in / /health /api/products /api/pricing; do
  curl -sS "${BASE_URL}${path}" >/dev/null
  sleep 0.2
done
```

## Validation
- p95 latency improves
- cache hit rate increases
- DB QPS decreases

## Stop Conditions
- DB CPU/QPS spikes unexpectedly
- Redis memory pressure/evictions spike
