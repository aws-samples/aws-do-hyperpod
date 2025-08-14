# Data Preparation Instructions

## Overview
After step 2b in the SageMaker HyperPod EKS workshop and before running the training job, please extract the data in the FSx filesystem. This README guides you through the process of extracting and verifying the data in your shared volume.

## Prerequisites
- Necessary environment variables are set

## Steps

1. **Extract the Data**

```bash
cat <<EOF> tarring.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: preprocess-data
spec:
  template:
    spec:
      containers:
      - name: preprocess-data
        image: ${REGISTRY}${DOCKER_IMAGE_NAME}:${TAG}
        command: ["/bin/bash"]
        args: 
          - "-c"
          - "cd /fsx && tar -xzf esmdata.tar.gz"
        volumeMounts:
        - name: volume
          mountPath: /fsx
      volumes:
      - name: volume
        persistentVolumeClaim:
          claimName: fsx-claim
      restartPolicy: Never
EOF

kubectl apply -f ./tarring.yaml
```

   This creates a Kubernetes job that will extract the required data files.

2. **Monitor the Extraction Progress**
   ```bash
   watch kubectl get pods
   ```
   Wait until you see the pod status change to "Completed"

3. **View the Extracted Data (Optional)**
   To verify the data extraction, you can inspect the FSx filesystem:

```bash
cat <<EOF> view-fsx.yaml
apiVersion: v1
kind: Pod
metadata:
  name: fsx-share-test
spec:
  containers:
  - name: fsx-share-test
    image: ubuntu
    command: ["/bin/bash"]
    args: ["-c", "while true; do echo  \"hello from FSx\" - $(date -u) >> /fsx-shared/test.txt; sleep 120; done"]
    volumeMounts:
    - name: fsx-pv
      mountPath: /fsx
  volumes:
  - name: fsx-pv
    persistentVolumeClaim:
      claimName: fsx-claim
EOF

kubectl apply -f ./view-fsx.yaml
```

   This creates a pod to view the FSx contents

   # Get the pod name and access it

   ```bash
   watch kubectl get pods
   ```

   Wait until the pod fsx-share-test is in Running state, then exec into it

   ```bash
   kubectl exec -it fsx-share-test -- /bin/bash
   ```

   Check on your data inside the pod:

   ```bash
   cd /fsx/arrow
   ls -alh
   ```

    Expected output:
    
    ```log
    root@fsx-share-test:/fsx/arrow# ls -alh
    total 179K
    drwxr-xr-x 5 root root 33K Aug 14 06:05 .
    drwxr-xr-x 7 root root 33K Aug 14 14:32 ..
    -rw-r--r-- 1 root root  43 Aug 14 06:33 dataset_dict.json
    drwxr-xr-x 2 root root 33K Aug 13 02:46 test
    drwxr-xr-x 2 root root 41K Aug 13 02:46 train
    drwxr-xr-x 2 root root 33K Aug 13 02:46 validation
    ```



## Next Steps
Once the data extraction job shows as "Completed", and optionally you have confirmed the data is extracted into your fsx volume, you can proceed with running your training job.


## Cleanup
After confirming that the data is correctly extracted and your training job is ready to run:
1. Delete the data extraction job:
   ```bash
   kubectl delete job preprocess-data
   ```
2. If you created a view-fsx pod, delete it:
   ```bash
   kubectl delete pod fsx-share-test
   ```

