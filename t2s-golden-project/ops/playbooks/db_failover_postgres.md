# Database Failover (PostgreSQL)

This playbook outlines safe steps to fail over PostgreSQL in a controlled manner.

## When to Run
- Primary DB failure
- Planned maintenance requiring primary rotation

## Preconditions
- Replication enabled and healthy
- Backups exist and recent restore test passed
- Application retry/backoff enabled

## Failover Steps (High-Level)
1. Freeze writes if possible (maintenance mode)
2. Identify best replica (lowest lag)
3. Promote replica to primary (managed failover or tool)
4. Update app connectivity (DNS/endpoint switch)
5. Validate correctness (smoke tests, writes, reads)

## Post-Failover
- Re-enable writes
- Monitor SLOs, error rate, latency
- Update runbooks with lessons learned
