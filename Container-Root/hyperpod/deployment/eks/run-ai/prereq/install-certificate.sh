#!/bin/bash

export DNS_NAME=${DNS_NAME}
export CERTIFICATE_NAME=$(echo ${DNS_NAME} | sed -e 's/\./-/g')
export RUNAI_BACKEND=${RUNAI_BACKEND}

export CERT_DIR=/aws-do-hyperpod/wd/cert/${CERTIFICATE_NAME}
export CERT=${CERT_DIR}/${CERTIFICATE_NAME}.crt
export KEY=${CERT_DIR}/${CERTIFICATE_NAME}.key
export CHAIN=${CERT_DIR}/${CERTIFICATE_NAME}-chain.crt

if [ -f ${CERT} ]; then

	echo ""
	echo "Installing certificate ${CERTIFICATE_NAME}"
	echo "from path ${CERT_DIR}"

	echo ""
	echo "Installing on ingress ..."
	kubectl create namespace ingress-nginx
	kubectl delete secret nginx-tls -n ingress-nginx
	kubectl create secret tls nginx-tls -n ingress-nginx --cert=$CERT --key=$KEY
	kubectl delete secret nginx-ca-cert -n ingress-nginx
	kubectl create secret generic nginx-ca-cert -n ingress-nginx --from-file=runai-ca.pem=$CHAIN

	echo ""
	echo "Installing on data plane ..."
	kubectl create namespace runai
	kubectl delete secret runai-ca-cert -n runai
	kubectl -n runai create secret generic runai-ca-cert --from-file=runai-ca.pem=$CHAIN
	kubectl label secret runai-ca-cert -n runai run.ai/cluster-wide=true run.ai/name=runai-ca-cert --overwrite

	if [ "$RUNAI_BACKEND" == "True" ]; then
		echo ""
		echo "Installing on control plane ..."
		kubectl create namespace runai-backend
		kubectl -n runai-backend delete secret runai-backend-tls
		kubectl create secret tls runai-backend-tls -n runai-backend --cert=$CERT --key=$KEY
		kubectl -n runai-backend delete secret runai-ca-cert
		kubectl -n runai-backend create secret generic runai-ca-cert --from-file=runai-ca.pem=$CHAIN
	fi
else
	echo ""
	echo "Certificate file $CERT not found"
fi
	
echo ""

