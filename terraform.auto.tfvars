# A unique bucket name
codepipeline_bucket_name = "codepipeline-libs"

# A project name for your CodePipeline
codepipeline_name = "AB2D-LIBS"

# A project name for your CodeBuild
codebuild_project_name = "ab2d-libs-codebuild"

env = "dev"

# List of repositories.
# repo is the repo name together with the user or organisation name
# slug is a short name to be used along with CodePipeline
actions = [
  {
    repo        = "sb-ebukaanene/SpringChallenge2022",
    slug        = "contract",
    main_branch = "main"
  },
  { repo        = "sb-ebukaanene/simple-java-maven-app",
    slug        = "aggregator",
    main_branch = "main"
  }
]
