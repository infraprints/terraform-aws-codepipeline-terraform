module "label" {
  source = "git::https://gitlab.com/infraprints/modules/terraform-terraform-unique-label"

  namespace  = "ACME"
  stage      = "proto"
  name       = "infrastructure"
  attributes = ["pipeline"]
}

resource "aws_s3_bucket" "loc" {
  bucket        = "${module.label.id}-artifacts"
  force_destroy = true
}

resource "aws_sns_topic" "notification" {
  name = "user-updates-topic"
}

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

  environment_variables = [
    {
      name  = "CUSTOM"
      value = "DEFAULT_VALUE"
    },
  ]
}
