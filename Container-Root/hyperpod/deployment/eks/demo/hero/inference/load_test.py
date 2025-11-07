#!/usr/bin/env python3
"""
Load testing script for HyperPod inference endpoint autoscaling.
This script sends concurrent requests to trigger CloudWatch metrics and autoscaling.
"""

import boto3
import json
import time
import threading
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime

class LoadTester:
    def __init__(self, endpoint_name, region='us-east-1', max_workers=10):
        self.endpoint_name = endpoint_name
        self.client = boto3.client('sagemaker-runtime', region_name=region)
        self.max_workers = max_workers
        self.request_count = 0
        self.success_count = 0
        self.error_count = 0
        self.lock = threading.Lock()
        
    def send_request(self, request_id):
        """Send a single inference request"""
        try:
            payload = {
                "inputs": f"Request {request_id}: What is the capital of France?",
                "parameters": {
                    "max_new_tokens": 50,
                    "temperature": 0.7
                }
            }
            
            start_time = time.time()
            response = self.client.invoke_endpoint(
                EndpointName=self.endpoint_name,
                ContentType='application/json',
                Accept='application/json',
                Body=json.dumps(payload)
            )
            
            response_body = response['Body'].read().decode('utf-8')
            end_time = time.time()
            
            with self.lock:
                self.success_count += 1
                
            print(f"✅ Request {request_id} completed in {end_time - start_time:.2f}s")
            return True
            
        except Exception as e:
            with self.lock:
                self.error_count += 1
            print(f"❌ Request {request_id} failed: {str(e)}")
            return False
    
    def run_load_test(self, total_requests, requests_per_second=2, duration_minutes=5):
        """Run load test with specified parameters"""
        print(f"🚀 Starting load test:")
        print(f"   Endpoint: {self.endpoint_name}")
        print(f"   Total requests: {total_requests}")
        print(f"   Requests per second: {requests_per_second}")
        print(f"   Duration: {duration_minutes} minutes")
        print(f"   Max workers: {self.max_workers}")
        print("-" * 50)
        
        start_time = time.time()
        end_time = start_time + (duration_minutes * 60)
        
        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            request_id = 0
            
            while time.time() < end_time and request_id < total_requests:
                # Submit batch of requests
                batch_size = min(requests_per_second, total_requests - request_id)
                futures = []
                
                for _ in range(batch_size):
                    request_id += 1
                    future = executor.submit(self.send_request, request_id)
                    futures.append(future)
                
                # Wait for batch to complete or timeout
                batch_start = time.time()
                for future in as_completed(futures, timeout=30):
                    try:
                        future.result()
                    except Exception as e:
                        print(f"❌ Future failed: {e}")
                
                # Control request rate
                elapsed = time.time() - batch_start
                sleep_time = max(0, 1.0 - elapsed)  # Aim for 1 request per second
                if sleep_time > 0:
                    time.sleep(sleep_time)
                
                # Print progress
                if request_id % 10 == 0:
                    elapsed_minutes = (time.time() - start_time) / 60
                    print(f"📊 Progress: {request_id} requests sent, {elapsed_minutes:.1f} minutes elapsed")
        
        total_time = time.time() - start_time
        print("-" * 50)
        print(f"🏁 Load test completed!")
        print(f"   Total time: {total_time:.2f} seconds")
        print(f"   Requests sent: {request_id}")
        print(f"   Successful: {self.success_count}")
        print(f"   Failed: {self.error_count}")
        print(f"   Success rate: {(self.success_count/request_id)*100:.1f}%")
        print(f"   Average RPS: {request_id/total_time:.2f}")

def main():
    parser = argparse.ArgumentParser(description='Load test HyperPod inference endpoint')
    parser.add_argument('--endpoint', required=True, help='SageMaker endpoint name')
    parser.add_argument('--requests', type=int, default=100, help='Total number of requests')
    parser.add_argument('--rps', type=int, default=2, help='Requests per second')
    parser.add_argument('--duration', type=int, default=5, help='Duration in minutes')
    parser.add_argument('--workers', type=int, default=10, help='Max concurrent workers')
    parser.add_argument('--region', default='us-east-1', help='AWS region')
    
    args = parser.parse_args()
    
    tester = LoadTester(
        endpoint_name=args.endpoint,
        region=args.region,
        max_workers=args.workers
    )
    
    tester.run_load_test(
        total_requests=args.requests,
        requests_per_second=args.rps,
        duration_minutes=args.duration
    )

if __name__ == "__main__":
    main()