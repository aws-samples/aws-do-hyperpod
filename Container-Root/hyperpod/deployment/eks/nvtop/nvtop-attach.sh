#!/bin/bash

help(){
	echo ""
	echo "Usage: $0 [nvtop_pod_name]"
	echo "       executes the nvtop command in the specified nvtop pod"
	echo "       if no pod name is specified, then the first nvtop pod in the list is used"
	echo "       if a partial pod name is specified that matches more than one pod"
	echo "       then the first matching nvtop pod in the list is used"
	echo ""
	echo "       nvtop_pod_name - name or partial (unique substring) name of pod to run nvtop in"
	echo ""
}

if [ "$1" == "--help" ]; then
	help
else
	if [ "$1" == "" ]; then
		pod_name=$(kubectl get pods | grep do-nvtop | head -n 1 | cut -d ' ' -f 1)
	else
		pod_name=$(kubectl get pods | grep $1 | head -n 1 | cut -d ' ' -f 1)
	fi
	CMD="kubectl exec -it ${pod_name} -- nvtop"
	if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "${CMD}"
fi

