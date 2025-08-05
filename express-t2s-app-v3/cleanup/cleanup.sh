#!/bin/bash
echo "Cleaning up ECS services..."
aws ecs delete-service --cluster t2s-ecs-cluster --service t2s-ecs-service --force
aws ecs delete-cluster --cluster t2s-ecs-cluster

echo "Cleaning up EKS cluster..."
aws eks delete-cluster --name t2s-eks-cluster

echo "Done."

