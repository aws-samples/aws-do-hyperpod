#!/bin/bash

help(){
	echo ""
	echo "Usage: $0 <node_name> <command>"
	echo "       node_name - required, partial or full name of node to inject reboot failure into"
	echo "                   if partial name matches more than one node, only the first node will be processed"
	echo "       command   - command to execute on node"
	echo ""
}

if [ "$2" == "" ]; then
	help
else

	node_name=$1

	node_name_full=$(kubectl get nodes | grep $node_name | head -n 1 | cut -d ' ' -f 1)

	shift

	command="$@"


cat <<EOF > job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: job
spec:
  template:
    spec:
      nodeSelector:
        kubernetes.io/hostname: "$node_name_full"
      containers:
      - command:
        - nsenter
        - --target
        - "1"
        - --mount
        - --uts
        - --ipc
        - --net
        - --pid
        - bash
        - -c
        - "${command}"
        image: docker.io/library/alpine
        imagePullPolicy: Always
        name: nsenter
        resources: {}
        securityContext:
          privileged: true
        stdin: true
        stdinOnce: true
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        tty: true
        volumeMounts:
        - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
          name: kube-api-access-frt9s
          readOnly: true
      dnsPolicy: ClusterFirst
      enableServiceLinks: true
      hostNetwork: true
      hostPID: true
      preemptionPolicy: PreemptLowerPriority
      priority: 0
      restartPolicy: Never
      schedulerName: default-scheduler
      securityContext: {}
      serviceAccount: default
      serviceAccountName: default
      terminationGracePeriodSeconds: 30
      tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      - effect: NoExecute
        operator: Exists
      volumes:
      - name: kube-api-access-frt9s
        projected:
          defaultMode: 420
          sources:
          - serviceAccountToken:
              expirationSeconds: 3607
              path: token
          - configMap:
              items:
              - key: ca.crt
                path: ca.crt
              name: kube-root-ca.crt
          - downwardAPI:
              items:
              - fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.namespace
                path: namespace
EOF

	kubectl apply -f ./job.yaml


	STATUS=$(kubectl get pods | grep job | head -n 1 | awk '{print $3}')
	while [ ! "$STATUS" == "Completed" ]; do
		sleep 1
		STATUS=$(kubectl get pods | grep job | head -n 1 | awk '{print $3}')
	done

	kubectl logs $(kubectl get pods | grep job | head -n 1 | cut -d ' ' -f 1) 

	kubectl delete -f ./job.yaml

	rm -f ./job.yaml

fi

