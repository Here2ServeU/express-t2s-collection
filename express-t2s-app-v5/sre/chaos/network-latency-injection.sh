#!/bin/bash
# Chaos Test: Inject network latency on target deployment

TARGET_APP=$1

kubectl exec -it \
$(kubectl get pods -l app=$TARGET_APP -o jsonpath='{.items[0].metadata.name}') \
-- tc qdisc add dev eth0 root netem delay 300ms

echo "Injected 300ms latency to $TARGET_APP"