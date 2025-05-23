#!/bin/bash

# Export certificate

usage(){
	echo ""
	echo "Usage: $0 <certificate_name>"
	echo ""
	echo "certificate_name   - name of certificate to export"
	echo ""
}

if [ "$1" == "" ]; then
	usage
else
	export CERTIFICATE_NAME=$1
	CMD="kubectl get certificate ${CERTIFICATE_NAME} | grep -v NAME | awk '{print \$3}'"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
	export SECRET_NAME=$(eval "$CMD")

	CMD="kubectl get secret ${SECRET_NAME} -o json -o=jsonpath='{.data.tls\.crt}' | base64 -d | tee ${CERTIFICATE_NAME}-chain.crt"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
        eval "$CMD"

	CMD="kubectl get secret ${SECRET_NAME} -o json -o=jsonpath='{.data.tls\.key}' | base64 -d | tee ${CERTIFICATE_NAME}.key"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
        eval "$CMD"

	CMD="cat ${CERTIFICATE_NAME}-chain.crt | sed '/BEGIN/,/END/!d;/END/q' | tee ${CERTIFICATE_NAME}.crt"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
        eval "$CMD"
fi

echo ""

