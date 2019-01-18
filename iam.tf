resource "aws_iam_role" "terraform" {
  name               = "${var.name}-terraform"
  #path = "/custom_path"
  description        = "Service-linked role used by Terraform Pipelines for executing terraform files."
  assume_role_policy = "${data.aws_iam_policy_document.terraform_assume_policy.json}"
}

data "aws_iam_policy_document" "terraform_assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.codepipeline.arn}"]
    }
  }
}

resource "aws_iam_role_policy" "terraform" {
  name   = "TerraformPolicy"
  role   = "${aws_iam_role.terraform.id}"
  policy = "${data.aws_iam_policy_document.terraform.json}"
}

data "aws_iam_policy_document" "terraform" {
  statement {
    sid       = "1"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["${var.artifacts_bucket_arn}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${var.artifacts_bucket_arn}/*"]
  }

  statement {
    sid    = "2"
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["${aws_codebuild_project.plan.id}", "${aws_codebuild_project.apply.id}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["${aws_iam_role.terraform.arn}"]
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "${var.name}-codebuild"
  description        = "Service-linked role used by Terraform Pipelines to enable integration of other AWS services with CodeBuild."
  assume_role_policy = "${data.aws_iam_policy_document.codebuild_assume_policy.json}"
}

data "aws_iam_policy_document" "codebuild_assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "codebuild" {
  name   = "CodeBuildPolicy"
  role   = "${aws_iam_role.codebuild.id}"
  policy = "${data.aws_iam_policy_document.codebuild.json}"
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    sid    = "CodeBuildPolicy"
    effect = "Allow"

    actions = [
      "codebuild:ListBuildsForProject",
      "codebuild:BatchGetBuilds",
      "codebuild:BatchGetProjects",
      "codebuild:BatchDeleteBuilds",
      "codebuild:CreateProject",
      "codebuild:DeleteProject",
      "codebuild:StartBuild",
      "codebuild:StopBuild",
      "codebuild:UpdateProject",
    ]

    resources = ["${aws_codebuild_project.apply.id}", "${aws_codebuild_project.plan.id}"]
  }

  statement {
    sid    = "CloudWatchLogsPolicy"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    sid       = "S3ObjectPolicy"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${var.artifacts_bucket_arn}/*"]
  }
}

## CodePipeline IAM

resource "aws_iam_role" "codepipeline" {
  name               = "${var.name}-codepipeline"
  description        = "Service-linked role used by Terraform Pipelines to enable integration of other AWS services with CodePipeline."
  assume_role_policy = "${data.aws_iam_policy_document.codepipeline_assume_policy.json}"
}

data "aws_iam_policy_document" "codepipeline_assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "codepipeline" {
  name   = "CodePipelinePolicy"
  role   = "${aws_iam_role.codepipeline.id}"
  policy = "${data.aws_iam_policy_document.codepipeline.json}"
}

data "aws_iam_policy_document" "codepipeline" {
  statement {
    sid       = "S3ObjectPolicy"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${var.artifacts_bucket_arn}/*"]
  }

  statement {
    sid    = "CodeBuildPolicy"
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["${aws_codebuild_project.plan.id}", "${aws_codebuild_project.apply.id}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["${aws_iam_role.terraform.arn}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = ["${var.notification_arn}"]
  }
}
