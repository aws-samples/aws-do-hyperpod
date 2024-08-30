# multi-accelerator-hyperpod-eks
This is a hyperpod cluster configuration with multiple accelerator types. 
It contains one generic cpu instance group with ml.m5.2xlarge instances, two GPU instance groups ml.g5.8xlarge and ml.p5.48xlarge, and one Neuron instance group ml.trn1.48xlarge.
These instance types and their counts are customizable via the [`./env_input'](./env_input) file or by executing `./hyperpod-config.sh` in the `aws-do-hyperpod` container shell.

