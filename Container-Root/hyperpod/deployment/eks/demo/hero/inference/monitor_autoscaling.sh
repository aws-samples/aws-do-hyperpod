#!/bin/bash

# Simple, clean autoscaling monitor
DEPLOYMENT_NAME="mistral-jumpstart-autoscale"
NAMESPACE="hyperpod-ns-inference-team"

echo "🎯 Monitoring $DEPLOYMENT_NAME autoscaling (Press Ctrl+C to stop)"
echo "Time     | Pods | Status"
echo "---------|------|--------------------------------------------------"

while true; do
    # Get current time
    TIME=$(date '+%H:%M:%S')
    
    # Get pod count and status
    POD_INFO=$(kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE -o custom-columns=READY:.status.readyReplicas,DESIRED:.spec.replicas --no-headers 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        READY=$(echo $POD_INFO | cut -d' ' -f1)
        DESIRED=$(echo $POD_INFO | cut -d' ' -f2)
        
        # Handle null values
        [ "$READY" = "<none>" ] && READY="0"
        [ "$DESIRED" = "<none>" ] && DESIRED="0"
        
        # Get scaling events
        RECENT_EVENT=$(kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' --no-headers 2>/dev/null | \
                      grep -E "(Scaled|ScalingReplicaSet)" | tail -1 | \
                      awk '{for(i=6;i<=NF;i++) printf "%s ", $i; print ""}' | \
                      cut -c1-40)
        
        # Color coding based on scaling activity
        if [ "$READY" -gt 1 ]; then
            STATUS="🟢 Scaled up: $READY/$DESIRED ready"
        elif [ "$READY" != "$DESIRED" ]; then
            STATUS="🟡 Scaling: $READY/$DESIRED ready"
        else
            STATUS="🔵 Stable: $READY/$DESIRED ready"
        fi
        
        printf "%-8s | %-4s | %s\n" "$TIME" "$READY" "$STATUS"
        
        # Show recent event if significant
        if [[ "$RECENT_EVENT" == *"Scaled"* ]]; then
            printf "         |      | 📈 %s\n" "$RECENT_EVENT"
        fi
    else
        printf "%-8s | %-4s | 🔴 Deployment not found\n" "$TIME" "?"
    fi
    
    sleep 5
done