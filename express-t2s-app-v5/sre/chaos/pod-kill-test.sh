#!/bin/bash
# Chaos Test: Kill a random pod

POD=$(kubectl get pods -n default -o name | shuf -n 1)

echo "Killing pod: $POD"

kubectl delete $POD --force --grace-period=0