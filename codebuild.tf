resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  acl    = "private"
}

resource "aws_iam_role" "role" {
  name = "codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "policy" {
  role = aws_iam_role.role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterfacePermission"
      ],
      "Resource": [
        "arn:aws:ec2:us-east-1:123456789012:network-interface/*"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:AuthorizedService": "codebuild.amazonaws.com"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_codebuild_project" "build" {
  name          = var.codebuild_project_name
  description   = "codebuild_project"
  build_timeout = "60"
  service_role  = aws_iam_role.role.arn

  artifacts {
    type      = "CODEPIPELINE"
    packaging = "NONE"
  }

  cache {
    type = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "ONLY_SCAN"
      value = "true"
    }
    environment_variable {
      name  = "JFROG_USER"
      value = var.JFROG_USER
    }
    environment_variable {
      name  = "JFROG_PASS"
      value = var.JFROG_PASS
    }
    environment_variable {
      name  = "JFROG_URL"
      value = var.JFROG_URL
    }
  }

  logs_config {
    cloudwatch_logs {
      status      = "ENABLED"
      group_name  = "codebuild-logs"
      stream_name = "scan-logs"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
                version: 0.2
                #env:
                  #variables:
                     # key: "value"
                     # key: "value"
                #batch:
                  #fast-fail: true
                  #build-list:
                  #build-matrix:
                  #build-graph:
                phases:
                  install:
                    commands:
                      - echo Entering install phase...
                      - wget https://jcenter.bintray.com/org/apache/maven/apache-maven/3.3.9/apache-maven-3.3.9-bin.tar.gz 
                      - tar xzvf apache-maven-3.3.9-bin.tar.gz -C /opt/
                      - export PATH=/opt/apache-maven-3.3.9/bin:$PATH
                      - wget -qO - https://releases.jfrog.io/artifactory/jfrog-gpg-public/jfrog_public_gpg.key | sudo apt-key add -
                      - echo "deb https://releases.jfrog.io/artifactory/jfrog-debs xenial contrib" | sudo tee -a /etc/apt/sources.list;
                      - apt update;
                      - apt install -y jfrog-cli-v2;
                  pre_build:
                    commands:
                      - sudo su -
                      - mvn -version
                      - jfrog -version
                  build:
                    commands:
                      # - wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.3.0.1492-linux.zip
                      # - unzip sonar-scanner-cli-3.3.0.1492-linux.zip
                      # - export PATH=$PATH:./sonar-scanner-3.3.0.1492-linux/bin/
                      # - echo "scan command here"
                      # - cd ../..
                      # - mvn clean verify sonar:sonar -Dsonar.projectKey=ebuka-project-key -Dsonar.host.url=http://3.85.193.21:9000 -Dsonar.login=1458a3c2b1d119b0c86dfd947ffd197497c2f120

                      - echo Configuring jfrog cli
                      - jfrog config add --user $JFROG_USER --password $JFROG_PASS --url $JFROG_URL --artifactory-url $JFROG_URL/artifactory --interactive=false
                      - jfrog rt ping --url=$JFROG_URL/artifactory

                      - echo Maven compile and package
                      - mvn compile
                      - mvn package

                      - echo jfrog registry upload
                      - jfrog rt upload "*.jar" libs-release-local --build-name=java-microservices --build-number=$CODEBUILD_BUILD_ID
                      - echo Collect environment variables for the build
                      - jfrog rt bce java-microservices $CODEBUILD_BUILD_ID
                      - echo Publish build info
                      - jfrog rt bp java-microservices $CODEBUILD_BUILD_ID

                  #post_build:
                    #commands:
                      # - command
                      # - command
                #reports:
                  #report-name-or-arn:
                    #files:
                      # - location
                      # - location
                    #base-directory: location
                    #discard-paths: yes
                    #file-format: JunitXml | CucumberJson
                #artifacts:
                  #files:
                    # - location
                    # - location
                  #name: $(date +%Y-%m-%d)
                  #discard-paths: yes
                  #base-directory: location

                artifacts:
                  files:
                    - '**/*'
                  secondary-artifacts:
                    artifact1:
                      base-directory: $CODEBUILD_SRC_DIR
                      files:
                        - contract_artifact
                    artifact2:
                      base-directory: $CODEBUILD_SRC_DIR_source2
                      files:
                        - aggregator_artifact
                #cache:
                  #paths:
                    # - paths
            EOT
  }
  # source_version = "master"

  tags = {
    Environment = var.env
  }
}
