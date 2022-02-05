# terraform-apollo-federation-infrastructure
Iac for apollo federation project.

Creating a ALP that has as target a Lambda function representing the Apollo Gateway from the Apollo federation project. 

--------------------------------
## Pre-requisites

Only using AWS services, an AWS account is required.

You will need to install [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)..

Clone the following [project]("https://github.com/inktense/apollo-federation) and run:

```
sls deploy
```

This will create the Lambda functions needed for the project.

---------------------------------------------------------------
## Deploying to the cloud

```
cd terraform 

tf init 
tf plan 
tf apply
```
In order to tear down the entire infrastructure use:
```
tf destroy
```

Remember to destroy the infrastructure after finishing with the project since ALB is a payed service.

---------------------------------------------------------------
## Usefull information

If you want to use Terraform with an AWS profile the only way it worked for me was using the following command:

```
export AWS_PROFILE= <profile>
```
