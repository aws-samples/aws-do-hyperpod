#!/bin/bash

export CLUSTER=$(kubectl config current-context | cut -d '/' -f 2)
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

echo ""
echo "Associating OIDC provider ..."
eksctl utils associate-iam-oidc-provider --cluster $CLUSTER --approve

echo ""
echo "Creating policy ..."
aws iam create-policy \
     --policy-name cert-manager-acme-dns01-route53 \
     --description "This policy allows cert-manager to manage ACME DNS01 records in Route53 hosted zones. See https://cert-manager.io/docs/configuration/acme/dns01/route53" \
     --policy-document file:///dev/stdin <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "route53:GetChange",
      "Resource": "arn:aws:route53:::change/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/*"
    },
    {
      "Effect": "Allow",
      "Action": "route53:ListHostedZonesByName",
      "Resource": "*"
    }
  ]
}
EOF

echo ""
echo "Creating role and IAM service account ..."
eksctl create iamserviceaccount \
  --name cert-manager-acme-dns01-route53 \
  --namespace cert-manager \
  --cluster ${CLUSTER} \
  --role-name cert-manager-acme-dns01-route53-${CLUSTER} \
  --attach-policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/cert-manager-acme-dns01-route53 \
  --approve

echo ""
echo "Setting permissions for cert-manager ..."
kubectl apply -f ./rbac.yaml

