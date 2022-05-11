# Configurations

Set below envrionment variables for terraform

## AWS
```
export AWS_ACCESS_KEY_ID="anaccesskey"  
export AWS_SECRET_ACCESS_KEY="asecretkey"  
export AWS_REGION="us-east-1"  
```

## Github
Update `terraform.auto.tfvars` file and add your Github microservice repository details in `actions`. Feel free to fork the existing repos from the file. Generate Github API token and add it as environment variable
```
export TF_VAR_github_token="github-token"  
```

## JFrog
Spin up JFrog artifactory server and create user with the access of `libs-release-local` and `libs-release` repository.
```
export TF_VAR_JFROG_USER=user
export TF_VAR_JFROG_PASS=pass
export TF_VAR_JFROG_URL=http://domain:port
```
# Install

- terraform init
- terraform plan
- terraform apply


# How to use?
Update any of the Java microservice repository present in `terraform.auto.tfvars` file and it should trigger a codepipeline which deploys to JFrog artifactory.

In case of this repo, below are the list of Java microservices which triggers the codepipeline.
- [java-microservice-api-gateway](https://github.com/yogingale/java-microservice-api-gateway)
- [java-microservice-car-service](https://github.com/yogingale/java-microservice-car-service)
- [java-microservice-discovery-service](https://github.com/yogingale/java-microservice-discovery-service)
