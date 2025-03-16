# Amazon EFS Support in SageMaker HyperPod EKS

Support for Amazon's Elastic File System is provided by the EFS CSI Driver.
The scripts included here offer a one-command deployment of the driver, creation of an EFS file system, a PVC and a sample pod with the EFS volume mounted.
Each of the script actions can be executed independently as needed. Each action is idempotent. An EFS file system is required for the creation of a storage class.

* [./efs-list.sh](efs-list.sh) - show a list of available EFS volumes and their tags.
* [./efs-create.sh](efs-create.sh) - create an EFS volume which the EKS cluster configured in the current context can access and tag this volume with `owner=$CLUSTER_NAME`.
* [./efs-delete.sh](efs-delete.sh) - delete a specified EFS volume.
* [./csi-deploy.sh](csi-deploy.sh) - deploy the EFS CSI driver on the current EKS cluster.
* [./csi-remove.sh](csi-remove.sh) - remove the EFS CSI driver from the current EKS cluster.
* [./sc-create.sh](sc-create.sh) - create a storage class using a specified EFS file system.
* [./sc-delete.sh](sc-delete.sh) - delete the storage class associated with a specified EFS file system.
* [./pvc-create.sh](pvc-create.sh) - create a PVC using the EFS storage class.
* [./pvc-delete.sh](pvc-delete.sh) - delete the EFS PVC.
* [./pod-create.sh](pod-create.sh) - create a sample pod which mounts the EFS PVC and periodically writes a timestamp into a file.
* [./pod-delete.sh](pod-delete.sh) - delete the sample pod.

For ease of use, the following one-click scripts are provided:

* [./deploy.sh](deploy.sh) - creates an EFS volume, deploys the EFS CSI driver, creates a storage class, PVC, and pod.
* [./remove.sh](remove.sh) - deletes the pod, PVC, storage class, removes the EFS CSI driver, and deletes the EFS volume.

# References
* [https://www.eksworkshop.com/docs/fundamentals/storage/efs/efs-csi-driver](https://www.eksworkshop.com/docs/fundamentals/storage/efs/efs-csi-driver)
* [https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html)
* [https://github.com/aws-samples/aws-do-eks/tree/main/Container-Root/eks/deployment/csi/efs](https://github.com/aws-samples/aws-do-eks/tree/main/Container-Root/eks/deployment/csi/efs)
