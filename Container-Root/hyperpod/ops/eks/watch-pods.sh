#!/bin/bash

if [ "$2" == "" ]; then
	if [ "$1" == "" ]; then
		watch "kubectl get pods -o wide"
	else
		if [ "$1" == "-A" ]; then
			watch "kubectl get pods -o wide -A"
		else
			watch "kubectl get pods -o wide | grep $1"
		fi
	fi
else	
	watch kubectl get pods -o wide "$@"
fi

