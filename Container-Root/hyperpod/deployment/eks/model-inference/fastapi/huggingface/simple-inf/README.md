# Container project description

This is a [do-framework](https://bit.ly/do-framework) project containing a simple model inference example, which works out of the box. 

This example works locally using Docker and can be deployed on a Kubernetes cluster.

To select the target orchestrator, set the `TO` property in the project configuration `.env` 

The project contains the following scripts:
* `config.sh` - open the configuration file .env in an editor so the project can be customized
* `build.sh` - build the container image
* `test.sh` - run container unit tests
* `push.sh` - push the container image to a registry
* `pull.sh` - pull the container image from a registry
* `run.sh [cmd]` - run the container, passing an argument overrides the default command
* `status.sh` - show container status - running, exited, etc.
* `logs.sh` - tail container logs
* `exec.sh [cmd]` - open a shell or execute a specified command in the running container
