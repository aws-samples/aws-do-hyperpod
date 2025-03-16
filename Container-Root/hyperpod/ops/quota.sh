#!/bin/bash

CMD="aws service-quotas list-service-quotas --service-code sagemaker --query 'Quotas[].{Code:QuotaCode,Level:QuotaAppliedAtLevel,Resource:UsageMetric.MetricDimensions.Resource,Name:QuotaName,Value:Value}' --output text"

if [ ! "$1" == "" ]; then
	CMD="$CMD | grep $1"
fi

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

