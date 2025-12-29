#!/bin/bash
# Chaos Test: Block outbound traffic from pods to simulate dependency failure

APP=$1

POD=$(kubectl get pods -l app=$APP -o jsonpath='{.items[0].metadata.name}')

kubectl exec -it $POD -- iptables -A OUTPUT -p tcp -j DROP

echo "Outbound traffic blocked for pod: $POD"