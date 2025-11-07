import boto3
import json

client = boto3.client('sagemaker-runtime')

response = client.invoke_endpoint(
    EndpointName='mistral-autoscale-endpoint',
    ContentType='application/json',
    Accept='application/json',
    Body=json.dumps({
        "inputs": "Hi, is water wet?",
        "parameters": {
            "max_new_tokens": 100,
            "temperature": 0.7
        }
    })
)

print(response['Body'].read().decode('utf-8'))