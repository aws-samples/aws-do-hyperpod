# FSxL Container Storage Interface

Run `csi-deploy.sh` first to deploy the CSI driver. This creates the fsx-sc storage class.
You can create dynamic FSxL following the [pvc-dynamic.yaml](pvc-dynamic.yaml) example. Alternatively, you can create an FSxL volume, using the fsx-create.sh script, then create a Kubernetes persistent volume, using the [./pv-create.sh](pv-create.sh), providing the file system id as argument. You can create a static persistent volume claim, following the [pvc-static.yaml](pvc-static.yaml) example.
Follow the [SageMaker HyperPod EKS workshop](https://bit.ly/smhp-eks-workshop) instructions for step-by-step guidance if needed.


Once a Bound FSx PVC is available, you can create a test pod that mounts the FSx volume by running:

```sh
kubectl apply -f ./pod.yaml
```

# References

* [SageMaker HyperPod EKS workshop](https://bit.ly/smhp-eks-workshop)
* [CSI driver](https://github.com/kubernetes-sigs/aws-fsx-csi-driver/tree/master)
* [Dynamic provisioning](https://github.com/kubernetes-sigs/aws-fsx-csi-driver/tree/master/examples/kubernetes/dynamic_provisioning)
* [Static provisioning](https://github.com/kubernetes-sigs/aws-fsx-csi-driver/tree/master/examples/kubernetes/static_provisioning)
* [Use existing FSxL volume from HyperPod EKS](https://catalog.us-east-1.prod.workshops.aws/workshops/2433d39e-ccfe-4c00-9d3d-9917b729258e/en-US/01-cluster/06-fsx-for-lustre#to-use-an-existing-fsxl-file-system-with-the-csi-driver-follow-the-below-steps)

