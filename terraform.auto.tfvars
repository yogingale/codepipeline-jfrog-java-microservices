# A unique bucket name
codepipeline_bucket_name = "codepipeline-jfrog-libs"

# A project name for your CodePipeline
codepipeline_name = "jfrog-artifactory-uploader"

# A project name for your CodeBuild
codebuild_project_name = "jfrog-artifactory-uploader"

env = "dev"

# List of repositories.
# repo is the repo name together with the user or organisation name
# slug is a short name to be used along with CodePipeline
actions = [
  {
    repo        = "yogingale/java-microservice-api-gateway",
    slug        = "microservice1",
    main_branch = "main"
  },
  {
    repo        = "yogingale/java-microservice-car-service",
    slug        = "microservice2",
    main_branch = "main"
  },
  {
    repo        = "yogingale/java-microservice-discovery-service",
    slug        = "microservice3",
    main_branch = "main"
  }
]
