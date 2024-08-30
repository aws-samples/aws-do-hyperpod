#!/bin/bash

help(){
	echo ""
	echo "Usage: $0 [htop_pod_name]"
	echo "       executes the htop command in the specified htop pod"
	echo "       if no pod name is specified, then the first htop pod in the list is used"
	echo "       if a partial pod name is specified that matches more than one pod"
	echo "       then the first matching htop pod in the list is used"
	echo ""
	echo "       htop_pod_name - name or partial (unique substring) name of pod to run htop in"
	echo ""
}

if [ "$1" == "--help" ]; then
	help
else
	if [ "$1" == "" ]; then
		pod_name=$(kubectl get pods | grep do-htop | head -n 1 | cut -d ' ' -f 1)
	else
		pod_name=$(kubectl get pods | grep $1 | head -n 1 | cut -d ' ' -f 1)
	fi
	CMD="kubectl exec -it ${pod_name} -- htop"
	if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "${CMD}"
fi

