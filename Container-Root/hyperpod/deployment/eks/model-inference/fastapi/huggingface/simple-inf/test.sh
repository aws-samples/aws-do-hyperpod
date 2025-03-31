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
	kubectl exec -it ${IMAGE} -- sh -c "for t in \$(ls /test*.sh); do echo Running test \$t; \$t; done;"
else
	echo "Running test for orchestrator $TO is not implemented"
fi



