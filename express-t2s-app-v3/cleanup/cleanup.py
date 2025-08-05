import boto3

ecs = boto3.client('ecs')
eks = boto3.client('eks')

def cleanup_ecs():
    print("Cleaning up ECS...")
    ecs.delete_service(cluster='t2s-ecs-cluster', service='t2s-ecs-service', force=True)
    ecs.delete_cluster(cluster='t2s-ecs-cluster')
    print("ECS cleanup complete.")

def cleanup_eks():
    print("Cleaning up EKS...")
    eks.delete_cluster(name='t2s-eks-cluster')
    print("EKS cleanup complete.")

cleanup_ecs()
cleanup_eks()
