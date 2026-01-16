#!/bin/bash

# Define variables
BUCKET_NAME="express-t2s-app-terraform-state-dev"
LOCK_TABLE="express-t2s-app-state-lock"
IAM_ROLE_NAME="express-t2s-app-execution-role"
ECR_REPO_NAME="express-t2s-app-repo"
ECS_CLUSTER_NAME="express-t2s-app-cluster"
ECS_SERVICE_NAME="express-t2s-app-service"
ECS_LOG_GROUP="/ecs/express-t2s-app"
ALB_NAME="express-t2s-app-alb"
TARGET_GROUP_NAME="express-t2s-app-tg"

echo "Starting FORCED cleanup of Terraform Backend and App dependencies..."

# 1. Empty and Delete Versioned S3 Bucket
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Force emptying S3 bucket: $BUCKET_NAME..."
    aws s3 rm "s3://$BUCKET_NAME" --recursive 2>/dev/null
    
    VERSIONS=$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --max-items 1000 --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)
    if [[ "$VERSIONS" != "null" && "$VERSIONS" != '{"Objects": null}' ]]; then
        aws s3api delete-objects --bucket "$BUCKET_NAME" --delete "$VERSIONS" >/dev/null
    fi
    
    MARKERS=$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --max-items 1000 --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json)
    if [[ "$MARKERS" != "null" && "$MARKERS" != '{"Objects": null}' ]]; then
        aws s3api delete-objects --bucket "$BUCKET_NAME" --delete "$MARKERS" >/dev/null
    fi
    aws s3 rb "s3://$BUCKET_NAME" --force && echo "S3 Bucket deleted."
fi

# 2. Delete DynamoDB Lock Table
if aws dynamodb describe-table --table-name "$LOCK_TABLE" 2>/dev/null; then
    echo "Deleting DynamoDB table: $LOCK_TABLE..."
    aws dynamodb delete-table --table-name "$LOCK_TABLE" >/dev/null
    aws dynamodb wait table-not-exists --table-name "$LOCK_TABLE" && echo "DynamoDB table deleted."
fi

# 3. ALB and Target Group Cleanup (Order matters to avoid 'ResourceInUse')
ALB_ARN=$(aws elbv2 describe-load-balancers --names "$ALB_NAME" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)
if [ -n "$ALB_ARN" ] && [ "$ALB_ARN" != "None" ]; then
    echo "Deleting Load Balancer: $ALB_NAME..."
    aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN"
    echo "Waiting for ALB to be fully deleted to release Target Group..."
    aws elbv2 wait load-balancers-deleted --load-balancer-arns "$ALB_ARN"
fi

TG_ARN=$(aws elbv2 describe-target-groups --names "$TARGET_GROUP_NAME" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)
if [ -n "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then
    echo "Deleting Target Group: $TARGET_GROUP_NAME..."
    # Loop to retry if listeners are still detaching
    for i in {1..5}; do
        aws elbv2 delete-target-group --target-group-arn "$TG_ARN" 2>/dev/null && break || echo "Target Group still in use, retrying in 10s..."
        sleep 10
    done
fi

# 4. CloudWatch Log Group (Fixed ResourceAlreadyExistsException)
# This addresses the error: creating CloudWatch Logs Log Group (/ecs/express-t2s-app)
echo "Checking for existing Log Group: $ECS_LOG_GROUP..."
if aws logs describe-log-groups --log-group-name-prefix "$ECS_LOG_GROUP" --query "logGroups[?logGroupName=='$ECS_LOG_GROUP']" --output text 2>/dev/null | grep -q "$ECS_LOG_GROUP"; then
    echo "Force deleting ECS Log Group: $ECS_LOG_GROUP..."
    aws logs delete-log-group --log-group-name "$ECS_LOG_GROUP"
    echo "Log Group deleted."
fi

# 5. IAM Execution Role
if aws iam get-role --role-name "$IAM_ROLE_NAME" 2>/dev/null; then
    echo "Cleaning up IAM Role: $IAM_ROLE_NAME..."
    POLICY_ARNS=$(aws iam list-attached-role-policies --role-name "$IAM_ROLE_NAME" --query 'AttachedPolicies[].PolicyArn' --output text)
    for POLICY in $POLICY_ARNS; do
        aws iam detach-role-policy --role-name "$IAM_ROLE_NAME" --policy-arn "$POLICY"
    done
    INLINE_POLICIES=$(aws iam list-role-policies --role-name "$IAM_ROLE_NAME" --query 'PolicyNames[]' --output text)
    for INLINE in $INLINE_POLICIES; do
        aws iam delete-role-policy --role-name "$IAM_ROLE_NAME" --policy-name "$INLINE"
    done
    aws iam delete-role --role-name "$IAM_ROLE_NAME"
fi

# 6. ECS & ECR Cleanup
echo "Cleaning up ECS and ECR..."
aws ecs update-service --cluster "$ECS_CLUSTER_NAME" --service "$ECS_SERVICE_NAME" --desired-count 0 2>/dev/null
aws ecs delete-service --cluster "$ECS_CLUSTER_NAME" --service "$ECS_SERVICE_NAME" --force 2>/dev/null
aws ecs delete-cluster --cluster "$ECS_CLUSTER_NAME" 2>/dev/null
aws ecr delete-repository --repository-name "$ECR_REPO_NAME" --force 2>/dev/null

echo "Forced cleanup of backend and dependencies complete."
