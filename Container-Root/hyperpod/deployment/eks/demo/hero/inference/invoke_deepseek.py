import boto3
import json

client = boto3.client('sagemaker-runtime')

response = client.invoke_endpoint(
    EndpointName='deepseek15b-s3',
    ContentType='application/json',
    Accept='application/json',
    Body=json.dumps({
    	"inputs": "Hi, is water wet?"
    })
)

print(response['Body'].read().decode('utf-8'))