module "label" {
  source = "git::https://gitlab.com/infraprints/modules/terraform-terraform-unique-label"

  namespace  = "ACME"
  stage      = "proto"
  name       = "infrastructure"
  attributes = ["pipeline"]
}

/// IAM Policies for these
module "backend" {
  source = "git::https://gitlab.com/infraprints/modules/aws/terraform-remote-state"

  dynamo_name = "${local.table_id}"
  bucket      = "${local.bucket_id}"
  region      = "${local.region}"
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = "${module.example.codebuild_name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy" "backend" {
  name   = "TerraformStateBackend"
  role   = "${module.example.codebuild_name}"
  policy = "${data.aws_iam_policy_document.backend.json}"
}

data "aws_iam_policy_document" "backend" {
  statement {
    sid       = "S3RemoteState"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["${module.backend.bucket_arn}"]
  }

  statement {
    sid       = "ReadWriteStateFiles"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${module.backend.bucket_arn}/*"]
  }

  statement {
    sid       = "LockTable"
    effect    = "Allow"
    actions   = ["dynamodb:*"]
    resources = ["${module.backend.table_arn}"]
  }
}

// IAM policy for this

resource "aws_s3_bucket" "loc" {
  bucket        = "${module.label.id}-artifacts"
  force_destroy = true
}

resource "aws_sns_topic" "notification" {
  name = "user-updates-topic"
}

locals {
  env_vars = [
    {
      name  = "TF_STATE_REGION"
      value = "${local.region}"
    },
    {
      name  = "TF_STATE_BUCKET"
      value = "${local.bucket_id}"
    },
    {
      name  = "TF_STATE_DYNAMO_TABLE"
      value = "${local.table_id}"
    },
    {
      name  = "TF_ENVIRONMENT"
      value = "${local.environment}"
    },
    {
      name  = "TF_VAR_tf_state_region"
      value = "${local.region}"
    },
    {
      name  = "TF_VAR_tf_state_bucket"
      value = "${local.bucket_id}"
    },
    {
      name  = "TF_VAR_tf_state_dynamo_table"
      value = "${local.table_id}"
    },
    {
      name  = "TF_VAR_tf_environment"
      value = "${local.environment}"
    },
  ]
}

//convert to vars
locals {
  region      = "us-east-1"
  environment = "dev"
  bucket_id   = "acme-prototype-pipelines-cedd"
  table_id    = "acme-prototype-pipelines-cedd"
}

locals {
  infra_vars = [
    {
      name  = "CUSTOM"
      value = "DEFAULT_VALUE"
    },
  ]
}

//base environment
module "example" {
  source = "../../"

  name                 = "${module.label.id}"
  artifacts_store      = "${aws_s3_bucket.loc.bucket}"
  artifacts_bucket_arn = "${aws_s3_bucket.loc.arn}"
  notification_arn     = "${aws_sns_topic.notification.arn}"

  owner      = "jrbeverly"
  repository = "simple-terraform"
  branch     = "master"
  image      = "hashicorp/terraform:light"

  environment_variables = "${concat(local.infra_vars, local.env_vars)}"
}
