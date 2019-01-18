resource "aws_codebuild_project" "plan" {
  name          = "${var.name}-plan"
  description   = "Defines an environment for planning the execution of terraform scripts."
  service_role  = "${aws_iam_role.codebuild.arn}"
  build_timeout = "${var.build_timeout}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "${var.compute_type}"
    image        = "${var.image}"
    type         = "LINUX_CONTAINER"

    environment_variable = "${concat(var.environment_variables, local.environment_vars)}"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "${var.buildspec["plan"]}"
  }
}

resource "aws_codebuild_project" "apply" {
  name          = "${var.name}-apply"
  description   = "Defines an environment for executing a terraform plan."
  service_role  = "${aws_iam_role.codebuild.arn}"
  build_timeout = "${var.build_timeout}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "${var.compute_type}"
    image        = "${var.image}"
    type         = "LINUX_CONTAINER"

    environment_variable = "${concat(var.environment_variables, local.environment_vars)}"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "${var.buildspec["apply"]}"
  }
}

locals {
  environment_vars = [{
    "name"  = "TF_IN_AUTOMATION"
    "value" = "true"
  }]
}

data "aws_cloudwatch_log_group" "plan" {
  name = "/aws/codebuild/${aws_codebuild_project.plan.name}"
}

data "aws_cloudwatch_log_group" "apply" {
  name = "/aws/codebuild/${aws_codebuild_project.apply.name}"
}

# data "aws_caller_identity" "current" {}

# locals {
#   account_id           = "${data.aws_caller_identity.current.account_id}"
#   cloudwatch_plan_arn  = "arn:aws:logs:us-east-1:${local.account_id}:log-group:/aws/codebuild/${aws_codebuild_project.plan.name}:*"
#   cloudwatch_apply_arn = "arn:aws:logs:us-east-1:${local.account_id}:log-group:/aws/codebuild/${aws_codebuild_project.apply.name}:*"
# }

resource "aws_codepipeline" "pipeline" {
  name     = "${var.name}"
  role_arn = "${aws_iam_role.codepipeline.arn}"

  artifact_store = {
    location = "${var.artifacts_store}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source"]

      configuration {
        Owner  = "${var.owner}"
        Repo   = "${var.repository}"
        Branch = "${var.branch}"
      }
    }
  }

  stage {
    name = "Plan"

    action {
      name     = "Plan"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      role_arn         = "${aws_iam_role.terraform.arn}"
      input_artifacts  = ["source"]
      output_artifacts = ["plan"]

      configuration {
        ProjectName = "${aws_codebuild_project.plan.name}"
      }
    }
  }

  stage {
    name = "Approve"

    action {
      name     = "Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration {
        NotificationArn = "${var.notification_arn}"
        CustomData      = "Review the output of the `terraform plan` to ensure the changes are acceptable."
      }
    }
  }

  stage {
    name = "Apply"

    action {
      name     = "Apply"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      role_arn        = "${aws_iam_role.terraform.arn}"
      input_artifacts = ["source", "plan"]

      configuration {
        ProjectName   = "${aws_codebuild_project.apply.name}"
        PrimarySource = "source"
      }
    }
  }
}
