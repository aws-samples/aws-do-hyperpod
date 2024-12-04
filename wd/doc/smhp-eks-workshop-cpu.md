# Amazon SageMaker HyperPod EKS Workshop

Follow this workflow for AWS events hosting [this workshop](https://bit.ly/smhp-eks-workshop) on CPU instances 

    0. Prerequisites
        1. At an AWS Event
    1. Cluster Setup
        a. Setup Environment Variables
        b. Configure the EKS Cluster
        c. Install Dependencies
        d. Create the HyperPod Cluster
        e. View the AWS Console
    8. Observability
        1. Amazon CloudWatch Container Insights
            a. Container Insights setup
    5. Pytorch DDP on CPU
        c. Simple Execution
            9. Resiliency
                a. Manual Reboot (while training job is running)
    6. Ray on HyperPod
        a. Setup
		1. Open aws-do-ray container shell
		2. Configure AWS credentials and environment variables
		3. Verify connection to hyperpod cluster
		4. Setup dependencies
        c. Serving Stable Diffusion Model for Inference
		1. Create a RayService
		2. Access Ray Dashboard (Optional)
			a. Port-forward the service locally and use a terminal-based browser to view the dashoard
		3. Inference
			Edit `stable_diffusion_cpu_req.py` and modify the value of variable `prompt` to customize your request
    8. Observability
        1. Amazon CloudWatch Container Insights
            b. Container Insights Dashboards
