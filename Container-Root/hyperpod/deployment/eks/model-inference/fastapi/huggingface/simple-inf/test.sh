#!/bin/bash

source .env

export MODE=-it

echo "Testing ${IMAGE} ..."

if [ "$TO" == "docker" ]; then
	# Check running status
	instances=$(docker ps | grep $IMAGE | wc -l | xargs)
	if [ "$instances" == "0" ]; then
		docker container run ${RUN_OPTS} ${CONTAINER_NAME}-test ${MODE} --rm ${NETWORK} ${PORT_MAP} ${VOL_MAP} ${REGISTRY}${IMAGE}${TAG} sh -c "for t in \$(ls /test*.sh); do echo Running test \$t; \$t; done;" 
	else
		docker exec -it ${IMAGE} sh -c "for t in \$(ls /test*.sh); do echo Running test \$t; \$t; done;"
	fi
elif [ "$TO" == "kubernetes" ]; then
	CONTAINER_INDEX=$1
        if [ "$CONTAINER_INDEX" == "" ]; then
        	CONTAINER_INDEX=1
        fi
	CMD="unset DEBUG; ${KUBECTL} -n ${NAMESPACE} exec -it $( ${KUBECTL} -n ${NAMESPACE} get pod | grep ${APP_NAME} | head -n ${CONTAINER_INDEX} | cut -d ' ' -f 1 ) -- sh -c 'for t in \$(ls /test*.sh); do echo Running test \$t; \$t; done;'"
	if [ ! "$verbose" == "false" ]; then echo -e "${CMD}"; eval "${CMD}"; fi 
else
	echo "Running test for orchestrator $TO is not implemented"
fi

