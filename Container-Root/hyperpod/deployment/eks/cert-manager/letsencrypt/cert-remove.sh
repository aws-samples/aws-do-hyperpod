#!/bin/bash

# Revoke and remove certificate

usage(){
	echo ""
	echo "Usage: $0 <certificate_name>"
	echo ""
	echo "certificate_name   - name of certificate to revoke and remove"
	echo ""
}

if [ "$1" == "" ]; then
	usage
else
	export CERTIFICATE_NAME=$1
	CMD="kubectl get certificate ${CERTIFICATE_NAME} | grep -v NAME | awk '{print \$3}'"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
	export SECRET_NAME=$(eval "$CMD")

	CMD="cmctl inspect secret ${SECRET_NAME}"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
        eval "$CMD"

	CMD="kubectl get secret ${SECRET_NAME} -o json -o=jsonpath='{.data.tls\.crt}' | base64 -d | tee ${CERTIFICATE_NAME}.crt"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
        eval "$CMD"

	CMD="kubectl get secret ${SECRET_NAME} -o json -o=jsonpath='{.data.tls\.key}' | base64 -d | tee ${CERTIFICATE_NAME}.key"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
        eval "$CMD"

	CMD="certbot revoke -n --cert-path ${CERTIFICATE_NAME}.crt --key-path ${CERTIFICATE_NAME}.key --reason cessationOfOperation"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
        eval "$CMD"

	CMD="kubectl delete certificate ${CERTIFICATE_NAME}"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
        eval "$CMD"

	CMD="kubectl delete secret ${SECRET_NAME}"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
        eval "$CMD"

	mv -vf ${CERTIFICATE_NAME}.crt /tmp
	mv -vf ${CERTIFICATE_NAME}.key /tmp

fi

echo ""

