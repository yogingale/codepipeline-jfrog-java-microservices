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
                  #install:
                    #If you use the Ubuntu standard image 2.0 or later, you must specify runtime-versions.
                    #If you specify runtime-versions and use an image other than Ubuntu standard image 2.0, the build fails.
                    #runtime-versions:
                      # name: version
                      # name: version
                    #commands:
                      # - command
                      # - command
                  pre_build:
                    commands:
                      - sudo su -
                      - wget https://dlcdn.apache.org/maven/maven-3/3.8.5/binaries/apache-maven-3.8.5-bin.tar.gz 
                      - tar zxf apache-maven-3.8.5-bin.tar.gz
                      - cd apache-maven-3.8.5
                      - cd bin
                      - export M2_HOME=/opt/apache-maven-3.8.5
                      - export M2=$M2_HOME/bin
                      - export PATH=$PATH:$M2_HOME/bin
                      - sudo apt update -y
                      - sudo apt install openjdk-11-jdk -y
                      - export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 
                      - export PATH=$PATH:$JAVA_HOME/bin
                      - mvn -version
                  build:
                    commands:
                      # - wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.3.0.1492-linux.zip
                      # - unzip sonar-scanner-cli-3.3.0.1492-linux.zip
                      # - export PATH=$PATH:./sonar-scanner-3.3.0.1492-linux/bin/
                      # - echo "scan command here"
                      # - cd ../..
                      # - mvn clean verify sonar:sonar -Dsonar.projectKey=ebuka-project-key -Dsonar.host.url=http://3.85.193.21:9000 -Dsonar.login=1458a3c2b1d119b0c86dfd947ffd197497c2f120
                      # - echo "more commands"
                      # - for dir in ${join(" ",[for v in var.actions:  v.slug ])}; do
                      #     VAR=CODEBUILD_SRC_DIR_$dir;
                      #     DIR=$(eval "echo \"\$$VAR\"");
                      #     ls $DIR;
                      #   done
                      - jfrog c add --user admin --password password --url http://54.175.229.83:8081 --artifactory-url http://54.175.229.83:8081/artifactory --interactive false
                      - jfrog rt ping --url=http://54.175.229.83:8081/artifactory
                      - mvn compile
                      - mvn package
                      - jfrog rt u "*.jar" libs-release-local
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
