#!/bin/bash

# 1. Create an IAM OIDC identity provider for your cluster with the following command:
eksctl utils associate-iam-oidc-provider --cluster $EKS_CLUSTER_NAME --approve

# 2. Create an IAM policy 
cat <<EOF> mlflowpolicy.json
{
    "Version": "2012-10-17",    
    "Statement": [        
        {            
            "Effect": "Allow",            
            "Action": [
                "sagemaker-mlflow:*",
                "sagemaker:CreateMlflowTrackingServer",
                "sagemaker:UpdateMlflowTrackingServer",
                "sagemaker:DeleteMlflowTrackingServer",
                "sagemaker:StartMlflowTrackingServer",
                "sagemaker:StopMlflowTrackingServer",
                "sagemaker:CreatePresignedMlflowTrackingServerUrl",
                "sagemaker:AddTags",
                "sagemaker:CreateModelPackageGroup",
                "sagemaker:CreateModelPackage",
                "sagemaker:DescribeModelPackageGroup",
                "sagemaker:UpdateModelPackage",
                "sagemaker:ListModelPackageGroups",
                "sagemaker:ListModelPackages",
                "sagemaker:DeleteModelPackageGroup",
                "sagemaker:DeleteModelPackage",
                "cloudwatch:PutMetricData",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:CreateLogGroup",
                "s3:Get*",
                "s3:Put*",
                "s3:List*"
            ],            
            "Resource": "*"        
        }        
    ]
}
EOF

aws iam create-policy \
    --policy-name SageMakerMlFlowAccessPolicy \
    --policy-document file://mlflowpolicy.json



# 3. Create an IAM role

# To Access MLFlow tracking server we need to create an IAM service account with a role that uses the above created policy. This section shows how to create an IAM role to delegate these permissions. To create this role we will use eksctl. 

MLFLOW_ROLE_NAME=SM_MLFLOW_ACCESS_ROLE_DEMO
MLFLOW_POLICY_ARN=$(aws iam list-policies --query 'Policies[?PolicyName==`SageMakerMlFlowAccessPolicy`]' | jq '.[0].Arn' |  tr -d '"')

eksctl create iamserviceaccount \
    --name sagemaker-mlflow-sa \
    --namespace hyperpod-ns-training-team \
    --cluster $EKS_CLUSTER_NAME \
    --attach-policy-arn $MLFLOW_POLICY_ARN \
    --approve \
    --role-name $MLFLOW_ROLE_NAME \
    --region $AWS_REGION \
    --override-existing-serviceaccounts

# Now please include a trust policy for the SageMaker service to the trust relationship for that role:
aws iam update-assume-role-policy --role-name $MLFLOW_ROLE_NAME --policy-document "$(aws iam get-role --role-name $MLFLOW_ROLE_NAME --query 'Role.AssumeRolePolicyDocument' --output json | jq '.Statement += [{"Effect": "Allow", "Principal": {"Service": "sagemaker.amazonaws.com"}, "Action": "sts:AssumeRole"}]')"

