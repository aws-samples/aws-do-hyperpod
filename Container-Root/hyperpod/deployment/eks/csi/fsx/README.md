# FSxL Container Storage Interface

Run `csi-deploy.sh` first to deploy the csi driver, then create a FSxL volume with EFA enabled by running the `./fsx-create.sh` script.
Follow the workshop instructions for using FSxL (see reference below) with a static volume to enable volume mounts into your pods.


# References

* [SageMaker HyperPod EKS workshop](https://bit.ly/smhp-eks-workshop)
* [CSI driver](https://github.com/kubernetes-sigs/aws-fsx-csi-driver/tree/master)
* [Dynamic provisioning](https://github.com/kubernetes-sigs/aws-fsx-csi-driver/tree/master/examples/kubernetes/dynamic_provisioning)
* [Static provisioning](https://github.com/kubernetes-sigs/aws-fsx-csi-driver/tree/master/examples/kubernetes/static_provisioning)
* [Use existing FSxL volume from HyperPod EKS](https://catalog.us-east-1.prod.workshops.aws/workshops/2433d39e-ccfe-4c00-9d3d-9917b729258e/en-US/01-cluster/06-fsx-for-lustre#to-use-an-existing-fsxl-file-system-with-the-csi-driver-follow-the-below-steps)

