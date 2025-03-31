#!/bin/bash

# Unit test of container

echo ""
echo "Running end-to-end test"

uvicorn_running=$(ps -aef | grep uvicorn | grep python | wc -l | xargs)

# Wait for service to start Running 
instances=$(ps -aef | grep uvicorn | grep python | wc -l | xargs)
if [ "$instances" == "0" ]; then
	echo "Starting server"
	./startup.sh &
else
	echo "Server is already running"
fi


# Wait for models to start serving
status_json=$(curl http://localhost:8080/)
server_status=$(echo $status_json | jq -r .Status)
while [ ! "$server_status" == "Serving" ]; do
	echo ""
	echo "Waiting for 'Serving' status. Current model status: ${server_status}"
	sleep 3
	status_json=$(curl http://localhost:8080/)
	server_status=$(echo $status_json | jq -r .Status)
done

echo ""
echo "Running inference tests ..."
# Run 5 predictions
for i in 1 2 3 4 5; do
	echo ""
	curl http://localhost:8080/predictions/model0
done

echo ""
echo "Test1 succeeded"
