# Queue Drain (Kafka)

Safely drains Kafka consumers before maintenance, deployments, or mitigation.

## When to Run
- Deployment impacting consumers
- Broker maintenance
- Incident requiring pause of downstream processing

## Steps
1. Reduce incoming load if possible (rate limit or pause producers)
2. Scale consumers down (or to zero) in Kubernetes
3. Monitor consumer group lag until target reached

## Example
```bash
kubectl -n <ns> scale deploy/<consumer-deploy> --replicas=0
# Validate lag in dashboards
```

## Resume
- Scale consumers up gradually
- Watch lag and error rates
