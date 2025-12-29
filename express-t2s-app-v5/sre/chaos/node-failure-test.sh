#!/bin/bash
# Chaos Test: Simulate node failure in EKS

NODE=$(kubectl get nodes -o name | shuf -n 1)

echo "⚠ Simulating node failure for: $NODE"

kubectl drain $NODE --ignore-daemonsets --delete-emptydir-data
sleep 10

echo "Node drained. Pods should reschedule automatically."
