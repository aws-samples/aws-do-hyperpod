# aws-do-hyperpod-eks
This is the default HyperPod cluster configuration. 
It contains one accelerated and one generic instance group.
By default the accelerated instances are `ml.g5.8xlarge` and the generic instances are `ml.m5.2xlarge`.
These instance types and their counts are customizable via the [`./env_input'](./env_input) file or by executing `./hyperpod-config.sh` in the `aws-do-hyperpod` container shell.

