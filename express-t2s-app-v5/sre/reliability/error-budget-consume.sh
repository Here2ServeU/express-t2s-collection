#!/bin/bash
# Simulate error budget consumption

TARGET_SERVICE=$1
ERROR_RATE=$2

echo "Injecting error rate: $ERROR_RATE% to $TARGET_SERVICE"

kubectl exec -it \
$(kubectl get pods -l app=$TARGET_SERVICE -o jsonpath='{.items[0].metadata.name}') \
-- sh -c "while true; do curl -s http://localhost/error?level=$ERROR_RATE; done"